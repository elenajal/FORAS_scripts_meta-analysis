# Timeline Visualisation Plot

This repository contains Python code for generating timeline
visualisations of timepoints employed in the included studies of the meta-analysis of prevalences of PTSD symptoms. 
The script uses **matplotlib**, **pandas**, and **numpy** to display time points and ranges for different authors.

## Description

The core of the project is a `Timeline` class that uses the following columns:

-   **Study**: Name of the author or entity.
-   **Time_points**: The exact timepoint assessment moments (in months) per study (e.g., 1, 2, 4, 8, 16).

The script then plots these values on a timeline for each author,
providing a clear overview of PTSD symptom assessment periods across studies.

## Requirements
The required data (`General_data.xlsx`) is available on **Dataverse**: <link>.

Install the following Python libraries:

``` bash
pip install matplotlib pandas numpy openpyxl
```

-   **matplotlib** -- for plotting
-   **pandas** -- for data handling
-   **numpy** -- for array operations
-   **openpyxl** -- for reading Excel files

## Usage

1.  Make sure the needed Excel file (`General_data.xlsx`) is in the `data` folder.
2.  Ensure the file contains the required `Study` and `time_points`
    columns.
3.  Run the Python script or Jupyter Notebook, updating the file path if
    needed (`data/General_data.xlsx`).
4.  The output will be a timeline plot titled *"Measurement points of
    included studies"*.
