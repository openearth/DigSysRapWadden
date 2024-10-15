# -*- coding: utf-8 -*-
"""
Created on Wed Jul 28 09:19:08 2021

@author: veenstra

Install hatyan (potentially in a separate env):
#conda create --name wadden_TA_env -c conda-forge python=3.7 -y
#conda activate wadden_TA_env
python -m pip install git+https://github.com/Deltares/hatyan
python TA_wadden.py

This script can be reran faster when loading the components from pkl files with calc_TA variable

"""

import os
import datetime as dt
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
plt.close('all')
from matplotlib import cm
import hatyan

dir_base = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\calculated'

dir_TA_filtersurge = os.path.join(dir_base,'TA_filtersurge')
if not os.path.exists(dir_TA_filtersurge):
    os.mkdir(dir_TA_filtersurge)
dir_TA_perstation = os.path.join(dir_base,'waterstand_berekend_m')
if not os.path.exists(dir_TA_perstation):
    os.mkdir(dir_TA_perstation)

#TODO: FAILED stations in fstats (22x ndays<40 en 6x andere issues: p:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\calculated\getijdenerrors_10082022.xlsx) >> besproken
#TODO: discuss with willem, currently predicting on each 10 minute timestep, but might not be on each measured timestep (interval is sometimes 1min), is that a problem? >> 10min is goed genoeg
#TODO: discuss with willem, drop UITHZWD1 and WIERMWD1? >> kunnen weg
#TODO: ext check performance of reanalysis tidalprediction compared to RWS (latter only available from 1953 onwards?)
#TODO: ext check trends in indicators/components for outliers

#TODO: rerun alle scripts met nieuwe RWS waterstandsdata (hopefully solves duplicate timesteps and weird additional condition for bool_invalid)
#TODO: ext derive GLLWS/GHHWS with 1min pred interval

#defining a list of the components to be analysed (can also be 'half_year' and others, 'year' contains 94 components and the mean waterlevel A0)
const_list_year = hatyan.get_const_list_hatyan('year')+['SSA'] #['A0','M2','S2','M4'] # TODO: add SSA and maybe other components for better reproduction
const_list_year3hr = const_list_year[:]
drop_list = ['S4','3M2S10','2SM6','4M2S12'] #dropping components that cannot be analysed with 3hr interval timeseries
for const in drop_list:
    const_list_year3hr.remove(const)

station_list = ['WIERMGDN','WESTTSLG','TEXNZE','TERSLNZE','SCHIERMNOG','NES','LAUWOG','HUIBGT','HOLWD','HARLGN','EEMSHVN','DENHDR','DELFZL']
station_list = ['DENHDR','WESTTSLG','TEXNZE','HARLGN','TERSLNZE','HOLWD','WIERMGDN','NES','HUIBGT','SCHIERMNOG','LAUWOG','EEMSHVN','DELFZL'][::-1] #sorted on M2 amplitude
station_list = ['DENHDR']
year_list = range(1879,2022)
#year_list = [2012]
plot_ts = True #plot all timeseries (takes quite some time)

