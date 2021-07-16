## voorbereiding van digitale watersysteemrapportage

####===  install packages and dependencies ========
source("r/runThisFirst.R")

mijnCatalogus <- read_delim(file.path(datadir, "ddl/metadata", paste0(mijnGebied, "_metadata.csv")), delim = ";")

# parametergroups <- read_delim(file.path(datadir, "../", "standaardlijsten", "Parameter_groups2.csv"), delim = ";", guess_max = 10000)
# korrelparams <- parametergroups %>% 
#   filter(grepl("korrel", Omschrijving, ignore.case = T))

korrelCatalogus <- mijnCatalogus %>%
  filter(
    grootheid.code == "KGF" |
    grepl(pattern = "korrel", parameter_wat_omschrijving)
    )


#========korrelCatalogus ophalen====================================

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
  for(jj in c(198:length(getList))){   #
    print(paste("getting", jj, ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], ophaalCatalogus$grootheid.code[jj], ophaalCatalogus$parameter.code[jj]))
    response <- rws_observations2(bodylist = getList[[jj]])
    if(!is.null(response & ncol(response$content != 0))){
      filename <- paste(ophaalCatalogus$locatie.code[jj], ophaalCatalogus$compartiment.code[jj], str_replace(ophaalCatalogus$grootheid.code[jj], "[^A-Za-z0-9]+", "_"), ophaalCatalogus$parameter.code[jj], str_replace(ophaalCatalogus$hoedanigheid.code[jj], "[^A-Za-z0-9]+", "_"), "ddl_wq.csv", sep = "_")
      write_delim(response$content, path = file.path(datadir, "ddl/raw/korrelgrootte", filename), delim = ";")} else next
  }
}


# aggregate data

# opwerken korrelgrootte
# 
source("r/runThisFirst.R")

allFiles = list()

filenamesRawKorrel = list.files(file.path(datadir, "ddl/raw/korrelgrootte"), full.names = T, recursive = T)
allFiles <- lapply(filenamesRawKorrel, function(x) 
  read_delim(x, delim = ";", 
             # col_types = 'cccccccccccn',
             guess_max = 100000
  ) %>%
    mutate(tijdstip = as_datetime(as.character(tijdstip), tz = "CET")) %>%
    filter(year(tijdstip) == median(year(tijdstip))) # to filter out first tijdstip in next year
  
)

# conversion should not be necessary, when reading is done as above
# allFiles <- map(allFiles, function(x) x %>% mutate(kwaliteitswaarde.code = as.character(kwaliteitswaarde.code)))
allFiles <- map(allFiles, function(x) x = x %>% select(-bemonsteringsapparaat.code))
allFiles <- map(allFiles, function(x) x = x %>% mutate(kwaliteitswaarde.code = as.character(kwaliteitswaarde.code)))
df_all <- bind_rows(allFiles) %>%
  filter(kwaliteitswaarde.code == "00", numeriekewaarde < 1e11)
table(df_all$parameter.wat.omschrijving) %>% View

# save(df_all, file = file.path(datadir, "ddl", "standard", paste0("korrelgrootte", today(), ".Rdata")))
write_delim(df_all, file.path(datadir, "ddl", "standard", paste0("korrelgrootte", today(), ".csv")), delim = ";")

rm(allFiles, df_all)



