## voorbereiding van digitale watersysteemrapportage

####===  install packages and dependencies ========
getPackage <- function(pkg){
  if(!require(pkg, character.only = TRUE)){
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
  return(TRUE)
}

getPackage("devtools")
## install functions for rwsapi from private github.
if(!require("rwsapi", character.only = TRUE)){
  devtools::install_github("wstolte/rwsapi")
  library("rwsapi", character.only = TRUE)
}

getPackage("tidyverse")
getPackage("httr")
getPackage("lubridate")
getPackage("magrittr")
getPackage("rlist")
getPackage("rgdal")
getPackage("sf")
getPackage("leaflet")
getPackage("purrr")
source("R/runThisFirst.R")

#==== ophalen DDL metadata catalogus ==================

# options(digits=22) # necessary for location numerical values, kan ook in functiecall !
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

wl2006 <- sf::read_sf(file.path(datadir, "../administratief/waterlichamen2006.geojson"))

wl2006 <- sf::st_set_crs(wl2006, 28992)
# mijnShape <- wl2006[grepl(x = tolower(wl2006$OWMNAAM), pattern = tolower(mijnGebied)),]
mijnShape <- wl2006 %>% filter(OWMIDENT %in% c("NL81_2", "NL81_3", "NL81_1", "NL95_4A", "NL81_10"))


buffer_in_m <- 0
mijnLocaties <- sf::st_intersection(locs_sf_rd, sf::st_buffer(mijnShape, buffer_in_m))
mijnLocaties$x_rd <- sf::st_coordinates(mijnLocaties)[,1]
mijnLocaties$y_rd <- sf::st_coordinates(mijnLocaties)[,2]
mijnLocaties_wgs <- sf::st_transform(mijnLocaties, crs = 4326)
mijnLocaties_wgs$x_wgs <- sf::st_coordinates(mijnLocaties_wgs)[,1]
mijnLocaties_wgs$y_wgs <- sf::st_coordinates(mijnLocaties_wgs)[,2]
# write_delim(as.data.frame(mijnLocaties_wgs), file.path("../1_data/", "administratief", paste(mijnGebied, "DDLLocations.csv")), delim = ";")

#check
leaflet::leaflet(mijnLocaties_wgs) %>%
  leaflet::addTiles(group = "OSM") %>%
  addProviderTiles(providers$Esri.WorldTopoMap, group = "Esri.WorldTopoMap") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Esri.WorldImagery") %>%
  leaflet::addPolygons(data = sf::st_transform(mijnShape, 4326), group = "watersysteem", color = "green", opacity = 0.3) %>%
  # leaflet::addPolygons(data = sf::st_transform(wl2006, 4326), group = "KRW waterlichamen 2006", popup = ~htmltools::htmlEscape(OWMNAAM)) %>%
  leaflet::addProviderTiles("OpenSeaMap", group = "OpenSeaMap") %>%
  leaflet::addCircleMarkers(label = ~htmltools::htmlEscape(paste0(Naam)), group = "all_locations", radius = 4) %>%
  leaflet::addLayersControl(
    baseGroups = c("OSM",  "Esri.WorldTopoMap", "Esri.WorldImagery"),
    overlayGroups = c("all_locations", "watersysteem", "OpenSeaMap")) %>%    #, "KRW waterlichamen 2006"
  hideGroup("KRW waterlichamen 2006")



mijnCatalogus <- rwsapi::rws_getParameters(metadata, locatiecode = unique(mijnLocaties$Code))
# write_delim(mijnCatalogus, path = file.path(datadir, "ddl/metadata", paste0(mijnGebied, "_metadata.csv")), delim = ";")

waterhoogteCatalogus <- mijnCatalogus[mijnCatalogus$grootheid.code=="WATHTE",]


ophaalCatalogus <- waterhoogteCatalogus
source("tempcustumfunctie.R")

#=== DDL metingen ophalen (experimenteel voor de rapportage) ===========================
# DDL bevat niet de niewste waarden en niet alle benodigde parameters

# options(digits=22)

startyear <- 1970
endyear <- 2019


# for(year in startyear:endyear){
for(year in 2002:endyear){
    
    # year = 1980
  startjaar = year; eindjaar = year +1
  startdate <- paste0(startjaar, "-01-01T09:00:00.000+01:00")
  enddate <- paste0(eindjaar, "-01-01T09:00:00.000+01:00")
  getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                                eindDatumTijd = enddate, 
                                mijnCompartiment = "OW",
                                mijnCatalogus = ophaalCatalogus
  )
  
  # ## example json string 
  # toJSON(getList[[12]], auto_unbox = T, digits = NA)
  
  # opnemen als functie in rwsapi package
  for(jj in c(1:length(getList))){   #length(getList)
    # jj = 3
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj], year))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response)){
      filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], startjaar, eindjaar, "ddl_wq.csv", sep = "_")
      write_delim(response$content, path = file.path(datadir, "ddl/raw", filename), delim = ";")
    } else next
  }
}


## paste together different years to one file per station

codes <- c("STAVNSE_OW_WATHTE_NVT",
  "ROOMPBNN_OW_WATHTE_NVT","MARLGT_OW_WATHTE_NVT","KRAMMSZWT_OW_WATHTE_NVT")


for(ii in seq(1:4)){
  # ii=2
  allWHfiles <- list.files(file.path(datadir, "ddl/raw"), pattern = codes[ii], full.names = T)
  lapply(
    allWHfiles, function(x) 
      read_delim(x, delim = ";", col_types = cols(.default = "c")) %>%
      distinct(locatie.code, geometriepunt.x, geometriepunt.y, tijdstip, kwaliteitswaarde.code,
               grootheid.code, eenheid.code, hoedanigheid.code, numeriekewaarde) %>%
      filter(grootheid.code == "WATHTE")
    ) %>%
    bind_rows() %>% 
  write_delim(file.path(datadir, "ddl/standard", paste0(codes[ii], ".csv")))
}




