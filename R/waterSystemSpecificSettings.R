
# still to be finalised

runonline = F
local = F

startyear <- 1970
endyear <- 2020

# voor naamgeving directory etc
mijnGebied <- "Wadden"
# voor selectie van data uit de DDL op basis van waterlichaam naam
mijnGebieden <- c("Wadden", "Eems", "Dollard")

# RWS stations with long term data
trendLocaties <- c(
  "ROTTMPT3", "VLIESM", "TERSLG10", "BOCHTVWTM", "DANTZGT", "DOOVBWT", "GROOTGND", "HUIBGOT", "MARSDND",  
  "BOOMKDP", "BOONTNMPL", "DOOVBMDN", "EEMSHVSMPL", "OORT", "WESTKSRK")


trendLocatiesFysisch <- c()

# time periods
wintermonths <- c(10, 11, 12, 1, 2, 3)
summermonths <- c(4,5,6,7,8,9)
springmonths <- c(3,4,5)

#directories

# p dir with frozen data
projectDataPath <- "p:/11202493--systeemrap-grevelingen/1_data"

# mirror of the p directory above
ThreddsDataPath <- "https://watersysteemdata.deltares.nl/thredds/fileServer/watersysteemdata"

# calalogue of the thredds server wadden
cataloguePath <- "https://watersysteemdata.deltares.nl/thredds/catalog/watersysteemdata/Wadden/catalog.html"
# calalogue of vaklodingen thredds server
catalogueVaklodingenPath <- "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/catalog.nc"


# local path !!!!! depends on manual copy from p. adjust name if necessary
localDataPath <- "../1_data"

commondir = ifelse(
  runonline, file.path(ThreddsDataPath), 
  ifelse(
    local, localDataPath, 
    projectDataPath))

datadir <- file.path(commondir, mijnGebied)

# events <- readxl::read_excel(file.path(datadir, "Beheer", "raw", "BeheerData.xlsx"))
# plotevents <- ggplot(events) + geom_rect(aes(xmin = date, xmax = enddate, ymin = 0, ymax = 1, fill = eventnaam))
