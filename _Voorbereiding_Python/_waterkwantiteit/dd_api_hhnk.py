#Nathalie Dees
#nathalie.dees@deltares.nl
#reading raw hhnk dd-api infomation and storing it to csv files
#%%
import os
import pandas as pd
import requests
from datetime import datetime

path='P:\\11202493--systeemrap-grevelingen\\1_data\\Wadden\\HHNK\\raw\\'
path_csv=r'C:\projecten\rws\2022\zoetwaterdebiet\hhnk\csv'

#path of api
ddapi = 'https://hhnk.lizard.net/api/v4/'

#names and codes of stations needed in analysis
names= ['Helsdeur', 'Oostoever', 'Leemans'] 
codes=['KGM-Q-29234', 'KGM-Q-29235', 'KGM-A-371','KGM-JF-44'  ]

mdata = []

# %%
#-----------start fetching data
#for loop to oop through the station codes and get the corresponding url to fetch data from
for i in range(len(codes)):
    tapi= ddapi + '/timeseries/?locationCode='+str(codes[i])
    tresponse = requests.get(tapi).json()
    #print(tapi)

    #for loop + if statement to select stations which only have the quantity ' Debiet'  (so waterhoogte ect is not taken into account)
    for l in range(len(tresponse['results'])):
        if tresponse['results'][l]['observationType']['quantity']== 'Debiet':

            #storing the metadata in a dictonary (easy fix, could be done more neat)
            metadata= {'locatie.naam' : tresponse['results'][l]['location']['properties']['locationName'], 
            'locatie.orgineel' :tresponse['results'][l]['location']['properties']['locationCode'],
            'longitude' : tresponse['results'][l]['location']['geometry']['coordinates'][0],
            'latitude' :tresponse['results'][l]['location']['geometry']['coordinates'][1]
            }

            mdata.append(metadata)
            #'qualifier' : tresponse['results'][l]['qualifier'], 
            #'grootheid.omschrijving' : tresponse['results'][l]['observationType']['quantity'], 

            df = pd.DataFrame(mdata)

            df.to_csv(os.path.join(path_csv, 'locations.csv'))


            #transform into df
            metadata=pd.DataFrame([metadata])
            #save name + code for later
            name=tresponse['results'][l]['location']['properties']['locationName']
            code=tresponse['results'][l]['location']['properties']['locationCode']

            #fetch specific location code url again
            dataurl = ddapi+'/timeseries/?locationCode='+tresponse['results'][l]['location']['properties']['locationCode']
            locresponse = requests.get(dataurl).json()
            print(dataurl)
            #print(l)
            #print(tresponse['results'][l]['location']['properties']['locationCode'])
            
            #loop through corresponding timeseries which matches the location code, fetching is based on available data
            for ts in range(len(locresponse['results'])):
                start=locresponse['results'][ts]['startTime']
                end=locresponse['results'][ts]['endTime']

                tsurl = locresponse['results'][ts]['url']
                drespons = requests.get(tsurl+'?startTime='+str(start)+'&endTime='+str(end)).json()  #(tsurl+'?startTime='+str(st)+'&endTime='+str(et))
                #print(drespons)
                if not drespons['events']:
                    print('no data found for ',tresponse['results'][l]['observationType']['quantity'])
                else:
                    #save data to csv file, combine with metadata
                    #more advanced, can be directly stored into the database
                    df = pd.DataFrame(drespons['events'])
                    df=df.join(metadata)
                   # df.to_csv(path+name+code+'.csv', index=False)
# %%
# the url to retrieve the data from, groundwaterstation data 
ground = "https://hhnk.lizard.net/api/v4/pumpstations/"
#creation of empty lists to fill during retrieving process
gdata = []
tsv=[]
timeurllist= []

#retrieve information about the different groundwater stations, this loops through all the pages
response = requests.get(ground).json()
groundwater = response['results']
while response["next"]:
    response = requests.get(response["next"]).json()
    groundwater.extend(response["results"])

    
# %%
#start retrieving of the seperate timeseries per groundwaterstation
    for i in range(len(response)):
        geom = response['results'][i]['geometry']
        #print( response['results'][i]['filters'][0]['code'])
        #creation of a metadata dict to store the data
        metadata= {
            'locatie.naam' : response['results'][i]['filters'][0]['code'], 
            'x' : geom["coordinates"][0],
            'y' : geom["coordinates"][1],
                }
        ts = response['results'][i]['filters'][0]['timeseries'][0]
        timeurllist.append([ts])
        #conversion to df
        gdata.append(metadata)

        #new call to retrieve timeseries
        tsresponse = requests.get(ts).json()
        start = tsresponse['start']
        end= tsresponse['end']

        if start is not None or end is not None:
            params = {'start': start, 'end': end}
            t = requests.get(ts + 'events', params=params).json()['results']
        #only retrieving data which has a flag below four, flags are added next to the timeseries
        #this is why we first need to extract all timeseries before we can filter on flags... 
        #for flags see: https://publicwiki.deltares.nl/display/FEWSDOC/D+Time+Series+Flags
            if t[i]['flag']<4:
                tsv.extend(t)
        timeseries = pd.DataFrame.from_dict(tsv) #check size of timeseries to see if data is returned
        df = pd.DataFrame(gdata)
# %%
