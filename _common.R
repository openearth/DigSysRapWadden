# example R options set globally

# options(width = 60)

source("r/runThisFirst.R")

# example chunk options set globally
knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  warning = F,
  message = F,
  echo = F,
  cache = T,
  out.width = "100%",
  cache.lazy = FALSE
  )

# require(tidyverse)
# require(lubridate)
# require(sf)
# require(stringr)
# require(raster)