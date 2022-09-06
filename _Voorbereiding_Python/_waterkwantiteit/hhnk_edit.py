# %%
#read in hhnk data and save to desired format
import pandas as pd
import matplotlib.pyplot as plt

# %%
dir='P:\\11202493--systeemrap-grevelingen\\1_data\\Wadden\\HHNK\\raw\\Helsdeur gemaalKGM-Q-29234.csv'

df=pd.read_csv(dir)

df['timeStamp'] =  pd.to_datetime(df['timeStamp'])
#print(type(df['timeStamp'][0]))
print(df.head(5))

#calculating averages
df = df.groupby(by=pd.Grouper(freq='D', key='timeStamp')).mean()

# %%
print(df['qualifier'])
