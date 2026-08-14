# %%
import pandas as pd
from pathlib import Path
import requests
import os
os.environ["PROJ_LIB"] = r"C:\Users\dees\.conda\envs\ddlpy\Library\share\proj" #if you're having problems with your projection installation
import ddlpy
import datetime as dt
import geopandas as gpd  #try on next installation conda install -c conda-forge pyproj proj

import logging
logging.basicConfig()
logging.getLogger("ddlpy").setLevel(logging.DEBUG)

#%% TODO write functions and move into jupyter scripts once the functions are there to allow the user for easier data selection and collection
path = Path.cwd()
grootheid = ['WATHTE']

#%%functions if needed
#%% locatielaatstewaarneming -> retrieving stations convert to function
wfs_url = 'https://geo.rijkswaterstaat.nl/services/ogc/hws/DDAPI20/ows'
typename = 'ddapi20:locatiesmetlaatstewaarneming'
params = {
    'service': 'WFS',
    'version': '1.0.0',
    'request': 'GetFeature',
    'typeName': typename,
    'outputFormat': 'json'  # GeoJSON format is commonly supported
}

response = requests.get(wfs_url, params=params)

if response.status_code == 200:
    # Load GeoJSON data into GeoDataFrame
    data = response.json()
    gdf = gpd.GeoDataFrame.from_features(data['features'])

    # Set CRS if known
    gdf.crs = {'init': 'epsg:4326'}  # Replace with correct EPSG code if known

    print('GeoDataFrame successfully created:')
    print(gdf.head())  # Display first few rows of the GeoDataFrame
else:
    print('Failed to retrieve data:', response.status_code)

print(gdf.columns)
stations = gdf[gdf['GROOTHEIDCODE'].isin(grootheid)]

#%%
#  crop spatially based on vector extent convert to function
wfs_url_spatial = 'https://geo.rijkswaterstaat.nl/services/ogc/gdr/nnn_begrenzing_rijkswateren/ows'
typename_spatial = 'natuurnetwerk_nederland_begrenzing_rijkswateren'
params_spatial = {
    'service': 'WFS',
    'version': '2.0.0',
    'request': 'GetFeature',
    'typeName': typename_spatial,
    'outputFormat': 'json'
}

response_spatial = requests.get(wfs_url_spatial, params=params_spatial)

if response_spatial.status_code == 200:
    data_spatial = response_spatial.json()
    gdf_spatial = gpd.GeoDataFrame.from_features(data_spatial['features'])

    gdf_spatial.crs = {'init': 'epsg:28992'}  # Replace with correct EPSG code if known
    print('Spatial GeoDataFrame successfully created:')
    print(gdf_spatial.head())
else:
    print('Failed to retrieve spatial data:', response_spatial.status_code)

print(gdf_spatial.columns)

#%% need a excel/csv to define which of these regions is part of which systems e.g. for Waddenzee it is those three
# unique_areas = gdf_spatial['identificatie'].unique()
# for area in unique_areas:
#     area_gdf = gdf_spatial[gdf_spatial['identificatie'] == area] #voor het uitwerken per watersysteem
waddenzee = ['Waddenzee', 'Eems-Dollard']
# gdf_spatial = gdf_spatial.to_crs(epsg=25831)  # Reproject to match the stations GeoDataFrame
selection_areas = gdf_spatial[gdf_spatial['identificatie'].isin(waddenzee)]
selection_areas = selection_areas.dissolve()
selection_areas.plot()

stations = stations.to_crs(epsg=28992)  # Reproject to match the selection areas GeoDataFrame
selected_stations = gpd.sjoin(stations, selection_areas)
selected_stations.plot()

#%%
# gdf_spatial = gdf_spatial[(gdf_spatial['identificatie'] == 'Waddenzee') | (gdf_spatial['identificatie'] == 'Eems-Dollard')]
#%% use ddlpy to retrieve information on each basin, or basin you need

# get the dataframe with locations and their available parameters
locations = ddlpy.locations()

# Filter the locations dataframe with the desired parameters and stations.
bool_stations = locations.index.isin(selected_stations['NAAM'].unique())
# meting/astronomisch/verwachting
# bool_procestype = locations["ProcesType"].isin(["meting"])
# waterlevel/waterhoogte (WATHTE)
bool_grootheid = locations["Grootheid.Code"].isin(grootheid)
# timeseries ("") versus extremes (GETETM2/GETETMSL2/GETETBRKD2/GETETBRKDMSL2)
# bool_groepering = locations["Groepering.Code"].isin([""])
# bool_parameter = locations["Parameter.Code"].isin(["Cl"])
# vertical reference (NAP/MSL)
# bool_hoedanigheid = locations["Hoedanigheid.Code"].isin(["Cl"])
selected = locations.loc[
    # bool_procestype
    bool_stations
    & bool_grootheid
    # & bool_parameter
    # & bool_groepering
    # & bool_hoedanigheid
    ]

start_date = selected_stations['TIJDSTIP_LAATSTE_METING'].min()  # Use the earliest measurement date from the selected stations
end_date = selected_stations['TIJDSTIP_LAATSTE_METING'].max()

# provide a single row of the locations dataframe to ddlpy.measurements
measurements = ddlpy.measurements(selected.iloc[0], start_date=start_date, end_date=end_date)

if not measurements.empty:
    print("Data was found in RWS Waterwebservices/DDL")
    # measurements.plot(y="Meetwaarde.Waarde_Numeriek", linewidth=0.8)
else:
    print("No Data!")
# %%
