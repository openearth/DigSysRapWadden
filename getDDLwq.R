

####===  install packages and dependencies ========
source("r/runThisFirst.R")


mijnCatalogus <- read_delim(file.path(datadir, "ddl/metadata", paste0(mijnGebied, "_metadata.csv")), delim = ";")

# Selection based on requirements for this version. only temp and salinity
# SPM (Zwevend staof) also needed, but missing from DDL at the moment. 
WQcatalogus <- mijnCatalogus  %>%
  filter(
    parameter_wat_omschrijving %in% c(
      "Temperatuur Oppervlaktewater oC",
      "Saliniteit Oppervlaktewater",
      "(massa)Concentratie Zwevende stof in Oppervlaktewater mg/l"  # This one is lacking now (june 2021)
    ),
  )


#=== ophalen alle jaren ===============================

if(!dir.exists(file.path(datadir, "ddl/raw"))) dir.create(file.path(datadir, "ddl/raw"))
if(!dir.exists(file.path(datadir, "ddl/raw/eutro_allyears"))) dir.create(file.path(datadir, "ddl/raw/eutro_allyears"))

ophaalCatalogus2 <- ophaalCatalogus %>% filter(locatie.code %in% trendLocaties)

startdate <- paste0(startyear, "-01-01T09:00:00.000+01:00")  # hardcoded startyear
enddate <- paste0(endyear, "-12-31T23:00:00.000+01:00")


getList <- rws_makeDDLapiList(beginDatumTijd = startdate, 
                              eindDatumTijd = enddate, 
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

allFiles <- lapply(filenamesRaw, function(x) read_delim(x, delim = ";", guess_max = 10000,
                                                         col_types = 'nccnnnccncccncccccccccccccccccccccccccccccccccccn'))
df_all <- bind_rows(allFiles)
write_delim(df_all, file.path(datadir, "ddl/standard/WQ_TS_trendstations_allyears.csv"), delim = ";")

