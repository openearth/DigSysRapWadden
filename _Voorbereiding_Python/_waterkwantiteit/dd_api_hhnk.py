#Nathalie Dees
#nathalie.dees@deltares.nl
#reading raw hhnk dd-api infomation and storing it to csv files

import os
import pandas as pd
import requests
from datetime import datetime

path='P:\\11202493--systeemrap-grevelingen\\1_data\\Wadden\\HHNK\\raw\\'

#path of api
ddapi = 'https://hhnk.lizard.net/dd/api/v2'

#names and codes of stations needed in analysis
names= ['Helsdeur', 'Oostoever', 'Leemans'] 
codes=['KGM-Q-29234', 'KGM-Q-29235', 'KGM-A-371','KGM-JF-44'  ]

#-----------start fetching data
#for loop to oop through the station codes and get the corresponding url to fetch data from
for i in range(len(codes)):
    tapi= ddapi + '/timeseries/?locationCode='+str(codes[i])
    tresponse = requests.get(tapi).json()
    #print(tapi)

    #for loop + if statement to select stations which only have the quantity ' Debiet'  (so waterhoogte ect is not taken into account)
    for l in range(len(tresponse['results'])):
        if tresponse['results'][l]['observationType']['quantity']== 'Debiet':

            #storing the metadata in a dictornary (easy fix, could be done more neat)
            metadata= {'qualifier' : tresponse['results'][l]['qualifier'], 
            'grootheid.omschrijving' : tresponse['results'][l]['observationType']['quantity'], 
            'locatie.naam' : tresponse['results'][l]['location']['properties']['locationName'], 
            'locatie.orgineel' :tresponse['results'][l]['location']['properties']['locationCode'],
            'longitude' : tresponse['results'][l]['location']['geometry']['coordinates'][0],
            'latitude' :tresponse['results'][l]['location']['geometry']['coordinates'][1]
            }
            
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