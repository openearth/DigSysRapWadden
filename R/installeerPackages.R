
# first time when installing this project

# renv::activate()
# renv::restore()



require("shiny")
require("rmarkdown")
require("sf")
require("bookdown")
require("pander")
require("data.table")
# require("strucchange")
require("zoo")
require("xts")
require("devtools")
require("httr")
require("lubridate")
require("rlist")
require("mblm")
require("leaflet")
require("webshot")
require("scales")
require("RColorBrewer")
require("tidyverse")
require("Tides")
require("plotly")
require("readxl")
require("tidync")
require("ggthemes")
require("leaflet.extras")
require("oce")
require("downloadthis")
require("rwsapi")
require("gstat")
require("raster")
require("reshape2")
require("jpeg")

select <- dplyr::select
addLegend <- leaflet::addLegend

# if(!require("rwsapi", character.only = TRUE)){
#   devtools::install_github("wstolte/rwsapi")
#   library("rwsapi", character.only = TRUE)
# }


# for embedding screenshots of interactive html into pdf documents:
# webshot::install_phantomjs()
