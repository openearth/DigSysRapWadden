from pathlib import Path
import requests
import geopandas as gpd

#%% locatielaatstewaarneming -> retrieving stations convert to function
def get_locatielaatstewaarning():
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
    return gdf if response.status_code == 200 else None

# %%
#  crop spatially based on vector extent convert to function
def get_begrenzing_rijkswateren():
    """Get natuurnetwerk_nederland_begrenzing_rijkswateren from WFS and return as GeoDataFrame.
    Still need to consider what is a part of what system, e.g. Waddenzee is Waddenzee and Eems-Dollard, but not the other areas in the Waddenzee."""
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
    return gdf_spatial if response_spatial.status_code == 200 else None 