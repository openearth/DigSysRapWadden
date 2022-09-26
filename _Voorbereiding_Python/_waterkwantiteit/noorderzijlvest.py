# %%
#import data from het xlsx of noorderzijlvest to db
import pandas as pd
import datetime
import configparser
from sqlalchemy import create_engine, MetaData

f = r'C:\projecten\rws\2022\zoetwaterdebiet\Volumes_uitw.KWK_NZV.xlsx'

df_dict=pd.read_excel(f, sheet_name=['Data'], header=[0,1,2,3])
df = pd.concat(df_dict.values(), axis=0)
colname=[]
for col in df.columns:
    colname.append(col)
#print(colname)

#df=df.loc[mask]
t=pd.to_datetime(df['CET/CEST']['Unnamed: 0_level_1']['Unnamed: 0_level_2']['Unnamed: 0_level_3'],format='%d-%m-%Y %H:%S')
#print(t.agg(['max']))

#print(t)

# %%
xy_cle=[208467,603027]
xy_noord=[234413,605790]
xy_spijk=[253803,604032]
xy_drie=[257449,594676]

# %%
#selecting the data from the multicol
c=df['R.J. Cleveringsluizen']['KSL011 - KWK']['Volume m3/dag']['Bewerkingen']
n=df['Noordpolderzijl']['KGM014 - KWK']['Volume m3/dag']['Bewerkingen']
s=df['Spijksterpompen']['KGM015 - KWK']['Volume m3/dag']['Bewerkingen']
d=df['De Drie Delfzijlen\n(excl. spuien)']['KGM046 - KWK']['Volume m3/dag']['Bewerkingen']

cl = pd.DataFrame(columns=["datum", "numeriekewaarde"])
no = pd.DataFrame(columns=["datum", "numeriekewaarde"])
sp = pd.DataFrame(columns=["datum", "numeriekewaarde"])
dr = pd.DataFrame(columns=["datum", "numeriekewaarde"])
for i in range (len(t)):
    cl.loc[len(cl)] = [t[i], c[i]]
    no.loc[len(no)] = [t[i], n[i]]
    sp.loc[len(sp)] = [t[i], s[i]]
    dr.loc[len(dr)] = [t[i], d[i]]

# %%

#dropping nan values from all df
#cl.dropna(subset=[1],inplace=True)
#no.dropna(subset=[1],inplace=True)
#sp.dropna(subset=[1],inplace=True)
#dr.dropna(subset=[1],inplace=True)

cl = cl.join(pd.DataFrame(
    {
        'locatie.origineel': 'R.J. Cleveringsluizen',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/dag',
        'longitude': xy_cle[0],
        'latitude':xy_cle[1],
        'locatie.naam':'R.J. Cleveringsluizen',
        'gebied':'Noorderzijlvest'
    }, index=cl.index
))

no = no.join(pd.DataFrame(
    {
        'locatie.origineel': 'Noordpolderzijl',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/dag',
        'longitude': xy_noord[0],
        'latitude':xy_noord[1],
        'locatie.naam':'Noordpolderzijl',
        'gebied':'Noorderzijlvest'
    }, index=no.index
))

sp = sp.join(pd.DataFrame(
    {
        'locatie.origineel': 'Spijksterpompen',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/dag',
        'longitude': xy_spijk[0],
        'latitude':xy_spijk[1],
        'locatie.naam':'Spijksterpompen',
        'gebied':'Noorderzijlvest'
    }, index=sp.index
))

dr = dr.join(pd.DataFrame(
    {
        'locatie.origineel': 'De Drie Delfzijlen (excl. spuien)',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/dag',
        'longitude': xy_drie[0],
        'latitude':xy_drie[1],
        'locatie.naam':'De Drie Delfzijlen (excl. spuien)',
        'gebied':'Noorderzijlvest'
    }, index=dr.index
))
# %%

all=pd.concat([cl, no ,sp, dr])
print(all['datum'].agg('max'))
all.to_csv(r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\Noorderzijlvest\standard\Volumes_uitw.KWK_NZV_edit.csv', sep=' ', index=False)