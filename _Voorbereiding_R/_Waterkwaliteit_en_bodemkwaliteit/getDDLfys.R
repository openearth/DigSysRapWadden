

####===  install packages and dependencies ========
source("r/runThisFirst.R")


mijnCatalogus <- read_delim(file.path(datadir, "ddl/metadata", paste0(mijnGebied, "_metadata.csv")), delim = ";")


# Selection based on requirements for this version. only temp and salinity
# SPM (Zwevend staof) also needed, but missing from DDL at the moment. 
golfCatalogus <- mijnCatalogus  %>%
  filter(
    parameter_wat_omschrijving %in% c(
      "Significante golfhoogte in het spectrale domein Oppervlaktewater golffrequentie tussen 30 en 500 mHz in cm",
      "Significante golfhoogte in het spectrale domein Oppervlaktewater golffrequentie tussen 30 en 1000 mHz in cm",
      "Gemiddelde golfrichting in het spectrale domein Oppervlaktewater golffrequentie tussen 30 en 500 mHz in graad",
      "Golfperiode bepaald uit de spectrale momenten m0 en m2 Oppervlaktewater golffrequentie tussen 30 en 500 mHz in s",
      "Golfperiode bepaald uit de spectrale momenten m0 en m2 Oppervlaktewater golffrequentie tussen 30 en 1000 mHz in s"
    ),
  )

waterhoogteCatalogus <- mijnCatalogus  %>%
  filter(
    parameter_wat_omschrijving %in% c(
      "Waterhoogte Oppervlaktewater t.o.v. Normaal Amsterdams Peil in cm",
      "Waterhoogte berekend Oppervlaktewater t.o.v. Normaal Amsterdams Peil in cm",
      "Berekend Wateropzet Oppervlaktewater cm"
    ),
  )


if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))
if(!dir.exists(file.path(datadir, "ddl/raw/golven"))) dir.create(file.path(datadir, "ddl/raw/golven"))
if(!dir.exists(file.path(datadir, "ddl/raw/waterhoogte"))) dir.create(file.path(datadir, "ddl/raw/waterhoogte"))


# #=== Check data availability for 2016 ======
# #
# startdate <- paste0(2016, "-01-01T09:00:00.000+01:00")  # hardcoded startyear
# enddate <- paste0(2016, "-01-31T23:00:00.000+01:00")
# 
# ophaalCatalogus <- bind_rows(golfCatalogus)
# 
# getList <- rws_makeDDLapiList(beginDatumTijd = startdate,
#                               eindDatumTijd = enddate,
#                               mijnCatalogus = ophaalCatalogus
# )
# 
# for(jj in c(1:length(getList))){   #
#   print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
#   response <- rws_observations2(bodylist = getList[[jj]])
#   if(!is.null(response) & nrow(response$content)!=0){
#     filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), "ddl_wq.csv", sep = "_")
#     write_delim(response$content, file = file.path(datadir, "ddl/raw/golven", filename), delim = ";")} else next
# }
# 
# filenamesRaw = list.files(file.path(datadir, "ddl/raw/golven"), full.names = T, recursive = T)
# allFiles <- lapply(filenamesRaw, function(x) read_delim(x, delim = ";", guess_max = 10000,
#                                                         col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
# df_all <- bind_rows(allFiles)
# 
# df_all %>% group_by(locatie.naam, grootheid.code) %>% summarise(n = n()) %>% View()
# golfLocaties <- df_all %>% distinct(locatie.naam) %>% unlist %>% unname
# 
# #==== waterhoogte voor januari 2016 =========
# 
# ophaalCatalogus <- bind_rows(waterhoogteCatalogus)
# 
# getList <- rws_makeDDLapiList(beginDatumTijd = startdate,
#                               eindDatumTijd = enddate,
#                               mijnCatalogus = ophaalCatalogus
# )
# 
# for(jj in c(1:length(getList))){   #
#   print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
#   response <- rws_observations2(bodylist = getList[[jj]])
#   if(!is.null(response) & nrow(response$content)!=0){
#     filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), "ddl_wq.csv", sep = "_")
#     write_delim(response$content, file = file.path(datadir, "ddl/raw/waterhoogte", filename), delim = ";")} else next
# }
# 
# filenamesRaw = list.files(file.path(datadir, "ddl/raw/waterhoogte"), full.names = T, recursive = T)
# allFiles <- lapply(filenamesRaw, function(x) read_delim(x, delim = ";", guess_max = 10000,
#                                                         col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
# df_all <- bind_rows(allFiles)
# 
# df_all %>% group_by(locatie.naam, grootheid.code) %>% summarise(n = n()) %>% View()
# waterhoogteLocaties <- df_all %>% distinct(locatie.naam) %>% unlist %>% unname


