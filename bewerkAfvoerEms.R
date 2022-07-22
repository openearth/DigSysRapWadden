source("r/runThisFirst.R")

#=== Ems afvoer lezen en netjes maken ===============================================

EmsAfvoerHeader <- readxl::read_excel(file.path(datadir, "NLWKN", "afvoeren", "raw", "Ems-discharge.xlsx"), skip = 1, n_max = 3, col_names = F) %>%
  t() %>% as.data.frame()

names(EmsAfvoerHeader) = col.names = c("locatie.naam", "rivier", "grootheid")

headers <- EmsAfvoerHeader %>% 
  mutate(name = stringr::str_replace_all(paste(locatie.naam, grootheid, sep = "_"), "-+", "_")) %>% 
  mutate(name = stringr::str_replace_all(name, " +", "_")) %>%
  mutate(name = stringr::str_replace_all(name, "\r\n", "_")) %>%
  select(name) %>% unlist %>% unname

EmsAfvoer <- readxl::read_excel(file.path(datadir, "NLWKN", "afvoeren", "raw", "Ems-discharge.xlsx"), 
                                skip = 4, 
                                col_names = c("datum", headers),
                                col_types = c("date", "numeric", "numeric", "numeric")
                                ) %>%
  janitor::clean_names() %>%
  mutate(q_hebrum_berekend_m3_s = case_when(
    !is.na(versen_gesamt_q_m3_s) ~ versen_gesamt_q_m3_s * 1.1,
    is.na(versen_gesamt_q_m3_s) ~ versen_wehr_durchstich_q_m3_s * 1.1
  )) %>%
pivot_longer(cols = -datum, names_to = "locatie.origineel", values_to = "numeriekewaarde") %>%
  mutate(waardebewerkingsmethode.omschrijving = "Etmaalgemiddelde") %>%
  mutate(grootheid.omschrijving = "Debiet",
         grootheid.code = "Q") %>%
  mutate(eenheid.code = "m3/s") %>%
  mutate(
    longitude = case_when(
      locatie.origineel == "versen_wehr_durchstich_q_m3_s" ~ 7.24186111,
      locatie.origineel == "lingen_darme_q_m3_s" ~ 7.28834158,
      locatie.origineel == "q_hebrum_berekend_m3_s" ~ 7.317734
    ),
    latitude = case_when(
      locatie.origineel == "versen_wehr_durchstich_q_m3_s" ~ 52.73296944,
      locatie.origineel == "lingen_darme_q_m3_s" ~ 	52.49658868,
      locatie.origineel == "q_hebrum_berekend_m3_s" ~ 53.038867
    ),
    locatie.naam = case_when(
      locatie.origineel == "versen_wehr_durchstich_q_m3_s" ~ "Versen",
      locatie.origineel == "lingen_darme_q_m3_s" ~ "Lingen-Darme",
      locatie.origineel == "q_hebrum_berekend_m3_s" ~ "Hebrum"
    ),
    gebied = "Eems"
  ) %>%
  drop_na(numeriekewaarde)



# visual inspection
EmsAfvoer %>%
  filter(grepl(pattern = "Hebrum", locatie.naam)) %>%
  mutate(jaar = year(datum), maand = month(datum)) %>%
  group_by(jaar, maand, locatie.naam) %>%
  summarize(maandelijksgemiddelde = mean(numeriekewaarde, na_rm = T)) %>%
  mutate(datum = ymd(paste(jaar, maand, "01"))) %>%
 ggplot(aes(datum, maandelijksgemiddelde)) +
  geom_path(aes(color = locatie.naam))

savepath = file.path(datadir, "NLWKN", "afvoeren", "standard")
if(!dir.exists(savepath)) dir.create(savepath)
write_delim(EmsAfvoer, file.path(savepath, "Ems-discharge_bewerkt.csv"))


