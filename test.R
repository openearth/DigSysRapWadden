

require(sf)
require(tidyverse)
require(leaflet)

baseurl = "https://wad.deontwikkelfabriek.nl/geoserver/wmr/ows?"
wfs_request = "service=WFS&version=1.0.0&request=GetFeature&typeName=wmr:zeehondtelgebieden&outputForma=application/json"
zeehondTelgebieden <- st_read(paste0(baseurl, wfs_request), crs = 4326)
st_crs(zeehondTelgebieden)
names(st_geometry(zeehondTelgebieden)) = NULL

pal = leaflet::colorNumeric("Greens", zeehondTelgebieden$n)

leaflet() %>%
  addTiles() %>%
  addPolygons(fillColor = ~pal(n), data = zeehondTelgebieden) %>%
  addLegend(position = "bottomright", pal = pal, values = zeehondTelgebieden$n, opacity = 1)







# bathymetry layer
"https://wad.deontwikkelfabriek.nl/geoserver/nioz/wms?service=WMS&version=1.1.0&request=GetMap&layers=nioz:bathymetrie&styles=&bbox=3.370947265625,51.229931640625,7.414697265560301,53.790348307250696&width=768&height=486&srs=EPSG:4326&format=application/openlayers"

# use geotiff
baseurl = "https://wad.deontwikkelfabriek.nl/geoserver/nioz/wms?service=WMS"
wms_request = "service=WMS&version=1.1.0&request=GetMap&layers=nioz:bathymetrie&outputFormat=geotiff"
st_read(st_read(paste0(baseurl, wms_request), crs = 4326))

# leaflet() %>% #setView(x.WGS, y.WGS, zoom = 11) %>%
#   addTiles() %>%
#   # addMarkers(lng = x.WGS, lat = y.WGS)%>%
#   addWMSTiles(
#     baseUrl = baseurl,
#     layers = "nioz:bathymetrie",
#     options = WMSTileOptions(format = "image/png", transparent = TRUE),
#     attribution = "") #%>%
#   addWMSLegend(uri ="https://geodata.nationaalgeoregister.nl/natura2000/ows?service=WMS&request=GetLegendGraphic&format=image%2Fpng&width=20&height=20&layer=natura2000")

