# -*- coding: utf-8 -*-
"""
Created on Thu Aug 11 11:04:05 2022

@author: veenstra

Plots the original RWS tidal prediction (based on measurement data from previous years) and the new tidal prediction (base on measurement data for the same year)
"""

import os
import pandas as pd
import datetime as dt
import numpy as np
import hatyan
hatyan.close('all')

# year_list = range(1940,2026)
dir_base = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026'

stations = pd.read_csv(os.path.join(dir_base,'selected_stations.csv'))
stations_list = stations['CODE'].unique()

dir_predcomparison = os.path.join(dir_base,'prediction_comparison')
if not os.path.exists(dir_predcomparison):
    os.mkdir(dir_predcomparison)

for station in stations_list:
    hatyan.close('all')
    ts_meas_rws = pd.DataFrame()
    print(f'reading RWS measurement data for {station} for:',end='')
    station = station.replace('_','.')
    file_meas_rws = os.path.join(dir_base,f'{station}_WATHTE_meting.csv')
    if not os.path.exists(file_meas_rws):
        continue
    ts_meas_rws_raw = pd.read_csv(file_meas_rws,sep=';',parse_dates=['time'])#,index_col=0,parse_dates=True) EEMSHVN_OW_WATHTBRKD_NVT_NAP_2000_ddl_wq
    ts_meas_rws_raw = pd.DataFrame({'values':ts_meas_rws_raw['Meetwaarde.Waarde_Numeriek'].values/100, 'QC':ts_meas_rws_raw['WaarnemingMetadata.Kwaliteitswaardecode'].values},index=ts_meas_rws_raw['time'].dt.tz_localize(None)).sort_index()
    ts_meas_rws_raw[ts_meas_rws_raw['QC']!=0] = np.nan
    ts_meas_rws = pd.concat([ts_meas_rws,ts_meas_rws_raw],axis=0)
    print('')
    ts_meas_rws_nodupl = ts_meas_rws[~ts_meas_rws.index.duplicated()]
    ts_meas_rws_hourly = ts_meas_rws_nodupl.loc[ts_meas_rws_nodupl.index.minute==0]
    
    ts_pred_rws = pd.DataFrame()
    print(f'reading RWS prediction data for {station} for:',end='')
    file_pred_rws = os.path.join(dir_base, f'{station}_WATHTE_astronomisch.csv')
    if not os.path.exists(file_pred_rws):
        continue
    ts_pred_rws_raw = pd.read_csv(file_pred_rws,sep=';',parse_dates=['time'])#,index_col=0,parse_dates=True) EEMSHVN_OW_WATHTBRKD_NVT_NAP_2000_ddl_wq
    ts_pred_rws = pd.DataFrame({'values':ts_pred_rws_raw['numeriekewaarde'].values/100},index=ts_pred_rws_raw['time'].dt.tz_localize(None)).sort_index()
    print('')
    if len(ts_pred_rws)==0:
        continue
    ts_pred_rws_nodupl = ts_pred_rws[~ts_pred_rws.index.duplicated()]
    ts_pred_rws_hourly = ts_pred_rws_nodupl.loc[ts_pred_rws_nodupl.index.minute==0]
    
    print(f'reading reanalysis_sameyear prediction data for {station} for:',end='')
    ts_pred_rea = pd.DataFrame()
    file_pred_rea_oneyear = os.path.join(dir_base,'waterstand_berekend_m',f'tspred_anasameyear_{station}_OW_WATHTASTRO_{year}.csv')
    if not os.path.exists(file_pred_rea_oneyear):
        continue
    ts_pred_rea_oneyear = pd.read_csv(file_pred_rea_oneyear,index_col=0,parse_dates=True)
    ts_pred_rea = pd.concat([ts_pred_rea,ts_pred_rea_oneyear],axis=0)
    print('')
    ts_pred_rea_hourly = ts_pred_rea.loc[ts_pred_rea.index.minute==0]
    if len(ts_pred_rea_hourly)==0:
        continue
    
    print('plotting')
    fig,(ax1,ax2) = hatyan.plot_timeseries(ts=ts_pred_rws_hourly,ts_validation=ts_meas_rws_hourly)
    ax1.set_title(f'{station} RWS pred vs measurement')
    ax2.set_ylim(-0.6,0.6)
    ax2.set_xlim(dt.datetime(year_list.start,1,1),dt.datetime(year_list.stop,1,1))
    fig.savefig(os.path.join(dir_predcomparison,f'{station}_predRWS.png'))
    
    fig,(ax1,ax2) = hatyan.plot_timeseries(ts=ts_pred_rea_hourly,ts_validation=ts_meas_rws_hourly)
    ax1.set_title(f'{station} reanalysis_sameyear pred vs measurement')
    ax2.set_ylim(-0.6,0.6)
    ax2.set_xlim(dt.datetime(year_list.start,1,1),dt.datetime(year_list.stop,1,1))
    fig.savefig(os.path.join(dir_predcomparison,f'{station}_predreanalysis.png'))
    
    fig,(ax1,ax2) = hatyan.plot_timeseries(ts=ts_pred_rea_hourly,ts_validation=ts_pred_rws_hourly)
    ax1.set_title(f'{station} reanalysis_sameyear pred vs RWS pred')
    ax2.set_ylim(-0.6,0.6)
    ax2.set_xlim(dt.datetime(year_list.start,1,1),dt.datetime(year_list.stop,1,1))
    fig.savefig(os.path.join(dir_predcomparison,f'{station}_preddiff.png'))
    print(f'{station} done')
    