#===  golven ophalen alle jaren ===============================

for(year in c(1870:1970)){
  startdate <- paste0(year, "-01-01T00:00:00.000+01:00")  
  enddate <- paste0(year+1, "-01-01T00:00:00.000+01:00")
  
  ophaalCatalogus <- bind_rows(golfCatalogus) %>% # hardcoded stations
    filter(locatie.naam %in% 
             c("Amelander zeegat, boei 11", "Amelander zeegat, boei 12", "Amelander zeegat, boei 21",
               "Amelander zeegat, boei 22", "Amelander zeegat, boei 31", "Amelander zeegat, boei 32", 
               "Amelander zeegat, boei 41", "Amelander zeegat, boei 42", "Amelander zeegat, boei 51", 
               "Amelander zeegat, boei 52", "Amelander zeegat boei 61", "Amelander zeegat boei 62",
               "Amelander Westgat platform", "Boschgat Zuid", "Eierlandse Gat",
               "Lauwers Oost", "Nes", "Oude Westereems noord boei 1",
               "Oude Westereems zuid boei 1", "Pieterburenwad 1", "Randzelgat noord", 
               "Schiermonnikoog noord", "Schiermonnikoog Westgat", "Stortemelk boei 1", 
               "Stortemelk Oost", "Uithuizerwad 1", "Westereems oost", 
               "Westereems west", "Wierumerwad 1")
    )
  
  getList <- rws_makeDDLapiList(beginDatumTijd = startdate,
                                eindDatumTijd = enddate,
                                mijnCatalogus = ophaalCatalogus
  )
  
  for(jj in c(1:length(getList))){   #
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response) & nrow(response$content)!=0){
      writefile <- response$content %>% select(
        locatie.naam, locatie.code, tijdstip, statuswaarde, kwaliteitswaarde.code, parameter.wat.omschrijving, eenheid.code, hoedanigheid.omschrijving, meetapparaat.omschrijving,
        parameter.code, grootheid.code, numeriekewaarde)
      filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), year, "ddl_wq.csv", sep = "_")
      write_delim(writefile, file = file.path(datadir, "ddl/raw/golven", filename), delim = ";")} else next
  }
}


#==== waterhoogte alle jaren  ===============================

# for(year in c(1991:2021)){ # done
for(year in c(1870:2021)){
  startdate <- paste0(year, "-01-01T00:00:00.000+01:00")  # hardcoded startyear
  enddate <- paste0(year+1, "-01-01T00:00:00.000+01:00")
  
  ophaalCatalogus <- bind_rows(waterhoogteCatalogus) %>%
    filter(locatie.naam %in% 
             c("Delfzijl", "Den Helder", "Eemshaven", "Harlingen", "Holwerd", "Huibertgat", "Lauwersoog",
               "Nes", "Schiermonnikoog", "Terschelling Noordzee", "Texel Noordzee", "Uithuizerwad 1", "West-Terschelling", "Wierumergronden",
               "Wierumerwad 1")
    )
  
  getList <- rws_makeDDLapiList(beginDatumTijd = startdate,
                                eindDatumTijd = enddate,
                                mijnCatalogus = ophaalCatalogus
  )
  
  for(jj in c(1:length(getList))){   #
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response) & nrow(response$content)!=0){
      writefile <- response$content %>% select(
        locatie.naam, locatie.code, tijdstip, statuswaarde, kwaliteitswaarde.code, parameter.wat.omschrijving, eenheid.code, hoedanigheid.omschrijving, meetapparaat.omschrijving,
        parameter.code, grootheid.code, numeriekewaarde
      )
      filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), year, "ddl_wq.csv", sep = "_")
      write_delim(writefile, file = file.path(datadir, "ddl/raw/waterhoogte", filename), delim = ";")} else next
  }
}

