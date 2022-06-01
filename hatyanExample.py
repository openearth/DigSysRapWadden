
import datetime as dt
import pandas as pd
import hatyan
hatyan.close('all')

file_data = r"p:\11202493--systeemrap-grevelingen\1_data\Wadden\RWS\hoogLaagWaters\gem_extr.dia"
test = hatyan.readts_dia(filename=file_data, station="DENHDR", block_ids="allstation")

