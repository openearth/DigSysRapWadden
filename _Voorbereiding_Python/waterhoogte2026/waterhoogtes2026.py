# %%
#TODO change strucutre to become more modular (yml approach)

# data we have so far - normal waterlevels, extremes, waterlevel calculated by RWS
# needed for DSR to calculate in R script: Gemiddels Hoogwater GLH (from extreme)
#Gemiddels Laagwater (GLW) from extremes
#Getijslag (difference GHW and GLW)
#above can be done in the R code directly using the data fetched from the services, use the 'GETETM2' data to do so

# tidal components - have been derived
#assymetry has not been derived  #TODO integrating hatyan tidal asymmetry scripts

#- Gemiddeld LaagLaag water bij Springtij #TODO integrating hatyan tidal indicators scripts
# - Gemiddeld HoogHoog water bij springtij #TODO integrating hatyan tidal indicators scripts

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

const_list = hatyan_core.get_const_list_hatyan(listtype='year')
const_list = const_list + ['SSA'] #['A0','M2','S2','M4'] # TODO: add SSA and maybe other components for better reproduction
#%% TODO write functions and move into jupyter scripts once the functions are there to allow the user for easier data selection and collection
path = Path.cwd()
grootheid = ['WATHTE']
save_path = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026'
Path(save_path).mkdir(parents=True, exist_ok=True)

dir_TA_filtersurge = os.path.join(save_path,'TA_filtersurge')
if not os.path.exists(dir_TA_filtersurge):
    os.mkdir(dir_TA_filtersurge)
dir_TA_perstation = os.path.join(save_path,'waterstand_berekend_m')
if not os.path.exists(dir_TA_perstation):
    os.mkdir(dir_TA_perstation)

define_selection = pd.read_excel(os.path.join(path, 'define_parameter_selection.xlsx'))
define_selection = define_selection[define_selection['Grootheid.Code'].isin(grootheid)]

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

        if define_selection_pars['ProcesType'] == 'meting' and define_selection_pars['Groepering.Code'] != 'GETETM2': 
            hatyan_df = hatyan.ddlpy_to_hatyan(measurements) #voor hatyan nemen we nu alleen geonctroleerde waarden

            for year, hatyan_df_year in hatyan_df.groupby(hatyan_df.index.year):

                if hatyan_df_year.empty:
                    continue

                timestep_min_all = ((hatyan_df_year.index[1:]-hatyan_df_year.index[:-1]).total_seconds()/60).astype(int).values
                uniq_vals, uniq_counts = np.unique(timestep_min_all,return_counts=True)
                timestep_min_dominant = uniq_vals[np.argmax(uniq_counts)]

                #resample if timestep is not constant
                if (hatyan_df_year.index.min() < pd.Timestamp(year-1,12,31,23,0,tz='UTC')) or (hatyan_df_year.index.max() > pd.Timestamp(year+1,1,1,1,0,tz='UTC')):
                    raise Exception('ERROR: start/stoptimes are not within expected range of year + 1 hour ath both sides')
                if len(uniq_vals)==1: # no resampling necessary if constant timestep
                    if timestep_min_dominant not in [10,60,180]:
                        raise Exception(f'ERROR: constant timestep of {timestep_min_dominant} min, while 10, 60 or 180 min is expected.')
                    ts_meas = hatyan_df_year.copy()
                else: #varying timestep, for instance in interval-transition year
                    if 180 in uniq_vals: #if 180 min interval occurs, resample to 180 min
                        ts_meas = hatyan.resample_timeseries(ts=hatyan_df_year, timestep_min=180, tstart=hatyan_df_year.index.min(), tstop=hatyan_df_year.index.max())
                    else: #otherwise resample to 60 minutes
                        ts_meas = hatyan.resample_timeseries(ts=hatyan_df_year, timestep_min=60, tstart=hatyan_df_year.index.min(), tstop=hatyan_df_year.index.max())
                try:
                    comp_frommeas = hatyan.analysis(ts_meas, const_list=const_list, nodalfactors=True, xfac=True, fu_alltimes=True)
                    print(f"Year {year}:")
                    print(ts_meas)
                except Exception as e:
                    print(f"Error during hatyan analysis for year {year}:", e)

                data_pd_TA_station = pd.DataFrame({}, columns=pd.MultiIndex.from_product([['A','phi_deg'],hatyan_df_year]), index=const_list) 

                comp_frommeas.to_csv(os.path.join(dir_TA_filtersurge,f'{station}_{year}_components_UTC+1.csv'),float_format='%.3f')
                # data_pd_TA_station.loc[const_list,(['A','phi_deg'],year)] = ts_meas.loc[const_list,['A','phi_deg']].values

                ts_pred = hatyan.prediction(comp=comp_frommeas,times=slice(dt.datetime(year,1,1),dt.datetime(year,12,31,23,50))) #removal of timestep, was previously timestep_min
                ts_pred.rename_axis('time').to_csv(os.path.join(dir_TA_perstation,f'tspred_anasameyear_{station}_OW_WATHTASTRO_{year}.csv'))

                            #make figure to check the raw data of the files that cannot be used for the tidal analysis
                fig,(ax1,ax2) = hatyan.plot_timeseries(ts=hatyan_df_year,ts_validation=ts_meas) 
                ax1.set_title(f'waterlevel measured raw vs filtered for {station} {year}')
                ax2.set_ylim(-1,1)
                fig.savefig(os.path.join(dir_TA_filtersurge,f'tsmeas_{station}_{year}.png'))

                fig,(ax1,ax2) = hatyan.plot_timeseries(ts=ts_meas,ts_validation=ts_pred)
                ax2.set_ylim(-1,1)
                ax1.set_title(f'tidal prediction vs measured for {station} {year}')
                fig.savefig(os.path.join(dir_TA_filtersurge,f'tspred_{station}_{year}.png'))


  # %%
hatyan.analysis_prediction.analysis()