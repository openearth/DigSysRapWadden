# %%
#TODO change strucutre to become more modular (yml approach)

# data we have so far - normal waterlevels, extremes, waterlevel calculated by RWS
# needed for DSR to calculate in R script: Gemiddels Hoogwater GLH (from extreme)
#Gemiddels Laagwater (GLW) from extremes
#Getijslag (difference GHW and GLW)
#above can be done in the R code directly using the data fetched from the services, use the 'GETETM2' data to do so

# opslaan per jaar
# gebruik de parameter wat omschrijving om dit te doen
# gebruik gelijk de extremen 
# verplaats scripts naar een losse folder met een yml en readme erbij
# later verplaatsen naar gitlab omgeving van RWS 
# voor de data komt een soort fileserver opgezet
# makkelijk aanpassen van laatstewaarnemingpunt
#%%
import pandas as pd
from pathlib import Path
import requests
import os
os.environ["PROJ_LIB"] = r"C:\Users\dees\.conda\envs\ddlpy\Library\share\proj" #if you're having problems with your projection installation
import ddlpy
import datetime as dt
import geopandas as gpd  #try on next installation conda install -c conda-forge pyproj proj
import numpy as np

from functions import get_locatielaatstewaarning, get_begrenzing_rijkswateren

import logging
logging.basicConfig()
logging.getLogger("ddlpy").setLevel(logging.DEBUG)

#%% TODO write functions and move into jupyter scripts once the functions are there to allow the user for easier data selection and collection
path = Path.cwd()
save_path = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026'
Path(save_path).mkdir(parents=True, exist_ok=True)

define_selection = pd.read_excel(os.path.join(path,  '_Voorbereiding_Python', 'waterhoogte2026', 'define_parameter_selection.xlsx'))
grootheid = define_selection['Grootheid.Code'].unique()

#%% locatielaatstewaarneming -> retrieving stations convert to function
gdf = get_locatielaatstewaarning()
print(gdf.columns)
stations = gdf[gdf['GROOTHEIDCODE'].isin(grootheid)]

gdf_rijkswateren = get_begrenzing_rijkswateren()
print(gdf_rijkswateren.columns)

#%% need a excel/csv to define which of these regions is part of which systems e.g. for Waddenzee it is those two
# then this can be plotted in the graph
# unique_areas = gdf_rijkswateren['identificatie'].unique()
# for area in unique_areas:
#     area_gdf = gdf_rijkswateren[gdf_rijkswateren['identificatie'] == area] #voor het uitwerken per watersysteem

waddenzee = ['Waddenzee', 'Eems-Dollard']
## gdf_rijkswateren = gdf_rijkswateren.to_crs(epsg=25831)  # Reproject to match the stations GeoDataFrame
selection_areas = gdf_rijkswateren[gdf_rijkswateren['identificatie'].isin(waddenzee)]
selection_areas = selection_areas.dissolve()
selection_areas.plot()

stations = stations.to_crs(epsg=28992)  # Reproject to match the selection areas GeoDataFrame
selected_stations = gpd.sjoin(stations, selection_areas)
selected_stations.plot()

#%% use ddlpy to retrieve information on each basin, or basin you need
# get the dataframe with locations and their available parameters
locations = ddlpy.locations()
# Filter the locations dataframe with the desired parameters and stations.
# do we take WaarnemingsMetadata.Statuswaarde =  ongecontroleerd or only gecontroleerd?

