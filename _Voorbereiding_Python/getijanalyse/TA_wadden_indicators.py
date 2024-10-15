# -*- coding: utf-8 -*-
"""
Created on Thu Aug 11 09:09:23 2022

@author: veenstra
"""

import os
import datetime as dt
import pandas as pd
import matplotlib.pyplot as plt
plt.close('all')
import hatyan
from matplotlib import cm

calc_indicators = False
write_csv = False
timestep_min = 10 #TODO: when rerunning, adjust to 1 min

station_list = ['WIERMGDN','WESTTSLG','TEXNZE','TERSLNZE','SCHIERMNOG','NES','LAUWOG','HUIBGT','HOLWD','HARLGN','EEMSHVN','DENHDR','DELFZL']
station_list = ['DENHDR','WESTTSLG','TEXNZE','HARLGN','TERSLNZE','HOLWD','WIERMGDN','NES','HUIBGT','SCHIERMNOG','LAUWOG','EEMSHVN','DELFZL'][::-1] #sorted on M2 amplitude

year_list = range(1879,2022)

##################

dir_base = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\calculated'

dir_indicators = os.path.join(dir_base,'tidal_indicators')
if not os.path.exists(dir_indicators):
    os.mkdir(dir_indicators)

data_pd_GLLWS = pd.DataFrame({}, columns=station_list, index=year_list, dtype=float) #index should stay as the 'old' const_list
data_pd_GHHWS = pd.DataFrame({}, columns=station_list, index=year_list, dtype=float) #index should stay as the 'old' const_list

file_GLLWScsv = os.path.join(dir_indicators,f'GLLWS_{timestep_min}min.csv')
file_GHHWScsv = os.path.join(dir_indicators,f'GHHWS_{timestep_min}min.csv')

if calc_indicators:
    for station in station_list:
        for year in year_list:
            print(f'STATION/YEAR: {station} {year}')
            file_comp = os.path.join(dir_base,'TA_filtersurge',f'{station}_{year}_components_UTC+1.csv')
            if not os.path.exists(file_comp):
                print('NO components available, skipped')
                continue
            comp = pd.read_csv(file_comp)
            comp = comp.set_index('comp')
            ts_pred = hatyan.prediction(comp,times_ext=[dt.datetime(year,1,1),dt.datetime(year+1,1,1)],timestep_min=timestep_min)
            
            ts_pred_ext = hatyan.calc_HWLW(ts_pred)
            ts_tidalindicators = hatyan.kenmerkendewaarden.calc_HWLWtidalindicators(ts_pred_ext)
            
            data_pd_GLLWS.loc[year,station] = ts_tidalindicators['LW_monthmin_mean']
            data_pd_GHHWS.loc[year,station] = ts_tidalindicators['HW_monthmax_mean']
    
    if write_csv:
        data_pd_GLLWS.to_csv(file_GLLWScsv)
        data_pd_GHHWS.to_csv(file_GHHWScsv)
else:
    data_pd_GLLWS = pd.read_csv(file_GLLWScsv,index_col=0)
    data_pd_GHHWS = pd.read_csv(file_GHHWScsv,index_col=0)
    year_list = range(data_pd_GLLWS.index.min(),data_pd_GLLWS.index.max()+1)
    station_list = data_pd_GLLWS.columns

#plot figure
colors_stat = cm.get_cmap('turbo', len(station_list))
fig,(ax1,ax2) = plt.subplots(2,1,figsize=(14,8))
ax1.set_ylabel('GHHWS [m]')
ax2.set_ylabel('GLLWS [m]')
for iS, station in enumerate(station_list):
    ax1.plot(year_list,data_pd_GHHWS.loc[:,station],color=colors_stat(iS),label=station)
    ax2.plot(year_list,data_pd_GLLWS.loc[:,station],color=colors_stat(iS),label=station)
ax1.legend()
ax2.legend()
fig.tight_layout()
fig.savefig(os.path.join(dir_indicators,f'GHHWS_GLLWS_{timestep_min}min.png'))


