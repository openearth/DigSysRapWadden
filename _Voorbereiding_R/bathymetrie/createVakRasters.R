
## create 2016 for report WaddenZe 2021

opendapdatapath <- "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/"
vakTiles <- fread("..//waddenZeeVaklodingen.csv")
vakTiles$tiles <- paste0(opendapdatapath, vakTiles$tiles)

# still to be developed:
#tilesInPolygon(bigbbox_wgs,names,dataset='vaklodingen')

# go through each vak file
yearsvak <- c(2016) #c(2004, 2010, 2016)
yy<-1
timevak <- c(paste0("X",yearsvak[yy],".01.01"))#, paste0("X",yearsvak[yy]+1,".01.01"))#, paste0("X",yearsvak[yy]-1,".01.01"))
df_tx <- list()

for (ii in 1:length(vakTiles$tiles)){
  print(ii)
  bathytile <- raster::brick(vakTiles$tiles[ii])
  # this will give priority to the most recent
  if (timevak %in% names(bathytile))  {
    rs <- subset(bathytile, timevak)
    df_tx <- append(df_tx, list(rs))
  }
}
# should include 
rsextra <- list(subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1716.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1716.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1514.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1514.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB127_1514.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB127_1312.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB128_1514.nc"), "X2017.01.01"))
df_tx <- append(df_tx, rsextra)
m <- do.call(merge, df_tx) 
crs(m )=CRS("+init=EPSG:28992")
writeRaster(m, paste0("../mosaic_", yearsvak[yy]), format = "GTiff")


## create 2010 for report WaddenZe 2021

opendapdatapath <- "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/"
vakTiles <- fread("..//waddenZeeVaklodingen.csv")
vakTiles$tiles <- paste0(opendapdatapath, vakTiles$tiles)

# still to be developed:
#tilesInPolygon(bigbbox_wgs,names,dataset='vaklodingen')

# go through each vak file
yearsvak <- c(2010) #c(2004, 2010, 2016)
yy<-1
timevak <- c(paste0("X",yearsvak[yy],".01.01"))#, paste0("X",yearsvak[yy]+1,".01.01"))#, paste0("X",yearsvak[yy]-1,".01.01"))
df_tx <- list()

for (ii in 1:length(vakTiles$tiles)){
  print(ii)
  bathytile <- raster::brick(vakTiles$tiles[ii])
  # this will give priority to the most recent
  if (timevak %in% names(bathytile))  {
    rs <- subset(bathytile, timevak)
    df_tx <- append(df_tx, list(rs))
  }
}
# should include 
rsextra <- list(subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB126_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB125_2120.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB125_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB124_1716.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB124_2120.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB124_1918.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB124_1918.nc"), "X2009.01.01"),subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1716.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1514.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_2120.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1918.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1514.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1716.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1716.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB121_1716.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB121_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB121_2120.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_2120.nc"), "X2009.01.01"))
df_tx <- append(rsextra, df_tx)
m <- do.call(merge, df_tx) 
crs(m )=CRS("+init=EPSG:28992")
writeRaster(m, paste0("../mosaic_", yearsvak[yy]), format = "GTiff")


# # brick will go through all of them.
# bathy1tile <- raster::brick("../vaklodingenKB126_1918.nc")
# 
# tile1 <- raster::brick("../vaklodingenKB126_1918.nc")
# tile2 <- raster::brick("../vaklodingenKB126_1514.nc")
# tile3 <- raster::brick("../vaklodingenKB125_1918.nc")
# tile4 <- raster::brick("../vaklodingenKB125_1514.nc")
# tile5 <- raster::brick("../vaklodingenKB126_1716.nc")
# tile6 <- raster::brick("../vaklodingenKB125_1716.nc")
# 
# tilex <- raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB125_1716.nc")
# 
# years_in_raster <- as.character(c(2010, 2016))
# 
# yeartab <- paste0('X',years_in_raster[2],'.01.01')
# 
# t1 <- subset(tile1,yeartab) # tile1$X2016.01.01
# t2 <- subset(tile2,yeartab)
# t3 <- subset(tile3,yeartab)
# t4 <- subset(tile4,yeartab)
# t5 <- subset(tile5,yeartab)
# t6 <- subset(tile6,yeartab)
# tx <- subset(tilex,yeartab)
# 
# x <- list(t1, t2, t3, t4, t5, t6)
# m <- do.call(merge, x) 
# crs(m )=CRS("+init=EPSG:28992")
# 
# nlayers(tile1)
# writeRaster(m, paste0("../filled_", years_in_raster[2]), format = "GTiff")


## Friesche Gat polygonen
opendapdatapath <- "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/"
vakTiles <- fread("..//FriescheGatVaklodingen.csv")
vakTiles$tiles <- paste0(opendapdatapath, vakTiles$tiles)
stacks <- list()

# list all possible years available in netcdf
for (ii in 1:length(vakTiles$tiles)){
  bathytile <- raster::brick(vakTiles$tiles[ii])
  stacks <- append(stacks, names(bathytile))
}
ustacks <- unique(stacks)
alltimes <- str_sort(ustacks) # here is the array of all stacks

# now per tile per year, create tiles and overlap with most recent years on top.
for (ii in 1:length(vakTiles$tiles)){
  print(ii)
  bathytile <- raster::brick(vakTiles$tiles[ii])
  # this will give priority to the most recent
  for (jj in 1:length(alltimes)){
    if (alltimes[jj] %in% names(bathytile)) {
      if (alltimes[jj] == names(bathytile)[1]) { # if it's the first stack
        df_tx <- list(subset(bathytile, alltimes[jj]))
        m <- subset(bathytile, alltimes[jj])
      } else {
        rs <- subset(bathytile, alltimes[jj])
        rs_file <- raster::brick(paste0(filenameRaster,'.tif')) # previous files
        df_tx <- append(list(rs), list(rs_file)) # give priority to recent ones.
        m <- do.call(merge, df_tx)
      }
    }
    crs(m) <- CRS("+init=EPSG:28992")
    filenameRaster <- paste0("../FG_processing_tiles/", str_sub(basename(vakTiles$tiles[ii]),1,-4),'_',str_sub(alltimes[jj],1,5))
    writeRaster(m, filenameRaster, format = "GTiff", overwrite=TRUE)
  }
}

# merge files per year
yearsvak <- c(2005, 2010, 2016)
for (yy in 1:length(yearsvak)){
  rsmerging <- list(raster::brick(paste0("../FG_processing_tiles/vaklodingenKB129_1312_X",yearsvak[yy],".tif")), 
                  raster::brick(paste0("../FG_processing_tiles/vaklodingenKB129_1514_X",yearsvak[yy],".tif")),
                  raster::brick(paste0("../FG_processing_tiles/vaklodingenKB130_1312_X",yearsvak[yy],".tif")), 
                  raster::brick(paste0("../FG_processing_tiles/vaklodingenKB130_1514_X",yearsvak[yy],".tif")),
                  raster::brick(paste0("../FG_processing_tiles/vaklodingenKB131_1312_X",yearsvak[yy],".tif")), 
                  raster::brick(paste0("../FG_processing_tiles/vaklodingenKB132_1312_X",yearsvak[yy],".tif")),
                  raster::brick(paste0("../FG_processing_tiles/vaklodingenKB133_1312_X",yearsvak[yy],".tif")))
  m <- do.call(merge, rsmerging) 
  crs(m )=CRS("+init=EPSG:28992")
  writeRaster(m, paste0("../FG_processing_tiles/mosaic_", yearsvak[yy]), format = "GTiff")
}


