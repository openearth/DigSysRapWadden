library(shiny)
library(miniUI)
# library(leaflet)
library(tidyverse)
library(raster)

diffMapDir <- "p:/11202493--systeemrap-grevelingen/1_data/Wadden/RWS/bathymetrie/processing_tiles/morphopy-v2/difference_maps"

# list of available years
doeljaren <- c("1927", "1949", "1971", "1975", "1985","1991", "2003", "2009", "2015")

diffYears <- expand.grid(doeljaren, doeljaren) %>%
  dplyr::mutate(Var1 = as.integer(as.character(Var1)), Var2 = as.integer(as.character(Var2))) %>%
  dplyr::filter(Var1 < Var2) %>%
  dplyr::mutate(
    periode = paste(Var1, Var2, sep = "-"),
    periodeNaam = paste(Var2, Var1, sep = "-"),
  ) %>%
  dplyr::arrange(-Var2, -Var1)

# rasterlist <- list.files(diffMapDir, full.names = TRUE)

# test color scale and plotting
cuts=c(-30,-20,-10,0,10,20,30) #set breaks
pal <- colorRampPalette(c("blue","white", "red"))

ui <- miniPage(
  gadgetTitleBar("Verschilkaarten Bathymetrie"),
  miniContentPanel(padding = 0,
                   plotOutput("diffPlot", height = "100%")
  ),
  miniButtonBlock(
    selectInput("periode",
                "kies periode:",
                diffYears$periodeNaam)
  )
)

server <- function(input, output, session) {
  output$diffPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    diff <- raster(file.path(diffMapDir, paste0(input$periode, ".tiff")))
    plot(diff, breaks=cuts, col = pal(5))
  })
}

runGadget(ui, server, viewer = paneViewer())
#' @examples
#' options(shiny.autoreload=TRUE)
#' shiny::runApp("test2.R", launch.browser = getOption("viewer", TRUE))