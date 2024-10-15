# -*- coding: utf-8 -*-
"""
Created on Fri Aug 12 13:50:51 2022

@author: veenstra
"""

import os
import pandas as pd
import matplotlib.pyplot as plt
plt.close('all')
from matplotlib import cm
import numpy as np

const_list = ['A0','M2','S2','M4'] # get_const_list_hatyan('year')

station_list = ['WIERMGDN','WESTTSLG','TEXNZE','TERSLNZE','SCHIERMNOG','NES','LAUWOG','HUIBGT','HOLWD','HARLGN','EEMSHVN','DENHDR','DELFZL']
station_list = ['DENHDR','WESTTSLG','TEXNZE','HARLGN','TERSLNZE','HOLWD','WIERMGDN','NES','HUIBGT','SCHIERMNOG','LAUWOG','EEMSHVN','DELFZL'][::-1] #sorted on M2 amplitude

year_list = range(1891,2021)

##################

dir_base = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\calculated'

dir_asymmetry = os.path.join(dir_base,'tidal_asymmetry')
if not os.path.exists(dir_asymmetry):
    os.mkdir(dir_asymmetry)

#reading all component data and storing into multiindex dataframe
data_pd_TA_allstations = pd.DataFrame({}, columns=pd.MultiIndex.from_product([station_list,['A','phi_deg'],year_list]), index=const_list)
for station in station_list:
    print(f'reading component data for {station} for:',end='')
    for year in year_list:
        file_comp = os.path.join(dir_base,'TA_filtersurge',f'{station}_{year}_components_UTC+1.csv')
        if not os.path.exists(file_comp):
            #print('NO components available, skipped')
            continue
        print(f' {year}',end='')
        comp = pd.read_csv(file_comp)
        comp = comp.set_index('comp')
        data_pd_TA_allstations.loc[:,(station,['A','phi_deg'],year)] = comp.loc[const_list].values
    print('')



compavailable = data_pd_TA_allstations.loc[['A0'],(data_pd_TA_allstations.columns.get_level_values(0),'A')].droplevel(1,axis=1).stack(1).droplevel(0)
compavailable_statint = compavailable*0 + np.arange(len(compavailable.columns))
fig,ax1 = plt.subplots(figsize=(12,6))
ax1.plot(compavailable_statint,color='r',linewidth=2)
ax1.set_yticks(range(len(compavailable_statint.columns)))
ax1.set_yticklabels(compavailable_statint.columns)
ax1.invert_yaxis()
ax1.grid()
ax1.set_title('available years per station (where TA was successful)')
fig.tight_layout()
fig.savefig(os.path.join(dir_asymmetry,'available_years_perstation.png'))

#plotting component timeseries
colors_stat = cm.get_cmap('turbo', len(station_list))
for comp_sel in const_list+['M4divM2']:
    fig,(ax1,ax2) = plt.subplots(2,1,figsize=(9,9))
    if 'div' in comp_sel: #tidal assymetry
        ax1.set_title('Tidal asymmetry')
        ax1.set_ylabel('Amplitude M4/M2 [-]')
        ax2.set_ylabel('2M2-M4 [$^\circ$]')
    else:
        ax1.set_title(f'Amplitude and phase for {comp_sel}')
        ax1.set_ylabel('Amplitude [m]')
        ax2.set_ylabel('phase [$^\circ$]')
    ax1.set_xlim(1890,2021)
    ax2.set_xlim(1890,2021)
    for iS, station in enumerate(station_list):
        data_pd_TA_station = data_pd_TA_allstations.loc[:,station]
        #data_pd_TA_station = pd.read_pickle(os.path.join(dir_comp_ts,f'data_pd_TA_{station}.pkl'))
        if comp_sel=='M4divM2': #tidal assymetry
            ax1.plot(data_pd_TA_station.loc['M4',('A')]/data_pd_TA_station.loc['M2',('A')],color=colors_stat(iS),label=station)
            if iS==0:
                ax2.plot([1890,2021],[180,180],'k-',linewidth=0.5)
                ax2.text(1915,182,'ebb dominant',va='bottom')
                ax2.text(1915,176,'flood dominant',va='top')
            ax2.plot((2*data_pd_TA_station.loc['M2',('phi_deg')]-data_pd_TA_station.loc['M4',('phi_deg')]+10)%360-10,color=colors_stat(iS),label=station)
        else:
            ax1.plot(data_pd_TA_station.loc[comp_sel,('A')],color=colors_stat(iS),label=station)
            if 0:#comp_sel=='A0': #'A0' phase array was previously used for storing timestep dominance but not anymore
                ax2.set_ylabel('dominant timestep [minutes]')
                ax2.plot([1890,2021],[60,60],'k-',linewidth=0.5)
                ax2.plot(data_pd_TA_station.loc['A0','timestep_min_dominant'],color=colors_stat(iS),label=station)
                ax2.set_yticks([0,10,60,120,180])
            else:
                ax2.plot((data_pd_TA_station.loc[comp_sel,('phi_deg')]+180)%360-180,color=colors_stat(iS),label=station)
    ax1.grid(linewidth=0.4)
    ax2.grid(linewidth=0.4)
    ax1.legend(loc=2,fontsize=9)
    ax2.legend(loc=2,fontsize=9)
    fig.tight_layout()
    fig.savefig(os.path.join(dir_asymmetry,f'ts_{comp_sel}.png'))
