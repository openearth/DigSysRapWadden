# %%
#debieten P:\11202493--systeemrap-grevelingen\1_data\Wadden\NLWKN\afvoeren\standard
#bewerking om op te slaan in database
import configparser
from sqlalchemy import create_engine, MetaData
import pandas as pd
import os

#make connection to db 
cf = configparser.ConfigParser()

online=r'C:\projecten\rws\2022\zoetwaterdebiet\connection_online.txt'
local=r'C:\projecten\rws\2022\scripts\_waterkwantiteit\connection_local.txt'
cf.read(online)

host = cf.get('Postgis', 'host')

connstr = 'postgresql+psycopg2://'+cf.get('Postgis','user')+':'+cf.get('Postgis','pass')+'@'+cf.get('Postgis','host')+'/'+cf.get('Postgis','db')
engine = create_engine(connstr,echo=True)

print(engine)

# %%
#read friesland file
path=r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\Noorderzijlvest\standard\Volumes_uitw.KWK_NZV_edit.csv'

""" ----- inlezen van csv in een dataframe""" 
df = pd.read_csv(path, delimiter=' ', low_memory=False)

""" ----- converteren van dataframe naar database """ 
aschema = 'zoetwaterafvoeren'
df.to_sql('noorderzijlvest', engine,schema=aschema,if_exists='replace')

""" ----- aanmaken colom met geometrie (in dit geval gebaseerd op lat lon coordinaten, check dit in de csv, welke EPSG/CRS dit is """ 
strSql = """alter table {s}.noorderzijlvest add geom geometry(POINT,28992)""".format(s=aschema)  # RD_new (28992)
engine.execute(strSql)

""" ----- vullen van de kolom, gebaseerd op de velden lon en lat """ 
strSql = """update {s}.noorderzijlvest set geom = st_setsrid(st_point(longitude,latitude),28992)""".format(s=aschema)
engine.execute(strSql)



# %%
#read friesland file
path=r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\Wetterskip\standard\friesland_debieten.csv'

""" ----- inlezen van csv in een dataframe""" 
df = pd.read_csv(path, delimiter=' ', low_memory=False)

""" ----- converteren van dataframe naar database """ 
aschema = 'zoetwaterafvoeren'
df.to_sql('friesland', engine,schema=aschema,if_exists='replace')

""" ----- aanmaken colom met geometrie (in dit geval gebaseerd op lat lon coordinaten, check dit in de csv, welke EPSG/CRS dit is """ 
strSql = """alter table {s}.friesland add geom geometry(POINT,28992)""".format(s=aschema)  # RD_new (28992)
engine.execute(strSql)

""" ----- vullen van de kolom, gebaseerd op de velden lon en lat """ 
strSql = """update {s}.friesland set geom = st_setsrid(st_point(longitude,latitude),28992)""".format(s=aschema)
engine.execute(strSql)

# %%
#duitse debieten naar db
dir=r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\NLWKN\afvoeren\standard'

    # iterating over all files
for files in os.listdir(dir):
    if files.endswith('.csv'): #search for files in folder with the csv extension
        df = pd.read_csv(os.path.join(dir, files), delimiter=' ', low_memory=False)
        f = os.path.join(dir, files)
        name=os.path.splitext(files)[0]
        name=name.replace('-','_')
        name=name.lower()

        df.to_sql(name, engine,schema=aschema,if_exists='replace')

        strSql = """alter table {s}.{t} add geom geometry(POINT,4326)""".format(s=aschema, t=name)  # RD_new (28992)
        engine.execute(strSql)

        strSql = """update {s}.{t} set geom = st_setsrid(st_point(longitude,latitude),4326)""".format(s=aschema, t=name)
        engine.execute(strSql)