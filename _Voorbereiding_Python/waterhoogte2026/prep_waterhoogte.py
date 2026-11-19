#%%
import pandas as pd
from pathlib import Path
import hatyan

#%%
path = r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026'

selected_stations = pd.read_csv(r'C:\projecten\DigSysRapWadden\_Voorbereiding_Python\waterhoogte2026\selected_stations.csv')
station = selected_stations['CODE'].drop_duplicates()

output_columns = [ 'time',
                      'HL', 
                      'numerieke.waarde', 
                      'locatie.naam',
                      'Lat',
                      'Lon']
cols_tokeep = ['time', 
                'Meetwaarde.Waarde_Numeriek', 
                'Naam',
                'locatie.naam',
                'Lat',
                'Lon']
dfs = []
station_metadata = []  # Track GETETM2 presence and measurement dates

#%%
for s in station:
    s_name = s.replace('.', '_')
    pathn = Path(path) / f'{s_name}_WATHTE_meting_GETETM2.csv'
    if pathn.exists():
        df = pd.read_csv(pathn)
        df['locatie.naam'] = s
        df['time'] = pd.to_datetime(df['time'])
        df = df[cols_tokeep]
        df['HL'] = df['Meetwaarde.Waarde_Numeriek'].apply(
            lambda value: 'L' if value < 0 else 'H' if value > 0 else pd.NA
        )
        df = df.rename(columns={'Meetwaarde.Waarde_Numeriek': 'h'})
        df = df[['time', 'HL', 'h', 'Naam', 'locatie.naam', 'Lat', 'Lon']]
        # df = df.rename(columns={'tijdstip': 'time', 'hoogwaterstand': 'HL', 'waarde': 'numerieke.waarde'})
        dfs.append(df)
        # Add metadata for GETETM2
        station_metadata.append({
            'station': s,
            'has_GETETM2': 'yes',
            'measurement_start': df['time'].min(),
            'measurement_end': df['time'].max()
        })
    else:
        print(f'File not found for station: {s}, calculating High and low water levels')
        pathn = Path(path) / f'{s_name}_WATHTE_meting_TIMESERIES.csv'
        if pathn.exists():
            df = pd.read_csv(pathn)
            df['locatie.naam'] = s
            df['time'] = pd.to_datetime(df['time'])
            df = df[cols_tokeep]
            df = df.sort_values("time").copy()
            df = df.rename(columns={'Meetwaarde.Waarde_Numeriek': 'h'})
            # Require at least four hours between detected peaks.

            ts = (
                df
                .loc[:, ["time", "h"]]
                .rename(columns={"h": "values", "time": "tijdstip"})
                .assign(tijdstip=lambda x: pd.to_datetime(x["tijdstip"]))
                .set_index("tijdstip")
                .sort_index()
            )

            # Optional metadata
            # Use "cm" if numeriekewaarde is in centimetres
            ts.attrs["eenheid"] = "cm"

            # Detect high and low waters
            extrema = hatyan.calc_HWLW(
                ts,
                calc_HWLW345=False,
                buffer_hr=6
            )

            print(extrema)

            extrema['HL'] = extrema['HWLWcode'].apply(
                        lambda value: 'L' if value == 2 else 'H' if value == 1 else pd.NA
                    )

            # Give calculated extrema the same columns and order as GETETM2 data.
            extrema = extrema.rename(columns={'values': 'h'}).rename_axis('time').reset_index()
            for column in ['Naam', 'locatie.naam', 'Lat', 'Lon']:
                extrema[column] = df[column].iloc[0]
            extrema = extrema[['time', 'HL', 'h', 'Naam', 'locatie.naam', 'Lat', 'Lon']]

        #     print(tides)
            dfs.append(extrema)
        #     # Add metadata for TIMESERIES (no GETETM2)
        #     station_metadata.append({
        #         'station': s,
        #         'has_GETETM2': 'no',
        #         'measurement_start': tides['time'].min(),
        #         'measurement_end': tides['time'].max()
        #     })
        # else:
        #     print(f'File not found for station: {s}, skipping')
        #     # Add metadata for skipped station
        #     station_metadata.append({
        #         'station': s,
        #         'has_GETETM2': 'no',
        #         'measurement_start': pd.NaT,
        #         'measurement_end': pd.NaT
        #     })
        #     continue
#%%
# dfx = pd.concat(dfs, ignore_index=True)
# dfx.to_csv(r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026\extremaHLL_latest.csv', index=False)
# # dfx.plot(x='time', y='h', kind='line', title=f'Tides for station {s}')

# # Create metadata dataframe
# df_metadata = pd.DataFrame(station_metadata)
# df_metadata.to_csv(r'P:\11202493--systeemrap-grevelingen\1_data\Wadden\ddl\raw\waterhoogte2026\station_metadata.csv', index=False)
# print("\nStation Metadata:")
# print(df_metadata)

# %%
