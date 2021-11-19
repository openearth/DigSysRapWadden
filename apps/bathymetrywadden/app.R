#
# App written by willem.stolte@deltares.nl and giorgio.santinelli@deltares.nl
# 

library(shiny)
library(leaflet)
library(httr)
library(jsonlite)

ui <- fluidPage(title = "Wadden Sea Bathymetry",
                tags$style("
        #controls {
          background-color: #ddd;
          opacity: 0.8;
          font-size:20px
        }
        #controls:hover{
          opacity: 1;
        }
               "),
                     fluidRow(
                         column(width = 12,
                             # to fill full height of page
                             tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"),
                             leafletOutput("map")
                         ),
                         absolutePanel(id = "controls", class = "panel panel-default",
                                       top = "5%", left = "5%", width = "600px",
                                       draggable = T,
                                       tags$style(type = 'text/css', '#big_slider .irs-grid-text {font-size: 14px}'), 
                                       div(id = 'big_slider',
                                           sliderInput("endyear", "Jaar", 1926, 2020, c(2005,2020), sep = "", dragRange = TRUE, width = "500px"),
                                           shiny::checkboxInput("hillshade", "hillshade", TRUE)
                                       )#div close,
                         )
                     )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$map <- renderLeaflet({
        request <- list(dataset = "vaklodingen", 
                        begin_date = paste0(as.integer(input$endyear[1])-0, "-01-01T00:00:00.000Z"), 
                        end_date = paste0(input$endyear[2], "-12-31T23:59:00.000Z"), 
                        min = -3000L, 
                        max = 1000L, 
                        hillshade = input$hillshade)
        jsonInput2012 <- toJSON(request, auto_unbox = T)
        # run request
        res <- POST(
            "https://hydro-engine.ey.r.appspot.com//get_bathymetry", 
            body = jsonInput2012, 
            encode = "form", 
            verbose(), 
            content_type("application/json")
        )
        # form map on a background
        leaflet() %>%
            addTiles(group = "OSM") %>%
            # addProviderTiles(provider = "Esri.WorldImagery", group = "ESRI worldimagery") %>%
            addTiles("http://{s}.{z}/{x}/{y}.png", group = "bathymetrie") %>%
            # addTiles("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png") %>%
            addTiles(content(res)$url) %>% setView(5.0, 53.0, zoom = 12) %>%
            # leaflet::addLayersControl(baseGroups = c("OSM", "ESRI worldimagery")) %>%
            leaflet::addLegend(
                colors = unlist(strsplit(content(res)$palette, ",")), 
                labels = round(seq(request$min/100, request$max/100, length.out = 20), 0), opacity = 1
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
