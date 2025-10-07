
library(shiny)
library(miniUI)
# library(leaflet)
library(tidyverse)
library(plotly)

#=== css styling for selectinput box ===========================================

CSS <- "
.selectize-dropdown {
  bottom: 100% !important;
  top: auto !important;
}
"

#==== load data ===========================================================

arealenfiles <- c(
  "Arealen_ZKL_18.6jr.csv",
  "Arealen_PGAT_18.6jr.csv",
  "Arealen_AME_18.6jr.csv",
  "Arealen_VLIE_18.6jr.csv",
  "Arealen_ELD_18.6jr.csv",
  "Arealen_MD_18.6jr.csv"
)

read_csv(arealenfiles[1])
arealen <- map(1:length(arealenfiles), \(x) read_csv(arealenfiles[x])) %>% bind_rows()


#=== user interface ============================================================

ui <- miniPage(
  miniTitleBar("Plot arealenverloop Waddenzee"),
  miniContentPanel(padding = 0,
                   plotlyOutput("areaalPlot", height = "100%")
  ),
  miniButtonBlock(
    tags$head(
      tags$style(HTML(CSS))
    ),
    selectizeInput(
      "diepteKlasse",
      "kies diepteklasse:",
      unique(arealen$dep),
      width = "30%"
    )
  )
)

#=== Server ====================================================================

server <- function(input, output, session) {
  
  output$areaalPlot <- renderPlotly({
    
    arealenSelectie <- arealen %>%
      filter(dep == input$diepteKlasse)
    
    p <- ggplot(arealenSelectie, aes(jaar, area)) +
      geom_line(aes(color = basin), linewidth = 1) +
      geom_point(aes(color = basin), shape = 21, fill = "white", linewidth = 2) +
      theme_light() +
      ylab("areaal in km2")
    
    ggplotly(p, dynamicTicks = TRUE)
    
  })
  
}

# runGadget(ui, server, viewer = paneViewer())
shinyApp(ui, server)

