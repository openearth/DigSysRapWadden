"""Read files from kiwis webservices with python
Author Nathalie Dees (nathalie.dees@deltares.nl)
https://kiwis-pie.readthedocs.io/en/latest/index.html
https://github.com/amacd31/kiwis_pie"""

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

#select the stations from the meetreeks
station_ids=[]
for i in range(len(meet_ids['meetreeks_id'])):
    ts_id=k.get_timeseries_list(ts_id=meet_ids['meetreeks_id'][i]) #, parametertype_name = 'Q')
    station_ids.append(ts_id['station_id'])

station_id = pd.DataFrame(station_ids)
station_id.reset_index(drop=True, inplace=True)

#combining station ID with meetreeks ID and save
combined=pd.concat([meet_ids,station_id], axis=1)
combined.rename(columns={'0':"Meetreeks"})
#combined.to_csv(r'C:\projecten\rws\2022\zoetwaterdebiet\hea\hunze_enAas.csv')

#find if selected stations are in all stations
selected_stations=stations.loc[stations['station_id'].isin(station_id.iloc[:,0])]
#selected_stations.to_csv(r'C:\projecten\rws\2022\zoetwaterdebiet\hea\selected_stationshez.csv')#save to csv


for i in range(len(meet_ids['meetreeks_id'])):
    #time.sleep(90) #timer for the server'
    print('processing :', meet_ids['Object'][i])
    t=k.get_timeseries_values(ts_id = meet_ids['meetreeks_id'][i], to = date(meet_ids['time_stop'][i],1,1), **{'from': date(meet_ids['time_start'][i],1,1)})
    t.to_csv(path + str(meet_ids['Object'][i]) + '.csv')

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