

csvfile <- "_Voorbereiding_R/_Bathymetrie/WaddenZeeVaklodingen.csv"
processingpath <- "_Voorbereiding_R/_Bathymetrie/processing_tiles_doeljaren/"

# install.packages("terra")
library(data.table)
require("raster")
require(stringr)

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

## run only once to download all nc files
# lapply(
#   vakTiles$tiles,
#   function(x) {
#     try(
#       download.file(url = gsub("dodsC", "fileServer",x),
#                     destfile = file.path(
#                       "_Voorbereiding_R",
#                       "_Bathymetrie",
#                       "processing_tiles",
#                       "nc",
#                       gsub("http://opendap.deltares.nl/thredds/dodsC/opendap/rijkswaterstaat/vaklodingen_new/", "",x)
#                     ), mode = 'wb'
#       )
#     )
#   }
# )


## create processing folder and subfolders, if they don't exist
dir.create(processingpath)
dir.create(paste0(processingpath,"tiles"))
dir.create(paste0(processingpath,"mosaic"))


## list all possible years available in netcdf
vakTiles2 <- list.files(file.path("_Voorbereiding_R", "_Bathymetrie", "processing_tiles_doeljaren", "nc"), full.names = T)
vakTiles2 <- list.files(file.path("_Voorbereiding_R", "_Bathymetrie", "processing_tiles", "nc"), full.names = T)
for (ii in 1:length(vakTiles2)){
  bathytile <- raster::brick(vakTiles2[ii])
  stacks <- append(stacks, names(bathytile))
}
ustacks <- unique(stacks)
alltimes <- str_sort(ustacks) # here is the array of all stacks

makeTiles <- function(vakTiles2, alltimes, processingpath){
  ## create tiles and overlap with most recent years on top, per tile and per year.
  # this for-loop takes approx. 2 minutes per tile.
  for (ii in 1:length(vakTiles2)){
    print(ii)
    bathytile <- raster::brick(vakTiles2[ii])
    ccount <- 0
    m <- NULL
    filenameRaster_previous <- NULL
    for (jj in 1:length(alltimes)){
      print(paste(str_sub(basename(vakTiles2[ii]),1,-4), ' ',alltimes[jj]))
      print(paste('ccount is', ' ', ccount))
      filenameRaster <- paste0(processingpath, "tiles/", str_sub(basename(vakTiles2[ii]),1,-4),'_',str_sub(alltimes[jj],1,5))
      if (alltimes[jj] %in% names(bathytile)) {
          ccount <- ccount + 1
          df_tx <- list(raster::subset(bathytile, alltimes[jj]))
          m <- raster::subset(bathytile, alltimes[jj])
          crs(m) <- CRS("+init=EPSG:28992")
        }
      if (length(m) == 0) {
        if (!is.null(filenameRaster_previous)) { # that's when timelayer is not there
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
}

makeTilesDoeljaren <- function(vakTiles2, alltimes, processingpath, doeljaren){
  ## create tiles and overlap with most recent years on top, per tile and per year, 
  # but starting again after each doeljaar
  doeljaren0 <- as.numeric(c(0,doeljaren))
  for (ii in 1:length(vakTiles2)){
    print(ii)
    bathytile <- raster::brick(vakTiles2[ii])
    ccount <- 0
    m <- NULL
    filenameRaster_previous <- NULL
    for (dd in 1:(length(doeljaren))){
      bathytile <- raster::brick(vakTiles2[ii])
      ccount <- 0
      m <- NULL
      filenameRaster_previous <- NULL
      alltimesdoeljaren <- alltimes[as.numeric(substr(alltimes, 2, 5))>doeljaren0[dd] &
                              as.numeric(substr(alltimes, 2, 5))<=doeljaren0[dd+1]]
      if (length(alltimesdoeljaren)==0) {next}
      for (jj in 1:length(alltimesdoeljaren)){
        print(paste(str_sub(basename(vakTiles2[ii]),1,-4), ' ',alltimesdoeljaren[jj]))
        print(paste('ccount is', ' ', ccount))
        filenameRaster <- paste0(processingpath, "tiles/", str_sub(basename(vakTiles2[ii]),1,-4),'_',str_sub(alltimesdoeljaren[jj],1,5))
        if (alltimesdoeljaren[jj] %in% names(bathytile)) {
          ccount <- ccount + 1
          df_tx <- list(raster::subset(bathytile, alltimesdoeljaren[jj]))
          m <- raster::subset(bathytile, alltimesdoeljaren[jj])
          crs(m) <- CRS("+init=EPSG:28992")
        }
        if (length(m) == 0) {
          if (!is.null(filenameRaster_previous)) { # that's when timelayer is not there
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
  }
}

mergeTiles2Mosaic <- function(vakTiles2, alltimes, processingpath){
  ## merge/mosaic files on years
  yearsvak <- as.numeric(unique(str_sub(alltimes,2,5)))
  for (yy in 1:length(yearsvak)){
    rsmerging <- list()
    for (ii in 1:length(vakTiles2)){
      tiff2bmerged <- paste0(
        processingpath, "tiles/", str_sub(basename(vakTiles2[ii]),1,-4),"_X",yearsvak[yy],".tif")
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
    writeRaster(m, paste0(processingpath, "mosaic/", "mosaic_", yearsvak[yy]), format = "GTiff", overwrite=T)
  }
}

# makeTiles(vakTiles2, alltimes, processingpath)

doeljaren <- c("1927","1949","1971","1975","1991","2003","2009","2015")
makeTilesDoeljaren(vakTiles2, alltimes, processingpath, doeljaren)
# from the mosaic folder, just select the doeljaren
mergeTiles2Mosaic(vakTiles2, alltimes, processingpath) 

