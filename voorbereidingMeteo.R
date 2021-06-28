

# voorbereding meteo gegevens
# zie: https://www.knmi.nl/kennis-en-datacentrum/achtergrond/data-ophalen-vanuit-een-script
# bij kopje "uurgegevens"
# 
baseurl <- "https://www.daggegevens.knmi.nl/klimatologie/uurgegevens"
# for(year in startyear:endyear){

year = 2000
start <- paste0(year, "010101")
end <- paste0(year + 1, "010101")
vars <- "DD:FH:FF:FX"  # Wind
stns <- "235:242:251:277"

require(httr)
res <- POST(baseurl,
            body = paste(paste0("start=", start), 
                         paste0("end=", end), 
                         paste0("vars=", vars), 
                         paste0("stns=", stns), 
                         sep = "&")
            # body = list(stns = stns,
            #             vars = stns,
            #             start = start,
            #             end = end
            # )#, encode = "multipart"
)

res$status_code
res$request
content(res, "text", encoding = "UTF_8")
# geeft geen data weer
View(content(res, "text"))

write(content(res, "text", encoding = "UTF-8"), output_file)

# }

"https://www.daggegevens.knmi.nl/klimatologie/uurgegevens/stns=235:242:251:277&vars=DD:FH:FF:FX&start=2000010101&end=2001010101"