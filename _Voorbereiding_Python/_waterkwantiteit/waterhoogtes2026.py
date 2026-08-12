# %%
import pandas as pd
from pathlib import Path
import os

path = Path.cwd()
stations = pd.read_csv(os.path.join(path, "waddenzee_waterhoogtegemeten.csv"), sep=",")

uniques = stations[['locatie_naam', 'locatie_code']].drop_duplicates()  
uniques.to_csv(os.path.join(path, "waddenzee_waterhoogtegemeten_uniek.csv"), index=False)