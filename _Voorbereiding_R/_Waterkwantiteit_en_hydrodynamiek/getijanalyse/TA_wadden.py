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

dir_ts_plots,dir_comp_plots,dir_comp_csv,dir_comp_ts = ['timeseries_plots','component_plots','component_csv','component_ts']
if not os.path.exists(dir_ts_plots):
    os.mkdir(dir_ts_plots)
if not os.path.exists(dir_comp_plots):
    os.mkdir(dir_comp_plots)
if not os.path.exists(dir_comp_csv):
    os.mkdir(dir_comp_csv)
if not os.path.exists(dir_comp_ts):
    os.mkdir(dir_comp_ts)

#defining a list of the components to be analysed (can also be 'half_year' and others, 'year' contains 94 components and the mean H0)
const_list = ['A0','M2','S2','M4'] # get_const_list_hatyan('year')
station_list = ['WIERMWD1','WIERMGDN','WESTTSLG','UITHZWD1','TEXNZE','TERSLNZE','SCHIERMNOG','NES','LAUWOG','HUIBGT','HOLWD','HARLGN','EEMSHVN','DENHDR','DELFZL']
station_list = ['UITHZWD1','WIERMWD1','DENHDR','WESTTSLG','TEXNZE','HARLGN','TERSLNZE','HOLWD','WIERMGDN','NES','HUIBGT','SCHIERMNOG','LAUWOG','EEMSHVN','DELFZL'][::-1] #sorted on M2 amplitude
#station_list = ['TEXNZE']
year_list = list(range(1891,2021))
#year_list = [2015]
calc_TA = True #True: calculate TA and write to pkl file  OR  False: read results from pkl file and plot component timeseries
plot_ts = False #plot all timeseries (takes quite some time)

