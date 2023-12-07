#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
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
cuts=c(-3,-2,-1,0,1,2,3) #set breaks
pal <- colorRampPalette(c("blue","white", "red"))

# Remove grid points that do not occur in all grids. Check with calculations in other part (valid points). 

# diff <- raster(file.path(diffMapDir, paste0(diffYears$periode[1], ".tiff")))

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Verschilkaarten bathymetrie"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput("periode",
                        "kies periode:",
                        diffYears$periodeNaam)
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("diffPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$diffPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
      diff <- raster(file.path(diffMapDir, paste0(input$periode, ".tiff")))
      plot(diff, breaks=cuts, col = pal(5))
      
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
