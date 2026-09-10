# tidal components - have been derived
#assymetry has not been derived  #TODO integrating hatyan tidal asymmetry scripts

#- Gemiddeld LaagLaag water bij Springtij #TODO integrating hatyan tidal indicators scripts
# - Gemiddeld HoogHoog water bij springtij #TODO integrating hatyan tidal indicators scripts

# THIS SCRIPT DOES NOT WORK YET!!
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
import hatyan

save_path = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026'
Path(save_path).mkdir(parents=True, exist_ok=True)

dir_TA_filtersurge = os.path.join(save_path,'TA_filtersurge')
if not os.path.exists(dir_TA_filtersurge):
    os.mkdir(dir_TA_filtersurge)
dir_TA_perstation = os.path.join(save_path,'waterstand_berekend_m')
if not os.path.exists(dir_TA_perstation):
    os.mkdir(dir_TA_perstation)

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


hatyan.analysis_prediction.analysis()