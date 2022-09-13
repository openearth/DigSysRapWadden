# %%
#import data from het xlsx of noorderzijlvest to db
#prefer to make it the format that Willem wants
import pandas as pd
import datetime

f = r'C:\projecten\rws\2022\zoetwaterdebiet\Volumes_uitw.KWK_NZV.xlsx'

df_dict=pd.read_excel(f, sheet_name=['Data'], header=[0,1,2,3])
df = pd.concat(df_dict.values(), axis=0)

# %%
colname=[]
for col in df.columns:
    colname.append(col)

# %%

time=df['CET/CEST']['Unnamed: 0_level_1']['Unnamed: 0_level_2']['Unnamed: 0_level_3']
time=pd.to_datetime(time)

# %%
time -= datetime.timedelta(days=1) #add one day (read the excel file for why)

#time.columns = time.columns.str.replace('Unnamed: 0_level_3','datetime') -> when adding data
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

#combining time with values
c=pd.concat([time,c], axis=1, ignore_index=True)
n=pd.concat([time,n], axis=1, ignore_index=True)
s=pd.concat([time,s], axis=1, ignore_index=True)
d=pd.concat([time,d], axis=1, ignore_index=True)
#dropping nan values from all df
c.dropna(subset=[1],inplace=True)
n.dropna(subset=[1],inplace=True)
s.dropna(subset=[1],inplace=True)
d.dropna(subset=[1],inplace=True)
# %%
c = c.join(pd.DataFrame(
    {
        'locatie.origineel': 'R.J. Cleveringsluizen',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/s',
        'longitude': xy_cle[0],
        'latitude':xy_cle[1],
        'locatie.naam':'R.J. Cleveringsluizen',
        'gebied':'Noorderzijlvest'
    }, index=c.index
))

c=c.rename({0: 'datum', 1: 'numeriekewaarde'}, axis=1)

n = n.join(pd.DataFrame(
    {
        'locatie.origineel': 'Noordpolderzijl',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/s',
        'longitude': xy_noord[0],
        'latitude':xy_noord[1],
        'locatie.naam':'Noordpolderzijl',
        'gebied':'Noorderzijlvest'
    }, index=n.index
))

n=n.rename({0: 'datum', 1: 'numeriekewaarde'}, axis=1)

s = s.join(pd.DataFrame(
    {
        'locatie.origineel': 'Spijksterpompen',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/s',
        'longitude': xy_spijk[0],
        'latitude':xy_spijk[1],
        'locatie.naam':'Spijksterpompen',
        'gebied':'Noorderzijlvest'
    }, index=s.index
))

s=s.rename({0: 'datum', 1: 'numeriekewaarde'}, axis=1)

d = d.join(pd.DataFrame(
    {
        'locatie.origineel': 'De Drie Delfzijlen (excl. spuien)',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/s',
        'longitude': xy_drie[0],
        'latitude':xy_drie[1],
        'locatie.naam':'De Drie Delfzijlen (excl. spuien)',
        'gebied':'Noorderzijlvest'
    }, index=d.index
))

d=d.rename({0: 'datum', 1: 'numeriekewaarde'}, axis=1)

all=pd.concat([c,n,s,d])
all=all.sort_values(by='datum')

all.to_csv(r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\Noorderzijlvest\standard\Volumes_uitw.KWK_NZV.csv', sep=' ', index=False)
