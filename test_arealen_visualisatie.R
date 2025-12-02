
require(tidyverse)
require(plotly)

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

  # list.files("apps/plot_arealen")
  arealenfiles = file.path("apps/plot_arealen", arealenfiles) 


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
  
#===== stacked area plot =======================

  p <- arealen %>%
    filter(diepteklasse != "Totaal") %>%
    mutate(diepteklasse_plotname = factor(diepteklasse_plotname, levels = rev(diepteklassen))) %>%
    mutate(diepteklasse = factor(diepteklasse, levels = str_replace(diepteklassen, fixed("\n"), ""))) %>%
    mutate(basin = factor(basin, levels = basins)) %>%
    ggplot(aes(jaar, area)) +
    geom_area(
      aes(fill = diepteklasse_plotname), 
      # position = position_fill(),
      alpha = 0.6
    ) +
    facet_wrap("basin", scales = "free") +
    scale_fill_manual(values = colors) +
    scale_y_continuous(expand = c(0, 20)) +
    scale_x_continuous(expand = c(0, 0)) +
    ylab(bquote("oppervlakte in  "(km^2))) +
    theme_bw() +
    theme(
      legend.position = "bottom",
      legend.title = element_blank(),
      panel.border = element_blank()
    )
  
  p

# ggplotly(p, dynamicTicks = TRUE)

# bar plot of relative areas

p <- arealen %>%
  filter(diepteklasse != "Totaal") %>%
  mutate(diepteklasse_plotname = factor(diepteklasse_plotname, levels = diepteklassen)) %>%
  mutate(diepteklasse = factor(diepteklasse, levels = str_replace(diepteklassen, fixed("\n"), ""))) %>%
  mutate(basin = factor(basin, levels = basins)) %>%
  ggplot(aes(diepteklasse_plotname, percentage)) +
  geom_col(aes(fill = jaar), position = position_dodge2()) +
  facet_wrap("basin") +
  theme(axis.text.x = element_text(angle = 90, vjust = 1, hjust = 1)) +
  ylab("relatief oppervlakte (%)") +
  xlab("diepteklasse")
p

ggplotly(p)







