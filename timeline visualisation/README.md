# Timeline Visualisation Plot

Python code to generate timeline visualisations of assessment timepoints in studies from a meta-analysis on PTSD symptom prevalence. Uses **matplotlib**, **pandas**, and **numpy** to plot points and ranges per study, optionally colour-coded by trauma type.

## Description

The `Timeline` class expects:

- **Study** — study name and year (e.g., *Lowe et al., 2020*).  
- **Time_points** — assessment timepoints in months (e.g., `1, 2, 4, 8, 16`).  
- **Trauma_type** — one of *Natural*, *Injury*, *Combat*, *Other* for colour coding.

It can render a single tall figure **or** a **split-panel** figure that distributes rows across multiple panels (ideal for papers/presentations), with control over columns, panel order, spacing, and saving to file.

## Requirements

Data file (`General_data.xlsx`) is available on **DataVerseNL**: <link>.

### Python packages (matching imports)

```text
matplotlib.pyplot as plt
matplotlib as mpl
matplotlib.lines.Line2D
matplotlib.gridspec.GridSpec
pandas as pd
numpy as np
re            # standard library
math          # standard library
```

### Install

```bash
pip install matplotlib pandas numpy openpyxl
```

*(No install needed for `re` or `math`; they’re in the Python standard library.)*

## Usage

1. Place `data/General_data.xlsx` in the repository.  
2. Ensure it has `Study` and `Time_points` (optionally `Trauma_type`).  
3. Run the script or notebook (adjust the path if needed).

### Single figure

```python
import pandas as pd
from timeline import Timeline

data = pd.read_excel("data/General_data.xlsx")
timeline = Timeline(data)
timeline.show()
```

### Split into panels (papers/presentations)

```python
timeline = Timeline(data)
timeline.show_split(
    num_panels=2,
    ncols=2,
    reverse_panels=True,
    savepath="timeline_two_panels.png",
    panel_wspace=0.5,
    row_step=10,
    x_pad=0.05
)
```

This produces a two-panel, two-column figure (reversed panel order), saved as `timeline_two_panels.png`.
