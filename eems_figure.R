

source("_common.R")
theme_hy <- theme_bw()

alt_theme_hy <- theme_tufte() + theme(axis.line=element_line()) #+ 
# scale_x_continuous(limits=c(10,35)) + scale_y_continuous(limits=c(0,400))
# 
# # knitr::include_graphics("images/zeespiegelmonitor.png")

# sea level
# 
sealevelurl <- "https://raw.githubusercontent.com/openearth/sealevel/master/data/deltares/results/dutch-sea-level-monitor-export-2022-01-14.csv"

sealevel <- read_csv(sealevelurl,
                     comment = "#")


sealevelAllStationsurl <- "https://raw.githubusercontent.com/openearth/sealevel/master/data/deltares/results/dutch-sea-level-monitor-export-stations-2021-11-26.csv"

stations <- read_delim("https://raw.githubusercontent.com/openearth/sealevel/master/data/psmsl/NLstations.csv", delim = ";")

sealevelAllStations <- read_csv(sealevelAllStationsurl,
                                comment = "#")

p <- sealevelAllStations %>% 
  left_join(stations %>% select(ID, StationName), by = c(station = "ID")) %>%
  filter(StationName == "DELFZIJL") %>%
  mutate(`height in cm` = height / 10,
         `predicted_linear_with_wind in cm` = predicted_linear_with_wind / 10) %>%
  ggplot() +
  geom_point(aes(year, `height in cm`, color = StationName)) +
  geom_line(aes(year, `predicted_linear_with_wind in cm`, color = StationName)) +
  # geom_line(data = sealevel, aes(x = year, y = predicted_linear_with_wind/10), color = "black") +
  theme_hy

p





#hoogwaters



df.extrema <- read_delim(file.path(datadir, "RWS", "standard", paste0("extremaHLLL", "latest", ".csv")), delim = ";") %>%
  mutate(h = h * 100) # van meter naar cm



p <- df.extrema %>%
  filter(HL == "H") %>%
  mutate(
    jaar = year(time)
  ) %>% 
  group_by(locatie.naam) %>% mutate(across(h, remove_outliers)) %>%
  group_by(locatie.naam, jaar) %>% 
  summarise(jaargemiddelde = mean(h, na.rm = T)) %>%
  # filter(jaar != 2021 & jaar > 1970) %>%
  ggplot() +
  geom_point(aes(x = jaar, y = jaargemiddelde, color = locatie.naam), size = 1) +
  geom_smooth(aes(jaar, jaargemiddelde, color = locatie.naam), method = "lm", 
              formula = y ~ x + I(cos(2 * pi * as.numeric(x) / (18.6))) + I(sin(2 * pi * as.numeric(x) / (18.6))),
              size = 1) +
  # coord_cartesian(ylim = c(-160, -100)) +
  # facet_wrap(~locatie.naam, ncol = 2, scales = "free") + 
  # scale_x_continuous(limits = c(1970, 2020)) +
  # coord_cartesian(ylim = c(-175, 0)) +
  theme_hy +
  xlab("Jaar") + ylab("Jaargemiddelde gemeten hoogwater in cm")

# if(knitr::is_html_output()){ggplotly(p)} else  
p


# laagwaters

p <- df.extrema %>%
  filter(HL == "L") %>%
  mutate(
    jaar = year(time)
  ) %>% 
  group_by(locatie.naam) %>% mutate(across(h, remove_outliers)) %>%
  group_by(locatie.naam, jaar) %>% 
  summarise(jaargemiddelde = mean(h, na.rm = T)) %>%
  # filter(jaar != 2021 & jaar > 1970) %>%
  ggplot() +
  geom_point(aes(x = jaar, y = jaargemiddelde, color = locatie.naam), size = 1) +
  geom_smooth(aes(jaar, jaargemiddelde, color = locatie.naam), method = "lm", 
              formula = y ~ x + I(cos(2 * pi * as.numeric(x) / (18.6))) + I(sin(2 * pi * as.numeric(x) / (18.6))),
              size = 1) +
  # coord_cartesian(ylim = c(-160, -100)) +
  # facet_wrap(~locatie.naam, ncol = 2, scales = "free") + 
  # scale_x_continuous(limits = c(1970, 2020)) +
  # coord_cartesian(ylim = c(-175, 0)) +
  theme_hy +
  xlab("Jaar") + ylab("Jaargemiddelde gemeten laagwater in cm")

# if(knitr::is_html_output()){ggplotly(p, width = 700, height = 550)} else 
p