
# Ruwe data, 1 jaar

f1 = file.path(datadir, "ddl/raw/waterhoogte/SCHIERMNOG_OW_WATHTBRKD_NVT_NAP_2017_ddl_wq.csv")
f2 = file.path(datadir, "ddl/raw/waterhoogte/SCHIERMNOG_OW_WATHTE_NVT_NAP_2017_ddl_wq.csv")

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


#==== tidal harmonics using oce package =================================

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


#===== package TideHarmonics ===================
#

require(TideHarmonics)

f1 = file.path(datadir, "ddl/raw/waterhoogte/SCHIERMNOG_OW_WATHTBRKD_NVT_NAP_2017_ddl_wq.csv")
f2 = file.path(datadir, "ddl/raw/waterhoogte/SCHIERMNOG_OW_WATHTE_NVT_NAP_2017_ddl_wq.csv")

d1 <- fread(f1, na.strings = c("-999999999", "999999999"))[,list(locatie.code, tijdstip, statuswaarde, grootheid.code, hoedanigheid.omschrijving, eenheid.code, numeriekewaarde)]
d2 <- fread(f2, na.strings = c("-999999999", "999999999"))[,list(locatie.code, tijdstip, statuswaarde, grootheid.code, hoedanigheid.omschrijving, eenheid.code, numeriekewaarde)]

Tides::gapsts(d1$tijdstip, 10)
# no gaps

d1 <- d1 %>% arrange(tijdstip)

TideHarmonics::ftide(d1$numeriekewaarde, d1$tijdstip, hcn = TideHarmonics::hc60, nodal = T)




