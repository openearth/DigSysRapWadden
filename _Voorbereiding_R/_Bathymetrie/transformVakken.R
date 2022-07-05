
source("R/runThisFirst.R")

# originele files staan in lbd en zijn delft-3d lbd files
# deze zijn ingelezen in Quickplot en ge-exporteerd als shp
# shp files worden hieringelezen, van crs voorzien (rdnew) en bewaard als geojson

shapes <- list.files(file.path(datadir, "shp"), pattern = "shp", full.names = T)
names <- gsub(".shp", "", list.files(file.path(datadir, "shp"), pattern = "shp"))

shapelist <- lapply(shapes, function(x) st_read(x, crs =28992))
names(shapelist) <- names
vakken <- rbindlist(shapelist, idcol = "naam") %>% select(-ID)

st_write(shape, file.path(datadir, "vakken", "vakken.geojson"))
         