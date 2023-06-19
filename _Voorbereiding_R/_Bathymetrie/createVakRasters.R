

csvfile <- "_Voorbereiding_R/_Bathymetrie/WaddenZeeVaklodingen.csv"
processingpath <- "_Voorbereiding_R/_Bathymetrie/processing_tiles/"

# install.packages("gdalUtils")
library("gdalUtils")
library(data.table)
require("raster")

## define function for mosaicking
setMethod('mosaic', signature(x='list', y='missing'), 
          function(x, y, fun, tolerance=0.05, filename=""){
            stopifnot(missing(y))
            args <- x
            if (!missing(fun)) args$fun <- fun
            if (!missing(tolerance)) args$tolerance<- tolerance
            if (!missing(filename)) args$filename<- filename
            do.call(mosaic, args)
          })

## read list from file
opendapdatapath <- "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/"
vakTiles <- fread(csvfile)
vakTiles$tiles <- paste0(opendapdatapath, vakTiles$tiles)
stacks <- list()

# download path: https://opendap.deltares.nl/thredds/fileServer/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB139_1514.nc

lapply(
  vakTiles$tiles[7:75],
  function(x) {
    try(download.file(url = stringr::str_replace(x, "dodsC", "fileServer") , 
                  destfile = file.path("_Voorbereiding_R", "_Bathymetrie", "processing_tiles", "nc", stringr::str_replace(x, "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/", ""))))
  }
)


## create processing folder and subfolders, if they don't exist
dir.create(processingpath)
dir.create(paste0(processingpath,"tiles"))
dir.create(paste0(processingpath,"mosaic"))


## list all possible years available in netcdf
for (ii in 1:length(vakTiles$tiles)){
  bathytile <- raster::brick(vakTiles$tiles[ii])
  stacks <- append(stacks, names(bathytile))
}
ustacks <- unique(stacks)
alltimes <- str_sort(ustacks) # here is the array of all stacks

## create tiles and overlap with most recent years on top, per tile and per year.
# this for-loop takes approx. 2 minutes per tile.
for (ii in 1:length(vakTiles$tiles)){
  print(ii)
  bathytile <- raster::brick(vakTiles$tiles[ii])
  ccount <- 0
  m <- NULL
  for (jj in 1:length(alltimes)){
    print(paste(str_sub(basename(vakTiles$tiles[ii]),1,-4), ' ',alltimes[jj]))
    if (alltimes[jj] %in% names(bathytile)) {
        ccount <- ccount + 1
        df_tx <- list(raster::subset(bathytile, alltimes[jj]))
        m <- raster::subset(bathytile, alltimes[jj])
        crs(m) <- CRS("+init=EPSG:28992")
      }
    filenameRaster <- paste0(processingpath, "tiles/", str_sub(basename(vakTiles$tiles[ii]),1,-4),'_',str_sub(alltimes[jj],1,5))
    if (length(m) == 0) {
      if (file.exists(paste0(filenameRaster_previous,'.tif'))) { # that's when timelayer is not there
        if (filenameRaster_previous == filenameRaster){ # that's when more timelayers exist for a single year
          next
        } 
        m_file <- raster::brick(paste0(filenameRaster_previous,'.tif'))
        writeRaster(m_file, filenameRaster, format = "GTiff", overwrite=TRUE)
        m <- NULL
        filenameRaster_previous <- filenameRaster
      }
      next
    } else if (ccount == 1) { # that's for the first timelayer of a raster
      writeRaster(m, filenameRaster, format = "GTiff", overwrite=TRUE)
      m <- NULL
      filenameRaster_previous <- filenameRaster
      next
    } else { # here the merge with previous file is done
      rs_file <- raster::brick(paste0(filenameRaster_previous,'.tif'))
      df_tx <- append(list(m), list(rs_file)) # give priority to recent ones.
      m <- do.call(merge, df_tx)
    }
    writeRaster(m, filenameRaster, format = "GTiff", overwrite=TRUE)
    m <- NULL
    filenameRaster_previous <- filenameRaster
  }
}

