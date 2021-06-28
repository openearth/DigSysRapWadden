

getPackage <- function(pkg){
  if(!require(pkg, character.only = TRUE)){
    install.packages(pkg, dependencies = TRUE)
    # library(pkg, character.only = TRUE)
  }
  return(TRUE)
}

getPackage("shiny")
getPackage("rmarkdown")
getPackage("rgdal")
getPackage("sf")
getPackage("bookdown")
getPackage("pander")
getPackage("data.table")
getPackage("strucchange")
getPackage("zoo")
getPackage("xts")
getPackage("devtools")
getPackage("httr")
getPackage("lubridate")
getPackage("rlist")
getPackage("mblm")
getPackage("leaflet")
getPackage("webshot")
getPackage("scales")
getPackage("RColorBrewer")
getPackage("tidyverse")


if(!require("rwsapi", character.only = TRUE)){
  devtools::install_github("wstolte/rwsapi")
  library("rwsapi", character.only = TRUE)
}


# for embedding screenshots of interactive html into pdf documents:
# webshot::install_phantomjs()
