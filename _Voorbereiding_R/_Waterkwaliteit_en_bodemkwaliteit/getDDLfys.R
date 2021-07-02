

####===  install packages and dependencies ========
source("r/runThisFirst.R")


mijnCatalogus <- read_delim(file.path(datadir, "ddl/metadata", paste0(mijnGebied, "_metadata.csv")), delim = ";")


mijnCatalogus %>%
  filter(
    (
      grepl("golf", parameter_wat_omschrijving, ignore.case = T) |
        grepl("hoogte", parameter_wat_omschrijving, ignore.case = T) |
        grepl("getij", parameter_wat_omschrijving, ignore.case = T) |
        grepl("opzet", parameter_wat_omschrijving, ignore.case = T)
    ) #&
      # !grepl("berekend", parameter_wat_omschrijving, ignore.case = T)
  ) %>% distinct(grootheid.code, parameter_wat_omschrijving) %>%
  View()  #%>% 
#write_delim("golfparameters.csv", delim = ";")


# Selection based on requirements for this version. only temp and salinity
# SPM (Zwevend staof) also needed, but missing from DDL at the moment. 
FysCatalogus <- mijnCatalogus  %>%
  filter(
    parameter_wat_omschrijving %in% c(
      "Golfhoogte Oppervlaktewater dm",
      "Waterhoogte Oppervlaktewater t.o.v. Normaal Amsterdams Peil in cm",
      "Waterhoogte berekend Oppervlaktewater t.o.v. Normaal Amsterdams Peil in cm",
      "Berekend Wateropzet Oppervlaktewater cm",
      "Significante golfhoogte in het spectrale domein Oppervlaktewater golffrequentie tussen 30 en 1000 mHz in cm",
      "Gemiddelde golfhoogte in het tijdsdomein Oppervlaktewater cm"
    ),
  )

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))
if(!dir.exists(file.path(datadir, "ddl/raw/fysisch"))) dir.create(file.path(datadir, "ddl/raw/fysisch"))


#=== Check data availability for 2016 ======
#
startdate <- paste0(2016, "-01-01T09:00:00.000+01:00")  # hardcoded startyear
enddate <- paste0(2016, "-12-31T23:00:00.000+01:00")


getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                              eindDatumTijd = enddate, 
                              mijnCatalogus = FysCatalogus
)

for(jj in c(1:length(getList))){   #
  print(paste("getting", jj, FysCatalogus$locatie.code[jj], FysCatalogus$compartiment.code[jj], FysCatalogus$grootheid.code[jj], FysCatalogus$parameter.code[jj]))
  response <- rws_observations2(bodylist = getList[[jj]])
  if(!is.null(response) & nrow(response$content)!=0){
    filename <- paste(FysCatalogus$locatie.code[jj], FysCatalogus$compartiment.code[jj], str_replace(FysCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), FysCatalogus$parameter.code[jj], str_replace(FysCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), "ddl_wq.csv", sep = "_")
    write_delim(response$content, path = file.path(datadir, "ddl/raw/fysisch", filename), delim = ";")} else next
}

filenamesRaw = list.files(file.path(datadir, "ddl/raw/fysisch"), full.names = T, recursive = T)

allFiles <- lapply(filenamesRaw, function(x) read_delim(x, delim = ";", guess_max = 10000,
                                                        col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
df_all <- bind_rows(allFiles)

df_all %>% group_by(locatie.naam, grootheid.code) %>% summarise(n = n()) %>% View()
fysischLocaties <- df_all %>% distinct(locatie.naam) %>% unlist %>% unname


#=== ophalen alle jaren ===============================




ophaalCatalogus <- FysCatalogus %>% filter(locatie.naam %in% fysischLocaties)


for(jj in c(1:length(getList))){   #
  for(ophaaljaar in startyear:endyear){
    startdate <- paste0(ophaaljaar, "-01-01T09:00:00.000+01:00")
    enddate <- paste0(ophaaljaar + 1, "-01-01T09:00:00.000+01:00")
    getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                                  eindDatumTijd = enddate, 
                                  mijnCatalogus = ophaalCatalogus
    )
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response) & nrow(response$content)!=0){
      filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaaljaar, "ddl_wq.csv", sep = "_")
      write_delim(response$content, path = file.path(datadir, "ddl/raw/fysisch", filename), delim = ";")} else next
  }
}

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

