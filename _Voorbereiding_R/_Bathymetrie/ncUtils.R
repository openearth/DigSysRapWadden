
# ncUtils


# scrape names from thredds catalogue page
# http://bradleyboehmke.github.io/2015/12/scraping-html-tables.html
require(rvest)
require(xml2)
require(magrittr)


url <- "https://opendap.deltares.nl/thredds/catalog/opendap/rijkswaterstaat/vaklodingen_new/catalog.html"
catalogue <- read_html(url)

names <- catalogue %>% 
  rvest::html_nodes('body') %>% 
  xml2::xml_find_all('.//table') %>% 
  rvest::html_table(fill = T)%>% 
  extract2(1) %>%
  filter(grepl('vaklodingenKB', Dataset)) # filtering only valid vaklodingen

# select based on bbox - from polygon:

require('rgdal')

tilesInPolygon <- function(bbox,names,dataset='vaklodingen') {
  # load the dfs and look into those
  if (dataset == 'vaklodingen'){
    
    }
  
  pt.tn <- NA
  for (ii in 1:nrow(df)){
    dfpolyc <- cbind(cbind(c(df$xmax[ii], df$xmax[ii], df$xmin[ii], df$xmin[ii], df$xmax[ii]),
                           c(df$ymax[ii], df$ymin[ii], df$ymin[ii], df$ymax[ii], df$ymax[ii])))
    dfpolys <- SpatialPolygons(list(Polygons(list(Polygon(dfpolyc)), df$tileName[ii])),1:1,proj4string=CRS(RDstring))
    pt.tn <- ifelse( !is.na(over(point, dfpolys)) & is.na(pt.tn), df$tileName[ii],pt.tn) # compute the inpolygon thing...
  }
  
  # make a df of ids [tiles]
  tn.df<-data.frame(pt.tn)
  # assign tilenames
  tn.df$tilename<-df$tileName[tn.df$pt.tn]
  
  return(tn.df$tilename)
}

