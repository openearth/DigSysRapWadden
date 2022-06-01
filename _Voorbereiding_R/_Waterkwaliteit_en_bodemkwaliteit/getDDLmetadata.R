## voorbereiding van digitale watersysteemrapportage
## Fetches DDL metadata
## Fetches Waterbody shapes
## Selects DDL locations within Waterbodies of interest

####===  install packages and dependencies ========
source("r/runThisFirst.R")

#==== ophalen DDL metadata catalogus ==================

metadata <- rwsapi::rws_metadata() # gets complete catalog
parsedmetadata <- jsonlite::fromJSON(content(metadata$resp, "text"), simplifyVector = T )

subsTable <- rlist::list.flatten(parsedmetadata$AquoMetadataLijst, use.names = T) %>% 
  as.data.frame() %>% 
  distinct()

locsTable <- parsedmetadata$LocatieLijst

if(locsTable %>% distinct(Coordinatenstelsel) %>% length() == 1){
  locs_sf <- sf::st_as_sf(locsTable, coords = c("X", "Y"), crs = 25831)
  locs_sf_rd <- sf::st_transform(locs_sf, crs = 28992)
} else print("warning, multiple epsg, sf object not produced")

# Get water body shape from web service
wl_act_v <- sf::st_read("https://geodata.nationaalgeoregister.nl/rws/kaderrichtlijnwateractueel/wfs/v1_0?service=WFS&request=GetFeature&version=1.1.0&typeName=kaderrichtlijnwateractueel:krw_oppervlaktewaterlichamen_rws_act_v&outputFormat=application%2Fjson%3B%20subtype%3Dgeojson")

# manual selection
WBofinterest <- c(
  "Eems-Dollard", "Eems-Dollard (kustwater)", "Eems territoriaal water",
  "Waddenzee vastelandskust", "Waddenzee", "Waddenkust (kustwater)",
  "Rijn territoriaal water")

mijnShape <- wl_act_v[wl_act_v$owmnaam %in% WBofinterest,]
mijnShape2 <- st_make_valid(mijnShape)
names(st_geometry(mijnShape2)) = NULL

leaflet::leaflet(mijnShape) %>%
  leaflet::addTiles(group = "OSM") %>%
  leaflet::addPolygons(data = sf::st_transform(wl_act_v, 4326), fillColor = "blue", group = "KRW waterlichamen", popup = ~htmltools::htmlEscape(nametext)) %>%
  leaflet::addPolygons(data = sf::st_transform(mijnShape2, 4326), group = "watersysteem", color = "green", opacity = 0.3) %>%
  leaflet::addLayersControl(baseGroups = c("OSM"),
  overlayGroups = c("watersysteem", "KRW waterlichamen"))
  
buffer_in_m <- 200
mijnLocaties <- sf::st_intersection(locs_sf_rd, sf::st_buffer(mijnShape2, buffer_in_m))
southernBorder = min(st_coordinates(mijnLocaties[grepl("Callantsoog", mijnLocaties$Naam),])[,"Y"])

BOOMKDP <- locs_sf %>% filter(Code == "BOOMKDP") %>% st_transform(4326)

mijnLocaties <- mijnLocaties %>% 
  bind_cols(mijnLocaties %>% 
              st_coordinates() %>% 
              as_tibble()
  ) %>%
  filter(Y >= southernBorder)
mijnLocaties_wgs <- sf::st_transform(mijnLocaties, crs = 4326)

st_write(mijnShape, file.path(datadir, "ddl/metadata", paste0(mijnGebied, "_metadata.geojson")), append = F)

# stationspal <- colorFactor(rainbow(3), mijnLocaties_wgs$stationsoort)

#check
# mijnLocaties_wgs <- read_delim(file.path("../1_data/", "administratief", paste(mijnGebied, "DDLLocations.csv")), delim = ";")
leaflet::leaflet(mijnLocaties_wgs) %>%
  leaflet::addTiles(group = "OSM") %>%
  addProviderTiles(providers$Esri.WorldTopoMap, group = "Esri.WorldTopoMap") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Esri.WorldImagery") %>%
  # leaflet::addPolygons(data = sf::st_transform(wl_act_v, 4326), fillColor = "blue", group = "KRW waterlichamen", popup = ~htmltools::htmlEscape(nametext)) %>%
  leaflet::addPolygons(data = sf::st_transform(mijnShape, 4326), group = "watersysteem", color = "green", opacity = 0.3) %>%
  leaflet::addProviderTiles("OpenSeaMap", group = "OpenSeaMap") %>%
  leaflet::addCircleMarkers(label = ~htmltools::htmlEscape(paste0(Naam)), group = "all_locations", radius = 4) %>%
  leaflet::addCircleMarkers(data = BOOMKDP, label = ~htmltools::htmlEscape(paste0(Naam)), radius = 10) %>%
  leaflet::addLayersControl(
    baseGroups = c("OSM",  "Esri.WorldTopoMap", "Esri.WorldImagery"),
    overlayGroups = c("all_locations", "watersysteem", "OpenSeaMap")) 


mijnCatalogus <- rwsapi::rws_getParameters(metadata, locatiecode = unique(mijnLocaties$Code)) %>%
  mutate(across(where(is.character), str_trim))
dir.create(file.path(datadir, "ddl"))
dir.create(file.path(datadir, "ddl/metadata"))
write_delim(mijnCatalogus, file = file.path(datadir, "ddl/metadata", paste0(mijnGebied, "_metadata.csv")), delim = ";")
