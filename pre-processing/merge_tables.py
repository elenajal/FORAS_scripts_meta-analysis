"""Data preparation pipeline for moderation analyses.

This script merges extraction sheets, runs sanity checks, enforces a stable output schema,
and writes a semicolon-separated CSV for downstream analyses.

Overview of steps:
1) Load three input files from ../data:
   - Data_extraction_general_data.xlsx
   - Data_extraction_model_results.xlsx
   - grolts_scores.csv
2) Normalize IDs (MID), run sanity checks (duplicates, overlaps, missing IDs).
3) Merge the general and model-results sheets on MID (inner join).
4) Extract a base MID to join Grolts scores (left join).
5) Filter to rows marked for analysis using "Final selection" from the general sheet.
6) Build location fields: pass-through free-text Location and binary Location_US (US vs Other).
7) Enforce the ANALYSIS_COLS schema (add missing columns as NA, reorder).
8) Clean conservative "NR"/"NA" tokens in select columns; coerce float/int dtypes.
9) Save to ./output/data_for_moderation_analyses.csv (semicolon-separated).

Usage:
    python prepare_moderation_data.py

Requirements:
    pandas, numpy, openpyxl (for .xlsx)
"""

from pathlib import Path
import pandas as pd
import numpy as np

# ----------------------------
# Config
# ----------------------------
# Input/output directories relative to this script's location.
DATA = Path("../data")
OUT = Path("./output")
OUT.mkdir(parents=True, exist_ok=True)

#: Columns guaranteed to exist in the final output (schema contract).
ANALYSIS_COLS = [
    "Study","Cohorts","MID","Grolts","Sample_Size","Mean_age","Developmental_age",
    "Percentage_women","Percentage_minority","Percentage_partner","High_education",
    "Location","Location_US","Assessed_trauma_type","Discrete","Health_First",
    "Trauma_type","Military","Occupational_trauma","Trauma_exposure",
    "Scale_moderator","Diagnostic_moderator","Diagnostic_DSM","Trajectory_analysis",
    "TP_assessments","N_trajectories","Trauma_TP1","TP1_TPX","Trauma_TPX",
    "Entropy","Low","Decreasing","Increasing","High","Moderate","Relapsing",
    "Worsened_improving","Low_rate","Low_percentage","Decreasing_rate",
    "Decreasing_percentage","Increasing_rate","Increasing_percentage","High_rate",
    "High_percentage","Moderate_rate","Moderate_percentage","Relapsing_rate",
    "Merging","Relabeling","Worsened_improved","Worsened_improved_percentage",
]

#: Preferred source column for free-text location (if present).
LOC_COL = "Location? Where the study is based"

#: Columns coerced to float dtype.
FLOAT_COLS = [
    "Mean_age","Percentage_women","Percentage_minority","Percentage_partner",
    "High_education","Trauma_TP1","TP1_TPX","Trauma_TPX","Entropy",
    "Low_rate","Low_percentage","Decreasing_rate","Decreasing_percentage",
    "Increasing_rate","Increasing_percentage","High_rate","High_percentage",
    "Moderate_rate","Moderate_percentage","Relapsing_rate",
    "Worsened_improved_percentage",
]

#: Columns coerced to nullable integer dtype (`Int64`).
INT_COLS = [
    "Cohorts","Sample_Size","N_trajectories","Low","Decreasing","Increasing",
    "High","Moderate","Relapsing","Worsened_improving","Merging","Relabeling",
    "Worsened_improved","TP_assessments",
]

# ----------------------------
# Helpers
# ----------------------------
def _normalize_mid(s: pd.Series) -> pd.Series:
    """Normalize ID strings (MID).

    Operations:
      - cast to string
      - strip surrounding whitespace
      - collapse internal whitespace
      - uppercase

    Parameters
    ----------
    s : pd.Series
        Series containing MID values.

    Returns
    -------
    pd.Series
        Normalized MID series (dtype: string/object as input).
    """
    return (
        s.astype(str)
         .str.strip()
         .str.replace(r"\s+", "", regex=True)
         .str.upper()
    )

def _clean_nr(series: pd.Series) -> pd.Series:
    """Replace common 'not reported' tokens with NaN conservatively.

    Tokens matched (case-insensitive, surrounded by optional whitespace):
        NR, N/R, N.R., NA, N.A.

    Parameters
    ----------
    series : pd.Series
        Input series (typically object/string).

    Returns
    -------
    pd.Series
        Series where exact matches to the above tokens are set to np.nan.
    """
    s = series.astype(str)
    mask = s.str.fullmatch(r"\s*(NR|N/R|N\.R\.|NA|N\.A\.)\s*", case=False, na=False)
    return series.mask(mask, np.nan)

