[![DOI](https://zenodo.org/badge/1054345057.svg)](https://doi.org/10.5281/zenodo.17098304)

# Overview

This repository is part of the **Hunt for the Last Relevant Paper** project,
pre-registered  as "[Trajectories of PTSD Following Traumatic Events: A Systematic and Multi-database Review](https://www.crd.york.ac.uk/prospero/display_record.php?RecordID=494027)".

The current repository is focusing on the scripts used for the meta-analysis (Pre-print: https://doi.org/10.31219/osf.io/fkjb2_v1).

# Contents

## `merge_tables.py`

- Within 'pre-processing' folder

- **Purpose**: Combining three data files (`Data_extraction_general_data.xlsx`, `Data_extraction_model_results.xlsx`, `grolts_scores.csv`) into one (`data_for_moderation_analyses.csv`) for further analysis.

- **Features**:
   - Merge the three data files
   - Clean up the data
   - Ensure columns have the correct data types
   - Test whether each record can be matched correctly between the three files
   - Outputs the `data_for_moderation_analyses.csv` in the `./pre-processing/output` folder

# Load the data

## Required Input Data for `merge_tables.py`

The following data are required to create the dataset file for further analysis

1. **`Data_extraction_general_data.xlsx`**
   - The general extracted data from the included studies
2. **`Data_extraction_model_results.xlsx`**
   - The model specific data from the included studies
3. **`grolts_scores.csv`**
   - The GRoLTS scores (see: https://doi.org/10.5281/zenodo.17100045).

## Required Input Data for Analysis

The following datasets are required to run the notebooks:

1. **`data_for_moderation_analyses.csv`**
   - The primary dataset with all extracted data from the included studies.
   - Located in `./pre-processing/output`

## Usage

1. Place these files in a `data/` directory at the root of the repository to ensure the notebooks can locate them.

Clone the repository:
   ```bash
   git clone https://github.com/yourusername/hunt-for-the-last-relevant-paper.git
   cd hunt-for-the-last-relevant-paper
   ```

2. Run the Python file `./pre-processing/merge_tables.py`.

## Funding 
The research is supported by the Dutch Research Council under grant number 406.22.GO.048

## Contact
For questions contact Rens van de Schoot (a.g.j.vandeschoot@uu.nl) 

