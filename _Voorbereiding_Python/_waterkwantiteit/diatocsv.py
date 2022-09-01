#save dia to csv
#nathalie dees

import pandas as pd
import datetime as dt #of date
import hatyan
import numpy as np
import os

dir = "P:\\11202493--systeemrap-grevelingen\\1_data\\Wadden\\RWS\\waterhoogtelevering\\levering_overigestations\\" 
save = 'C:\\projecten\\rws\\2022\\scripts\\'

# iterating over all files
for files in os.listdir(dir):
    if files.endswith('.dia'): #search for files in folder with the dia extension
        diablocks_pd = hatyan.get_diablocks(dir + files)
        stat_code = diablocks_pd['station'].unique()[0] #this assumes there is only one station in the file, since it uses the first unique station
        data = hatyan.readts_dia(filename=dir +files, station=stat_code, block_ids="allstation", get_status = True)

        data = data.reset_index(drop=False) # tijd index als kolom maken
        new_name = files.replace (".dia", ".csv") #change extension

        data.to_csv(dir + new_name, sep=';') #edit to save as csv
    else:
        continue