def _ensure_columns(df: pd.DataFrame, cols: list[str]) -> pd.DataFrame:
    """Ensure all columns exist in DataFrame, adding missing as NA (object dtype).

    Parameters
    ----------
    df : pd.DataFrame
        Input DataFrame.
    cols : list[str]
        Required columns.

    Returns
    -------
    pd.DataFrame
        Same DataFrame with any missing columns added (filled with NA).
    """
    missing = [c for c in cols if c not in df.columns]
    for c in missing:
        df[c] = pd.Series(pd.NA, index=df.index, dtype="object")
    return df

def print_duplicates(df: pd.DataFrame, name: str) -> None:
    """Print duplicate MID values (if any) for a dataset.

    Parameters
    ----------
    df : pd.DataFrame
        Dataset to inspect.
    name : str
        Label used in the printed output.
    """
    dupes = df[df.duplicated("MID", keep=False)]
    if not dupes.empty:
        print(f"\n🔁 Non-unique MIDs in {name}:")
        print(dupes[["MID"]].drop_duplicates())
    else:
        print(f"\n✅ No duplicate MIDs in {name}.")

def print_common_mids(
    df1: pd.DataFrame,
    df2: pd.DataFrame,
    name1: str,
    name2: str,
    expected_count: int | None = None,
    show: int = 0,
) -> set:
    """Print counts of unique and overlapping MID values across two datasets.

    Parameters
    ----------
    df1, df2 : pd.DataFrame
        Datasets to compare (must contain 'MID').
    name1, name2 : str
        Labels used in the printed output.
    expected_count : int | None, optional
        If provided, prints a checkmark/cross depending on whether the
        overlap equals this expected count.
    show : int, optional
        Unused here (kept for interface symmetry).

    Returns
    -------
    set
        Set of common MID values.
    """
    for df, nm in [(df1, name1), (df2, name2)]:
        if "MID" not in df.columns:
            print(f"❗[{nm}] column 'MID' not found.")
            return set()

    mids1 = set(df1["MID"].dropna())
    mids2 = set(df2["MID"].dropna())
    common = mids1 & mids2

    u1, u2, uc = len(mids1), len(mids2), len(common)

    if expected_count is None:
        print(f"\n🔗 Common MIDs between {name1} and {name2}: {uc}")
    else:
        status = "✅" if uc == expected_count else "❌"
        print(f"\n{status} Common MIDs between {name1} and {name2}: {uc} (expected {expected_count})")

    print(f"{name1} unique MIDs: {u1} | {name2} unique MIDs: {u2}")
    return common

def print_missing_mids(
    source_df: pd.DataFrame,
    target_df: pd.DataFrame,
    source_name: str,
    target_name: str,
    contains: bool = False,
    show: int = 0,
) -> list[str]:
    """Print which MIDs in source are missing from target.

    Parameters
    ----------
    source_df, target_df : pd.DataFrame
        Datasets to compare (must contain 'MID').
    source_name, target_name : str
        Labels used in output messages.
    contains : bool, default False
        If True, consider a source MID present if it **starts with** any target MID
        (useful when source MIDs have suffixes). Otherwise, require exact match.
    show : int, default 0
        If > 0, prints up to `show` example missing IDs.

    Returns
    -------
    list[str]
        List of missing MID values from the source perspective.
    """
    for df, nm in [(source_df, source_name), (target_df, target_name)]:
        if "MID" not in df.columns:
            print(f"❗[{nm}] column 'MID' not found.")
            return []

    s = source_df["MID"].dropna().astype(str)
    t = target_df["MID"].dropna().astype(str)

    if contains:
        prefixes = tuple(t.unique())
        present_mask = s.str.startswith(prefixes) if prefixes else s.apply(lambda _: False)
    else:
        present_mask = s.isin(set(t))

    missing = s[~present_mask].unique()
    count = len(missing)

    status = "✅" if count == 0 else "❌"
    print(f"\n{status} MIDs in {source_name} but not in {target_name}: {count}")

    if show and count:
        examples = sorted(missing)[:show]
        print(f"Examples ({len(examples)} of {count}): {examples}")

    return missing.tolist()

# ----------------------------
# Load
# ----------------------------
df_general = (
    pd.read_excel(DATA / "Data_extraction_general_data.xlsx", dtype={"MID": "string"})
      .rename(columns={"Final Selection": "Final selection"})
      .loc[lambda d: d["Final selection"].ne(0)]
      .copy()
)

df_model_results = (
    pd.read_excel(DATA / "Data_extraction_model_results.xlsx", dtype={"MID": "string"})
      .rename(columns={"Final Selection": "Final selection"})
      .loc[lambda d: d["Final selection"].ne(0)]
      .copy()
)

grolts_scores = (
    pd.read_csv(DATA / "grolts_scores.csv", usecols=["paper_id", "score"])
      .rename(columns={"paper_id": "MID", "score": "Grolts"})
)

