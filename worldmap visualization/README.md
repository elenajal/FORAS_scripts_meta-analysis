# World Map Visualization Plot  

Python code to generate a choropleth world map of study locations from the meta-analysis of prevalences of PTSD symptom trajectories dataset. Takes a column of country names, normalizes to ISO-3 codes, aggregates counts, and exports an interactive HTML map, a static PNG, and a CSV of country counts.

**Description**  
The notebook expects:

- `file_path` — `../data/Data_extraction_general_data.xlsx`  
- `country_col` — column containing country names or lists of countries (default: `Location? Where the study is based`).  
- Country strings may contain multiple entries split by commas/semicolons/slashes/“and”.

It can render an interactive choropleth (for browsers) and a high-resolution static PNG (for papers/presentations), and writes a counts table for reporting.

**Requirements**  
Data file (`Data_extraction_general_data.xlsx`) placed in `data/`

**Python packages**  
- plotly.express as px  
- pandas as pd  
- country_converter as coco  
- kaleido             # for PNG export from Plotly  
- openpyxl            # for reading .xlsx

**Install**  
```bash
pip install plotly pandas country_converter kaleido openpyxl
```

**Usage**  
Place `data/Data_extraction_general_data.xlsx` in the repository.
Ensure the sheet has a country column (default: `Location? Where the study is based`).  
Open and run the notebook `worldmap_visualisation.ipynb`.

**Basic run (inside the notebook)**  
```python
# Configure
file_path = '../data/Data_extraction_general_data.xlsx'
country_col = 'Location? Where the study is based'

# Run all cells to:
# 1) parse & normalise country names to ISO3
# 2) aggregate counts
# 3) render choropleth
# 4) save outputs under ./outputs
```

**Outputs**  
- `outputs/world_meta_analysis.html` — interactive map (hover for counts).  
- `outputs/world_meta_analysis.png` — static 2× PNG for slides/papers.  
- `outputs/world_meta_analysis_counts.csv` — ISO3 and study_count table.

**Notes**  
- Change colour scale by editing `color_continuous_scale` in the plotting cell.  
- Switch fonts or projection in the layout cell.  
- If PNG export fails, ensure `kaleido` is installed.
