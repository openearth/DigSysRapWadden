"""Read files from kiwis webservices with python
Author Nathalie Dees (nathalie.dees@deltares.nl)
https://kiwis-pie.readthedocs.io/en/latest/index.html
https://github.com/amacd31/kiwis_pie"""
# %%
from datetime import date
from kiwis_pie import KIWIS
import pandas as pd
import time

#id van de meetreeksen
meet_ids = pd.read_csv(r'C:\projecten\rws\2022\zoetwaterdebiet\hunze_enAas_ids.csv', sep=';') #stations and station IDS
meet_ids['Object']=meet_ids['Object'].str.replace(' ', '_')
meet_ids['Object']=meet_ids['Object'].str.replace('(', '')
meet_ids['Object']=meet_ids['Object'].str.replace(')', '')
meet_ids['Object']=meet_ids['Object'].str.replace(':', '')
meet_ids['Object']=meet_ids['Object'].str.replace('/', '_')

print(meet_ids)

path= 'C:\\projecten\\rws\\2022\\zoetwaterdebiet\\hea\\'

#time.sleep(60) #timer for the server
# selecteren op debiet 
k = KIWIS('https://meetreeksen.hunzeenaas.nl/KiWIS/KiWIS?service=kisters', strict_mode=False)

#find allstations
stations = k.get_station_list()
#stations.to_csv(r'C:\projecten\rws\2022\zoetwaterdebiet\stationshez.csv')
# %%
#select the stations from the meetreeks
station_ids=[]
for i in range(len(meet_ids['meetreeks_id'])):
    ts_id=k.get_timeseries_list(ts_id=meet_ids['meetreeks_id'][i] 
                                ) #, parametertype_name = 'Q')
    print(ts_id)
    station_ids.append(ts_id['station_id'])

station_id = pd.DataFrame(station_ids)
station_id.reset_index(drop=True, inplace=True)

#combining station ID with meetreeks ID and save
combined=pd.concat([meet_ids,station_id], axis=1)
combined=combined.rename(columns={0:"station_id"})

#find if selected stations are in all stations
selected_stations=stations.loc[stations['station_id'].isin(station_id.iloc[:,0])]
# Perform the join on the 'ID' column, when they are similar
result = pd.merge(combined, selected_stations, on='station_id')
#%%

#for i in range(len(meet_ids['meetreeks_id'])):#the last entry does not work, so is skipped for noww
for i in range(len(station_ids)):
    #time.sleep(90) #timer for the server'
    print('processing :', result['Object'][i])
    l = meet_ids.iloc[i]
    t=k.get_timeseries_values(ts_id = result['meetreeks_id'][i], 
                            to = date(result['time_stop'][i],1,1), 
                            **{'from': date(result['time_start'][i],1,1)}
                            )
    print(t)
    t=t.reset_index()
    t=t.rename(columns={'Timestamp':'datumtijd', 'Value': 'numeriekewaarde'})
    dfx = t.join(pd.DataFrame({
        'locatie.origineel': result['station_id'][i],
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q',
        'eenheid.code':'m3/s',
        'longitude': result['station_longitude'][i],
        'latitude':result['station_latitude'][i],
        'locatie.naam':result['Object'][i],
        'gebied':'Hunze en Aas'}, index=t.index
    ))

    dfx.to_csv(path + str(meet_ids['Object'][i]) + '.csv')

"""
#get timeseries for ts_id (timeseriesid)
t=k.get_timeseries_values(ts_id = meet_ids['meetreeks_id'][0], to = date(meet_ids['time_stop'][0],1,1), **{'from': date(meet_ids['time_start'][0],1,1)})
t.to_csv( path+str(meet_ids['Object'][0]) +'.csv')
print('saved')
#t=k.get_timeseries_values(ts_id = meet_ids['meetreeks_id'][1], to = date(meet_ids['time_stop'][1],1,1), **{'from': date(meet_ids['time_start'][1],1,1)})
#t.to_csv('C:\\projecten\\rws\\2022\\zoetwaterdebcdiet\\hea\\' + str(meet_ids['Object'][1]) + '.csv')
#t=k.get_timeseries_values(ts_id = meet_ids['meetreeks_id'][2], to = date(meet_ids['time_stop'][2],1,1), **{'from': date(meet_ids['time_start'][2],1,1)})
#t.to_csv('C:\\projecten\\rws\\2022\\zoetwaterdebiet\\hea\\' + str(meet_ids['Object'][2]) + '.csv')
"""
# %%
