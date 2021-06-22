## voorbereiding van digitale watersysteemrapportage

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
  "Eems-Dollard", "Eems-Dollard", "Waddenzee vastelandskust", 
  "Waddenzee", "Rijn territoriaal water", "Eems-Dollard (kustwater)", 
  "Eems-Dollard (kustwater)", "Waddenkust (kustwater)", "Eems territoriaal water"   
)

mijnShape <- wl_act_v[wl_act_v$owmnaam %in% WBofinterest,]

buffer_in_m <- 100
mijnLocaties <- sf::st_intersection(locs_sf_rd, sf::st_buffer(mijnShape, buffer_in_m))
southernBorder = min(st_coordinates(mijnLocaties[grepl("Callantsoog", mijnLocaties$Naam),])[,"Y"])

mijnLocaties <- mijnLocaties %>% 
  bind_cols(mijnLocaties %>% 
              st_coordinates() %>% 
              as_tibble()
  ) %>%
  filter(Y >= southernBorder)
mijnLocaties_wgs <- sf::st_transform(mijnLocaties, crs = 4326)

# stationspal <- colorFactor(rainbow(3), mijnLocaties_wgs$stationsoort)

#check
# mijnLocaties_wgs <- read_delim(file.path("../1_data/", "administratief", paste(mijnGebied, "DDLLocations.csv")), delim = ";")
leaflet::leaflet(mijnLocaties_wgs) %>%
  leaflet::addTiles(group = "OSM") %>%
  addProviderTiles(providers$Esri.WorldTopoMap, group = "Esri.WorldTopoMap") %>%
  addProviderTiles(providers$Esri.WorldImagery, group = "Esri.WorldImagery") %>%
  leaflet::addPolygons(data = sf::st_transform(wl_act_v, 4326), fillColor = "blue", group = "KRW waterlichamen", popup = ~htmltools::htmlEscape(nametext)) %>%
  leaflet::addPolygons(data = sf::st_transform(mijnShape, 4326), group = "watersysteem", color = "green", opacity = 0.3) %>%
  leaflet::addProviderTiles("OpenSeaMap", group = "OpenSeaMap") %>%
  leaflet::addCircleMarkers(label = ~htmltools::htmlEscape(paste0(Naam)), group = "all_locations", radius = 4) %>%
  leaflet::addLayersControl(
    baseGroups = c("OSM",  "Esri.WorldTopoMap", "Esri.WorldImagery"),
    overlayGroups = c("all_locations", "watersysteem", "OpenSeaMap")) %>%    #, "KRW waterlichamen 2006"
  leaflet::hideGroup("KRW waterlichamen 2006")



mijnCatalogus <- rwsapi::rws_getParameters(metadata, locatiecode = unique(mijnLocaties$Code)) %>%
  mutate(across(where(is.character), str_trim))
dir.create(file.path(datadir, "ddl"))
dir.create(file.path(datadir, "ddl/metadata"))
write_delim(mijnCatalogus, path = file.path(datadir, "ddl/metadata", paste0(mijnGebied, "_metadata.csv")), delim = ";")

if(!dir.exists(file.path(datadir, "ddl/raw")))dir.create(file.path(datadir, "ddl/raw"))

parametergroups <- read_delim(file.path(datadir, "../", "standaardlijsten", "Parameter_groups2.csv"), delim = ";", guess_max = 10000)

# Selection based on requirements for this version. only temp and salinity
# SPM (Zwevend staof) also needed, but missing from DDL at the moment. 
WQcatalogus <- mijnCatalogus  %>%
  filter(
    parameter_wat_omschrijving %in% c(
      "Temperatuur Oppervlaktewater oC",
      "Saliniteit Oppervlaktewater"#,
      # "Natgewicht Zwevende stof g", # niet zeker dat dit de goede is. CONCTT ZS is niet aanwezig !!
    ),
  )

fysischparams <- 
  parametergroups %>%
  filter(groep_ %in% c("fysische parameters")) %>%
  distinct(Grootheid, parameter.code)

fysischCatalogus <- mijnCatalogus %>%
  filter(parameter.code %in% fysischparams$parameter.code | grootheid.code %in% fysischparams$Grootheid)