#=== golven opwerking =================



#====  golfhoogte ======================
# 1.	95-percentiel van de significante golfhoogte per jaar
# 2.	Aantal stormen (gedefinieerd als Hs> xx m) per jaar
# 3.	Afwijking maandgemiddeld t.o.v. langjarig gemiddelde, als maat voor seizoensdynamiek. Verschillende jaren weergeven als lijnen met kleurverloop (oude jaren blauw en naar heden toe verkleurend naar rood) 


filenamesRawHm0 = list.files(file.path(datadir, "ddl/raw/golven"), full.names = T, recursive = T, pattern = "Hm0")

listData <- lapply(filenamesRawHm0, function(x) 
  read_delim(x, delim = ";", guess_max = 10000,
             # col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn', 
             col_types = 'cccccccccccn',
             na = c("-999999999", "999999e32", "999999999")
  ) %>%
    # select(locatie.naam, locatie.code, tijdstip, statuswaarde, kwaliteitswaarde.code, parameter.wat.omschrijving, eenheid.code, hoedanigheid.omschrijving, meetapparaat.omschrijving,
    #        parameter.code, grootheid.code, numeriekewaarde) %>%
    # drop_na(numeriekewaarde) %>%
    filter(kwaliteitswaarde.code < 50, numeriekewaarde < 10000 & numeriekewaarde >= 0) %>%
    mutate(tijdstip = as_datetime(as.character(tijdstip), tz = "CET")) %>%
    mutate(jaar = year(tijdstip), maand = month(tijdstip), yearly_perc95 = quantile(numeriekewaarde, 0.95, na.rm = T)) %>%
    filter(jaar == median(jaar)) %>% # to filter out first tijdstip in next year
    group_by(ID = data.table::rleid(numeriekewaarde > 200)) %>%
    mutate(`duur in uren` = if_else(numeriekewaarde > 200, row_number(), 0L)) %>% ungroup() %>%
    mutate(aantalstormen = sum(`duur in uren` == 1L)) %>%
    group_by(locatie.naam, locatie.code, parameter.wat.omschrijving, jaar, maand) %>%
    summarize(
      maandgemiddelde = mean(numeriekewaarde, na.rm = T),
      maand95perc = quantile(numeriekewaarde, 0.95, na.rm = T),
      maandmaximum = max(numeriekewaarde, na.rm = T),
      yearly_perc95 = mean(yearly_perc95),
      aantalstormen = mean(aantalstormen)
      )
  )

df_all <- bind_rows(listData)
write_delim(df_all, file.path(datadir, "ddl", "standard", paste0("golven", today(), ".csv")), delim = ";")

#test:
ggplot(df_all, aes(x = (jaar + maand/12))) +
  geom_point(aes(y = aantalstomen)) +
  facet_


df_all %>% group_by(locatie.naam, grootheid.code) %>% summarise(n = n()) %>% View()
golfLocaties <- df_all %>% distinct(locatie.naam) %>% unlist %>% unname


#====  golfperiode ======================

# 1.	95-percentiel van de golfperiode Tm02 per jaar, incl metingen als losse puntjes


filenamesRawTm02 = list.files(file.path(datadir, "ddl/raw/golven"), full.names = T, recursive = T, pattern = "Tm02")

listData <- lapply(filenamesRawTm02, function(x) 
  read_delim(x, delim = ";", guess_max = 10000,
             # col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn', 
             col_types = 'cccccccccccn',
             na = c("-999999999", "999999e32", "999999999")
  ) %>%
    # select(locatie.naam, locatie.code, tijdstip, statuswaarde, kwaliteitswaarde.code, parameter.wat.omschrijving, eenheid.code, hoedanigheid.omschrijving, meetapparaat.omschrijving,
    #        parameter.code, grootheid.code, numeriekewaarde) %>%
    # drop_na(numeriekewaarde) %>%
    filter(kwaliteitswaarde.code < 50, numeriekewaarde < 10000 & numeriekewaarde >= 0) %>%
    mutate(tijdstip = as_datetime(as.character(tijdstip), tz = "CET")) %>%
    mutate(jaar = year(tijdstip), maand = month(tijdstip), yearly_perc95 = quantile(numeriekewaarde, 0.95, na.rm = T)) %>%
    filter(jaar == median(jaar)) # to filter out first tijdstip in next year
)

