[![DOI](https://zenodo.org/badge/1054345057.svg)](https://doi.org/10.5281/zenodo.17098304)

# Overview

This repository is part of the **Hunt for the Last Relevant Paper** project,
pre-registered  as "[Trajectories of PTSD Following Traumatic Events: A Systematic and Multi-database Review](https://www.crd.york.ac.uk/prospero/display_record.php?RecordID=494027)".

The current repository is focusing on the scripts used for the meta-analysis (Pre-print: https://doi.org/10.31219/osf.io/fkjb2_v1).

# Contents

## `merge_tables.py`

- Within `pre-processing` folder

- **Purpose**: Combining the three data files (`Data_extraction_general_data.xlsx`, `Data_extraction_model_results.xlsx`, `grolts_scores.csv`) into one (`data_for_moderation_analyses.csv`) for further analysis.

- **Features**:
   - Merge the three data files
   - Clean up the data
   - Ensure columns have the correct data types
   - Test whether each record can be matched correctly between the three files
   - Outputs the `data_for_moderation_analyses.csv` in the `./pre-processing/output` folder

## `Prevalences_analysis.Rmd`

- Located within `prevalences` folder

- **Purpose**: R Markdown workflow to compute and visualise pooled **prevalence** estimates for the FORAS project on PTSD trajectories after traumatic events.

- **Features**:
   - Reads extracted study data (events / totals)
   - Computes pooled prevalence (random-effects), with common transformations for proportions
   - Quantifies heterogeneity (τ², I²) and influence diagnostics
   - Produces forest and (optionally) funnel-type plots
   - Writes summaries/plots to `prevalences/output/`

## `Moderator_analysis.Rmd`

- Located within `moderators` folder

- **Purpose**: R Markdown workflow to run **moderator / meta‑regression analyses** for the FORAS meta‑analysis of PTSD trajectories. 

- **Features**:
   - Loads cleaned study‑level data (events, totals, study descriptors)
   - Defines moderators (design/sample features, follow‑up, quality, etc.)
   - Fits random‑effects meta‑regressions (and subgroup analyses when relevant)
   - Reports effect sizes, CIs, heterogeneity (τ², I²), model fit
   - Produces forest/coef plots and summary tables to `moderators/output/`
  
## `timeline_visualisation`
- Located in `timeline visualisation/`
- **Purpose**: Creates **timeline plots** of study assessments and follow-ups to visualise when PTSD trajectories were measured.  
- **Features**:
  - Reads dataset (`Data_extraction_model_results.xlsx`) from `data/` directory
  - Produces timeline graphics for each study or aggregated across studies
  - Helps contextualise follow-up timepoints across included studies
  - Outputs figures to `timeline visualisation/output/`

## `worldmap_visualization`
- Located in `worldmap visualization/`
- **Purpose**: Generates a **world map** displaying the geographical distribution of included studies.  
- **Features**:
  - Reads dataset (`Data_extraction_general_data.xlsx`) from `data/` directory
  - Maps study locations by country
  - Highlights global spread and potential clustering of research
  - Outputs figures to `worldmap visualization/output/`

# Usage

## Load Data

### Required Input Data for `merge_tables.py`

1. `Data_extraction_general_data.xlsx` – general extracted study data  
2. `Data_extraction_model_results.xlsx` – model-specific results  
3. `grolts_scores.csv` – GRoLTS scores (for details on calculation see: https://doi.org/10.5281/zenodo.17100045)

These datasets will be made available on DataVerseNL.

### Running the Merging Script

```bash
git clone https://github.com/yourusername/FORAS_scripts_meta-analysis.git
cd FORAS_scripts_meta-analysis

# Run merging script
python ./pre-processing/merge_tables.py
```

This generates the combined dataset `pre-processing/output/data_for_moderation_analyses.csv`.

## Running Analyses

Both R Markdown notebooks require the merged `data_for_moderation_analyses.csv` dataset:

- `prevalences/Prevalences_analysis.Rmd`
- `moderators/Moderator_analysis.Rmd`

Run them in RStudio or via `rmarkdown::render()` after ensuring `data_for_moderation_analyses.csv` is in the expected `pre-processing/output/` folder.

## Running Visualisations

### Timeline Visualisation

```bash
cd "timeline visualisation"
Rscript timeline_visualisation.R
```

- Requires: `data/Data_extraction_model_results.xlsx`  
- Output: Timeline plots in `timeline visualisation/output/`

### Worldmap Visualisation

```bash
cd "worldmap visualization"
Rscript worldmap_visualization.R
```

- Requires: `data/Data_extraction_general_data.xlsx` 
- Output: World map figures in `worldmap visualization/output/`

# Funding 
The research is supported by the Dutch Research Council under grant number 406.22.GO.048

# Contact
For questions contact Rens van de Schoot (a.g.j.vandeschoot@uu.nl) 

