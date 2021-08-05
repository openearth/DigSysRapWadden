require(tidyverse)
source("r/runThisFirst.R")
# Sedimentatlas op https://svn.oss.deltares.nl/repos/openearthrawdata/trunk/rijkswaterstaat/sedimentatlas_waddenzee/raw/korrel.txt
# 
require(RNetCDF)
url = "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/sedimentatlas_waddenzee/korrel.nc"
con = RNetCDF::open.nc(url)
RNetCDF::print.nc(con)

lats <- RNetCDF::var.get.nc(con, "lat")
lons <- RNetCDF::var.get.nc(con, "lon")

RNetCDF::close.nc(con)

require(tidync)
nc <- tidync::tidync(url)
tidync::hyper_dims(nc)
tidync::hyper_vars(nc)
tidync::hyper_dims(nc)

diameters <- c( 4000.0, 2828.0, 2000.0, 1414.0, 1000.0, 707.0, 500.0, 354.0, 250.0, 177.0, 125.0, 88.0, 63.0, 44.0, 32.0, 22.0, 16.0, 11.0, 8.0, 5.5, 4.0, 2.7, 2.0, 1.4, 1.0, 0.7)
names(diameters) <- c(1:length(diameters)) 

sedimentatlas <- tidync::hyper_tibble(nc) %>%
  mutate(diam = recode(particle_diameter, !!!diameters)) %>%
  mutate(lng = recode(locations, !!!lons)) %>%
  mutate(lat = recode(locations, !!!lats))



slib <- sedimentatlas %>% 
  group_by(lng, lat) %>%
  summarize(
    slibgehalte = sum(phi[diam < 63.0]),
    rest = sum(phi[diam >= 63.0])
    ) %>% 
  filter(slibgehalte < 100)

slib %>%
  ggplot(aes(lng, lat)) +
  geom_point(aes(color = slibgehalte)) 

pal = leaflet::colorNumeric(jet.colors(n = 7), slib$slibgehalte)

leaflet(slib) %>%
  leaflet::addTiles() %>%
  # addCircleMarkers(stroke = F, fillColor = ~pal(slibgehalte), fillOpacity = 1)
  addCircles(color = ~pal(slibgehalte), fillOpacity = 1, weight = 10) %>%
  leaflet::addLegend(position = "bottomright", pal = pal, values = slib$slibgehalte)

# dataset korrelgrootte bodemchemie

url = "https://rwsprojectarchief.openearth.nl/geoserver/mwtl/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=mwtl%3Akorrelgrootte_bodem_sediment_chemie_marien"
chemiekorrel <- sf::st_read(url)

# dataset korrelgrootte macrobenthos

url1 = "https://rwsprojectarchief.openearth.nl/geoserver/mwtl/wms?service=WMS&request=GetMap&layers=korrelgrootte_bodem_sediment_macrofauna_marien&bbox=2,51,7,54&width=768&height=486&srs=EPSG:4326&format=application/openlayers"
read_csv(url1)

# RWS benthos tijdelijk

url = "https://rwsprojectarchief.openearth.nl/geoserver/rwsbenthos/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=rwsbenthos%3Aihm_rwsbenthos_tijdelijk"
chemiekorrel <- sf::st_read(url)

