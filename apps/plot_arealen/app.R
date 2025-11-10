
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

test = F

require(tidyverse)

colors <- c(
  "Geul\n(< -5 m NAP)" = "#16466E",
  "Geul\n(-3 tot -5 m NAP)" = "#3681BF",
  "Subgetijde\n(GLW tot -3 m NAP)" = "#87BCE8",
  "Intergetijde\n(GLW tot GHW)" = "#CFBA7C",
  "Supragetijde\n(> GHW)"  = "#61A13B"
)

diepteklassen <- c(
  "Geul\n(< -5 m NAP)",
  "Geul\n(-3 tot -5 m NAP)",
  "Subgetijde\n(GLW tot -3 m NAP)",
  "Intergetijde\n(GLW tot GHW)",
  "Supragetijde\n(> GHW)",
  "Totaal"
)

basins <- c(
  "Marsdiep",
  "Eijerlandse Gat",
  "Vlie",
  "Borndiep",
  "Pinkegat",
  "Zoutkamperlaag",
  "Groninger Wad",
  "Eems-Dollard"
)

arealenfiles <- c(
  "Arealen_ZKL_18.6jr.csv",
  "Arealen_PGAT_18.6jr.csv",
  "Arealen_AME_18.6jr.csv",
  "Arealen_VLIE_18.6jr.csv",
  "Arealen_ELD_18.6jr.csv",
  "Arealen_MD_18.6jr.csv",
  "Arealen_GRWAD_18.6jr.csv",
  "Arealen_ED_18.6jr.csv"
)

if(test){ 
  arealenfiles = file.path("apps/plot_arealen", arealenfiles) 
} else{
  arealenfiles = arealenfiles
}


arealen <- map(
  1:length(arealenfiles), 
  \(x) read_csv(arealenfiles[x])
) %>% 
  bind_rows() %>%
  mutate(
    percentage = round(percentage,0),
    area = signif(area, 3)
  ) %>%
  mutate(diepteklasse_plotname = 
           str_replace_all(
             diepteklasse_plotname, 
             fixed(" \\n "), 
             "\n"
           )
  )


#=== user interface ============================================================

ui <- miniPage(
  miniTitleBar("Arealenverloop Waddenzee"),
  miniContentPanel(padding = 0,
                   plotlyOutput("areaalPlot", height = "100%")
  ),
  miniButtonBlock(
    tags$head(
      tags$style(HTML(CSS))
    ),
    selectizeInput(
      "diepteklasse",
      "kies diepteklasse:",
      unique(arealen$diepteklasse),
      width = "30%"
    ),
    radioButtons(
      "scale_abs_rel",
      "kies soort grafiek:",
      c("absoluut", "relatief"),
      width = "30%"
    )
    
  )
)

#=== Server ====================================================================

server <- function(input, output, session) {
  
  output$areaalPlot <- renderPlotly({
    
    arealenSelectie <- arealen %>%
      filter(diepteklasse == input$diepteklasse)
    
    if(input$scale_abs_rel == "absoluut"){
      p <- arealenSelectie %>%
        # mutate(diepteklasse_plotname = factor(diepteklasse_plotname, levels = rev(diepteklassen))) %>%
        # mutate(diepteklasse = factor(diepteklasse, levels = str_replace(diepteklassen, fixed("\n"), " "))) %>%
        mutate(basin = factor(basin, levels = basins)) %>%
        ggplot(aes(jaar, area)) +
        ylab("oppervlakte in  km^2")
    }

    if(input$scale_abs_rel == "relatief"){
      p <- arealenSelectie %>%
        # mutate(diepteklasse_plotname = factor(diepteklasse_plotname, levels = rev(diepteklassen))) %>%
        # mutate(diepteklasse = factor(diepteklasse, levels = str_replace(diepteklassen, fixed("\n"), " "))) %>%
        mutate(basin = factor(basin, levels = basins)) %>%
        ggplot(aes(jaar, percentage)) +
        ylab("oppervlakte in %")
    }
    
    p <- p +
      geom_line(aes(color = basin), linewidth = 1.5) +
      geom_point(aes(color = basin), size = 2) +
      # facet_wrap("diepteklasse", scales = "free") +
      theme_light()


   ggplotly(p, dynamicTicks = TRUE)    

  })
  
}

# runGadget(ui, server, viewer = paneViewer())
shinyApp(ui, server)