# for station in selected_stations['CODE'].unique():
for j in range(len(selected_stations['CODE'].unique()[0:1])):
    station = selected_stations['CODE'].unique()[j]
    for i in range(len(define_selection)):
        define_selection_pars = define_selection.iloc[i]
        bool_stations = locations.index.isin([station])
        # meting/astronomisch/verwachting
        # need to investigate how it works with multiple parameters
        bool_procestype = locations["ProcesType"].isin([define_selection_pars['ProcesType']])
        # waterlevel/waterhoogte (WATHTE)
        bool_grootheid = locations["Grootheid.Code"].isin([define_selection_pars['Grootheid.Code']])
        # timeseries ("") versus extremes (GETETM2/GETETMSL2/GETETBRKD2/GETETBRKDMSL2)
        if pd.isna(define_selection_pars['Groepering.Code']):  
            define_selection_pars['Groepering.Code'] = ""  # if no groepering is defined, we don't filter on it
        bool_groepering = locations["Groepering.Code"].isin([define_selection_pars['Groepering.Code']])
        # bool_parameter = locations["Parameter.Code"].isin(["Cl"])
        # vertical reference (NAP/MSL)
        bool_hoedanigheid = locations["Hoedanigheid.Code"].isin([define_selection_pars['Hoedanigheid.Code']])
        selected = locations.loc[
            bool_procestype
            & bool_stations
            & bool_grootheid
            # & bool_parameter
            & bool_groepering
            & bool_hoedanigheid
            ]

        start_date = selected_stations['TIJDSTIP_LAATSTE_METING'].min()  # Use the earliest measurement date from the selected stations
        end_date = selected_stations['TIJDSTIP_LAATSTE_METING'].max()

        # start_date = dt.datetime(1950, 1, 1)  # Use a fixed start date for testing only
        # end_date = dt.datetime(1975, 12, 31)  

        # provide a single row of the locations dataframe to ddlpy.measurements
        try: 
            measurements = ddlpy.measurements(selected.iloc[0], start_date=start_date, end_date=end_date)
        except Exception as e:
            print("Error retrieving measurements for station:", station)
            print(selected.iloc[0]) #sometimes selected ends up empty then creates error. print this and continue

        if not measurements.empty:
            print("Data was found in RWS Waterwebservices/DDL")
            print("data for location:", selected['Naam'].iloc[0])
            measurements.plot(y="Meetwaarde.Waarde_Numeriek", linewidth=0.8)
        else:
            print("No Data!")


        cols_tokeep = ['WaarnemingMetadata.Bemonsteringshoogte',
            'WaarnemingMetadata.Kwaliteitswaardecode',
            'WaarnemingMetadata.OpdrachtgevendeInstantie',
            'WaarnemingMetadata.Referentievlak', 'WaarnemingMetadata.Statuswaarde',
            'BemonsteringsApparaat.Code', 'BemonsteringsApparaat.Omschrijving',
            'BemonsteringsMethode.Code', 'BemonsteringsMethode.Omschrijving',
            'BemonsteringsSoort.Code', 'BemonsteringsSoort.Omschrijving',
            'Compartiment.Code',
            'Compartiment.Omschrijving', 'Eenheid.Code', 'Eenheid.Omschrijving',
            'Groepering.Code', 'Groepering.Omschrijving', 'Grootheid.Code',
            'Grootheid.Omschrijving', 'Hoedanigheid.Code',
            'Hoedanigheid.Omschrijving', 'MeetApparaat.Code',
            'MeetApparaat.Omschrijving',
            'Parameter.Code', 'Parameter.Omschrijving',
            'Parameter_Wat_Omschrijving', 'ProcesType', 'Typering.Code',
            'Typering.Omschrijving', 'WaardeBepalingsMethode.Code',
            'WaardeBepalingsMethode.Omschrijving', 'WaardeBepalingsTechniek.Code',
            'WaardeBepalingsTechniek.Omschrijving', 'WaardeBewerkingsMethode.Code',
            'WaardeBewerkingsMethode.Omschrijving',
            'Meetwaarde.Waarde_Alfanumeriek', 'Meetwaarde.Waarde_Numeriek', 'Code',
            'Coordinatenstelsel', 'Naam', 'Lon', 'Lat']

        measurements = measurements[cols_tokeep]
        save_station = station.replace('.', '_')
        output_filename = (
            f"{save_station}_"
            f"{define_selection_pars['Grootheid.Code']}_"
            f"{define_selection_pars['ProcesType']}_"
            f"{define_selection_pars['Groepering.Code']}.csv"
        )  ##TODO check if it needs to be stored with timezone information or not
        measurements.to_csv(os.path.join(save_path, output_filename), index=True)
