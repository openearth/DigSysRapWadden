#%%
import pandas as pd
from pathlib import Path

path = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026'

selected_stations = pd.read_csv(r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026\selected_stations.csv')
station = selected_stations['CODE'].drop_duplicates()

output_columns = [ 'time',
                      'HL', 
                      'numerieke.waarde', 
                      'locatie.naam']
cols_tokeep = ['time', 
                'Meetwaarde.Waarde_Numeriek', 
                'Naam',
                'locatie.naam']
dfs = []
for s in station:
    s_name = s.replace('.', '_')
    pathn = Path(path) / f'{s_name}_WATHTE_meting_GETETM2.csv'
    if pathn.exists():
        df = pd.read_csv(pathn)
        df['locatie.naam'] = s
        df['time'] = pd.to_datetime(df['time'])
        df = df[cols_tokeep]
        # df = df.rename(columns={'tijdstip': 'time', 'hoogwaterstand': 'HL', 'waarde': 'numerieke.waarde'})
        dfs.append(df)
    else:
        print(f'File not found for station: {s}, calculating High and low water levels')
        pathn = Path(path) / f'{s_name}_WATHTE_meting_TIMESERIES.csv'

# %%
