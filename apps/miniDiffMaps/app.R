library(shiny)
library(miniUI)
# library(leaflet)
library(tidyverse)
library(raster)
library(colorRamps)
library(sf)
library(terra)
library(leaflet)

#=== css styling for selectinput box ===========================================
CSS <- "
.selectize-dropdown {
  bottom: 100% !important; 
  top: auto !important;
}
"

#=== Preparation ======= run once ============================================

prepare = FALSE

if(prepare) {
  
  wadden <- sf::read_sf("https://datahuiswadden.openearth.nl/geoserver/dhw/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=dhw%3Akombergingen&maxFeatures=50&outputFormat=application%2Fjson") %>%
    dplyr::select(id) %>%
    sf::st_transform(28992) %>%
    sf::st_simplify()

    diffMapDirRDS <- "apps/miniDiffMaps/data"
  diffMapDirPrep <- "p:/11202493--systeemrap-grevelingen/1_data/Wadden/RWS/bathymetrie/processing_tiles/volledige_bodemkaarten_BenO_Wadden/morphopy/verschilkaarten/"
  
  filesprep <- list.files(diffMapDirPrep, pattern = "tiff", full.names = FALSE)
  
  diffMaps <- lapply(
    filesprep,
    function(x){
      terra::rast(
        file.path(diffMapDirPrep, x)
      ) %>%
        terra::aggregate(2) %>%
        terra::mask(wadden) %>%
        terra::project("epsg:4326") %>%
        saveRDS(file = file.path(diffMapDirRDS, paste0(sub(".tiff", "", x),  ".RDS")))
    }
  )
}


diffMapDir <- "data"
files <- list.files(diffMapDir, pattern = ".RDS")
diffYears <- sub(".RDS", "", files)

#=== user interface ============================================================

ui <- miniPage(
  miniTitleBar("Verschilkaarten Bathymetrie"),
  miniContentPanel(padding = 0,
                   leafletOutput("diffPlot", height = "100%")
  ),
  miniButtonBlock(
    tags$head(
      tags$style(HTML(CSS))
    ),
    selectizeInput(
      "periode",
      "kies periode:",
      diffYears, 
      width = "30%"
    ),
    numericInput(
      "maxScale",
      "max scale in meters",
      10,
      5,
      30, 
      width = "30%"
    ),
    actionButton(
      inputId = "btn", 
      label = "refresh scale", 
      width = "30%"
    )
  )
)

#=== Server ====================================================================

server <- function(input, output, session) {
  
  maxScale <- reactiveValues()
  
  observeEvent(c(input$btn),{
    maxScale$values <- input$maxScale
  }, 
  ignoreNULL = FALSE)
  
  output$diffPlot <- renderLeaflet({
    
    diff <- terra::rast(
      file.path(diffMapDir, paste0(input$periode, ".RDS"))
    )
    
    #=== colors for plot raster ====================================================
    
    pal <- colorNumeric(c("orange", "white", "blue"), c(-maxScale$values, maxScale$values),
                        na.color = "transparent")
    
    leaflet::leaflet() %>%
      leaflet::addTiles(group = "OpenStreetMap") %>%
      addProviderTiles(provider = "Esri.WorldImagery", group = "ESRI worldimagery") %>%
      leaflet::addRasterImage(diff, colors = pal, opacity = 0.6, group = "verschilkaart") %>%
      leaflet::addLegend(labFormat = labelFormat(suffix = " m"), position = "bottomright", pal = pal, values = c(-maxScale$values, maxScale$values)) %>%
      leaflet::addLayersControl(
        baseGroups = c("OpenStreetMap", "ESRI worldimagery"), 
        overlayGroups = c("verschilkaart"),
        options = layersControlOptions(noHide = T, collapsed = FALSE),
      )
  })
}

# runGadget(ui, server, viewer = paneViewer())
shinyApp(ui, server)
