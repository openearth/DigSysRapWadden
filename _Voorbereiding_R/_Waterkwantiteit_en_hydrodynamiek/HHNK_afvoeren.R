require(tidyverse)

rawdir <- file.path(datadir, "HHNK/raw/")
fl <- list.files(rawdir, pattern = "*.csv", full.names = T)

afvoeren <- lapply(fl,
  function(x) {read_delim(x) %>%
      fill(locationName, quantity, qualifier)
    }
) %>%
  bind_rows()

afvoeren %>%
  mutate(date = as.Date(timeStamp)) %>%
  group_by(date, locationName) %>% summarise(dailySum = sum(value), .groups = 'drop') %>%
  sample_n(10000) %>%
ggplot(aes(date, dailySum)) +
  geom_point(size = 0.5) + 
  facet_grid(locationName ~ ., scales = "free_y") +
  theme(strip.text.y = element_text(angle = 0))

# check of twee Helsdeur tijdseries gelijk zijn. 
afvoeren %>% 
  filter(grepl("helsdeur", locationName, ignore.case = T)) %>%
  filter(!grepl("pompen", locationName)) %>%
  mutate(date = as.Date(timeStamp)) %>%
  group_by(date, locationName) %>% summarise(dailySum = sum(value), .groups = 'drop') %>%
  pivot_wider(names_from = locationName, values_from = dailySum) %>%
  ggplot(aes(`Helsdeur gemaal`, `Helsdeur, Debiet berekend spuien`)) +
  geom_point(aes())
