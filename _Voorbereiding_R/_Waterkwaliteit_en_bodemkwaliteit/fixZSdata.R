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
#   distinct(loccod, loc_xcrdgs, loc_ycrdgs )
#   select(parcod, paroms, cpmoms, ehdcod, hdhcod, loccod, locoms, rks_xcrdgs, rks_ycrdgs, refvlk, bemhgt, datum, tijd, waarde, kwlcod) %>% str()
# 
# read_delim(file.path(datadir, "RWS/zwevendstoflevering/Zwevend Stof.csv"), delim = ";",  
#            guess_max = 10000, na = c("-999999999", "999999999999"), locale = locale(decimal_mark = ",")) %>% 
#   select(parcod, paroms, cpmoms, ehdcod, hdhcod, loccod, locoms, rks_xcrdgs, rks_ycrdgs, refvlk, bemhgt, datum, tijd, waarde, kwlcod) %>% str()
# 

ZSdf <-
  map(ZSfiles, 
            function(x) {
              read_delim(x, delim = ";", guess_max = 10000, na = c("-999999999", "999999999999"), locale = locale(decimal_mark = ",")) %>% 
                dplyr::select(parcod, paroms, cpmcod, ehdcod, hdhcod, loccod, locoms, crdtyp, rks_xcrdgs, rks_ycrdgs, refvlk, bemhgt, datum, tijd, waarde, kwlcod)
            }
) %>%
  filter(kwlcod == 0) %>% # alleen metingen met kwaliteitscode 0 of "00"
  bind_rows() %>%
  dplyr::group_split(crdtyp)
names(ZSdf) <- map(ZSdf, function(x) unique(x$crdtyp))

# transform locations

# convert E50 (dms) to decimal coordinates function
dms2dec <- function(dms) {
  deg <- substr(dms,1,2)
  min <- substr(dms,3,4)
  sec <- substr(dms,5,8)
  
  dec <- as.numeric(deg) + (as.numeric(min) / 60) + (as.numeric(sec) / 360000)
  return(dec)
}  # end dms2dec function


ZSdf.E50 <- ZSdf$E50 %>% 
  mutate(rks_xcrdgs = str_pad(as.character(rks_xcrdgs), width = 8, side = "left", pad = "0")) %>% 
  mutate(rks_ycrdgs = str_pad(as.character(rks_ycrdgs), width = 8, side = "left", pad = "0")) %>%
  mutate(x = dms2dec(rks_xcrdgs)) %>%
  mutate(y = dms2dec(rks_ycrdgs)) %>%
  select( -rks_xcrdgs, -rks_ycrdgs, -crdtyp) %>%
  mutate(coordinatenstelsel = "4326")

ZSdf.RD <- ZSdf$RD %>%
  mutate(rks_xcrdgs = rks_xcrdgs/100, rks_ycrdgs = rks_ycrdgs/100) %>%
  sf::st_as_sf(coords = c("rks_xcrdgs", "rks_ycrdgs"), crs = 28992) %>% 
  sf::st_transform(4326) %>%                                                # transformatie naar WGS84
  mutate(x = unlist(map(.$geometry,1)),
         y = unlist(map(.$geometry,2))) %>%
  sf::st_drop_geometry() %>%
  select(-crdtyp) %>%
  mutate(coordinatenstelsel = "4326")

ZSdf.WGS <- ZSdf$W84 %>%
  mutate(rks_xcrdgs = str_pad(as.character(rks_xcrdgs), width = 8, side = "left", pad = "0")) %>% 
  mutate(rks_ycrdgs = str_pad(as.character(rks_ycrdgs), width = 8, side = "left", pad = "0")) %>%
  mutate(x = dms2dec(rks_xcrdgs)) %>%
  mutate(y = dms2dec(rks_ycrdgs)) %>%
  select( -rks_xcrdgs, -rks_ycrdgs, -crdtyp) %>%
  mutate(coordinatenstelsel = "4326")

ZSdf.all <- bind_rows(ZSdf.E50, ZSdf.RD, ZSdf.WGS) %>%
mutate(
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
    geometriepunt.x = x,
    geometriepunt.y = y,
    coordinatenstelsel,
    bemonsteringshoogte = bemhgt,
    referentievlak = refvlk,
    kwaliteitswaarde.code = kwlcod,
    tijdstip,
    numeriekewaarde = waarde
  )

ZSdf.all %>% distinct(locatie.naam, geometriepunt.x, geometriepunt.y) %>%
leaflet() %>%
  leaflet::addTiles(group = "OSM") %>%
  leaflet::addCircleMarkers(
    lng = ~geometriepunt.x, 
    lat = ~geometriepunt.y,
    label = ~htmltools::htmlEscape(paste0(locatie.naam)), group = "all_locations", radius = 4)
  

dir.create(file.path(datadir, "RWS", "standard"))
write_delim(ZSdf.all, file.path(datadir, "RWS", "standard", "ZS_all.csv"), delim = ";")