df_all <- bind_rows(listData)
save(df_all, 
     file = file.path(datadir, "ddl", "standard", paste0("golfperiode", today(), ".Rdata"))
     )
# write_delim(df_all, file.path(datadir, "ddl", "standard", paste0("golfperiode", today(), ".csv")), delim = ";")





#== waterhoogte opwerken ==============================================================
# 
source("r/runThisFirst.R")

allFiles = list()

filenamesRaw = list.files(file.path(datadir, "ddl/raw/waterhoogte"), full.names = T, recursive = T, pattern = "WATHTE")
allFiles <- lapply(filenamesRaw, function(x) 
  read_delim(x, delim = ";", 
             col_types = 'cccccccccccn',
             guess_max = 100000
  ) %>%
    filter(kwaliteitswaarde.code < 50, numeriekewaarde < 999, numeriekewaarde >= -999) %>%
    mutate(tijdstip = as_datetime(as.character(tijdstip), tz = "CET")) %>%
    filter(year(tijdstip) == median(year(tijdstip))) # to filter out first tijdstip in next year
    
)

# conversion should not be necessary, when reading is done as above
# allFiles <- map(allFiles, function(x) x %>% mutate(kwaliteitswaarde.code = as.character(kwaliteitswaarde.code)))
df_all_WATHTE <- bind_rows(allFiles)
save(df_all_WATHTE, file = file.path(datadir, "ddl", "standard", paste0("waterhoogte", today(), ".Rdata")))
# write_delim(df_all, file.path(datadir, "ddl", "standard", paste0("waterhoogte", today(), ".csv")), delim = ";")

rm(allFiles, df_all)

filenamesRaw = list.files(file.path(datadir, "ddl/raw/waterhoogte"), full.names = T, recursive = T, pattern = "WATHTBRKD")
allFiles <- lapply(filenamesRaw, function(x) 
  read_delim(x, delim = ";", 
             col_types = 'cccccccccccn',
             guess_max = 100000
  ) %>%
    filter(kwaliteitswaarde.code < 50, numeriekewaarde < 999, numeriekewaarde >= -999) %>%
    mutate(tijdstip = as_datetime(as.character(tijdstip), tz = "CET")) %>%
    filter(year(tijdstip) == median(year(tijdstip))) # to filter out first tijdstip in next year
  
)

# conversion should not be necessary, when reading is done as above
# allFiles <- map(allFiles, function(x) x %>% mutate(kwaliteitswaarde.code = as.character(kwaliteitswaarde.code)))
df_all_WATHTBRKD <- bind_rows(allFiles)
save(df_all_WATHTBRKD, file = file.path(datadir, "ddl", "standard", paste0("waterhoogteberekend", today(), ".Rdata")))
# write_delim(df_all, file.path(datadir, "ddl", "standard", paste0("waterhoogte", today(), ".csv")), delim = ";")



rm(allFiles)

# 
# berekenen van maandelijkse statistiek
load(file.path(datadir, "ddl", "standard", paste0("waterhoogteberekend", "2021-07-26", ".Rdata")))
load(file.path(datadir, "ddl", "standard", paste0("waterhoogte", "2021-07-26", ".Rdata")))

df_all_WATHTE <- as.data.table(df_all_WATHTE)
df_all_WATHTBRKD <- as.data.table(df_all_WATHTBRKD)

setkey(df_all_WATHTE, "tijdstip", "locatie.code", "eenheid.code", "hoedanigheid.omschrijving")
setkey(df_all_WATHTBRKD, "tijdstip", "locatie.code", "eenheid.code", "hoedanigheid.omschrijving")

memory.limit(size = 32000)
df.h.d <- df_all_WATHTE[df_all_WATHTBRKD]


# df_all = data.table::rbindlist(list(data.table(df_all_WATHTBRKD), data.table(df_all_WATHTE)))
# df_all = unique(df_all)[grootheid.code != "WATOZT"]
# 
# # df.h.d <- dcast(df.h, locatie.naam + tijdstip + eenheid.code + hoedanigheid.code ~ grootheid.code, value.var = "numeriekewaarde")

