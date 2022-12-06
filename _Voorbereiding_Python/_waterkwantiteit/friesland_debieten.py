#read in friesland debieten
#debieten zijn miljoen m3 per etmaal, worden omgerekend naar m3 per seconde
#processing to dataformat of eems
# %%
from datetime import date
import pandas as pd
import numpy as np

debieten = pd.read_excel("C:\\projecten\\rws\\2022\zoetwaterdebiet\\Debieten_friesland.xlsx", header=2)
debieten['Datum']=pd.to_datetime(debieten['Datum'], format='%Y-%m-%d')

#replace ----- with zeros as they are no measurements
debieten=debieten.replace('-----', np.NaN)
debieten=debieten.dropna()

xy_harlingen=[157210,576940]
xy_ropta=[158487,580303]
xy_hgmiedema=[170898,591438]

debieten['Harlingen']=1000000*debieten['Harlingen']
debieten[ 'Ropta']=1000000*debieten['Ropta']
debieten['H.G. Miedema']=1000000*debieten['H.G. Miedema']

#make new df and drop nans
h=debieten[['Datum', 'Harlingen']].copy().dropna()
r=debieten[['Datum', 'Ropta']].copy().dropna()
m=debieten[['Datum', 'H.G. Miedema']].copy().dropna()
"""
datum locatie.origineel numeriekewaarde waardebewerkingsmethode.omschrijving grootheid.omschrijving grootheid.code eenheid.code longitude latitude locatie.naam gebied
"""

h = h.join(pd.DataFrame(
    {
        'locatie.origineel': 'Harlingen',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/dag',
        'longitude': xy_harlingen[0],
        'latitude':xy_harlingen[1],
        'locatie.naam':'Harlingen',
        'gebied':'Friesland'
    }, index=h.index
))

h.columns = h.columns.str.replace('Harlingen','numeriekewaarde')
h.columns = h.columns.str.replace('Datum','datum')

r = r.join(pd.DataFrame(
    {
        'locatie.origineel': 'Ropta',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/dag',
        'longitude': xy_ropta[0],
        'latitude':xy_ropta[1],
        'locatie.naam':'Ropta',
        'gebied':'Friesland'
    }, index=r.index
))

r.columns = r.columns.str.replace('Ropta','numeriekewaarde')
r.columns = r.columns.str.replace('Datum','datum')

m = m.join(pd.DataFrame(
    {
        'locatie.origineel': 'H.G. Miedema',
        'waardebewerkingsmethode.omschrijving': 'Etmaalgemiddelde',
        'grootheid.omschrijving': 'Debiet',
        'grootheid.code': 'Q', 
        'eenheid.code':'m3/dag',
        'longitude': xy_hgmiedema[0],
        'latitude':xy_hgmiedema[1],
        'locatie.naam':'H.G. Miedema',
        'gebied':'Friesland'
    }, index=m.index
))

m.columns = m.columns.str.replace('H.G. Miedema','numeriekewaarde',regex=True)
m.columns = m.columns.str.replace('Datum','datum')

all=pd.concat([h,r,m])
all=all.sort_values(by='datum')

# %%
all.to_csv(r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\Wetterskip\standard\friesland_debieten.csv', sep=' ', index=False)


# %%