korrelparams <- parametergroups %>% 
  filter(grepl("korrel", Omschrijving, ignore.case = T))

korrelCatalogus <- mijnCatalogus %>%
  filter(parameter.code %in% korrelparams$parameter.code | grootheid.code %in% korrelparams$Grootheid)



#==== WQ data ============================== test voor 2016 ========

ophaalCatalogus <- WQcatalogus

nieuwedataophalen <- T

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))
if(!dir.exists(file.path(datadir, "ddl/raw/eutro"))) dir.create(file.path(datadir, "ddl/raw/eutro"))

if(nieuwedataophalen) {
    
  startdate <- paste0(2016, "-01-01T09:00:00.000+01:00")  # hardcoded startyear
  enddate <- paste0(2016, "-12-31T23:00:00.000+01:00")
  
  getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                                eindDatumTijd = enddate, 
                                # mijnCompartiment = "OW",
                                mijnCatalogus = ophaalCatalogus
  )
  
  for(jj in c(1:length(getList))){   #
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response) & nrow(response$content)!=0){
      filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), "ddl_wq.csv", sep = "_")
      write_delim(response$content, path = file.path(datadir, "ddl/raw/eutro", filename), delim = ";")} else next
  }
}

# inspect results
filenamesRaw = list.files(file.path(datadir, "ddl/raw/eutro"), full.names = T, recursive = T)
allFiles <- lapply(filenamesRaw, function(x) read_delim(x, delim = ";", guess_max = 10000,
                                                        col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
df_all <- bind_rows(allFiles)

all_trendlocaties <- df_all %>% filter(year(tijdstip) > 2010) %>%
  group_by(locatie.code, grootheid.code, parameter.code) %>% 
  summarize(n = n()) %>% 
  filter(grootheid.code != "NG") %>%
  # filter(n < 100) %>% 
  unite(c(grootheid.code, parameter.code), col = "grootheid_parameter") %>%
  pivot_wider(names_from = grootheid_parameter, id_cols = locatie.code, values_from = n) %>% 
    arrange(SALNTT_NVT, T_NVT) %>%
  filter(!is.na(SALNTT_NVT) | !is.na(CONCTTE_ZS)) %>% 
  distinct(locatie.code) %>% unlist() %>% unname


#=== ophalen alle jaren ===============================

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))
if(!dir.exists(file.path(datadir, "ddl/raw/eutro_allyears"))) dir.create(file.path(datadir, "ddl/raw/eutro_allyears"))

  ophaalCatalogus2 <- ophaalCatalogus %>% filter(locatie.code %in% all_trendlocaties)
  
  startdate <- paste0(startyear, "-01-01T09:00:00.000+01:00")  # hardcoded startyear
  enddate <- paste0(endyear, "-12-31T23:00:00.000+01:00")
  

  getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                                eindDatumTijd = enddate, 
                                # mijnCompartiment = "OW",
                                mijnCatalogus = ophaalCatalogus2
  )

  for(jj in c(1:length(getList))){   #
    print(paste("getting", jj, ophaalCatalogus2$locatie.code[jj], ophaalCatalogus2$compartiment.code[jj], ophaalCatalogus2$grootheid.code[jj], ophaalCatalogus2$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response) & nrow(response$content)!=0){
      filename <- paste(ophaalCatalogus2$locatie.code[jj], ophaalCatalogus2$compartiment.code[jj], str_replace(ophaalCatalogus2$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus2$parameter.code[jj], str_replace(ophaalCatalogus2$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), "ddl_wq.csv", sep = "_")
      write_delim(response$content, path = file.path(datadir, "ddl/raw/eutro_allyears", filename), delim = ";")} else next
  }

  
  filenamesRaw2 = list.files(file.path(datadir, "ddl/raw/eutro_allyears"), full.names = T, recursive = T)

  allFiles2 <- lapply(filenamesRaw, function(x) read_delim(x, delim = ";", guess_max = 10000,
                                                          col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
  df_all2 <- bind_rows(allFiles)
  write_delim(df_all2, file.path(datadir, "ddl/standard/WQ_TS_trendstations_allyears.csv"), delim = ";")




#=== Fysische data ================================================

ophaalCatalogus <- mijnCatalogus %>%
  filter(
    (
      grepl("golf", parameter_wat_omschrijving, ignore.case = T) |
        grepl("hoogte", parameter_wat_omschrijving, ignore.case = T) |
        grepl("getij", parameter_wat_omschrijving, ignore.case = T)
      ) &
      !grepl("berekend", parameter_wat_omschrijving, ignore.case = T)
  )

# check

ophaalCatalogus %>% 
  distinct(parameter_wat_omschrijving, grootheid.code, compartiment.code, parameter.code) %>% 
  write_delim(file.path(datadir, "ddl/metadata", "fysischeparameters.csv"), delim = ";")
  View()

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))

if(nieuwedataophalen) {
  
  #=== DDL metingen ophalen ( ===========================
  # DDL bevat niet de niewste waarden en niet alle benodigde parameters
  
  # options(digits=22)
  
  dir.create(file.path(datadir, "ddl/raw/fysisch"))
  
  for(year in seq(2016, 2016, 1)){
    
    startdate <- paste0(year, "-01-01T09:00:00.000+01:00")
    enddate <- paste0(year + 1, "-12-31T23:00:00.000+01:00")
    
    
    getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                                  eindDatumTijd = enddate, 
                                  mijnCatalogus = ophaalCatalogus
    )
    
    # ## example json string 
    toJSON(getList[[12]], auto_unbox = T, digits = NA)
    
    # opnemen als functie in rwsapi package
    for(jj in c(167:length(getList))){   #
      print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
      response <- rws_observations2(bodylist = getList[[jj]])
      if(!is.null(response)){
        filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), year, "ddl_wq.csv", sep = "_")
        filename <- str_replace(filename, "/", "_")
        write_delim(response$content, path = file.path(datadir, "ddl/raw/fysisch", filename), delim = ";")} else next
    }
  C}
}

  # inspect results
  filenamesRaw = list.files(file.path(datadir, "ddl/raw/fysisch"), full.names = T, recursive = T)
  allFiles <- lapply(filenamesRaw, function(x) read_delim(x, delim = ";", guess_max = 10000, n_max = 50, 
                                                          col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
  df_all <- bind_rows(allFiles)
  
  wave_trendlocaties <- df_all %>% filter(year(tijdstip) > 2010) %>%
    filter(grepl("golf", parameter.wat.omschrijving, ignore.case = T)) %>%
    group_by(locatie.code, parameter.wat.omschrijving) %>% 
    summarize(n = n()) %>% 
    pivot_wider(names_from = locatie.code, id_cols = parameter.wat.omschrijving, values_from = n) %>%  
    write_delim(file.path(datadir, "ddl/standard/wave_locations.csv"), delim = ";")
    distinct(locatie.code) %>% unlist() %>% unname
  
    level_trendlocaties <- df_all %>% filter(year(tijdstip) > 2010) %>%
      filter(grepl("waterhoogte", parameter.wat.omschrijving, ignore.case = T)) %>%
      group_by(locatie.code, parameter.wat.omschrijving) %>% 
      summarize(n = n()) %>% 
      pivot_wider(names_from = locatie.code, id_cols = parameter.wat.omschrijving, values_from = n) %>%  
      write_delim(file.path(datadir, "ddl/standard/level_locations.csv"), delim = ";")
    distinct(locatie.code) %>% unlist() %>% unname
    
  
#========korrelCatalogus ophalen====================================

# ophaalCatalogus <- mijnCatalogus[mijnCatalogus$parameter.code ==  "ZS",]
ophaalCatalogus <- korrelCatalogus 

nieuwedataophalen <- T

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))
if(!dir.exists(file.path(datadir, "ddl/raw/korrelgrootte"))) dir.create(file.path(datadir, "ddl/raw/korrelgrootte"))

if(nieuwedataophalen) {
  

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
  for(jj in c(1:length(getList))){   #
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response)){
      filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), "ddl_wq.csv", sep = "_")
      write_delim(response$content, path = file.path(datadir, "ddl/raw/korrelgrootte", filename), delim = ";")} else next
  }
}

