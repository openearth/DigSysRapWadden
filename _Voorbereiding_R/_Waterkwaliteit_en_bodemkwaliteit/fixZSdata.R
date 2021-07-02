# fix ZS concentrations
# ZS is currently (June 2021) no in DDL
# data were requested from the servicedesk data (RWS)
# obtained as tabular file
# though in different format (DONAR)
# This scripts reads the file and converts a minimu set of fields to AQUO
# 

require(tidyverse)
require(lubridate)

source("r/runThisFirst.R")

# [1] "kannum"     "wnsnum"     "parcod"     "paroms"     "casnum"     "staind"     "cpmcod"     "cpmoms"     "domein"    
# [10] "ehdcod"     "hdhcod"     "hdhoms"     "orgcod"     "orgoms"     "sgkcod"     "1.klscod"   "1.klsoms"   "2.klscod"  
# [19] "2.klsoms"   "3.klscod"   "3.klsoms"   "muxcod"     "muxoms"     "btccod"     "btlcod"     "btxoms"     "btnnam"    
# [28] "ivscod"     "ivsoms"     "anicod"     "anioms"     "bhicod"     "bhioms"     "bmicod"     "bmioms"     "ogicod"    
# [37] "ogioms"     "gbdcod"     "gbdoms"     "loccod"     "locoms"     "locsrt"     "crdtyp"     "loc_xcrdgs" "loc_ycrdgs"
# [46] "ghoekg"     "rhoekg"     "metrng"     "straal"     "xcrdmp"     "ycrdmp"     "omloop"     "anacod"     "anaoms"    
# [55] "bemcod"     "bemoms"     "bewcod"     "bewoms"     "vatcod"     "vatoms"     "rkstyp"     "refvlk"     "bemhgt"    
# [64] "rks_xcrdgs" "rks_ycrdgs" "vakstp"     "tydehd"     "tydstp"     "rks_begdat" "rks_begtyd" "rks_enddat" "rks_endtyd"
# [73] "syscod"     "beginv"     "endinv"     "vzmcod"     "vzmoms"     "svzcod"     "svzoms"     "ssvcod"     "ssvoms"    
# [82] "ssscod"     "sssoms"     "xcrdwb"     "ycrdzb"     "xcrdob"     "ycrdnb"     "xcrdmn"     "ycrdmn"     "xcrdmx"    
# [91] "ycrdmx"     "datum"      "tijd"       "bpgcod"     "waarde"     "kwlcod"     "rkssta" 

ZSfiles <- list.files(file.path(datadir, "RWS/zwevendstoflevering"), pattern = ".csv", full.names = T)

select <- dplyr::select

# test
# read_delim(file.path(datadir, "RWS/zwevendstoflevering/ROTTMPT3 EN TERSLG10.csv"), delim = ";", 
#            guess_max = 10000, na = c("-999999999", "999999999999"), locale = locale(decimal_mark = ",")) %>% 
#   select(parcod, paroms, cpmoms, ehdcod, hdhcod, loccod, locoms, rks_xcrdgs, rks_ycrdgs, refvlk, bemhgt, datum, tijd, waarde, kwlcod) %>% str()
# 
# read_delim(file.path(datadir, "RWS/zwevendstoflevering/Zwevend Stof.csv"), delim = ";",  
#            guess_max = 10000, na = c("-999999999", "999999999999"), locale = locale(decimal_mark = ",")) %>% 
#   select(parcod, paroms, cpmoms, ehdcod, hdhcod, loccod, locoms, rks_xcrdgs, rks_ycrdgs, refvlk, bemhgt, datum, tijd, waarde, kwlcod) %>% str()
# 

ZSdf <- map(ZSfiles, 
            function(x) {
              read_delim(x, delim = ";", guess_max = 10000, na = c("-999999999", "999999999999"), locale = locale(decimal_mark = ",")) %>% 
                dplyr::select(parcod, paroms, cpmcod, ehdcod, hdhcod, loccod, locoms, rks_xcrdgs, rks_ycrdgs, refvlk, bemhgt, datum, tijd, waarde, kwlcod)
            }
) %>%
  bind_rows() %>%
mutate(
  coordinatenstelsel = 28992,
  compartiment.code = case_when(
    cpmcod ==10 ~ "OW"
  ),
  grootheid.code = "CONCTTE",
  datum = as.Date(datum, format = "%d %m %Y"),
  tijdstip = lubridate::ymd(datum) + lubridate::hms(tijd)
  ) %>% 
  select(
    locatie.code = loccod,
    locatie.naam = locoms,
    compartiment.code,
    grootheid.code,
    parameter.code = parcod, 
    parameter.omschrijving = paroms, 
    eenheid.code = ehdcod,
    geometriepunt.x = rks_xcrdgs,
    geometriepunt.y = rks_ycrdgs,
    coordinatenstelsel,
    bemonsteringshoogte = bemhgt,
    referentievlak = refvlk,
    kwaliteitswaarde.code = kwlcod,
    tijdstip,
    numeriekewaarde = waarde
  )

dir.create(file.path(datadir, "RWS", "standard"))
write_delim(ZSdf, file.path(datadir, "RWS", "standard", "ZS_all.csv"), delim = ";")