if calc_TA:
    for station in station_list:
        data_pd_TA_station = pd.DataFrame({}, columns=pd.MultiIndex.from_product([['A','phi_deg'],year_list]), index=const_list)
        file_fstats = os.path.join(dir_comp_ts,f'fstats{station}.txt')
        if len(year_list)>1:
            with open(file_fstats,'w') as fstats:
                pass
        plt.close('all')
        compplot_open = False
        for year in year_list:
            print(f'processing {station} for {year}')
            url_dataraw = 'http://watersysteemdata.deltares.nl/thredds/fileServer/watersysteemdata/Wadden/ddl/raw/waterhoogte/'
            file_csv = url_dataraw+f'{station}_OW_WATHTE_NVT_NAP_{year}_ddl_wq.csv'
            try:
                data_pd = pd.read_csv(file_csv,sep=';',parse_dates=['tijdstip'])            
            except: #if not available, skip this station+year combination
                print('csv not found')
                continue
            
            bool_invalid = (data_pd['kwaliteitswaarde.code']!=0) | (data_pd['numeriekewaarde']>340) | (data_pd['numeriekewaarde']<-340)
            data_pd.loc[bool_invalid,'numeriekewaarde'] = np.nan
            ts_meas_raw = pd.DataFrame({'values':data_pd['numeriekewaarde'].values/100},index=data_pd['tijdstip'].dt.tz_localize(None)) #read dataset and convert to DataFrame with correct format
            ts_meas_raw = ts_meas_raw.sort_index(axis='index') #sort dataset on times (not necessary but easy for debugging)
            bool_duplicated_index = ts_meas_raw.index.duplicated()
            if bool_duplicated_index.sum()>0:
                ts_meas_raw = ts_meas_raw[~bool_duplicated_index] #remove duplicate timesteps if they are present
            
            #get dominant timestep
            if len(ts_meas_raw)>1:
                timestep_min_all = ((ts_meas_raw.index[1:]-ts_meas_raw.index[:-1]).total_seconds()/60).astype(int).values
                uniq_vals, uniq_counts = np.unique(timestep_min_all,return_counts=True)
                timestep_min_dominant = uniq_vals[np.argmax(uniq_counts)]
                data_pd_TA_station.loc['A0',('timestep_min_dominant',year)] = timestep_min_dominant
            if (ts_meas_raw.index.minute==40).all(): #3 hourly data for DELFZL is stored at 40 minute timestamp
                ts_meas = hatyan.resample_timeseries(ts=ts_meas_raw, timestep_min=60, tstart=dt.datetime(year,1,1,0,40), tstop=dt.datetime(year+1,1,1,0,40)) #generate timeseries with correct tstart/tstop and interval of 60min
            else:
                ts_meas = hatyan.resample_timeseries(ts=ts_meas_raw, timestep_min=60, tstart=dt.datetime(year,1,1), tstop=dt.datetime(year+1,1,1)) #generate timeseries with correct tstart/tstop and interval of 60min
            perct_nan = ts_meas['values'].isnull().sum()/len(ts_meas['values'])*100
            
            if plot_ts:
                #fig,(ax1,ax2) = Timeseries.plot_timeseries(ts=ts_meas_raw)
                fig,(ax1,ax2) = hatyan.plot_timeseries(ts=ts_meas)
                #breakit
                fig.savefig(os.path.join(dir_ts_plots,f'ts_{station}_{year}.png'))
                plt.close()
            with open(file_fstats,'a') as fstats:
                fstats.write(f'%20s {year}: (%s to %s, %.1f%% nan in full year ts, duplicates_dropped=%4d)'%(station,ts_meas_raw.index.min(),ts_meas_raw.index.max(),perct_nan,bool_duplicated_index.sum()))
            
            if perct_nan > 70: #if more than 70% is nan, skip this station+year combination (3 hourly values is 66.6% nan in hourly interval)
                with open(file_fstats,'a') as fstats:
                    fstats.write(' >> TS TOO SHORT\n')
                continue
            comp_frommeas = hatyan.get_components_from_ts(ts=ts_meas, const_list=const_list, nodalfactors=True, xfac=True, return_allyears=False, fu_alltimes=True, analysis_peryear=False)
            comp_frommeas.index.name = 'comp'
            comp_frommeas.to_csv(os.path.join(dir_comp_csv,f'{station}_{year}_components_UTC+1.csv'),float_format='%.3f')
            data_pd_TA_station.loc[:,(['A','phi_deg'],year)] = comp_frommeas.values
            
            if not compplot_open: #if this is the first succesful year for a station, open a components plot
                comp_fig,(comp_ax1,comp_ax2) = hatyan.plot_components(comp=comp_frommeas)
                comp_ax1.lines[1].remove()
                comp_ax2.lines[1].remove()
                comp_ax1.set_ylim(-0.2,1.5)
                comp_ax1.set_title(f'Amplitudes and Phases per component for {station}')
                compplot_open = True
            comp_ax1.plot(comp_frommeas['A'].values,'o-',linewidth=1.2,markersize=4, label=f'{year}')#,color='gray'
            comp_ax2.plot(comp_frommeas['phi_deg'].values,'o-',linewidth=1.2,markersize=4, label=f'{year}')#,color='gray'
            
            with open(file_fstats,'a') as fstats:
                fstats.write(' >> SUCCESS\n')
    
        if compplot_open:
            comp_fig.tight_layout()
            comp_ax1.legend(loc='upper right')
            comp_ax2.legend(loc='upper right')
            comp_fig.savefig(os.path.join(dir_comp_plots,f'components_{station}.png'))
        data_pd_TA_station.to_pickle(os.path.join(dir_comp_ts,f'data_pd_TA_{station}.pkl'))

else:
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
            if comp_sel=='A0':
                ax2.set_ylabel('dominant timestep [minutes]')
            else:
                ax2.set_ylabel('phase [$^\circ$]')
        ax1.set_xlim(1890,2021)
        ax2.set_xlim(1890,2021)
        for iS, station in enumerate(station_list):
            data_pd_TA_station = pd.read_pickle(os.path.join(dir_comp_ts,f'data_pd_TA_{station}.pkl'))
            if comp_sel=='M4divM2': #tidal assymetry
                ax1.plot(data_pd_TA_station.loc['M4',('A')]/data_pd_TA_station.loc['M2',('A')],color=colors_stat(iS),label=station)
                if iS==0:
                    ax2.plot([1890,2021],[180,180],'k-',linewidth=0.5)
                    ax2.text(1915,182,'ebb dominant',va='bottom')
                    ax2.text(1915,176,'flood dominant',va='top')
                ax2.plot((2*data_pd_TA_station.loc['M2',('phi_deg')]-data_pd_TA_station.loc['M4',('phi_deg')]+10)%360-10,color=colors_stat(iS),label=station)
            else:
                ax1.plot(data_pd_TA_station.loc[comp_sel,('A')],color=colors_stat(iS),label=station)
                if comp_sel=='A0':
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
        fig.savefig(os.path.join(dir_comp_ts,f'ts_{comp_sel}.png'))






