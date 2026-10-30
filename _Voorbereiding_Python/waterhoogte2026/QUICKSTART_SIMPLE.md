# Quick Start - Simple Version

## Installation
```bash
pip install geopandas pandas requests ddlpy pyyaml
```

## Usage

### 1. Configure (config_simple.yml)

**Option A: Automatic regional selection**
```yaml
station_selection:
  mode: 'function'
  function:
    regions:
      - 'Waddenzee'
      - 'Eems-Dollard'
    cutoff_date: '2000-01-01'
    parameter_file: 'define_parameter_selection.xlsx'
```

**Option B: Specific stations**
```yaml
station_selection:
  mode: 'manual'
  manual:
    stations:
      - 'MAES'
      - 'DELF'
      - 'TERHD'
```

### 2. Run
```python
from waterhoogtes2026_simple import main

main('config_simple.yml')
```

## Output
```
output/waterhoogte2026/
├── selected_stations.csv
├── MAES_WATHTE_meting_TIMESERIES.csv
├── MAES_WATHTE_meting_GETETM2.csv
└── ...
```

## Configuration Options

### Modes
- **`mode: 'function'`** - Automatic: select all stations in specified regions
- **`mode: 'manual'`** - Manual: retrieve data for specific station codes

### Date Range
- `start_date: null` - Auto-detect from station metadata
- `start_date: '2010-01-01'` - Specify explicit start date

### Parameters
Add more parameter combinations as needed:
```yaml
parameters:
  - Grootheid.Code: 'WATHTE'
    ProcesType: 'meting'
    Hoedanigheid.Code: 'NAP'
    Groepering.Code: null        # null = timeseries
  
  - Grootheid.Code: 'WATHTE'
    ProcesType: 'meting'
    Hoedanigheid.Code: 'MSL'     # Different reference level
    Groepering.Code: null
  
  - Grootheid.Code: 'WATHTE'
    ProcesType: 'meting'
    Hoedanigheid.Code: 'NAP'
    Groepering.Code: 'GETETM2'   # Extremes
```

### Output Columns
```yaml
output:
  # Empty list = keep all columns
  keep_columns: []
  
  # Specific columns
  keep_columns:
    - 'Meetwaarde.Waarde_Numeriek'
    - 'Grootheid.Code'
    - 'Code'
    - 'Naam'
```

## Path Configuration

### Relative Paths (portable)
```yaml
parameter_file: 'define_parameter_selection.xlsx'
save_path: 'output/waterhoogte2026'
```

### Windows Absolute Paths (use raw string)
```yaml
parameter_file: r'C:\Users\username\data\define_parameter_selection.xlsx'
save_path: r'P:\11202493--systeemrap\1_data\Wadden\ddl\raw\waterhoogte2026'
```

### Unix Paths
```yaml
parameter_file: '/home/username/data/define_parameter_selection.xlsx'
save_path: '/mnt/data/waterhoogte2026'
```

## Examples

### Example 1: Waddenzee (Auto)
```yaml
station_selection:
  mode: 'function'
  function:
    regions: ['Waddenzee', 'Eems-Dollard']
    cutoff_date: '2000-01-01'
    parameter_file: 'define_parameter_selection.xlsx'

data_retrieval:
  start_date: null
  end_date: null
  parameters:
    - Grootheid.Code: 'WATHTE'
      ProcesType: 'meting'
      Hoedanigheid.Code: 'NAP'
      Groepering.Code: null

output:
  save_path: 'output/waddenzee'
  keep_columns: []
```

### Example 2: Specific Stations
```yaml
station_selection:
  mode: 'manual'
  manual:
    stations:
      - 'MAES'
      - 'DELF'
      - 'TERHD'
      - 'HARGEN'

data_retrieval:
  start_date: '2015-01-01'
  end_date: '2023-12-31'
  parameters:
    - Grootheid.Code: 'WATHTE'
      ProcesType: 'meting'
      Hoedanigheid.Code: 'NAP'
      Groepering.Code: null

output:
  save_path: r'P:\data\waterhoogte'
  keep_columns:
    - 'Meetwaarde.Waarde_Numeriek'
    - 'Code'
    - 'Naam'
```

## Troubleshooting

### "No stations found"
- Check region names are correct (function mode)
- Check station codes exist (manual mode)
- Verify parameter file exists

### "Empty result"
- Station may not have data for that parameter combination
- Check date range - may not have measurements in that period
- Try a different parameter

### "File not found"
- Verify `parameter_file` path is correct
- Use absolute path if relative path doesn't work

## That's it!
Two modes, simple config, straightforward execution.