# df.h.d <- dcast(df_all, locatie.naam + tijdstip + eenheid.code + hoedanigheid.omschrijving ~ grootheid.code, value.var = "numeriekewaarde", fun.aggregate = mean, na.rm = T)

monthlyStat <- df.h.d[hoedanigheid.omschrijving == "t.o.v. Normaal Amsterdams Peil", .(
  opzet = numeriekewaarde - i.numeriekewaarde,
  month = lubridate::month(tijdstip) , 
  year = lubridate::year(tijdstip),
  station = locatie.naam
)][, .(
  station = station,
  max = max(opzet, na.rm = T),
  p95 = quantile(opzet, 0.95, na.rm = T),
  p99 = quantile(opzet, 0.99, na.rm = T)
  ), 
  by = list(year, month, station)][,.(
  station, max, p95, datum = as.Date(paste(year, month, "15", sep = "-"))),
]

write_delim(monthlyStat, file.path(datadir, "ddl", "standard", paste0("monthlyStatWaterhoogte", today(), ".csv")), delim = ";")

yearlyStat <- df_all_WATHTE[hoedanigheid.omschrijving == "t.o.v. Normaal Amsterdams Peil" & grootheid.code == "WATHTE", .(
  year = lubridate::year(tijdstip),
  station = locatie.naam,
  parameter.wat.omschrijving,
  eenheid.code,
  numeriekewaarde
)][, .(
  station = station,
  max = max(numeriekewaarde, na.rm = T),
  p95 = quantile(numeriekewaarde, 0.95, na.rm = T),
  p99 = quantile(numeriekewaarde, 0.99, na.rm = T)
), 
by = list(year, station,  parameter.wat.omschrijving, eenheid.code
)][,.(
  station,  parameter.wat.omschrijving, eenheid.code, year, max, p95),
]

write_delim(yearlyStat, file.path(datadir, "ddl", "standard", paste0("yearlyStatWaterhoogte", today(), ".csv")), delim = ";")

rm(df_all, df_all_WATHTBRKD, df_all_WATHTE, df.h.d)

# df_all %>% group_by(locatie.naam, grootheid.code) %>% summarise(n = n()) %>% View()
# waterhoogteLocaties <- df_all %>% distinct(locatie.naam) %>% unlist %>% unname

#================================================================

# test data processing
# 
# opzet berekenen
f1 = file.path(datadir, "ddl/raw/fysisch/SCHIERMNOG_OW_WATHTBRKD_NVT_NAP_2020_ddl_wq.csv")
f2 = file.path(datadir, "ddl/raw/fysisch/SCHIERMNOG_OW_WATHTE_NVT_NAP_2020_ddl_wq.csv")

d1 <- fread(f1, na.strings = c("-999999999", "999999999"))[,list(locatie.code, tijdstip, statuswaarde, grootheid.code, hoedanigheid.code, eenheid.code, numeriekewaarde)]
d2 <- fread(f2, na.strings = c("-999999999", "999999999"))[,list(locatie.code, tijdstip, statuswaarde, grootheid.code, hoedanigheid.code, eenheid.code, numeriekewaarde)]

setkey(d1, "tijdstip", "locatie.code", "eenheid.code")
setkey(d2, "tijdstip", "locatie.code", "eenheid.code")

d3 <- d1[d2]

# niet nodig om te casten... 
# dcast(DT.m1, family_id + age_mother ~ child, value.var = "dob")

d3$opzet <- data.table::fcase(
  d3$i.numeriekewaarde - d3$numeriekewaarde < 50, "laag",
  d3$i.numeriekewaarde - d3$numeriekewaarde >= 50, "hoog"
)

ggplot(d3, aes()) +
  geom_point(aes(tijdstip, i.numeriekewaarde - numeriekewaarde, color = opzet), size = 0.4)


# tidal analysis for one year
require(oce)

sl <- oce::as.sealevel(elevation = d1$numeriekewaarde, time = d1$tijdstip, stationName = d1$locatie.code)
plot(sl)

m <- tidem(sl)
summary(m)
plot(m)
pred <- predict.tidem(m)
obs <- sl@data$elevation
time <- sl@data$time

