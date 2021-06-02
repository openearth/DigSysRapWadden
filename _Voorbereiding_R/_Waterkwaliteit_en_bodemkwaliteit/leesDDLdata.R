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
  devtools::install_github("wstolte/rwsapi", force = TRUE)
  library("rwsapi", character.only = TRUE)
}
require(rwsapi)
getPackage("tidyverse")
getPackage("httr")
getPackage("lubridate")
getPackage("magrittr")
getPackage("rlist")
getPackage("gdalUtils")
getPackage("rgdal")
getPackage("sf")
getPackage("leaflet")
getPackage("purrr")
source("runThisFirst.R")
getPackage("devtools")
## install functions for rwsapi from private github.
if(!require("rwsapi", character.only = TRUE)){
  devtools::install_github("wstolte/rwsapi", force = TRUE)
  library("rwsapi", character.only = TRUE)
}
require(rwsapi)

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
# functie aanpassen als er meerdere crs worden gebruikt
# lapply(locsTable, Coordinatenstelsel, fun ) etc.. 


# wl_act_v <- sf::st_read("https://geodata.nationaalgeoregister.nl/rws/kaderrichtlijnwateractueel/wfs/v1_0?service=WFS&request=GetFeature&version=1.1.0&typeName=kaderrichtlijnwateractueel:krw_oppervlaktewaterlichamen_rws_act_v&outputFormat=application%2Fjson%3B%20subtype%3Dgeojson")
# possibleShapes <- unlist(apply(array(wl_act_v$owmnaam), 1, function(x) str_subset(x, pattern = mijnGebied)))
# # check if these areas are the ones wanted. Subset if necessary.
# mijnShape <- wl_act_v[wl_act_v$owmnaam %in% possibleShapes,]
# buffer_in_m <- 100 
# mijnLocaties <- sf::st_intersection(locs_sf_rd, sf::st_buffer(mijnShape, buffer_in_m))
# # something wrong with intersection... 


# alternative, but older water body shape
wl2006 <- sf::read_sf("../1_data/administratief/waterlichamen2006.shp", "waterlichamen2006")

wl2006 <- sf::st_set_crs(wl2006, 28992)
mijnShape <- wl2006[grepl(x = tolower(wl2006$OWMNAAM), pattern = tolower(mijnGebied)),]

buffer_in_m <- 100
mijnLocaties <- sf::st_intersection(locs_sf_rd, sf::st_buffer(mijnShape, buffer_in_m))
mijnLocaties_wgs <- sf::st_transform(mijnLocaties, crs = 4326)

# stationspal <- colorFactor(rainbow(3), mijnLocaties_wgs$stationsoort)

#check
# mijnLocaties_wgs <- read_delim(file.path("../1_data/", "administratief", paste(mijnGebied, "DDLLocations.csv")), delim = ";")
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
dir.create(file.path(datadir, "ddl"))
dir.create(file.path(datadir, "ddl/metadata"))
write_delim(mijnCatalogus, path = file.path(datadir, "ddl/metadata", paste0(mijnGebied, "_metadata.csv")), delim = ";")

if(!dir.exists(file.path(datadir, "ddl/raw")))dir.create(file.path(datadir, "ddl/raw"))

parametergroups <- read_delim(file.path(datadir, "../", "standaardlijsten", "Parameter_groups2.csv"), delim = ";", guess_max = 10000)


eutroparams <- parametergroups %>%
  filter(groep_ %in% c("Algemeen/Nutriënten_NO2-groep", "Algemeen/Nutriënten", "Veldmetingen", "Algemeen/Nutriënten_Cl-groep", "Diverse organische stoffen", "Algemeen", "Biologische parameters")) %>%
  distinct(Grootheid, parameter.code)

eutroCatalogus <- mijnCatalogus %>%
  filter(parameter.code %in% eutroparams$parameter.code | grootheid.code %in% eutroparams$Grootheid)
# filter(grootheid.code == "CONCTTE")

fysischparams <- 
  parametergroups %>%
  filter(groep_ %in% c("fysische parameters")) %>%
  distinct(Grootheid, parameter.code)

