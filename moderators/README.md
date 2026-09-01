# Moderator Analysis of Prevalences of PTSD Trajectories

R Markdown workflow to run **moderator / meta‑regression analyses** for the FORAS meta‑analysis of PTSD trajectories. It loads the harmonised study dataset, defines candidate moderators, fits random‑effects models, and exports publication‑ready tables/figures.

---

## What it does
- Loads cleaned study‑level data (events, totals, study descriptors)
- Defines moderators (design/sample features, follow‑up, quality, etc.)
- Fits random‑effects meta‑regressions (and subgroup analyses when relevant)
- Reports effect sizes, CIs, heterogeneity (τ², I²), model fit
- Produces forest/coef plots and summary tables to `moderators/output/`

---

## Requirements

-   This file can be run on R versions 4.2 - 4.5.1
-   Rtools (Windows only) --- required for compiling `rstan` and `brms`
-   Required R packages:
    -   tidyverse
    -   lme4
    -   gt
    -   knitr
    -   brms
    -   rlang
    -   glue

---
### brms Dependency Note

The `brms` package requires **Stan** via the `rstan` backend. If you
encounter installation issues, also run:

``` r
install.packages("rstan")
```

On **Windows**, make sure **Rtools** is installed *before* installing
`rstan` or `brms`.

Download Rtools here:\
https://cran.r-project.org/bin/windows/Rtools/

### Installation

Install all required packages with:

``` r
install.packages(c(
    "tidyverse",
    "lme4",
    "gt",
    "knitr",
    "brms",
    "rlang",
    "glue"
))
```
---

## Inputs
- The combined dataset `pre-processing/output/data_for_moderation_analyses.csv`
---

## How to run
From RStudio: open `moderators/Moderator_analysis.Rmd` → **Knit**.  
From R:
```r
rmarkdown::render("moderators/Moderator_analysis.Rmd")
```
Outputs (HTML by default) and figures/tables are written under `moderators/` (see Rmd for exact paths).

---

## License / Citation
- License: MIT (see repository root).  
- Please cite the FORAS meta‑analysis project/preprint when using these materials.
