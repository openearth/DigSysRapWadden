#
# App written by willem.stolte@deltares.nl and giorgio.santinelli@deltares.nl
# 

library(shiny)
library(leaflet)
library(httr)
library(jsonlite)
library(sf)
library(tidyverse)
library(ows4R)
library(leaflet.extras)

# voorbereiding. alleen draaien als andere polygoon nodig is. 
# wfs_wmr <- "https://opengeodata.wmr.wur.nl/geoserver/WS3shp/ows"
# url <- parse_url(wfs_wmr)
# url$query <- list(service = "wfs",
#                   #version = "2.0.0", # optional
#                   request = "GetFeature",
#                   typename = "WS3shp:ws3_tidalbasins",
#                   srsName = "EPSG:4326",
#                   outputFormat = "application/json"
# )
# request <- build_url(url)
# polygonsInRaster <- c(35, 36, 37, 29, 30, 31, 32, 38, 33, 34)
# poly <- read_sf(request) %>%
#   st_simplify() %>% #Lambert2008
# dplyr::filter(fid %in% polygonsInRaster)
# st_write(poly, "apps/bathymetrywadden/vakken.geojson")

layers <- c(
  `1997` = "mosaic_ASC_1991_1997_def",
  `2002` = "mosaic_ASC_1997_2002_def",
  `2008` = "mosaic_ASC_2003_2008_def",
  `2014` = "mosaic_ASC_2009_2014_def",
  `2020` = "mosaic_ASC_2015_2020_def"
)

jaren = names(layers)

wms_base <- "https://datahuiswadden.openearth.nl/geoserver/ows"

poly <- st_read("vakken.geojson")

ui <- fluidPage(title = "Wadden Sea Bathymetry",
                tags$style("
        #controls {
          background-color: #ddd;
          opacity: 0.8;
          font-size:14px
        }
        #controls:hover{
          opacity: 1;
        }
               "),
                fluidRow(
                  column(width = 12,
                         # to fill full height of page
                         tags$style(type = "text/css", "#map {height: calc(100vh - 10px) !important;}"),
                         leafletOutput("map")
                  ),
                  absolutePanel(id = "controls", class = "panel panel-default", align = 'center', 
                                top = "2%", left = "5%", width = "300px", height = "75px",
                                draggable = T,
                                tags$style(type = 'text/css', '#big_slider .irs-grid-text {font-size: 14px}'), 
                                div(id = 'big_slider',
                                    selectInput(
                                      inputId = "endyear", 
                                      label = "select bathymetry", 
                                      choices = names(layers), 
                                      selected = tail(names(layers),1), 
                                      width = "250px"
                                    )
                                )#div close,
                  )
                )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  # initialize map
  output$map = renderLeaflet({
    leaflet() %>% 
      setView(5.0, 53.0, zoom = 12) 
  })
  
  # output$map <- renderLeaflet({
  observe({
    
    leafletProxy("map") %>%
      clearTiles() %>%
      addTiles(group = "OSM") %>%
      addProviderTiles(provider = "Esri.WorldImagery", group = "ESRI worldimagery") %>%
      leaflet::clearImages() %>%
      addWMSTiles(
        baseUrl = wms_base,
        layers = paste0('bathymetrie:', unname(layers[input$endyear])),
        # layers = "bathymetrie:mosaic_ASC_2015_2020_def", # example
        options = WMSTileOptions(
          format = "image/png",
          transparent = TRUE,
          version = "1.3.1"),
        group = "bathymetrie"
      ) %>%
    addPolygons(
        data = poly,
        fill = F,
        label = ~name,
        labelOptions = labelOptions(noHide = T),
        group = "vakken",
        color = "red") %>%
      leaflet::addLayersControl(
        baseGroups = c("OSM", "ESRI worldimagery"), 
        overlayGroups = c("vakken", "bathymetrie"),
        options = layersControlOptions(
          noHide = T, 
          collapsed = FALSE,
          position = 'bottomleft'),
      )
  })
  
  # Use a separate observer to recreate the legend as needed.
  observe({
    proxy <- leafletProxy("map")

    # Remove any existing legend, and only if the legend is
    # enabled, create a new one.
    proxy %>%
      clearControls() %>%
      leaflet.extras::addWMSLegend(
        uri=paste0(sub("ows", "wms", wms_base),
                   "?request=",
                   "GetLegendGraphic&version=1.3.0&",
                   "format=image/png&layer=",
                   "bathymetrie:",
                   unname(layers[input$endyear])
                   )
      )
  })
  
  # keep zooming level when input changes
  # after e.g. https://stackoverflow.com/questions/48397262/in-shiny-how-to-fix-lock-leaflet-map-view-zoom-and-center
  
  zoom <- reactive({
    ifelse(is.null(input$map_zoom),3,input$map_zoom)
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
