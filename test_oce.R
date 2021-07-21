
# Ruwe data, 1 jaar

f1 = file.path(datadir, "ddl/raw/waterhoogte/SCHIERMNOG_OW_WATHTBRKD_NVT_NAP_2020_ddl_wq.csv")
f2 = file.path(datadir, "ddl/raw/waterhoogte/SCHIERMNOG_OW_WATHTE_NVT_NAP_2020_ddl_wq.csv")

d1 <- fread(f1, na.strings = c("-999999999", "999999999"))[,list(locatie.code, tijdstip, statuswaarde, grootheid.code, hoedanigheid.omschrijving, eenheid.code, numeriekewaarde)]
d2 <- fread(f2, na.strings = c("-999999999", "999999999"))[,list(locatie.code, tijdstip, statuswaarde, grootheid.code, hoedanigheid.omschrijving, eenheid.code, numeriekewaarde)]

setkey(d1, "tijdstip", "locatie.code", "eenheid.code")
setkey(d2, "tijdstip", "locatie.code", "eenheid.code")

# join gemeten en berekend
d3 <- d1[d2]

# niet nodig om te casten... moet alleen als de twee met rowbind aan elkaar zijn geplakt
# dcast(DT.m1, family_id + age_mother ~ child, value.var = "dob")

# voorbeeld klassificering van opzet
d3$opzet <- data.table::fcase(
  d3$i.numeriekewaarde - d3$numeriekewaarde < 50, "laag",
  d3$i.numeriekewaarde - d3$numeriekewaarde >= 50, "hoog"
)

ggplot(d3, aes()) +
  geom_point(aes(tijdstip, i.numeriekewaarde - numeriekewaarde, color = opzet), size = 0.4)


# oce package voor oceanographic analysis

require(oce)

# maak sealevel object
sl <- oce::as.sealevel(elevation = d1$numeriekewaarde, time = d1$tijdstip, stationName = d1$locatie.code)

plot(sl)

# model
m <- tidem(sl)
# summary met parameters
summary(m)
# plot contribution of tidal components 
plot(m)
# calculate predicted tides 
pred <- predict.tidem(m)
obs <- sl@data$elevation
time <- sl@data$time
# plot diff
oce.plot.ts(time, obs-pred, ylab = "obs - pred")

m@data$amplitude
m@data$phase


# voor alle data (nog testen)

require(data.table)
require(oce)
require(lubridate)
require(tidyverse)
filenamesRaw = list.files(file.path(datadir, "ddl/raw/waterhoogte"), full.names = T, recursive = T)


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


