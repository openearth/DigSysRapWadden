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
                                top = "2%", left = "5%", width = "550px", height = "100px",
                                draggable = T,
                                tags$style(type = 'text/css', '#big_slider .irs-grid-text {font-size: 14px}'), 
                                div(id = 'big_slider',
                                    sliderInput(
                                      inputId = "endyear", 
                                      label = NULL, 
                                      min = 1920, 
                                      max = 2020, 
                                      value = c(2005,2020), 
                                      ticks = T,
                                      # step = 10, 
                                      sep = "", 
                                      dragRange = TRUE, 
                                      width = "500px"
                                    ), # animate = animationOptions(loop = F, interval = 2000), 
                                    shiny::checkboxInput("hillshade", "hillshade", TRUE)
                                )#div close,
                  )
                )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  
  request <- reactive({list(dataset = "vaklodingen", 
                            begin_date = paste0(as.integer(max(c(input$endyear[1]), 1926))-0, "-01-01T00:00:00.000Z"), 
                            end_date = paste0(input$endyear[2], "-12-31T23:59:00.000Z"), 
                            min = -30L, 
                            max = 10L, 
                            hillshade = input$hillshade)
  })
  
  jsonInput <- reactive(toJSON(request(), auto_unbox = T))
  
  res <- reactive({
    POST(
      "https://hydro-engine.ey.r.appspot.com//get_bathymetry", 
      body = jsonInput(), 
      encode = "form", 
      verbose(), 
      content_type("application/json")
    )
  })
  
  
  output$map = renderLeaflet({
    
    
    # run request
    
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
      addTiles(content(res())$url, group = "bathymetrie") %>%
      # addWMSTiles(baseUrl = "https://opengeodata.wmr.wur.nl/geoserver/WS3shp/wms",
      #             layers = "WS3shp:ws3_tidalbasins",
      #             options = WMSTileOptions(format = "image/png", transparent = TRUE),
      #             group = "vakken"
      # ) %>%
      # !!!! werkt niet netjes. de polygonen zijn niet zichtbaar bovenop de bathymetrie
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
        options = layersControlOptions(noHide = T, collapsed = FALSE),
      ) #%>%
    # leaflet::addLegend(
    #     colors = unlist(strsplit(content(res())$palette, ",")),
    #     labels = round(seq(request()$min/100, request()$max/100, length.out = 20), 0), opacity = 1
    # )
  })
  
  # Use a separate observer to recreate the legend as needed.
  observe({
    proxy <- leafletProxy("map")
    
    # Remove any existing legend, and only if the legend is
    # enabled, create a new one.
    proxy %>% 
      clearControls() %>%
      leaflet::addLegend(
        colors = unlist(strsplit(content(res())$palette, ",")),
        labels = round(seq(request()$min, request()$max, length.out = 20), 0), opacity = 1
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
