"""
Water level data retrieval with YAML configuration.
Simplified, minimal wrapper around original script logic.
"""

import os
os.environ["PROJ_LIB"] = r"C:\Users\dees\.conda\envs\ddlpy\Library\share\proj"

import yaml
import pandas as pd
import geopandas as gpd
from pathlib import Path
import ddlpy

from functions import get_locatielaatstewaarning, get_begrenzing_rijkswateren

config_path=r'C:\projecten\DigSysRapWadden\_Voorbereiding_Python\waterhoogte2026\config_simple.yml'

# %%
def load_config(config_path):
    """Load YAML configuration."""
    with open(config_path) as f:
        return yaml.safe_load(f)

# %%
def main(config_path=config_path):
    """Main processing - simplified version of original script."""
    
    config = load_config(config_path)
    
    # Setup paths
    path = Path.cwd()
    save_path = Path(config['output']['save_path'])
    save_path.mkdir(parents=True, exist_ok=True)
    
    # Get configuration
    station_mode = config['station_selection']['mode']
    output_cols = config['output'].get('keep_columns', [])
    
    print(f"Mode: {station_mode}")
    print(f"Output: {save_path}")
    
    # %% Select stations
    if station_mode == 'manual':
        # Manual mode: use specific station codes
        station_codes = config['station_selection']['manual']['stations']
        gdf = get_locatielaatstewaarning()
        selected_stations = gdf[gdf['CODE'].isin(station_codes)]
        
        print(f"Selected {len(selected_stations)} stations (manual mode)")
        
    else:  # function mode
        # Function mode: spatial selection based on regions
        func_config = config['station_selection']['function']
        regions = func_config['regions']
        cutoff = pd.Timestamp(func_config['cutoff_date'])
        
        # Get parameter file path
        param_file = func_config.get('parameter_file', 'define_parameter_selection.xlsx')
        define_selection = pd.read_excel(param_file)
        grootheid = define_selection['Grootheid.Code'].unique()
        
        # Get stations
        gdf = get_locatielaatstewaarning()
        selected_stations = gdf[gdf['GROOTHEIDCODE'].isin(grootheid)]
        
        # Spatial filter
        gdf_rijkswateren = get_begrenzing_rijkswateren()
        selection_areas = gdf_rijkswateren[gdf_rijkswateren['identificatie'].isin(regions)]
        selection_areas = selection_areas.dissolve()
        selected_stations = selected_stations.to_crs(epsg=28992)
        selected_stations = gpd.sjoin(selected_stations, selection_areas)
        
        # Date filter
        selected_stations['TIJDSTIP_LAATSTE_METING'] = (
            pd.to_datetime(selected_stations['TIJDSTIP_LAATSTE_METING'], errors='coerce', utc=True)
            .dt.tz_localize(None)
        )
        selected_stations = selected_stations[
            selected_stations['TIJDSTIP_LAATSTE_METING'] > cutoff
        ]
        
        print(f"Selected {len(selected_stations)} stations (function mode, regions: {regions})")
    
    # Save station list for reference
    selected_stations.to_csv(save_path / 'selected_stations.csv', index=False)
    
    # %% Retrieve data for each station and parameter
    locations = ddlpy.locations()
    define_selection_list = config['data_retrieval']['parameters']
    
    # Auto-detect date range if not provided
    start_date = config['data_retrieval'].get('start_date')
    end_date = config['data_retrieval'].get('end_date')
    
    if not start_date or not end_date:
        min_date = selected_stations['TIJDSTIP_LAATSTE_METING'].min()
        max_date = selected_stations['TIJDSTIP_LAATSTE_METING'].max()
        start_date = start_date or min_date
        end_date = end_date or max_date
        print(f"Auto-detected date range: {start_date} to {end_date}")
    else:
        start_date = pd.Timestamp(start_date)
        end_date = pd.Timestamp(end_date)
    
    # Retrieve measurements
    total = len(selected_stations['CODE'].unique()) * len(define_selection_list)
    count = 0
    
    for station in selected_stations['CODE'].unique():
        for param_idx, param in enumerate(define_selection_list):
            count += 1
            
            # Filter locations
            bool_station = locations.index.isin([station])
            bool_proces = locations["ProcesType"].isin([param['ProcesType']])
            bool_groot = locations["Grootheid.Code"].isin([param['Grootheid.Code']])
            bool_hoedanig = locations["Hoedanigheid.Code"].isin([param['Hoedanigheid.Code']])
            
            groepering = param.get('Groepering.Code')
            if pd.isna(groepering) or groepering is None:
                groepering = ""
            bool_group = locations["Groepering.Code"].isin([groepering])
            
            selected = locations.loc[bool_proces & bool_station & bool_groot & bool_group & bool_hoedanig]
            
            if selected.empty:
                print(f"  [{count}/{total}] {station} - No data found")
                continue
            
            try:
                measurements = ddlpy.measurements(
                    selected.iloc[0], 
                    start_date=start_date, 
                    end_date=end_date
                )
                
                if measurements.empty:
                    print(f"  [{count}/{total}] {station} - Empty result")
                    continue
                
                # Filter columns if specified
                if output_cols:
                    keep = [c for c in output_cols if c in measurements.columns]
                    measurements = measurements[keep]
                
                # Save to file
                station_safe = station.replace('.', '_')
                groot = param['Grootheid.Code']
                proces = param['ProcesType']
                group = param.get('Groepering.Code', '')
                if pd.isna(group) or group == "":
                    group = 'TIMESERIES'
                
                filename = f"{station_safe}_{groot}_{proces}_{group}.csv"
                measurements.to_csv(save_path / filename, index=True)
                
                print(f"  [{count}/{total}] {station} - OK ({len(measurements)} rows)")
                
            except Exception as e:
                print(f"  [{count}/{total}] {station} - Error: {str(e)}")
    
    print(f"\nComplete! Output saved to: {save_path}")

# %%
if __name__ == '__main__':
    main()
