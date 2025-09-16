import pandas as pd
import numpy as np
import re

# Load the data
from pathlib import Path
DATA = Path("../data")

df_general = (
    pd.read_excel(DATA / "Data_extraction_general_data.xlsx")
      .rename(columns={"Final Selection": "Final selection"})
      .loc[lambda d: d["Final selection"].ne(0)]
      .copy()
)

df_model_results = (
    pd.read_excel(DATA / "Data_extraction_model_results.xlsx")
      .loc[lambda d: d["Final selection"].ne(0)]
      .copy()
)

grolts_scores = (
    pd.read_csv(DATA / "grolts_scores.csv", usecols=["paper_id", "score"])
      .rename(columns={"paper_id": "MID", "score": "Grolts"})
)


def print_duplicates(df, name):
    dupes = df[df.duplicated("MID", keep=False)]
    
    if not dupes.empty:
        print(f"\n???? Non-unique MIDs in {name}:")
        print(dupes[["MID"]].drop_duplicates())
    else:
        print(f"\n??? No duplicate MIDs in {name}.")


def print_common_mids(df1, df2, name1, name2, expected_count=None, show=0):
  
    for df, nm in [(df1, name1), (df2, name2)]:
        if "MID" not in df.columns:
            print(f"???[{nm}] column 'MID' not found.")
            return set()

    mids1 = set(df1["MID"].dropna())
    mids2 = set(df2["MID"].dropna())
    common = mids1 & mids2

    u1, u2, uc = len(mids1), len(mids2), len(common)

    if expected_count is None:
        print(f"\n???? Common MIDs between {name1} and {name2}: {uc}")
    else:
        status = "???" if uc == expected_count else "???"
        print(f"\n{status} Common MIDs between {name1} and {name2}: {uc} (expected {expected_count})")

    print(f"{name1} unique MIDs: {u1} | {name2} unique MIDs: {u2}")
    

def print_missing_mids(source_df, target_df, source_name, target_name, contains=False, show=0):
  
    for df, nm in [(source_df, source_name), (target_df, target_name)]:
        if "MID" not in df.columns:
            print(f"???[{nm}] column 'MID' not found.")
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

    status = "???" if count == 0 else "???"
    print(f"\n{status} MIDs in {source_name} but not in {target_name}: {count}")

    if show and count:
        examples = sorted(missing)[:show]
        print(f"Examples ({len(examples)} of {count}): {examples}")

    return missing.tolist()

# === Run Sanity Checks ===

def run_sanity_checks(df_general, df_model_results, grolts_scores):
    datasets = {
        "df_general": df_general,
        "df_model_results": df_model_results,
        "grolts_scores": grolts_scores,
    }

    # 1) Duplicates
    for name, df in datasets.items():
        print_duplicates(df, name)

    # 2) Common MIDs (with expected counts)
    for a, b, expected in [
        ("df_general", "df_model_results", 113),
        ("df_model_results", "grolts_scores", 99),
    ]:
        print_common_mids(datasets[a], datasets[b], a, b, expected_count=expected)

    # 3) Missing MIDs (exact vs prefix match)
    for src, tgt, contains in [
        ("df_general", "df_model_results", False),
        ("df_model_results", "df_general", False),
        ("df_model_results", "grolts_scores", True),
        ("grolts_scores", "df_model_results", False),
    ]:
        print_missing_mids(datasets[src], datasets[tgt], src, tgt, contains=contains)

# Run once:
run_sanity_checks(df_general, df_model_results, grolts_scores)


# === Merge data ===

# 4) Merge on 'MID', then bring in grolts by matching a 'MID_base' prefix
merged_df = df_general.merge(
    df_model_results, on="MID", suffixes=("_general", "_model_results")
)

merged_df["MID_base"] = merged_df["MID"].astype(str).str.extract(r"^(MU?\d+)", expand=False)

grolts = grolts_scores.rename(columns={"MID": "MID_base"})

merged_df = merged_df.merge(grolts, on="MID_base", how="left")

merged_df = merged_df.drop(columns="MID_base")

# 5) Filter rows

LOC_COL = "Location? Where the study is based"

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

# Keep only rows used for analysis
merged_df = merged_df.loc[merged_df["Final selection"].ne(0)].copy()

# 6) Simple US indicator from the location text

loc_norm = merged_df[LOC_COL].astype(str).str.strip().str.upper()
merged_df["Location_US"] = loc_norm.isin({"US", "USA"}).map({True: "US", False: "Other"})

# 7) Keep only the analysis columns (order preserved)

merged_df = merged_df.loc[:, ANALYSIS_COLS]

# 8) Convert any 'NR' (in any case, anywhere in the string) to NaN in selected columns

NR_COLS = [
    "Mean_age", "Entropy", "High_education",
    "Percentage_partner", "Percentage_minority", "Percentage_women",
]

for col in NR_COLS:
    s = merged_df[col].astype(str)
    merged_df[col] = merged_df[col].where(~s.str.contains("NR", case=False, na=False), np.nan)

# 9) Convert columns to numeric types (floats vs. nullable ints)

FLOAT_COLS = [
    "Mean_age","Percentage_women","Percentage_minority","Percentage_partner",
    "High_education","Trauma_TP1","TP1_TPX","Trauma_TPX","Entropy",
    "Low_rate","Low_percentage","Decreasing_rate","Decreasing_percentage",
    "Increasing_rate","Increasing_percentage","High_rate","High_percentage",
    "Moderate_rate","Moderate_percentage","Relapsing_rate",
    "Worsened_improved_percentage",
]

INT_COLS = [
    "Cohorts","Sample_Size","N_trajectories","Low","Decreasing","Increasing",
    "High","Moderate","Relapsing","Worsened_improving","Merging","Relabeling",
    "Worsened_improved","TP_assessments",
]

# Ints: coerce ??? round ??? convert to nullable integer (keeps NaNs)
merged_df[int_cols] = (
    merged_df[int_cols]
      .apply(pd.to_numeric, errors="coerce")
      .round()
      .astype("Int64")
)

# 10. Save to file
merged_df.to_csv("./output/data_for_moderation_analyses.csv", index=False, sep=';')
