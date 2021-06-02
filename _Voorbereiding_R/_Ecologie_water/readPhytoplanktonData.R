#-----------------------------------------------------------------------#
####                       Import data                               ####
#-----------------------------------------------------------------------#
# phytoplankton data verkregen via Theo Prins. 
# Prins et al. (2006)
# 
# laad rapportage settings
source("waterSystemSpecificSettings.R")
require(tidyverse)

datadir <- "..\\1_data\\biologie\\fytoplankton"
files <- unzip(file.path(datadir, "raw", "PhytoplanktonData1990_2016.zip"), list = T)
mijnFiles <- files[grep(mijnGebied, files$Name),]

phytolist <- list()
for(ii in seq(1:length(mijnFiles$Name))){
  print(ii)
  print(mijnFiles[ii,1])
  tempdf <- read.table(
    unz(
      file.path(datadir, "raw", "PhytoplanktonData1990_2016.zip"
      ), filename = mijnFiles[ii,1]
    ), stringsAsFactors = FALSE , sep = ";", header = T,  encoding = "unknown", dec = "."
  )
  phytolist[[ii]] <- tempdf
  rm(tempdf)
}

phyto <- bind_rows(phytolist)
names(phyto) <- tolower(names(phyto))
rm(phytolist)

worms_match <- read_delim(file.path(datadir, "raw", "phyto_species_corrected_matched2.csv"), delim = ";", guess_max = 0)
wat_bewerkt <- read_delim(file.path(datadir, "raw", "TBL-WAT-BEWERKT2.csv"), delim = ";", na = "NA")

df.phytoplankton <- phyto %>%
  left_join(wat_bewerkt[,c(2,9,11,16,28,29)], by = c("btxoms" = "btxoms", "biovlme_" = "BIOVLME_")) %>% 
  gather(key = grootheid, value = waarde, biomassa, cells.l) %>% 
  mutate(datum = lubridate::as_date(date, format = "%d-%m-%y", tz = "CET")) %>%
  mutate(eenheid = case_when(
    grootheid == "cells.l" ~ "n/l",
    grootheid == "biovlme_" ~ "um3/cell",
    grootheid == "biomassa" ~ "ugC/l"
  )) %>% #str()
  select(gebied,
         locatie = loccod,
         datum,
         diepte = refvlk,
         soort = btxoms,
         soort_info = sgkoms,
         grootheid,
         eenheid,
         waarde,
         biovolume = biovlme_,
         chlfa = CHLFa_,
         trofie = Trofie,
         ecologische_informatie = `Ecologische informatie`,
         benthisch = Benthisch
         ) %>%
  left_join(worms_match, by = c(soort = "speciesname_original")) %>%
  filter(biovolume > 0 & !is.na(biovolume)) %>%
  mutate(
    # change order of stations if necessary
    # loccod = recode_factor(loccod,
    #                        `1` = "SCHAARVODDL",
    #                        `2` = "HANSWGL",
    #                        `3` = "VLISSGBISSVH"
    # ),
    jaar = lubridate::year(datum),
    maand = lubridate::month(datum),
    week = lubridate::week(datum),
    dag = lubridate::yday(datum)
  )

# write_csv(df.phytoplankton, file.path(datadir, "base", "fytoplankton_grevelingen_1990_2016.csv"))
