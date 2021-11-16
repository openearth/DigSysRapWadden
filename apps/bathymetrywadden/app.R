#
# App written by willem.stolte@deltares.nl and giorgio.santinelli@deltares.nl
# 

library(shiny)
library(leaflet)
library(httr)
library(jsonlite)

ui <- fluidPage(title = "Wadden Sea Bathymetry",
                     fluidRow(
                         column(width = 12,
                             sliderInput("endyear", "Jaar", 1990, 2020, 2020, sep = ""),
                             # to fill full height of page
                             tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"),
                             leafletOutput("map")
                         )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$map <- renderLeaflet({
        
        request <- list(dataset = "vaklodingen", 
                        begin_date = paste0(as.integer(input$endyear)-10, "-01-01T00:00:00.000Z"), 
                        end_date = paste0(input$endyear, "-12-31T23:59:00.000Z"), 
                        min = -3000L, 
                        max = 1000L, 
                        hillshade = TRUE)
        
        jsonInput2012 <- toJSON(request, auto_unbox = T)
        
        # run request
        res <- POST("https://hydro-engine.ey.r.appspot.com//get_bathymetry", body = jsonInput2012, encode = "form", verbose(), content_type("application/json"))
        
        # get url from response, which is a wmts service
        # content(res)$url
        
        # form map on a background
        leaflet() %>%
            # addTiles("http://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png") %>%
            addTiles("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png") %>%
            addTiles(content(res)$url) %>% setView(5.0, 53.0, zoom = 11)    
        })
}

# Run the application 
shinyApp(ui = ui, server = server)
