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

dir=r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\HHNK\raw\20221205_deltares_debieten_uitwisselpunten'
locations=r'C:\projecten\rws\2022\zoetwaterdebiet\hhnk\csv\locations.csv'
loc=pd.read_csv(locations)
loc=loc.drop([5,7,8,9,10])

#%%
def join_tables(dfs,loc):
    dfx = dfs.join(pd.DataFrame(
        {
            'locatie.origineel': loc['locatie.orgineel'].iloc[-1],
            'waardebewerkingsmethode.omschrijving': 'Kwartierwaarde',
            'grootheid.omschrijving': 'Debiet',
            'grootheid.code': 'Q', 
            'eenheid.code':'m3/s',
            'longitude': loc['longitude'].iloc[-1],
            'latitude':loc['latitude'].iloc[-1],
            'locatie.naam':loc['locatie.naam'].iloc[-1],
            'gebied':'HHNK',
        }, index=dfs.index
    ))
    return dfx

def map_score(quality):
  if quality == 'original reliable':
    return "betrouwbaar"
  elif quality == 'completed unreliable':
    return "onbetrouwbaar"
  elif quality == 'None':
    return "None"

# %%
for fname in os.listdir(dir):
    f = os.path.join(dir, fname)
    name=os.path.splitext(fname)[0]
    print(f)
    if name =='helsdeur_debiet':
            df=pd.read_csv(f, sep=';', low_memory=False)
            df=df.drop(df.columns[8:20], axis=1)
            df=df.iloc[1: , :]
           # print(df)
            hels=(loc[loc['locatie.orgineel'] == "KGM-Q-29234"] )
            hels2=(loc.loc[loc['locatie.orgineel'].str.match('KGM-Q-29234_debiet_berekend_spuien')])
           # print(hels)
            df['datum'] = df['Unnamed: 0'] 

            dfs=pd.DataFrame().assign(datum=df['datum'],
            quality=df['KGM-Q-29234_debiet_berekend_spuien quality'], 
            numeriekewaarde=df['KGM-Q-29234_debiet_berekend_spuien'])

            dfs["kwaliteitsoordeel.code"] = dfs["quality"].apply(lambda quality: map_score(quality)) #rename scale labels

            dfh=pd.DataFrame().assign(datum=df['datum'],
            quality=df['KGM-Q-29234 quality'], 
            numeriekewaarde=df['KGM-Q-29234'])

            dfh["kwaliteitsoordeel.code"] = dfh["quality"].apply(lambda quality: map_score(quality)) #rename scale labels
            
            dfh1 = join_tables(dfh, hels)
            dfh2 = join_tables(dfs, hels2)
    elif name =='leemans_debiet':
            dfz=pd.read_csv(f, sep=';', low_memory=False)
            dfz=dfz.drop(dfz.columns[8:20], axis=1)
            dfz=dfz.iloc[1: , :]
           # print(df)
            lee=(loc.loc[loc['locatie.orgineel'].str.match('KGM-A-371')])

           # print(hels)
            dfz['datum'] = dfz['Unnamed: 0'] 

            dfk=pd.DataFrame().assign(datum=dfz['datum'],
            quality=dfz['KGM-A-371 quality'], 
            numeriekewaarde=dfz['KGM-A-371'])

            dfk["kwaliteitsoordeel.code"] = dfk["quality"].apply(lambda quality: map_score(quality)) #rename scale labels

            dfl = join_tables(dfk, lee)
    elif name=='oostoever_debiet':
            dfx=pd.read_csv(f, sep=';', low_memory=False)
            dfx=dfx.drop(dfz.columns[8:20], axis=1)
            dfx=dfx.iloc[1: , :]
            #print(dfx)
            oost=(loc.loc[loc['locatie.orgineel'].str.match('KGM-Q-29235')])
            
           # print(hels)
            dfx['datum'] = dfx['Unnamed: 0'] 

            dfo=pd.DataFrame().assign(datum=dfx['datum'],
            quality=dfx['KGM-Q-29235_debiet_berekend_spuien quality'], 
            numeriekewaarde=dfx['KGM-Q-29235_debiet_berekend_spuien'])

            dfo["kwaliteitsoordeel.code"] = dfo["quality"].apply(lambda quality: map_score(quality)) #rename scale labels

            dfoo = join_tables(dfo, oost)


    #dft = pd.concat([dfe, df2])


# %%
dfend=pd.concat([dfh1, dfh2, dfl, dfoo])
dfend=dfend.drop(columns=['quality'])
# %%
dfend.to_csv(r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\HHNK\standard\hhnk_processed.csv')
# %%
