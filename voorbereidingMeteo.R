
source("r/runThisFirst.R")

# voorbereding meteo gegevens
# zie: https://www.knmi.nl/kennis-en-datacentrum/achtergrond/data-ophalen-vanuit-een-script
# bij kopje "uurgegevens"
# 

baseurl <- "https://www.daggegevens.knmi.nl/klimatologie/uurgegevens"
years <- c(startyear:endyear)

getWindForYear <- function(x){
cat("
De volgende parameters worden opgehaald:
DD: Windrichting (in graden) gemiddeld over de laatste 10 minuten van het afgelopen uur (360=noord, 90=oost, 180=zuid, 270=west, 0=windstil 990=veranderlijk.
FH: Uurgemiddelde windsnelheid (in 0.1 m/s). Meer info
FF: Windsnelheid (in 0.1 m/s) gemiddeld over de laatste 10 minuten van het afgelopen uur
FX: Hoogste windstoot (in 0.1 m/s) over het afgelopen uurvak
voor jaar       ")
print(x)

  require(httr)
  require(data.table)
  start <- paste0(x, "010101")
  end <- paste0(x + 1, "010124")
  vars <- "DD:FH:FF:FX"  # Wind
  stns <- "235:242:251:277"
  res <- POST(baseurl,
              body = paste(paste0("start=", start), 
                           paste0("end=", end), 
                           paste0("vars=", vars), 
                           paste0("stns=", stns), 
                           sep = "&")
  )
  fread(content(res, "text", encoding = "UTF_8"))[,
                                                  .(
                                                    date = as.Date(as.character(YYYYMMDD), format = "%Y%m%d"),
                                                    datetime = as.POSIXct(paste(YYYYMMDD, H), format = "%Y%m%d %H"),
                                                    station = fcase(
                                                      `# STN` == 235, "De Kooy",
                                                      `# STN` == 277, "Lauwersoog",
                                                      `# STN` == 251, "Hoorn Terschelling",
                                                      `# STN` == 242, "Vlieland"
                                                    ),
                                                    stationnr = `# STN`,
                                                    "Windrichting in graden" = DD,
                                                    "Uurgemiddelde windsnelheid in 0.1 m/s" = FH,
                                                    "Windsnelheid in 0.1 m/s" = FF,
                                                    "Hoogste windstoot laatste uur in 0.1 m/s" = FX
                                                  )
  ]
}


winddata <- map(years, getWindForYear) %>%
  data.table::rbindlist()

winddata[, year := lubridate::year(date)]
winddata[, month := lubridate::month(date)]

str(winddata)
data.table::fwrite(winddata, file = file.path(datadir, "KNMI", "raw", "uurgegevenswind.csv"), sep = ";", append = F, )
