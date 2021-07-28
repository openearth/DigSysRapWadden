require(tidyverse)
source("r/runThisFirst.R")
# Sedimentatlas op https://svn.oss.deltares.nl/repos/openearthrawdata/trunk/rijkswaterstaat/sedimentatlas_waddenzee/raw/korrel.txt
# 

sedimentatlas <- "RWS\\korrelgrootten\\korrelSediementAtlas.txt"
df.sed.atlas <- read_csv(file.path(datadir, sedimentatlas))


# dataset korrelgrootte bodemchemie

url = "https://rwsprojectarchief.openearth.nl/geoserver/mwtl/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=mwtl%3Akorrelgrootte_bodem_sediment_chemie_marien"
chemiekorrel <- sf::st_read(url)

# dataset korrelgrootte macrobenthos

url1 = "https://rwsprojectarchief.openearth.nl/geoserver/mwtl/wms?service=WMS&request=GetMap&layers=korrelgrootte_bodem_sediment_macrofauna_marien&bbox=2,51,7,54&width=768&height=486&srs=EPSG:4326&format=application/openlayers"
read_csv(url1)

# RWS benthos tijdelijk

url = "https://rwsprojectarchief.openearth.nl/geoserver/rwsbenthos/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=rwsbenthos%3Aihm_rwsbenthos_tijdelijk"
chemiekorrel <- sf::st_read(url)