## merge/mosaic files on yearly basis
# this for-loop takes approx. 1 minutes per tile.
yearsvak <- as.numeric(unique(str_sub(alltimes,2,5)))
for (yy in 1:length(yearsvak)){
  rsmerging <- list()
  for (ii in 1:length(vakTiles$tiles)){
    tiff2bmerged <- paste0(
      processingpath, "tiles/", str_sub(basename(vakTiles$tiles[ii]),1,-4),"_X",yearsvak[yy],".tif")
    print(tiff2bmerged)
    if (file.exists(tiff2bmerged)) {
      rsmerging <- append(rsmerging,raster::brick(tiff2bmerged))
    }
  }
  if (length(rsmerging) == 1){
    m <- do.call(merge, rsmerging)
    crs(m )=CRS("+init=EPSG:28992")
  } else {
    
    rsmerging$fun <- mean  
    rsmerging$na.rm <- TRUE
    m <- do.call(mosaic, rsmerging)
    crs(m )=CRS("+init=EPSG:28992")
  }
  writeRaster(m, paste0(processingpath, "mosaic/", "mosaic_", yearsvak[yy]), format = "GTiff")
}




# re-usable garbage?!
#subset <- raster::subset
## create 2016 for report WaddenZe 2021
# opendapdatapath <- "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/"
# vakTiles <- fread("..//waddenZeeVaklodingen.csv")
# vakTiles$tiles <- paste0(opendapdatapath, vakTiles$tiles)
# 
# # still to be developed:
# #tilesInPolygon(bigbbox_wgs,names,dataset='vaklodingen')
# 
# # go through each vak file
# yearsvak <- c(2016) #c(2004, 2010, 2016)
# yy<-1
# timevak <- c(paste0("X",yearsvak[yy],".01.01"))#, paste0("X",yearsvak[yy]+1,".01.01"))#, paste0("X",yearsvak[yy]-1,".01.01"))
# df_tx <- list()
# 
# for (ii in 1:length(vakTiles$tiles)){
#   print(ii)
#   bathytile <- raster::brick(vakTiles$tiles[ii])
#   # this will give priority to the most recent
#   if (timevak %in% names(bathytile))  {
#     rs <- subset(bathytile, timevak)
#     df_tx <- append(df_tx, list(rs))
#   }
# }
# # should include 
# rsextra <- list(subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1716.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1716.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1514.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1514.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB127_1514.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB127_1312.nc"), "X2017.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB128_1514.nc"), "X2017.01.01"))
# df_tx <- append(df_tx, rsextra)
# m <- do.call(merge, df_tx) 
# crs(m )=CRS("+init=EPSG:28992")
# writeRaster(m, paste0("../mosaic_", yearsvak[yy]), format = "GTiff")
# 
# 
# ## create 2010 for report WaddenZe 2021
# 
# opendapdatapath <- "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/"
# vakTiles <- fread("..//waddenZeeVaklodingen.csv")
# vakTiles$tiles <- paste0(opendapdatapath, vakTiles$tiles)
# 
# # still to be developed:
# #tilesInPolygon(bigbbox_wgs,names,dataset='vaklodingen')
# 
# # go through each vak file
# yearsvak <- c(2010) #c(2004, 2010, 2016)
# yy<-1
# timevak <- c(paste0("X",yearsvak[yy],".01.01"))#, paste0("X",yearsvak[yy]+1,".01.01"))#, paste0("X",yearsvak[yy]-1,".01.01"))
# df_tx <- list()
# 
# for (ii in 1:length(vakTiles$tiles)){
#   print(ii)
#   bathytile <- raster::brick(vakTiles$tiles[ii])
#   # this will give priority to the most recent
#   if (timevak %in% names(bathytile))  {
#     rs <- subset(bathytile, timevak)
#     df_tx <- append(df_tx, list(rs))
#   }
# }
# # should include 
# rsextra <- list(subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB126_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB125_2120.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB125_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB124_1716.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB124_2120.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB124_1918.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB124_1918.nc"), "X2009.01.01"),subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1716.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1514.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_2120.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1918.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB123_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1514.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1716.nc"), "X2011.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1716.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB121_1716.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB121_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_1918.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB121_2120.nc"), "X2009.01.01"), subset(raster::brick("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/vaklodingenKB122_2120.nc"), "X2009.01.01"))
# df_tx <- append(rsextra, df_tx)
# m <- do.call(merge, df_tx) 
# crs(m )=CRS("+init=EPSG:28992")
# writeRaster(m, paste0("../mosaic_", yearsvak[yy]), format = "GTiff")
# 
# 
# ## Friesche Gat polygonen
# opendapdatapath <- "http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/"
# vakTiles <- fread("..//FriescheGatVaklodingen.csv")
# vakTiles$tiles <- paste0(opendapdatapath, vakTiles$tiles)
# stacks <- list()
# 
# # list all possible years available in netcdf
# for (ii in 1:length(vakTiles$tiles)){
#   bathytile <- raster::brick(vakTiles$tiles[ii])
#   stacks <- append(stacks, names(bathytile))
# }
# ustacks <- unique(stacks)
# alltimes <- str_sort(ustacks) # here is the array of all stacks
# 
# # now per tile per year, create tiles and overlap with most recent years on top.
# for (ii in 1:length(vakTiles$tiles)){
#   print(ii)
#   bathytile <- raster::brick(vakTiles$tiles[ii])
#   # this will give priority to the most recent
#   for (jj in 1:length(alltimes)){
#     if (alltimes[jj] %in% names(bathytile)) {
#       if (alltimes[jj] == names(bathytile)[1]) { # if it's the first stack
#         df_tx <- list(subset(bathytile, alltimes[jj]))
#         m <- subset(bathytile, alltimes[jj])
#       } else {
#         rs <- subset(bathytile, alltimes[jj])
#         rs_file <- raster::brick(paste0(filenameRaster,'.tif')) # previous files
#         df_tx <- append(list(rs), list(rs_file)) # give priority to recent ones.
#         m <- do.call(merge, df_tx)
#       }
#     }
#     crs(m) <- CRS("+init=EPSG:28992")
#     filenameRaster <- paste0("FG_processing_tiles/", str_sub(basename(vakTiles$tiles[ii]),1,-4),'_',str_sub(alltimes[jj],1,5))
#     writeRaster(m, filenameRaster, format = "GTiff", overwrite=TRUE)
#   }
# }
# 
# # merge files per year
# yearsvak <- c(2005, 2010, 2016)
# for (yy in 1:length(yearsvak)){
#   rsmerging <- list(raster::brick(paste0("../FG_processing_tiles/vaklodingenKB129_1312_X",yearsvak[yy],".tif")), 
#                   raster::brick(paste0("../FG_processing_tiles/vaklodingenKB129_1514_X",yearsvak[yy],".tif")),
#                   raster::brick(paste0("../FG_processing_tiles/vaklodingenKB130_1312_X",yearsvak[yy],".tif")), 
#                   raster::brick(paste0("../FG_processing_tiles/vaklodingenKB130_1514_X",yearsvak[yy],".tif")),
#                   raster::brick(paste0("../FG_processing_tiles/vaklodingenKB131_1312_X",yearsvak[yy],".tif")), 
#                   raster::brick(paste0("../FG_processing_tiles/vaklodingenKB132_1312_X",yearsvak[yy],".tif")),
#                   raster::brick(paste0("../FG_processing_tiles/vaklodingenKB133_1312_X",yearsvak[yy],".tif")))
#   m <- do.call(merge, rsmerging) 
#   crs(m )=CRS("+init=EPSG:28992")
#   writeRaster(m, paste0("../FG_processing_tiles/mosaic_", yearsvak[yy]), format = "GTiff")
# }