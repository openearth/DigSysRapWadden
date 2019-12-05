

names <- 
  c(
    "Zeetrektellingen Noordzeekustzone",
    "Aantallen en verspreiding pleisterende watervogels in de Waddenzee",
    "Aantallen en verspreiding pleisterende wad- en watervogels in de Waddenzee",
    "Aantallen watervogels in de Waddenzee (op basis van boottellingen)",
    "Aantallen watervogels in de Waddenzee (vliegtuigtellingen)",
    # "Aantallen broedende wad- en watervogels langs Waddenzee en Noordzeekustzone",
    "Broedsucces van wad- en watervogels in Waddenzee en Noordzeekustzone",
    "Aantallen ganzen en zwanen (Wz, Delta, kustgebieden)",
    "Monitoring zeevogels Noordzee (vliegtuigtellingen)",
    "Populatiestudies: Aalscholver",
    "Populatiestudies: Blauwe Kiekendief",
    "Populatiestudies: Grote Stern",
    "Populatiestudies: Monitoring Kanoet",
    "Populatiestudies: Monitoring Rosse Grutto",
    "Populatiestudies: Lepelaar",
    "Populatiestudies: Rotgans",
    "Verspreiding en overleving individuele broed- en trekvogels",
    "Ringonderzoek aan wadvogels in getijdengebieden",
    "Populatiestudies: Scholekster",
    "Meetnet Nestkaarten",
    "PTT (Punt-Transect-Tellingen",
    "CES-project",
    "Meetnet slaapplaatsen",
    "Vogel- en zoogdiersterfte",
    "Wadplaattellingen waddenunit EZ",
    "Populatiestudies: Drieteenstrandloper",
    "Populatiestudie Kleine Mantelmeeuw",
    "Populatiestudies: Zilvermeeuw",
    "Populatiestudies: Tureluur",
    "Populatiestudies: Steenloper",
    "Populatiestudies: Kluut",
    "Populatiestudies: Visdief",
    "Populatiestudies: Noordse Stern")

tidyNames <- paste0("_", tolower(stringr::str_replace_all(names, '[^a-zA-Z0-9_]+', '_')))

titles <- paste("#", names)

x = titles[1]

writeLines(x, file.path('_40_vogels', paste0(x,".Rmd")))

for(x in 1:length(names)){
  writeLines(titles[x], con = file.path('_40_vogels', paste0(tidyNames[x],".Rmd")))
}