oce.plot.ts(time, obs-pred, ylab = "obs - pred")

m@data$amplitude
m@data$phase



require(data.table)
require(oce)
require(lubridate)
require(tidyverse)
filenamesRaw = list.files(file.path(datadir, "ddl/raw/fysisch"), full.names = T, recursive = T)


# locs = unique(ophaalCatalogus$locatie.code)
# filenamesRaw = list.files(file.path(datadir, "ddl/raw/fysisch"), full.names = T, recursive = T, pattern = )

# for(loc in locs){
# loc = locs[1]
fn1 <- filenamesRaw[grepl(paste("OW", "WATHTE", sep = "_"), filenamesRaw)]
fn2 <- filenamesRaw[grepl(paste("OW", "WATHTBRKD", sep = "_"), filenamesRaw)]
d1 <- rbindlist(lapply(fn1, function(x) fread(x, na.strings = c("-999999999", "999999999"))[,list(locatie.code, tijdstip, statuswaarde, grootheid.code, hoedanigheid.code, eenheid.code, numeriekewaarde)]))
d2 <- rbindlist(lapply(fn2, function(x) fread(x, na.strings = c("-999999999", "999999999"))[,list(locatie.code, tijdstip, statuswaarde, grootheid.code, hoedanigheid.code, eenheid.code, numeriekewaarde)]))
setkey(d1, "tijdstip", "locatie.code", "eenheid.code")
setkey(d2, "tijdstip", "locatie.code", "eenheid.code")
d3 <- d1[d2]
rm(d1, d2)
d3$numeriekewaarde <- oce::fillGap(d3$numeriekewaarde)

# sl <- oce::as.sealevel(elevation = d3$numeriekewaarde, time = d3$tijdstip, stationName = d3$locatie.code)
# plot(sl)

# d3$opzet <- data.table::fcase(
#   d3$i.numeriekewaarde - d3$numeriekewaarde < 50, "laag",
#   d3$i.numeriekewaarde - d3$numeriekewaarde >= 50, "hoog"
# )

d3[locatie.code == "DELFZL"] %>% 
  mutate(year = year(tijdstip)) %>%
  group_by(year, hoedanigheid.code, i.hoedanigheid.code, eenheid.code) %>% summarize(n = n()) %>% View()


monthlyMax <- d3[hoedanigheid.code == "NAP", .(
  opzet = numeriekewaarde - i.numeriekewaarde,
  month = lubridate::month(tijdstip) , 
  year = lubridate::year(tijdstip),
  station = locatie.code
)][, .(
  station = station,
  max = max(opzet),
  p99 = quantile(opzet, 0.99)
  ),
  by = list(year, month, station)][,.(
    station, max, p99, datum = as.Date(paste(year, month, "15", sep = "-"))),
  ]

# boxplot per year based on monthly max
ggplot(monthlyMax, aes(datum, max)) +
  geom_boxplot(aes(group = year(datum))) +
  # geom_smooth(method = "lm", aes(color = station), alpha = 0) +
  geom_point(aes(color = station), alpha = 0.2) +
  coord_cartesian(ylim = c(0, 450)) +
  facet_wrap( ~ station)


yearlyMax <- d3[hoedanigheid.code == "NAP", .(
  opzet = numeriekewaarde - i.numeriekewaarde,
  # month = lubridate::month(tijdstip) , 
  year = lubridate::year(tijdstip),
  station = locatie.code
)][, .(
  station = station,
  max = max(opzet),
  p99 = quantile(opzet, 0.99)
),
by = list(year, station)][,.(
  station, max, p99, year),
]

ggplot(yearlyMax, aes(year, p99)) +
  # geom_point(aes(color = station)) +
  geom_ribbon(aes(ymin = p99, ymax = max)) + 
  # geom_smooth(method = "loess", aes(color = station), alpha = 0) +
  coord_cartesian(ylim = c(30, 350)) +
  facet_grid(station ~ .)




# }

# allFiles <- lapply(filenamesRaw, function(x) read_delim(x, delim = ";", guess_max = 10000,
#                                                          col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
# df_all <- bind_rows(allFiles)
# write_delim(df_all, file.path(datadir, "ddl/standard/fysisch_trendstations_allyears.csv"), delim = ";")

