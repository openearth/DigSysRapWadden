# tidal components - have been derived
#assymetry has not been derived  #TODO integrating hatyan tidal asymmetry scripts

#- Gemiddeld LaagLaag water bij Springtij #TODO integrating hatyan tidal indicators scripts
# - Gemiddeld HoogHoog water bij springtij #TODO integrating hatyan tidal indicators scripts

# THIS SCRIPT DOES NOT WORK YET!!
#%%
import os
import datetime as dt
from pathlib import Path
import pandas as pd

import numpy as np
import hatyan
import matplotlib.pyplot as plt

save_path = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026'
Path(save_path).mkdir(parents=True, exist_ok=True)

const_list_year = hatyan.get_const_list_hatyan('year')+['SSA'] #['A0','M2','S2','M4'] # TODO: add SSA and maybe other components for better reproduction
const_list_year3hr = const_list_year[:]

#%% tidal components
dir_TA_filtersurge = os.path.join(save_path,'TA_filtersurge')
if not os.path.exists(dir_TA_filtersurge):
    os.mkdir(dir_TA_filtersurge)
dir_TA_perstation = os.path.join(save_path,'waterstand_berekend_m') #zelf berekenen of de rws waardes gebruiken? 
if not os.path.exists(dir_TA_perstation):
    os.mkdir(dir_TA_perstation)

for file in os.listdir(save_path):
    if file.endswith('WATHTE_meting_TIMESERIES.csv'):
        hatyan_df = pd.read_csv(os.path.join(save_path, file), index_col='time', parse_dates=True)
        station = file.split('WATHTE', 1)[0]

        for year, data_pd in hatyan_df.groupby(hatyan_df.index.year):

            if data_pd.empty:
                continue

            plt.close('all')
        print(f'processing {station} for {year}')  
        data_pd = data_pd[data_pd['Groepering.Code'] == 'NVT']
        bool_invalid = (data_pd['Kwaliteitswaarde.Code']!=0) & (data_pd['Kwaliteitswaarde.Code']!=25) | data_pd['Meetwaarde.Waarde_Numeriek'].isin([740,999,1010,1011,1012]) #latter is for HUIBGT 1985/1987 and maybe others#| (data_pd['numeriekewaarde']>340) | (data_pd['numeriekewaarde']<-340) 
        data_pd.loc[bool_invalid,'Meetwaarde.Waarde_Numeriek'] = np.nan
        ts_meas_raw = pd.DataFrame({'values':data_pd['Meetwaarde.Waarde_Numeriek'].values/100},index=data_pd['time'].dt.tz_localize(None)) #read dataset and convert to DataFrame with correct format. Tijdzone is MET (UTC+1), ook van de resulterende getijcomponenten.
        ts_meas_raw = ts_meas_raw.sort_index(axis='index') #sort dataset on times (not necessary but easy for debugging)
        bool_duplicated_index = ts_meas_raw.index.duplicated()
        if bool_duplicated_index.sum()>0:
            ts_meas_raw = ts_meas_raw[~bool_duplicated_index] #remove duplicate timesteps if they are present #TODO: data on duplicate timesteps is not always equal
        
        ndays = (ts_meas_raw.index.max()-ts_meas_raw.index.min()).total_seconds()/3600/24
        if ndays < 40:
            print('TOO SHORT, SKIPPING')
            continue

        #get dominant timestep
        timestep_min_all = ((ts_meas_raw.index[1:]-ts_meas_raw.index[:-1]).total_seconds()/60).astype(int).values
        uniq_vals, uniq_counts = np.unique(timestep_min_all,return_counts=True)
        timestep_min_dominant = uniq_vals[np.argmax(uniq_counts)]
            
        #use shorter constituent list in case of 3hr interval, otherwise normal 1year constituent list
        if timestep_min_dominant==180:
            const_list = const_list_year3hr
        else:
            const_list = const_list_year
        
        #resample if timestep is not constant
        if (ts_meas_raw.index.min() < dt.datetime(year-1,12,31,23,0)) or (ts_meas_raw.index.max() > dt.datetime(year+1,1,1,1,0)):
            raise Exception('ERROR: start/stoptimes are not within expected range of year + 1 hour ath both sides')
        if len(uniq_vals)==1: # no resampling necessary if constant timestep
            if timestep_min_dominant not in [10,60,180]:
                raise Exception(f'ERROR: constant timestep of {timestep_min_dominant} min, while 10, 60 or 180 min is expected.')
            ts_meas = ts_meas_raw.copy()
        else: #varying timestep, for instance in interval-transition year
            if 180 in uniq_vals: #if 180 min interval occurs, resample to 180 min
                ts_meas = hatyan.resample_timeseries(ts=ts_meas_raw, timestep_min=180, tstart=ts_meas_raw.index.min(), tstop=ts_meas_raw.index.max())
            else: #otherwise resample to 60 minutes
                ts_meas = hatyan.resample_timeseries(ts=ts_meas_raw, timestep_min=60, tstart=ts_meas_raw.index.min(), tstop=ts_meas_raw.index.max())
        perct_nan = ts_meas['values'].isnull().sum()/len(ts_meas['values'])*100 


#%% tidal predictors

dir_indicators = os.path.join(save_path,'tidal_indicators')
if not os.path.exists(dir_indicators):
    os.mkdir(dir_indicators)


#%% tidal assymetry