

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
  filter(locatie.naam == "Delfzijl" | locatie.naam == "Eemshaven") %>%
  #filter(jaar > 1985) %>%
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
  xlab("Jaar") + ylab("Jaargemiddelde hoogwater in cm t.o.v. NAP")

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
  filter(locatie.naam == "Delfzijl" | locatie.naam == "Eemshaven") %>%
  filter(jaar > 1985) %>%
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
  xlab("Jaar") + ylab("Jaargemiddelde laagwater in cm t.o.v. NAP")

# if(knitr::is_html_output()){ggplotly(p, width = 700, height = 550)} else 
p

# getijslag

p <- df.extrema %>%
  # filter(HL == "L") %>%
  mutate(jaar = year(time)) %>% 
  filter(jaar > 1985) %>%
  group_by(locatie.naam, jaar, HL) %>% summarise(mean = mean(h)) %>%
  filter(locatie.naam == "Delfzijl" | locatie.naam == "Eemshaven") %>%
  pivot_wider(id_cols = c(locatie.naam, jaar), names_from = HL, values_from = mean) %>%
  mutate(`getijslag in cm` = H-L) %>%
  ggplot() +
  geom_point(aes(jaar, `getijslag in cm`, color = locatie.naam)) +
  geom_smooth(aes(jaar, `getijslag in cm`, color = locatie.naam), method = "lm", 
              formula = y ~ x ) +
  geom_smooth(aes(jaar, `getijslag in cm`, color = locatie.naam), method = "lm", 
              formula = y ~ x + I(cos(2 * pi * x / (18.6))) + I(sin(2 * pi * (x) / (18.6)))) +
  
  #geom_line(aes(x = jaar, y=zoo::rollmean(`getijslag in cm`, 19, na.pad=TRUE))) + # poging om rolling average toe te voegen. Ziet er lelijk uit
  # facet_wrap(~locatie.naam, scales = "free_y", ncol = 2) +
  theme_hy

# if(knitr::is_html_output()){ggplotly(p, height = 550, width = 700)} else 
p