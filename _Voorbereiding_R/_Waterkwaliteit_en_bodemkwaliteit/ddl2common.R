source("runThisFirst.R")

require(tidyverse)
select <- dplyr:select

# verwerking eutrofieringsdata
  
filenamesRaw = list.files(file.path(datadir, "ddl/raw/eutro"), full.names = T, recursive = T)
allFiles <- lapply(filenamesRaw, function(x) read_delim(x, delim = ";", guess_max = 10000,
                                                        col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
df_all <- bind_rows(allFiles)
rm(allFiles)
df_all$tijdstip <- lubridate::as_datetime(as.character(df_all$tijdstip))
df_all$numeriekewaarde[df_all$numeriekewaarde == 999999999999] <- NA
df_all$numeriekewaarde[df_all$numeriekewaarde == 999999999] <- NA
# check for duplicates - should be zero, but is usually not. Leave out duplicate measurements
df_all  %>% duplicated() %>% which() %>% length()
# df_all[duplicated(df_all),] %>% distinct(grootheid.code, parameter.code)
which(duplicated(filenamesRaw)) # no duplicates in filelist, so duplicates occur within each file
df_all <- df_all[!duplicated(df_all),]
write_delim(df_all, path = file.path(datadir, "ddl/standard/", paste0(today(), 'all_ddl_ow.csv')), delim = ";")



#=== Eutrophication parameters to separate file ================================

name_map <- read.csv2("../1_data/standaardlijsten/overview_waterbase_netcdf_aquo_coupling.csv")
df_eutro <- read_delim(file.path(datadir, "ddl/standard/", paste0(today(), 'all_ddl_ow.csv')), delim = ";", guess_max = 100000) %>%
  filter(grootheid.code %in% name_map$aquo_grootheid & parameter.code %in% name_map$aquo_parameter)
# df_eutro %>% distinct(grootheid.code, parameter.code, hoedanigheid.code, eenheid.code)
df_eutro$tijdstip <- lubridate::as_datetime(as.character(df_eutro$tijdstip))
df_eutro$numeriekewaarde[df_eutro$numeriekewaarde == 999999999999] <- NA
write_delim(df_eutro, path = file.path(datadir, "ddl/standard/", paste0(today(), 'eutro_ddl_ow.csv')), delim = ";")

# make general for all types of data
# location_map <- eutroCatalogue %>% select(Code, Naam) %>% distinct()

df_eutro2 <- df_eutro %>%
  left_join(name_map, by = c(
    grootheid.code = "aquo_grootheid",
    parameter.code = "aquo_parameter",
    hoedanigheid.code = "aquo_hoedanigheid"
  )) %>% 
  dplyr::select(
    locatie = locatie.naam, 
    EPSG = coordinatenstelsel,
    x.long = geometriepunt.x,
    y.lat = geometriepunt.y,
    datumtijd = tijdstip,
    grootheid.code,
    parameter.code,
    short,
    unit = eenheid.code,
    waarde = numeriekewaarde,
    referentievlak,
    bemonsteringshoogte
  ) %>% 
  unite(param, short, unit) %>%
  ### nog niet uitvoeren, eerst dieptes ophalen uit DDL
  group_by(locatie, param, datumtijd, EPSG, x.long, y.lat, referentievlak, bemonsteringshoogte) %>%
  summarize(gemwaarde = mean(waarde), n = n(), sd = sd(waarde, na.rm = T)) %>%
  spread(key = param, value = gemwaarde) %>%
  mutate(`DIN_mg/l` = `NO2_mg/l` + `NO3_mg/l` + `NH4_mg/l`) %>%
  mutate(
    DINDIP_DMSLS = `DIN_mg/l`/`PO4_mg/l`,
    DINSi_DMSLS = `DIN_mg/l`/`SiO2_mg/l`,
    DIPSi_DMSLS = `PO4_mg/l`/`SiO2_mg/l`
  ) %>%
  ungroup() %>% 
  # mutate(datumtijd = as.POSIXct(paste(datum, tijd), format = "%Y-%m-%d %H:%M")) %>% 
  dplyr::select(-n, -sd) %>%
  gather(key = parameter, value = waarde, -locatie, -datumtijd, -EPSG, -x.long, -y.lat, -referentievlak, -bemonsteringshoogte) %>%
  filter(!is.na(waarde)) %>%
  mutate(parameter = replace(parameter, parameter == 'E_DIMSLS', 'E_/m')) %>%
  mutate(
    jaar = lubridate::year(datumtijd),
    maand = lubridate::month(datumtijd),
    winterjaar = case_when(
      maand %in% summermonths ~ jaar,
      maand %in% wintermonths & maand <= 6 ~ jaar,
      maand %in% wintermonths & maand > 6 ~ jaar + 1
    ),
    seizoen = ifelse(
      maand %in% summermonths, "zomer", "winter"
    )
  )

write_delim(df_eutro2, path = file.path(datadir, "ddl/standard/", paste0(today(), 'eutro_short_ddl_ow.csv')), delim = ";")


#==== metalen ===================

source("runThisFirst.R")
require(tidyverse)

filenamesOW = list.files(file.path(datadir, "ddl/raw/metalen"), full.names = T)
OWFiles <- lapply(filenamesOW, function(x) read_delim(x, delim = ";", guess_max = 10000,
                                                      col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
df_all_metalen <- bind_rows(OWFiles)
rm(OWFiles)

df_all_metalen$tijdstip <- lubridate::as_datetime(as.character(df_all_metalen$tijdstip))
df_all_metalen$numeriekewaarde[df_all_metalen$numeriekewaarde == 999999999999] <- NA
df_all_metalen$numeriekewaarde[df_all_metalen$numeriekewaarde == 999999999] <- NA
# check for duplicates - should be zero, but is usually not. Leave out duplicate measurements
df_all_metalen  %>% duplicated() %>% which() %>% length()
df_all_metalen[duplicated(df_all_metalen),] %>% distinct(grootheid.code, parameter.code)
which(duplicated(filenamesOW)) # no duplicates in filelist, so duplicates occur within each file
df_all_metalen <- df_all_metalen[!duplicated(df_all_metalen),]
dir.create(file.path(datadir, "ddl/standard/"))
write_delim(df_all_metalen, path = file.path(datadir, "ddl/standard/", paste0(today(), 'all_ddl_metalen.csv')), delim = ";")

df_all_metalen %>% 
  group_by(locatie.code, bemonsteringshoogte, referentievlak, compartiment.code, 
           grootheid.code, parameter.code, hoedanigheid.code) %>% 
  summarize(begin = min(tijdstip), eind = max(tijdstip)) %>% 
  write_delim(file.path(datadir, "ddl/metadata/", paste0(today(), 'overzicht_metalen.csv')), delim = ";")



#==== contaminanten ===================

source("runThisFirst.R")
require(tidyverse)

filenamesOW = list.files(file.path(datadir, "ddl/raw/contaminanten"), full.names = T)
OWFiles <- lapply(filenamesOW, function(x) read_delim(x, delim = ";", guess_max = 10000,
                                                      col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
df_all_contam <- bind_rows(OWFiles)
rm(OWFiles)

df_all_contam$tijdstip <- lubridate::as_datetime(as.character(df_all_contam$tijdstip))
df_all_contam$numeriekewaarde[df_all_contam$numeriekewaarde == 999999999999] <- NA
df_all_contam$numeriekewaarde[df_all_contam$numeriekewaarde == 999999999] <- NA
# check for duplicates - should be zero, but is usually not. Leave out duplicate measurements
df_all_contam  %>% duplicated() %>% which() %>% length()
df_all_contam[duplicated(df_all_contam),] %>% distinct(grootheid.code, parameter.code)
which(duplicated(filenamesOW)) # no duplicates in filelist, so duplicates occur within each file
df_all_contam <- df_all_contam[!duplicated(df_all_contam),]
dir.create(file.path(datadir, "ddl/standard/"))
write_delim(df_all_contam, path = file.path(datadir, "ddl/standard/", paste0(today(), 'all_ddl_contaminanten.csv')), delim = ";")

df_all_contam %>% 
  group_by(locatie.code, bemonsteringshoogte, referentievlak, compartiment.code, 
           grootheid.code, biotaxon.code, parameter.omschrijving, hoedanigheid.code) %>% 
  summarize(begin = min(tijdstip), eind = max(tijdstip)) %>% 
  write_delim(file.path(datadir, "ddl/metadata/", paste0(today(), 'overzicht_contaminanten.csv')), delim = ";")