fysischCatalogus <- mijnCatalogus %>%
  filter(parameter.code %in% fysischparams$parameter.code | grootheid.code %in% fysischparams$Grootheid)

metalenparams <- parametergroups %>% 
  filter(grepl("metalen", Omschrijving, ignore.case = T) | grepl("metalen", waarneminggroep, ignore.case = T))

metalenCatalogus <- mijnCatalogus %>%
  filter(parameter.code %in% metalenparams$parameter.code | grootheid.code %in% metalenparams$Grootheid)


korrelparams <- parametergroups %>% 
  filter(grepl("korrel", Omschrijving, ignore.case = T))

korrelCatalogus <- mijnCatalogus %>%
  filter(parameter.code %in% korrelparams$parameter.code | grootheid.code %in% korrelparams$Grootheid)


# contaminantenparams <- parametergroups %>% 
#   filter(grepl("organische", Omschrijving, ignore.case = T) | grepl("", waarneminggroep, ignore.case = T))

contaminantenCatalogus <- mijnCatalogus %>%
  filter(!parameter_wat_omschrijving %in% eutroCatalogus$parameter_wat_omschrijving &
         !parameter_wat_omschrijving %in% fysischCatalogus$parameter_wat_omschrijving &
         !parameter_wat_omschrijving %in% metalenCatalogus$parameter_wat_omschrijving &
           !parameter_wat_omschrijving %in% metalenCatalogus$parameter_wat_omschrijving &
           grepl("massa", parameter_wat_omschrijving, ignore.case = T)
         )

contaminantenCatalogus %>%  View()

Compartimenten = c("OW", "BS", "OE") # oppervlaktewater, bodem en sediment, organisme
mijnCompartiment = Compartimenten[1]


#==== Eutrofiering data ==================================

# ophaalCatalogus <- mijnCatalogus[mijnCatalogus$parameter.code ==  "ZS",]
ophaalCatalogus <- eutroCatalogus 

nieuwedataophalen <- T

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))
if(!dir.exists(file.path(datadir, "ddl/raw/eutro"))) dir.create(file.path(datadir, "ddl/raw/eutro"))

if(nieuwedataophalen) {
  
  #=== DDL metingen ophalen (experimenteel voor de rapportage) ===========================
  # DDL bevat niet de niewste waarden en niet alle benodigde parameters
  
  # options(digits=22)
  
  startdate <- paste0(startyear, "-01-01T09:00:00.000+01:00")
  enddate <- paste0(endyear, "-12-31T23:00:00.000+01:00")
  
  
  getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                                eindDatumTijd = enddate, 
                                # mijnCompartiment = "OW",
                                mijnCatalogus = ophaalCatalogus
  )
  
  # ## example json string 
  # toJSON(getList[[12]], auto_unbox = T, digits = NA)
  
  # opnemen als functie in rwsapi package
  for(jj in c(670:length(getList))){   #
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response)){
      filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), "ddl_wq.csv", sep = "_")
      write_delim(response$content, path = file.path(datadir, "ddl/raw/eutro", filename), delim = ";")} else next
  }
}


#=== Fysische data ================================================

ophaalCatalogus <- fysischCatalogus 

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))

if(nieuwedataophalen) {
  
  #=== DDL metingen ophalen (experimenteel voor de rapportage) ===========================
  # DDL bevat niet de niewste waarden en niet alle benodigde parameters
  
  # options(digits=22)
  
  for(year in seq(startyear, endyear, 1)){
    
    startdate <- paste0(year, "-01-01T09:00:00.000+01:00")
    enddate <- paste0(year + 1, "-12-31T23:00:00.000+01:00")
    
    
    getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                                  eindDatumTijd = enddate, 
                                  mijnCompartiment = "OW",
                                  mijnCatalogus = ophaalCatalogus
    )
    
    # ## example json string 
    # toJSON(getList[[12]], auto_unbox = T, digits = NA)
    
    # opnemen als functie in rwsapi package
    for(jj in c(1:length(getList))){   #
      print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
      response <- rws_observations2(bodylist = getList[[jj]])
      if(!is.null(response)){
        filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), year, "ddl_wq.csv", sep = "_")
        write_delim(response$content, path = file.path(datadir, "ddl/raw/fysisch", filename), delim = ";")} else next
    }
  }
}

