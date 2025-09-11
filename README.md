[![DOI](https://zenodo.org/badge/1054345057.svg)](https://doi.org/10.5281/zenodo.17098304)

# Overview

This repository is part of the **Hunt for the Last Relevant Paper** project,
pre-registered  as "[Trajectories of PTSD Following Traumatic Events: A
Systematic and Multi-database Review]
(https://www.crd.york.ac.uk/prospero/display_record.php?RecordID=494027)".

The current repository is focusing on the scripts used for the meta-analysis (Pre-print: https://doi.org/10.31219/osf.io/fkjb2_v1).

# Contents

## GLMM_Final.R

- **Purpose**: Processing and applying generalized linear mixed methods as an meta-analytical approach to PTSD symptoms trajectories.

- **Features**:
  - Estimate relative prevalence for PTSD symptoms trajectories
  - Moderation analysis 
  - Sensitive analysis 


## Required Input Datasets

The following datasets are required to run the notebooks:

1. **`data_for_moderation_analyses.csv`**
   - The primary dataset with all extracted data from the included studies.



## Usage

Place these files in a `data/` directory at the root of the repository to ensure the notebooks can locate them.

Clone the repository:
   ```bash
   git clone https://github.com/yourusername/hunt-for-the-last-relevant-paper.git
   cd hunt-for-the-last-relevant-paper
   ```

Install dependencies: install R Studio and the following R packages: Metafor, lme4, influence.ME

Knit the R script `Prevelances_analysis.Rmd`
   

## Funding 
The research is supported by the Dutch Research Council under grant number 406.22.GO.048

## Contact
For questions contact Rens van de Schoot (a.g.j.vandeschoot@uu.nl) 

