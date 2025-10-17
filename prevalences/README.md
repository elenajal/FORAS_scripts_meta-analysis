# Prevalence Estimates for the Meta-analysis of PTSD Symptom Trajectories

R Markdown workflow to compute and visualise pooled **prevalence** estimates for the FORAS project on PTSD trajectories after traumatic events. It loads study-level counts, runs meta-analyses of proportions, and exports publication-ready figures/tables. The script lives at:

```
prevalences/Prevalences_analysis.Rmd
```
---

## What this does

- Reads extracted study data (events / totals)
- Computes pooled prevalence (random-effects), with common transformations for proportions
- Quantifies heterogeneity (τ², I²) and influence diagnostics
- Produces forest and (optionally) funnel-type plots
- Writes summaries/plots to `prevalences/output/`

---

## Requirements

- R (≥ 4.2)
- R packages: `rmarkdown`, `tidyverse`, `metafor`, `meta` (and any others called at the top of the Rmd)

Install essentials:

```r
install.packages(c("rmarkdown", "tidyverse", "metafor", "meta"))
```

---

## Inputs
- The combined dataset `pre-processing/output/data_for_moderation_analyses.csv`
---

## How to run

From RStudio: open `prevalences/Prevalences_analysis.Rmd` and **Knit**.

From R:

```r
rmarkdown::render("prevalences/Prevalences_analysis.Rmd")
```

Outputs (HTML by default) and figures are saved under `prevalences/` (see the Rmd for exact paths).

---