# Normalize MID early
for _df in (df_general, df_model_results, grolts_scores):
    if "MID" in _df.columns:
        _df["MID"] = _normalize_mid(_df["MID"])

# ----------------------------
# Sanity checks
# ----------------------------
def run_sanity_checks(
    df_general: pd.DataFrame,
    df_model_results: pd.DataFrame,
    grolts_scores: pd.DataFrame,
) -> None:
    """Run basic sanity checks and print summaries.

    Checks:
      1) Duplicate MIDs within each dataset.
      2) Common MIDs across pairs of datasets (optionally assert expected counts).
      3) Missing MIDs between datasets (exact vs prefix match).

    Parameters
    ----------
    df_general, df_model_results, grolts_scores : pd.DataFrame
        Input datasets.
    """
    datasets = {
        "df_general": df_general,
        "df_model_results": df_model_results,
        "grolts_scores": grolts_scores,
    }
    # 1) Duplicates
    for name, df in datasets.items():
        print_duplicates(df, name)
    # 2) Common MIDs (with expected counts if you want to enforce)
    for a, b, expected in [
        ("df_general", "df_model_results", None),   # set numbers if you really want strict checks
        ("df_model_results", "grolts_scores", None),
    ]:
        print_common_mids(datasets[a], datasets[b], a, b, expected_count=expected)
    # 3) Missing MIDs (exact vs prefix match)
    for src, tgt, contains in [
        ("df_general", "df_model_results", False),
        ("df_model_results", "df_general", False),
        ("df_model_results", "grolts_scores", True),   # model results may have suffixed MIDs
        ("grolts_scores", "df_model_results", False),
    ]:
        print_missing_mids(datasets[src], datasets[tgt], src, tgt, contains=contains, show=10)

run_sanity_checks(df_general, df_model_results, grolts_scores)

# ----------------------------
# Merge
# ----------------------------
merged_df = df_general.merge(
    df_model_results, on="MID", suffixes=("_general", "_model_results"), how="inner"
)

# Extract a base MID
merged_df["MID_base"] = (
    merged_df["MID"]
      .str.extract(r"([A-Z]*U?\d+)", expand=False)
      .astype("string")
)

grolts = grolts_scores.rename(columns={"MID": "MID_base"})
merged_df = merged_df.merge(grolts, on="MID_base", how="left").drop(columns="MID_base")

# ----------------------------
# Filter rows USED FOR ANALYSIS
# ----------------------------
# Prefer one provenance; here we keep the 'general' flag after the merge
final_sel_col_general = "Final selection_general" if "Final selection_general" in merged_df.columns else "Final selection"
if final_sel_col_general not in merged_df.columns:
    raise KeyError("Could not find a 'Final selection' column to filter on.")
merged_df = merged_df.loc[merged_df[final_sel_col_general].ne(0)].copy()

# ----------------------------
# Location columns
# ----------------------------
# Choose source for location text
if LOC_COL in merged_df.columns:
    loc_src = merged_df[LOC_COL].astype("string")
elif "Location" in merged_df.columns:
    loc_src = merged_df["Location"].astype("string")
else:
    loc_src = pd.Series(pd.NA, index=merged_df.index, dtype="string")

# Create normalized 'Location' and binary 'Location_US'
merged_df["Location"] = loc_src
loc_norm = loc_src.fillna("").str.strip().str.upper()
merged_df["Location_US"] = np.where(
    loc_norm.str.fullmatch(r"(US|USA|UNITED STATES|UNITED STATES OF AMERICA)\.?",
                           case=False, na=False),
    "US",
    "Other",
)

# ----------------------------
# Keep only analysis columns (make schema stable)
# ----------------------------
merged_df = _ensure_columns(merged_df, ANALYSIS_COLS).loc[:, ANALYSIS_COLS]

# ----------------------------
# Clean NR tokens conservatively
# ----------------------------
for col in [
    "Mean_age", "Entropy", "High_education",
    "Percentage_partner", "Percentage_minority", "Percentage_women",
]:
    if col in merged_df.columns:
        merged_df[col] = _clean_nr(merged_df[col])

# ----------------------------
# Type conversions
# ----------------------------
# Floats
present_float_cols = [c for c in FLOAT_COLS if c in merged_df.columns]
merged_df[present_float_cols] = merged_df[present_float_cols].apply(pd.to_numeric, errors="coerce")

# Ints (no rounding; enforce integer-ness)
present_int_cols = [c for c in INT_COLS if c in merged_df.columns]
merged_df[present_int_cols] = (
    merged_df[present_int_cols]
      .apply(pd.to_numeric, errors="coerce")
      .astype("Int64")
)

# ----------------------------
# Save
# ----------------------------
out_file = OUT / "data_for_moderation_analyses.csv"
merged_df.to_csv(out_file, index=False, sep=";")
print(f"✅ Wrote {len(merged_df):,} rows to {out_file}")