metadata = c("Ems discharge gegevens bij Hebrum zijn berekend als",
             "1.1 * de afvoer bij Versen",
             "Ruwe data staan in p:/11202493--systeemrap-grevelingen/1_data/Wadden/NLWKN/afvoeren/raw/Ems-discharge.xlsx",
             "Berekening voor Hebrumgedaan met script bewerkAfvoerEms.R",
             "Locatie Hebrum (53.038867, 7.317734) geschat uit Google Maps.")

write_lines(metadata, file.path(savepath, "Ems-discharge_metadata.txt"))


#=== Leda afvoer lezen en netjes maken ===============================================

filenaam <- "Leer_Leda_Oberwasser_2014-2022.xlsx"

LedaAfvoerHeader <- readxl::read_excel(file.path(datadir, "NLWKN", "afvoeren", "raw", filenaam), skip = 0, n_max = 2, col_names = F) %>%
    select(1) %>%  t() %>% as.data.frame() %>% separate(V1, c("grootheid", "locatie.naam"), sep = " ") %>%
  rename(eenheid = V2)

headers <- LedaAfvoerHeader %>% 
  mutate(name = stringr::str_replace_all(paste(grootheid, locatie.naam, eenheid, sep = "_"), "-+", "_")) %>% 
  mutate(name = stringr::str_replace_all(name, " +", "_")) %>%
  mutate(name = stringr::str_replace_all(name, "\r\n", "_")) %>%
  select(name) %>% unlist %>% unname

LedaAfvoer <- readxl::read_excel(file.path(datadir, "NLWKN", "afvoeren", "raw", filenaam), 
                                skip = 2, 
                                col_names = c("datum", headers),
                                col_types = c("text", "numeric", "skip", "skip")
) %>%
  janitor::clean_names() %>%
  separate(datum, c("maand", "jaar"), sep = " ") %>%
  mutate(maand = case_when(
    maand == "Jan" ~ "Jan",
    maand == "Feb" ~ "Feb",
    maand == "Mrz" ~ "Mar",
    maand == "Apr" ~ "Apr",
    maand == "Mai" ~ "May",
    maand == "Jun" ~ "Jun",
    maand == "Jul" ~ "Jul",
    maand == "Aug" ~ "Aug",
    maand == "Sep" ~ "Sep",
    maand == "Okt" ~ "Oct",
    maand == "Nov" ~ "Nov",
    maand == "Dez" ~ "Dec"
  )) %>%
  mutate(datum = as.Date(paste(jaar, maand, "15"), format = "%Y %h %d")) %>%
  select(-jaar, -maand) %>%
  pivot_longer(cols = -datum, names_to = "locatie.origineel", values_to = "numeriekewaarde") %>% 
  mutate(
    grootheid.code = "Q",
    grootheid.omschrijving = "Debiet",
    eenheid.code = "m3/s"
  ) %>%
  mutate(waardebewerkingsmethode.omschrijving = "Maandgemiddelde") %>% # bestaat nog niet in AQUO
  mutate(
    longitude = 7.449445,
    latitude = 53.213771,
    locatie.naam = "Leer",
    gebied = "Leda"
  ) %>%
  drop_na(numeriekewaarde)


savepath = file.path(datadir, "NLWKN", "afvoeren", "standard")
if(!dir.exists(savepath)) dir.create(savepath)
write_delim(EmsAfvoer, file.path(savepath, "Leda-discharge_bewerkt.csv"))


metadata = c("Leda discharge gegevens bij Leer ",
             "Ruwe data staan in p:/11202493--systeemrap-grevelingen/1_data/Wadden/NLWKN/afvoeren/raw/Leer_Leda_Oberwasser_2014-2022.xlsx",
             "Transformatie gedaan met script bewerkAfvoerEms.R",
             "Locatie Leer (53.213771, 7.449445) geschat uit Google Maps.")

write_lines(metadata, file.path(savepath, "Leer-Leda-discharge_metadata.txt"))

