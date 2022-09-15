# %%
#read in hhnk data and save to desired format
import pandas as pd
import matplotlib.pyplot as plt

import os
# %%
#loop through the csv files in the dir

#calculate etmaalgemiddelden 

#fill all the nan columns with first value in df 

#add missing columns + column names to the df

#append final data to one big df

#upload final df to the db

"""
desired output format for the dataframe
etmaalgemiddelde data 
datum locatie.origineel numeriekewaarde waardebewerkingsmethode.omschrijving grootheid.omschrijving grootheid.code eenheid.code longitude latitude locatie.naam gebied
"""

dir=r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\HHNK\raw'

dfe = pd.DataFrame() # empty dataframe

for fname in os.listdir(dir):
    f = os.path.join(dir, fname)
    df=pd.read_csv(f)

    #doe ingewikeld want ik kon geen andere manier vinden
    df['timeStamp'] =  pd.to_datetime(df['timeStamp'])
    df_top=df.iloc[0]
    df=df.drop(columns=['longitude','latitude'])

    # %%
    df1 = df.groupby(by=pd.Grouper(freq='D', key='timeStamp')).mean() #calculate average
    #print(df1.head(5))

    df = df1.join(pd.DataFrame(
        {
            'locatie.origineel': df_top['locatie.origineel'],
            'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
            'grootheid.omschrijving': 'Debiet',
            'grootheid.code': 'Q', 
            'eenheid.code':'m3/s',
            'longitude': df_top['longitude'],
            'latitude':df_top['latitude'],
            'locatie.naam':df_top['locatie.naam'],
            'gebied':'HHNK'
        }, index=df1.index
    ))

    dft = pd.concat([dfe, df2])

