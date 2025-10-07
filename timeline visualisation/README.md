# Timeline Visualization Plot

This repository contains Python code for generating timeline
visualizations of timepoints employed in the included studies of the meta-analysis of prevalences of PTSD symptoms. 
The script uses **matplotlib**, **pandas**, and **numpy** to display time points and ranges for different authors.

## Description

The core of the project is a `Timeline` class that takes the following columns:

-   **Study**: Name of the author or entity.\
-   **time_points**: A string of time points or ranges (e.g.,
    `"2, 5:8, 12"`).

The script then plots these values on a timeline for each author,
providing a clear overview of data collection periods across studies.
The required data is available on **Dataverse**.

## Requirements

Install the following Python libraries:

``` bash
pip install matplotlib pandas numpy openpyxl
```

-   **matplotlib** -- for plotting\
-   **pandas** -- for data handling\
-   **numpy** -- for array operations\
-   **openpyxl** -- for reading Excel files

## Usage

1.  Make sure the Excel file (`general_data.xlsx`) in the `data` folder.\
2.  Ensure the file contains the required `Study` and `time_points`
    columns.\
3.  Run the Python script or Jupyter Notebook, updating the file path if
    needed (`data/general_data.xlsx`).\
4.  The output will be a timeline plot titled *"Measurement points of
    included studies"*.
