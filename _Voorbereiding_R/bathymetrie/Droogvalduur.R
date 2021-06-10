
require(tidyverse)
require(scales)
require(raster)
require(sf)
source("runThisFirst.R")

#=== 2013 dvd uit bathymetrie en waterhoogte

# codes voor waterhoogte per station
codes <- c("STAVNSE_OW_WATHTE_NVT","ROOMPBNN_OW_WATHTE_NVT","MARLGT_OW_WATHTE_NVT","KRAMMSZWT_OW_WATHTE_NVT")

hoogte <- lapply(codes, function(x) read_delim(file = file.path(datadir, "ddl/standard", paste0(x, ".csv")), delim=" ") %>%
                   mutate(tijdstip = as_datetime(tijdstip)) %>%
                   mutate(jaar = year(tijdstip)) %>%
                   filter(numeriekewaarde<1e7 & grootheid.code == "WATHTE") %>%
                   filter(jaar > 2013 & jaar < 2019)) %>%
  bind_rows()

stations = hoogte %>% distinct(locatie.code, geometriepunt.x, geometriepunt.y) %>%
  st_as_sf(coords = c("geometriepunt.x", "geometriepunt.y"), crs = 25831) %>% 
  sf::st_transform(4326)

#=== Vakken voor berekening van dvd uit waterhoogtes per station
vakken <- sf::read_sf(file.path(datadir, "kaarten", "wl2018_OSv4.geojson")) %>% 
  sf::st_transform(28992) %>% 
  mutate(DEELGEBIED = case_when(DEELGEBIED == "west" ~ "monding",
                                DEELGEBIED == "midden" ~ "midden",
                                DEELGEBIED == "oost" ~ "kom",
                                DEELGEBIED == "noord" ~ "noord"))

#=== lees 2013 bathymetrie
bathy2013 <- raster::raster(file.path(datadir, "RWS_bathymetrie/Vakloding/selection/OSbathymetrie2013_correct.tif"))
proj4rd <- CRS('+init=EPSG:28992')
proj4wgs <- CRS('+init=EPSG:4326')
raster::crs(bathy2013) <- proj4rd

bathy2013WGS <- projectRaster(bathy2013, crs = proj4wgs)

st <- c("STAVNSE","ROOMPBNN","MARLGT","KRAMMSZWT")
# gebied <- c("midden", "west", "oost", "noord")
gebied <- c("midden", "monding", "kom", "noord")
rasterlist <- list()
for(ii in 1:4){
  ii
  deelraster <- raster::mask(bathy2013, vakken[vakken$DEELGEBIED==gebied[ii],])
  f <- ecdf(hoogte[hoogte$locatie.code == st[ii],]$numeriekewaarde)
  droogval.raster <- calc(deelraster, fun = function(x) f(x*100)*100)
  rasterlist[[ii]] <- droogval.raster
  # plot(droogval.raster, main = paste("Droogvalduur per etmaal Oosterschelde", gebied[ii], "2013 - 2018"))
}
droogvalraster <- do.call(merge, rasterlist)

raster::writeRaster(x = droogvalraster, file.path(datadir, "RWS_bathymetrie", "standard", "dvd2013.asc"))


#==== test reading =====================

dvd1983 <- file.path(datadir, "RWS_ecotopen", "standard", "Basisbestanden Ecotopenkaart OS 1983/parameterkaarten/drgv_83/hdr.adf")
dvd1990 <- file.path(datadir, "RWS_ecotopen", "standard", "Basisbestanden Ecotopenkaart OS 1990/parameterkaarten/drgv_89/hdr.adf")
dvd2001 <- file.path(datadir, "RWS_ecotopen", "standard", "Basisbestanden Ecotopenkaart OS 2001/parameterkaarten/drgv_01/hdr.adf")
dvd2009 <- file.path(datadir, "RWS_ecotopen", "standard", "Basisbestanden Ecotopenkaart OS 2009/Droogvalduur/dvd_10/hdr.adf")
dvd2013 <- file.path(datadir, "RWS_bathymetrie", "standard", "dvd2013.asc")
dvd2016 <- file.path(datadir, "RWS_ecotopen", "standard", "Basisbestanden Ecotopenkaart OS 2016/dvd2016/hdr.adf")

# r1983 <- raster(dvd1983); crs(r1983) <- CRS("+init=epsg:28992"); r1983[r1983 <= 0] <- NA 
# De 1983 dvd wordt niet meegenomen omdat getwijfeld wordt aan de kwaliteit (Eric van Zanten)
r1990 <- raster(dvd1990); crs(r1990) <- CRS("+init=epsg:28992"); r1990[r1990 <= 0] <- NA
r2001 <- raster(dvd2001); crs(r2001) <- CRS("+init=epsg:28992"); r2001[r2001 <= 0] <- NA
r2009 <- raster(dvd2009); crs(r2009) <- CRS("+init=epsg:28992"); r2009[r2009 <= 0] <- NA
r2013 <- raster(dvd2013); crs(r2013) <- CRS("+init=epsg:28992"); r2013[r2013 <= 0] <- NA
r2016 <- raster(dvd2016); crs(r2016) <- CRS("+init=epsg:28992"); r2016[r2016 <= 0] <- NA


rlist <- list(r1990, r2001, r2009, r2013, r2016) # diff extents, stack not possible
# lapply(rlist, function(x) plot(x))
# lapply(rlist, function(x) hist(x))

rlist84 <- list()
for(ii in 1:length(rlist)){
  print(crs(rlist[[ii]]))
  rlist84[[ii]] <- projectRaster(rlist[[ii]], crs = CRS("+init=epsg:4326"))
}


