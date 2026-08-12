#%%
import geopandas as gpd
import pandas as pd
import requests
import os

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
    gdf.crs = {'init': 'epsg:25831'}  # Replace with correct EPSG code if known

    print('GeoDataFrame successfully created:')
    print(gdf.head())  # Display first few rows of the GeoDataFrame
else:
    print('Failed to retrieve data:', response.status_code)

sel = [ 'WATHTE', 'Q', 'T', 'GELDHD', 'GGH', 'Hm0']
grootheid = gdf[gdf['GROOTHEIDCODE'].isin(sel)]
# sel_status = ['Gecontroleerd', 'Definitief']
# grootheid = grootheid[grootheid['STATUSWAARDE'].isin(sel_status)]
grootheid = grootheid.drop_duplicates()
grootheid['TIJDSTIP_LAATSTE_METING'] = pd.to_datetime(grootheid['TIJDSTIP_LAATSTE_METING'])
indexes = (grootheid['TIJDSTIP_LAATSTE_METING'].dt.year > 2020)

grootheid = grootheid.loc[indexes]
grootheid = grootheid.set_crs("EPSG:25831")

cols =['NAAM', 'CODE', 'OMSCHRIJVING',
       'STATUSWAARDE', 'KWALITEITSWAARDE_CODE', 
       'EENHEIDCODE', 'GROOTHEIDCODE',  'WAARDEBEPALINGSTECHNIEKCODE', 
       'BEMONSTERINGSHOOGTE', 'REFERENTIEVLAK', 'geometry']

resultaat = grootheid[cols].drop_duplicates()
print(len(resultaat))
resultaat.to_file('data-before-drop-donar.gpkg', driver = 'GPKG')

#%% Cell voor onbrekende data
# golven: buitenkant Haringvlietsluizen
# JOIN met de koppeltabel van LMW zodat we de LMN locaties hebben
koppeltabel = pd.read_csv(r'P:\11208031-004-optimalisatie-lmw2\7_Workshop\voorbereiding-gesprekken\koppeltabel_LMW_DONAR.csv')
# koppeltabel = koppeltabel.loc[koppeltabel['LMWlocatiecode']!='AWG'] #rare mapping, mapt naar 30 entries
# koppeltabel = koppeltabel.loc[koppeltabel['LMWlocatiecode']!='AWG1'] 
koppeltabel = koppeltabel.loc[koppeltabel['LMWlocatiecode']!='BAB']
koppeltabel = koppeltabel.loc[koppeltabel['LMWlocatiecode']!='BABhernoemd']#ook een rare mapping, mapt ook naar 5 entries
koppeltabel.rename(columns ={'Donarlocatiecode': 'CODE'}, inplace=True)
resultaat=resultaat.merge(koppeltabel, on='CODE', how='left')
print(len(resultaat.loc[resultaat['NAAM'] == 'Lobith']))

cols =['NAAM', 'CODE','LMWlocatiecode', 'OMSCHRIJVING',
       'STATUSWAARDE', 
       'EENHEIDCODE', 'GROOTHEIDCODE',  'WAARDEBEPALINGSTECHNIEKCODE', 
       'BEMONSTERINGSHOOGTE', 'REFERENTIEVLAK', 'geometry']
resultaat=resultaat[cols]
# resultaat.drop_duplicates(inplace=True, keep='first') #eerste behouden zodat niet alle duplicaten worden verwijderd
resultaat= resultaat.query('CODE != "DENOVBNPTN"')
resultaat = resultaat.sort_values(by='LMWlocatiecode').drop_duplicates(subset=['CODE','GROOTHEIDCODE'], keep='first')

##alleen een check voor de hoeveelheid unieke waardes per column
valuecounts=resultaat[['LMWlocatiecode','CODE']].value_counts()
df_val_counts = pd.DataFrame(valuecounts)
df_value_counts_reset = df_val_counts.reset_index()
print(len(resultaat))
resultaat.to_file('lmw-after-drop.gpkg', driver='GPKG')

#%%
#JOIN zodat we de waardes per verschillend gebied hebben
overlay = gpd.read_file(r"P:\11208031-004-optimalisatie-lmw2\7_Workshop\voorbereiding-gesprekken\geodata\overlay-25831.shp")
overlay = overlay.to_crs(resultaat.crs)
areas = overlay['name'].unique()
parameter = resultaat['GROOTHEIDCODE'].unique()

cols =['NAAM', 'CODE','LMWlocatiecode', 
       'STATUSWAARDE', 
       'EENHEIDCODE', 'GROOTHEIDCODE',  'WAARDEBEPALINGSTECHNIEKCODE', 
       'BEMONSTERINGSHOOGTE', 'REFERENTIEVLAK', 'name']

save_path = r'P:\11208031-004-optimalisatie-lmw2\7_Workshop\voorbereiding-gesprekken\excel'
# Perform spatial join to find which points are in which polygons
df = gpd.sjoin(resultaat, overlay, how='left', op='within')
df = df[cols]
#save excel based on area
for i in range(len(areas)):
    dfi = df.loc[df['name'] == areas[i]]
    dfi.to_excel(os.path.join(save_path,areas[i] + '.xlsx' ), index=False)

#save based on parameter
for i in range(len(parameter)):
    dfi = df.loc[(df['GROOTHEIDCODE'] == parameter[i]) & (~df['name'].isna())]
    dfi.to_excel(os.path.join(save_path,parameter[i] + '.xlsx' ), index=False)

# resultaat.to_file('wfs-laatste-waarneming-LMW.geojson', driver='GeoJSON')