#==== metalen ===============================================

ophaalCatalogus <- metalenCatalogus 

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))
if(!dir.exists(file.path(datadir, "ddl/raw/metalen"))) dir.create(file.path(datadir, "ddl/raw/metalen"))

nieuwedataophalen <- TRUE

if(nieuwedataophalen) {
  
  #=== DDL metingen ophalen (experimenteel voor de rapportage) ===========================
  # DDL bevat niet de niewste waarden en niet alle benodigde parameters
  
  # options(digits=22)
  
  startdate <- paste0(startyear, "-01-01T09:00:00.000+01:00")
  enddate <- paste0(endyear, "-12-31T23:00:00.000+01:00")
  
  # rws_makeDDLapiList <- function (mijnCatalogus, beginDatumTijd, eindDatumTijd, mijnCompartiment = NULL) 
  # {
  #   result <- list()
  #   for (ii in seq(1:dim(mijnCatalogus[1]))) {
  #     if (ii == 1) 
  #       ll <- list()
  #     l <- list(AquoPlusWaarnemingMetadata = list(AquoMetadata = list(Compartiment = list(Code = mijnCompartiment), 
  #                                                                     Parameter = list(Code = mijnCatalogus$parameter.code[ii]), 
  #                                                                     Grootheid = list(Code = mijnCatalogus$grootheid.code[ii]), 
  #                                                                     Hoedanigheid = list(Code = mijnCatalogus$hoedanigheid.code[ii]))), 
  #               Locatie = list(X = as.character(mijnCatalogus["x"][ii, 
  #               ]), Y = as.character(mijnCatalogus["y"][ii, 
  #               ]), Code = as.character(mijnCatalogus["locatie.code"][ii, 
  #               ])), Periode = list(Begindatumtijd = beginDatumTijd, 
  #                                   Einddatumtijd = eindDatumTijd))
  #     ll[[ii]] <- l
  #   }
  #   return(ll)
  # }
  # 
  getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                                eindDatumTijd = enddate, 
                                mijnCatalogus = ophaalCatalogus
  )
  
  # ## example json string 
  # toJSON(getList[[12]], auto_unbox = T, digits = NA)
  
  # opnemen als functie in rwsapi package
  for(jj in c(1:length(getList))){   #
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response)){
      filename <- paste(
        ophaalCatalogus$locatie.code[jj], 
        ophaalCatalogus$compartiment.code[jj], 
        str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), 
        ophaalCatalogus$parameter.code[jj], 
        str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), 
        "ddl_wq.csv", sep = "_")
      write_delim(response$content, path = file.path(datadir, "ddl/raw/metalen", filename), delim = ";")} else next
  }
}

#==== Contaminanten data ==================================

# ophaalCatalogus <- mijnCatalogus[mijnCatalogus$parameter.code ==  "ZS",]
ophaalCatalogus <- contaminantenCatalogus 

nieuwedataophalen <- T

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))
if(!dir.exists(file.path(datadir, "ddl/raw/contaminanten"))) dir.create(file.path(datadir, "ddl/raw/contaminanten"))

if(nieuwedataophalen) {
  
  #=== DDL metingen ophalen (experimenteel voor de rapportage) ===========================
  # DDL bevat niet de niewste waarden en niet alle benodigde parameters
  
  # options(digits=22)
  
  startdate <- paste0(startyear, "-01-01T09:00:00.000+01:00")
  enddate <- paste0(endyear, "-12-31T23:00:00.000+01:00")
  
  
  getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                                eindDatumTijd = enddate, 
                                # mijnCompartiment = "OW",
                                mijnCatalogus = ophaalCatalogus
  )
  
  # ## example json string 
  # toJSON(getList[[12]], auto_unbox = T, digits = NA)
  
  # opnemen als functie in rwsapi package
  for(jj in c(670:length(getList))){   #
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response)){
      filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), "ddl_wq.csv", sep = "_")
      write_delim(response$content, path = file.path(datadir, "ddl/raw/contaminanten", filename), delim = ";")} else next
  }
}


