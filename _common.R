# example R options set globally

# options(width = 60)

concept = TRUE

# source("r/runThisFirst.R")
source("r/installeerPackages.R")
source("r/waterSystemSpecificSettings.R")
source("r/plotfuncties.r")
source("r/Breakpoints_functions.r")

# example chunk options set globally
knitr::opts_chunk$set(
  comment = "#>",
  # collapse = TRUE,
  warning = F,
  message = F,
  echo = F,
  # cache = T,
  out.width = "100%",
  cache.lazy = FALSE
  )

# require(tidyverse)
# require(lubridate)
# require(sf)
# require(stringr)
# require(raster)

