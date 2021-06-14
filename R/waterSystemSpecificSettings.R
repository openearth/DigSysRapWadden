
# still to be finalised

runonline = F
local = T

startyear <- 2000
endyear <- 2020

# voor naamgeving directory etc
mijnGebied <- "Wadden"
# voor selectie van data uit de DDL op basis van waterlichaam naam
mijnGebieden <- c("Wadden", "Eems", "Dollard")

trendLocaties <- c(

)

# time periods
wintermonths <- c(10, 11, 12, 1, 2, 3)
summermonths <- c(4,5,6,7,8,9)
springmonths <- c(3,4,5)

#directories

cataloguePath <- "https://watersysteemdata.deltares.nl/thredds/catalog/watersysteemdata/Wadden/catalog.html"

ThreddsDataPath <- "https://watersysteemdata.deltares.nl/thredds/fileServer/watersysteemdata"

#projectDataPath <- "p:/11202493--systeemrap-grevelingen/1_data"

localDataPath <- "../1_data"

commondir = ifelse(
  runonline, file.path(ThreddsDataPath), 
  ifelse(
    local, localDataPath, 
    projectDataPath))

datadir <- file.path(commondir, mijnGebied)

# events <- readxl::read_excel(file.path(datadir, "Beheer", "raw", "BeheerData.xlsx"))
# plotevents <- ggplot(events) + geom_rect(aes(xmin = date, xmax = enddate, ymin = 0, ymax = 1, fill = eventnaam))
