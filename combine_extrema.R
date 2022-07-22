

source("r/runThisFirst.R")

latestExtrema <- file.path(datadir, "ddl", "standard", paste0("extremaHLLL", "2021-08-04", ".csv"))

Waterbase_locations <- read_delim("C:/repos_checkouts/digitale_systeemrapportages/1_data/standaardlijsten/Waterbase_locations.csv", 
                                  delim = ";", escape_double = FALSE, trim_ws = TRUE)
# to map names to the dia station codes
station_map <- Waterbase_locations %>% 
  select(locatie.code = loccod, locatie.naam = locoms)

df.extrema <- read_delim(latestExtrema, delim = ";")

extrema.dia.files <- list.files(file.path(datadir, "RWS", "hoogLaagWaters"), pattern = "\\.csv", full.names = T)

df.extrema.dia <- lapply(extrema.dia.files, 
                         function(x) 
                           read_delim(x, delim = ";")
                         )

df.extrema.dia <- bind_rows(df.extrema.dia) %>%
  left_join(station_map, by = c(station = "locatie.code")) %>%
  mutate(HWLWcode = case_when(
    HWLWcode == 1 ~ "H",
    HWLWcode == 2 ~ "L"
  ))

# Welke stations komen niet voor in de dia extremen files?
unique(df.extrema$locatie.naam)[is.na(match(unique(df.extrema$locatie.naam), unique(df.extrema.dia$locatie.naam)))]



df.extrema.dia%>%
  sample_n(10000) %>%
  mutate(HWLWcode = as.factor(HWLWcode)) %>%
  ggplot(aes(times, values)) +
  geom_line(aes(group = station, color = Status)) +
  # ggplot(aes(times, values)) +
  # geom_point(aes(color = Status), alpha = 0.2) +
  facet_grid(station ~ HWLWcode)


# check the two series for DENHDR

df.extrema.dia%>%
  filter(year(times) == 2015) %>%
  filter(station == "WIERMGDN") %>%
  rename(HL = HWLWcode) %>%
  # sample_n(10000) %>%
  mutate(HL = as.factor(HL)) %>% 
  mutate(values = 100 * values) %>%
  ggplot(aes(times, values)) +
  geom_line(aes(color = HL)) +
  geom_line(data = df.extrema %>% 
              filter(year(time) == 2015) %>%
              filter(locatie.naam == "Wierumergronden") %>%
              mutate(HL = as.factor(HL)), 
            aes(time, h, color = HL)
            ) +
  coord_cartesian(xlim = c(ymd_hm(paste0("2015-01-01 00:00")), ymd_hm(paste0("2015-02-01 00:00"))))
# facet_grid(station ~ HL) +

df.extrema.dia %>%
  mutate(jaar = year(times)) %>%
  group_by(locatie.naam, jaar) %>%
  summarize(n = n()) %>%
  ggplot(aes(jaar, n)) +
  geom_line(aes(), color = "blue") +
  geom_line(data = df.extrema%>%
              mutate(jaar = year(time)) %>%
              group_by(locatie.naam, jaar) %>%
              summarize(n = n()), 
            aes(jaar, n)
  )  +
  facet_wrap(~ locatie.naam)
  # coord_cartesian(xlim = c(ymd_hm(paste0("2015-01-01 00:00")), ymd_hm(paste0("2015-02-01 00:00"))))


# Combineren heeft op dit moment geen zin. De door RWS aangeleverde extremen dekken dezelfde periode als die
#  (in hele jaren) gedekt wordt door de zelf berekende hoog- en laagwaters

df.extrema.combined <- df.extrema.dia %>%
  mutate(jaar = year(times)) %>%
  group_by(locatie.naam, jaar) %>%
  filter(n() > 1250) %>% ungroup() %>%
  select(time = times,
         HL = HWLWcode,
         h = values,
         locatie.naam,
         status = Status) # %>%
  # bind_rows(
  #   df.extrema %>%
  #     mutate(jaar = year(time)) %>%
  #     group_by(locatie.naam, jaar) %>% #summarize(n = n())
  #     filter( n() > 1250) %>%View()
  # )

write_delim(df.extrema.combined, file.path(datadir, "RWS", "standard", paste0("extremaHLLL", "latest", ".csv")), delim = ";")