for station in station_list:
    ts_pred_allyears = pd.DataFrame() #define empty station timeseries dataframe to fill 
    data_pd_TA_station = pd.DataFrame({}, columns=pd.MultiIndex.from_product([['A','phi_deg'],year_list]), index=const_list_year) #index should stay as the 'old' const_list
    file_fstats = os.path.join(dir_TA_filtersurge,f'fstats{station}.txt')
    if len(year_list)>1:
        with open(file_fstats,'w') as fstats:
            pass
    for year in year_list:
        plt.close('all')
        print(f'processing {station} for {year}')
        url_dataraw = 'http://watersysteemdata.deltares.nl/thredds/fileServer/watersysteemdata/Wadden/ddl/raw/waterhoogte/'
        file_csv = url_dataraw+f'{station}_OW_WATHTE_NVT_NAP_{year}_ddl_wq.csv'
        try:
            data_pd = pd.read_csv(file_csv,sep=';',parse_dates=['tijdstip'])            
        except: #if not available, skip this station+year combination
            print('NO CSV, SKIPPING')
            with open(file_fstats,'a') as fstats:
                fstats.write(f'{station:20s} {year}: NO CSV, SKIPPING\n')
            continue
        
        bool_invalid = (data_pd['kwaliteitswaarde.code']!=0) & (data_pd['kwaliteitswaarde.code']!=25) | data_pd['numeriekewaarde'].isin([740,999,1010,1011,1012]) #latter is for HUIBGT 1985/1987 and maybe others#| (data_pd['numeriekewaarde']>340) | (data_pd['numeriekewaarde']<-340) 
        data_pd.loc[bool_invalid,'numeriekewaarde'] = np.nan
        ts_meas_raw = pd.DataFrame({'values':data_pd['numeriekewaarde'].values/100},index=data_pd['tijdstip'].dt.tz_localize(None)) #read dataset and convert to DataFrame with correct format. Tijdzone is MET (UTC+1), ook van de resulterende getijcomponenten.
        ts_meas_raw = ts_meas_raw.sort_index(axis='index') #sort dataset on times (not necessary but easy for debugging)
        bool_duplicated_index = ts_meas_raw.index.duplicated()
        if bool_duplicated_index.sum()>0:
            ts_meas_raw = ts_meas_raw[~bool_duplicated_index] #remove duplicate timesteps if they are present #TODO: data on duplicate timesteps is not always equal
        
        ndays = (ts_meas_raw.index.max()-ts_meas_raw.index.min()).total_seconds()/3600/24
        if ndays < 40:
            print('TOO SHORT, SKIPPING')
            with open(file_fstats,'a') as fstats:
                fstats.write(f'{station:20s} {year}: {ndays:.2f} DAYS OF DATA, SKIPPING\n')
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
        with open(file_fstats,'a') as fstats:
            fstats.write(f'{station:20s} {year}: ({ts_meas_raw.index.min()} to {ts_meas_raw.index.max()}, {ndays:5.1f} days, {len(ts_meas_raw):5d} values, {len(uniq_vals):3d} time intervals and {timestep_min_dominant:3d} min is dominant, {perct_nan:.1f}% nan in full year ts, duplicates_dropped={bool_duplicated_index.sum():4d})')
        
        if 0:
            #validate with DDL data retrieved with Python
            ts_py = pd.read_pickle(os.path.join(r'p:\11208031-010-kenmerkende-waarden-k\work\measurements_wl_18700101_20220101',f'{station}_measwl.pkl'))
            ts_py.index = ts_py.index.tz_localize(None)
            ts_py = ts_py.loc[(ts_py.index>=dt.datetime(year,1,1)) & (ts_py.index<=dt.datetime(year+1,1,1))]
            fig,(ax1,ax2) = hatyan.plot_timeseries(ts=ts_meas_raw,ts_validation=ts_py)
            ax1.set_title(f'{station} {year}')
            ax2.set_ylim(-1,1)
            plt.show()
        
        if plot_ts:
            #make figure to check the raw data of the files that cannot be used for the tidal analysis
            fig,(ax1,ax2) = hatyan.plot_timeseries(ts=ts_meas_raw,ts_validation=ts_meas) 
            ax1.set_title(f'waterlevel measured raw vs filtered for {station} {year}')
            ax2.set_ylim(-1,1)
            fig.savefig(os.path.join(dir_TA_filtersurge,f'tsmeas_{station}_{year}.png'))
        
        #tidal analysis
        try:  #do the tidal analysis
            comp_frommeas = hatyan.get_components_from_ts(ts=ts_meas, const_list=const_list, nodalfactors=True, xfac=True, fu_alltimes=True, xTxmat_condition_max=11.5)
        except: #if the tidal analysis does not work
            with open(file_fstats,'a') as fstats:
                fstats.write(' >> ANALYSIS FAILED\n')
            continue
        
        comp_frommeas.index.name = 'comp'
        comp_frommeas.to_csv(os.path.join(dir_TA_filtersurge,f'{station}_{year}_components_UTC+1.csv'),float_format='%.3f')
        data_pd_TA_station.loc[const_list,(['A','phi_deg'],year)] = comp_frommeas.loc[const_list,['A','phi_deg']].values
        ts_pred = hatyan.prediction(comp=comp_frommeas,times_ext=[dt.datetime(year,1,1),dt.datetime(year,12,31,23,50)],timestep_min=10)
        ts_pred.rename_axis('time').to_csv(os.path.join(dir_TA_perstation,f'tspred_anasameyear_{station}_OW_WATHTASTRO_{year}.csv'))
        
        if plot_ts:
            fig,(ax1,ax2) = hatyan.plot_timeseries(ts=ts_meas,ts_validation=ts_pred)
            ax2.set_ylim(-1,1)
            ax1.set_title(f'tidal prediction vs measured for {station} {year}')
            fig.savefig(os.path.join(dir_TA_filtersurge,f'tspred_{station}_{year}.png'))
        
        with open(file_fstats,'a') as fstats:
            fstats.write(' >> SUCCESS\n')
    
    """
    if year_list==list(range(1879,2022)): #overwrite only if all years are done
        #save timeseries data in one big csv #TODO: maybe remove this part, files per year are also available
        ts_pred_allyears = ts_pred_allyears.append(ts_pred)
        ts_pred_allyears.rename_axis('time').to_csv(os.path.join(dir_TA_perstation,f'tspred_anasameyear_{station}_OW_WATHTASTRO_allyears.csv'))
        
        #also save all components
        data_pd_TA_station.to_pickle(os.path.join(dir_TA_filtersurge,f'data_pd_TA_{station}.pkl'))
    """
