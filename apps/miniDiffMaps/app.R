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

#=== read data =================================================================

# diffMapDir <- "p:/11202493--systeemrap-grevelingen/1_data/Wadden/RWS/bathymetrie/processing_tiles/volledige_bodemkaarten_BenO_Wadden/verschilkaarten_nieuwedata/"

wadden <- sf::read_sf("https://datahuiswadden.openearth.nl/geoserver/dhw/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=dhw%3Akombergingen&maxFeatures=50&outputFormat=application%2Fjson") %>%
  dplyr::select(id) %>%
  sf::st_transform(28992) %>%
  sf::st_simplify()

diffMapDir <- "data"

files <- list.files(diffMapDir, pattern = ".RDS")

diffYears <- sub(".RDS", "", files)


#=== Preparation ===============================================================

# diffMaps <- lapply(
#   files,
#   function(x){
#     terra::rast(
#       file.path(diffMapDir, x)
#     ) %>%
#       terra::aggregate(2) %>%
#       terra::mask(wadden) %>%
#       terra::project("epsg:4326") %>%
#     saveRDS(file = file.path(diffMapDir, paste0(sub(".tiff", "", x),  ".RDS")))
#   }
# )


#=== user interface ============================================================

ui <- miniPage(
  gadgetTitleBar("Verschilkaarten Bathymetrie"),
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
      diffYears
    ),
    numericInput(
      "maxScale",
      "max scale",
      10,
      5,
      20
    ),
    actionButton(
      inputId = "btn", 
      label = "refresh scale",
      width = "50px"
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
    
    pal <- colorNumeric(c("red", "white", "blue"), c(-maxScale$values, maxScale$values),
                        na.color = "transparent")
    
    leaflet::leaflet() %>%
      leaflet::addTiles(group = "OpenStreetMap") %>%
      addProviderTiles(provider = "Esri.WorldImagery", group = "ESRI worldimagery") %>%
      leaflet::addRasterImage(diff, colors = pal, opacity = 0.6, group = "verschilkaart") %>%
      leaflet::addLegend(position = "bottomright", pal = pal, values = c(-maxScale$values, maxScale$values)) %>%
      leaflet::addLayersControl(
        baseGroups = c("OpenStreetMap", "ESRI worldimagery"), 
        overlayGroups = c("verschilkaart"),
        options = layersControlOptions(noHide = T, collapsed = FALSE),
      )
  })
}

# runGadget(ui, server, viewer = paneViewer())
shinyApp(ui, server)
