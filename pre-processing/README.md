# Scipt for merging data extraction tables

## Overview
This script merges study-level metadata, model results, and Grolts quality scores into a single, analysis‑ready CSV. It performs sanity checks (duplicates, overlaps, and missing IDs), harmonises columns, coerces types, and derives a simple US/Other location flag.

## Inputs (expected relative paths)
Place these in `../data` (one level **above** the script):
- `Data_extraction_general_data.xlsx` — must include `MID` and `Final selection` (or `Final Selection`, which is auto-renamed).
- `Data_extraction_model_results.xlsx` — must include `MID` and `Final selection`.
- `grolts_scores.csv` — columns: `paper_id`, `score` (mapped to `MID` prefix and `Grolts`).

## What the script does
1. **Load & filter** rows with `Final selection != 0` from both Excel sources.
2. **Sanity checks** printed to stdout:
   - Duplicate `MID`s per dataset.
   - Common `MID`s between datasets (expected counts: 113 for general↔model, 99 for model↔Grolts).
   - Missing `MID`s (exact match for most; prefix match for Grolts).
3. **Merge** general ↔ model on `MID`.
4. **Attach Grolts** by extracting a base ID (`MID_base`) via regex `^(MU?\d+)` and left-joining the scores.
5. **Derive** `Location_US` from `"Location? Where the study is based"` (values `US`/`USA` → `US`, everything else → `Other`).
6. **Select analysis columns**, normalise `'NR'` tokens to `NaN` in key columns, then **coerce** numeric columns (floats/nullable ints).
7. **Write output** to `./output/data_for_moderation_analyses.csv` (semicolon-separated).

## Output
`./output/data_for_moderation_analyses.csv` — tidy dataset with selected variables, numeric types coerced, and a `Location_US` flag; delimiter `;`.
