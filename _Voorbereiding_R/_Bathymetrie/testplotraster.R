require(raster)
require(tidyverse)
require(leaflet)
source("r/runThisFirst.R")

proj4wgs <- CRS('+init=EPSG:4326')

mosaicdir <- file.path(datadir, "RWS", "bathymetrie", "processing_tiles", "mosaic")
mosaiclist <- list.files(mosaicdir)

bathymetry <- raster::raster(file.path(mosaicdir, mosaiclist[18]))
poly <- sf::st_read(file.path(datadir, "RWS", "bathymetrie", "FriescheZeegat-P-Z.geojson"), quiet = T)

bathymetrywgs <- projectRaster(bathymetry, crs = proj4wgs)


plot(bathymetry)
polygon(poly)

# bath <- as(bathymetry, "SpatialPixelsDataFrame")
# bath.df <- as.data.frame(bath)

pal = colorNumeric(palette = "viridis", domain = values(bathymetry), na.color = "transparent", reverse = T)

poly %>%
  st_transform(4326) %>%
leaflet() %>% 
  addTiles() %>%
  addPolygons() %>%
    addRasterImage(bathymetrywgs, colors = pal, opacity = 80)
  
