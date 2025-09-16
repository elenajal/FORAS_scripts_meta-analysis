# Prevalence Trajectories — GLMM Meta‑Analysis (R Markdown)

This project estimates pooled prevalences of PTSD symptom **trajectory classes** (Low, Decreasing, Increasing, Moderate, High) across studies using generalized linear mixed models (GLMMs). It renders an HTML report (and optionally Word/PDF) from `Prevalences_analysis.Rmd`.

## Functions
- Loads study‑level data and computes descriptives.
- Fits random‑effects GLMMs on logit proportions via `metafor::rma.glmm()` (primary) and complementary `lme4::glmer()` models.
- Applies a small continuity correction for 0%/100% cells.
- Runs sensitivity analyses (drop ≥90% cells, large‑N only, influence diagnostics via Cook’s distance).
- Produces a table of **relative prevalence** across trajectories.

## Input data
- Expected file: `../pre-processing/output/data_for_moderation_analyses.csv` (semicolon‑separated).
- Required columns (example): `Study`, `Study_ID`, `Sample_Size`, `Mean_age`, `Percentage_women`, `Assessed_trauma_type`, `Military`/`Mil`, `TP_assessments`, `N_trajectories`, trajectory counts and/or percentages: `Low_n`, `Decreasing_n`, `Increasing_n`, `Moderate_n`, `High_n` (+ optional `%` columns).  
  *Adjust the data path in the load‑data chunk if needed.*

## Requirements
- **R** ≥ 4.0
- Packages: `readr`, `metafor`, `lme4`, `influence.ME`, `dplyr`, `gt`, `knitr`, `rmarkdown`, `rstudioapi`
```r
install.packages(c("readr","metafor","lme4","influence.ME","dplyr","gt","knitr","rmarkdown","rstudioapi"))
# For PDF output:
# tinytex::install_tinytex()
```

## Outputs
- HTML report with descriptives, pooled prevalence (95% CI) per trajectory, sensitivity analyses, influence diagnostics, and a formatted “Table 1” of relative prevalences.
- Optional DOCX/PDF versions (configure in YAML).

---
*File: `README.md` for `Prevalences_analysis.Rmd`*
