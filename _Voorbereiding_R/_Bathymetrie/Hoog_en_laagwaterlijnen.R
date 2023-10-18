#' Hoog- en laagwaterlijn 
#' 
require(sf)
require(raster)
require(ggplot2)
require(gridExtra)
require(raster)
require(gstat)
require(sp)
require(tidyverse)
require(rgdal)

#' Informatie en directories
datadir <- 'p:/11202493--systeemrap-grevelingen/1_data/Wadden/'
crsdata <- CRS('+init=EPSG:28992')
mosaicdir <- file.path(datadir, "RWS", "bathymetrie", "processing_tiles", "mosaic")
mosaiclist <- list.files(mosaicdir)
years <- as.numeric(gsub("mosaic_|\\.tif", "", mosaiclist)) #create vector of all years with bathymetric data

#' Eerst het grid creeëren
bathymetry1927 <- raster::raster(file.path(mosaicdir, mosaiclist[1]))  #%>% projectRaster(, crs=28992)
(plot_bath_1927 <- plot(bathymetry1927)) #lijkt te werken 
extent <- extent(bathymetry1927) #We need to make this into a grid

grid_bath1927 <- data.frame(x=c(extent[1], extent[2], extent[1], extent[2]), 
                            y=c(extent[4], extent[4], extent[3], extent[3]),
                            r=c('NO', 'NW', 'ZO', 'ZW'))
grid_bath1927.sp <- grid_bath1927
coordinates(grid_bath1927.sp) <- ~x+y
grid_bath1927.sp <- SpatialPoints(grid_bath1927[,1:2], proj4string= crs(bathymetry1927))

grid.sp <- spsample(x = grid_bath1927.sp, n=10000, type = 'regular') 

#' Nu willen we informatie over de hoog en laagwaterniveas van de verschillende stations door de jaren 
#' Al gedaan voor 3.3 en 3.4
df.extrema <- read_delim(file.path(datadir, "RWS", "standard", paste0("extremaHLLL", "latest", ".csv")), delim = ";") %>%
  mutate(h = h * 100)

df.extrema.jaar <- df.extrema %>%
  mutate(jaar = year(time)) %>% 
  # group_by(locatie.naam) %>%
  # mutate(across(h, remove_outliers)) %>%
  group_by(locatie.naam, jaar, HL) %>% 
  summarise(
    jaargemiddelde = mean(h, na.rm = T),
    n = n())
#'Laten we 1927 gewoon weer gebruiken
waterstanden1927 <- df.extrema.jaar %>% filter(jaar == 1927) 
#'Dat werkt niet, want toen werd nog niet overal gemeten
#'We moeten dus echt trendlijnen gaan maken, voor het gemak eerst even voor de hele periode van 1933 tot en met nu
#'
all(unique(df.extrema.jaar$jaar[df.extrema.jaar$jaar>1932])==1933:2020) #elk jaar beschikbaar tm 2020
waterstanden <- df.extrema.jaar %>% filter(jaar >1932)
HW_plot <- 
  ggplot(aes(x=jaar, y=jaargemiddelde, color=locatie.naam), data=as.data.frame(waterstanden) %>% 
           mutate(HL=factor(HL)) %>% mutate(locatie.naam= factor(locatie.naam)) %>% 
           filter(HL=='H'))+
  geom_point()+
  geom_smooth(method='lm')+
  ggtitle('Hoogwater')+theme_bw()
HW_plot

LW_plot <- 
  ggplot(aes(x=jaar, y=jaargemiddelde, color=locatie.naam), data=as.data.frame(waterstanden) %>% 
           mutate(HL=factor(HL)) %>% mutate(locatie.naam= factor(locatie.naam)) %>% 
           filter(HL=='L'))+
  geom_point()+
  geom_smooth(method = 'lm')+
  ggtitle('Laagwater')+theme_bw()
LW_plot

lmH <- lm(jaargemiddelde ~ jaar * locatie.naam, data=waterstanden %>% filter(HL== 'H'))

n <- length(unique(waterstanden$locatie.naam))
waterstanden_hw.df <- data.frame(locatie.naam = unique(waterstanden$locatie.naam),
                                 Intercept = unname(summary(lmH)$coefficients[,1])[c(1,(3):(n+1))],
                                 Slope = unname(summary(lmH)$coefficients[,1])[c(2,(n+2):(2*n))])
hwDInt <- waterstanden_hw.df$Intercept[1]
hwDSlo <- waterstanden_hw.df$Slope[1]

waterstanden_hw.df$Intercept[2:n] <- hwDInt + waterstanden_hw.df$Intercept[2:n]
waterstanden_hw.df$Slope[2:n] <- hwDSlo + waterstanden_hw.df$Slope[2:n]

lmL <- lm(jaargemiddelde ~ jaar * locatie.naam, data=waterstanden %>% filter(HL== 'L'))

waterstanden_lw.df <- data.frame(locatie.naam = unique(waterstanden$locatie.naam),
                                 Intercept = unname(summary(lmL)$coefficients[,1])[c(1,(3):(n+1))],
                                 Slope = unname(summary(lmL)$coefficients[,1])[c(2,(n+2):(2*n))])
lwDInt <- waterstanden_lw.df$Intercept[1]
lwDSlo <- waterstanden_lw.df$Slope[1]

waterstanden_lw.df$Intercept[2:n] <- lwDInt + waterstanden_lw.df$Intercept[2:n]
waterstanden_lw.df$Slope[2:n] <- lwDSlo + waterstanden_lw.df$Slope[2:n]

#' So now we can calculate the high and low water values for each year. 
#' Next we have to assign the coordinates to the locations
#' 

metadata <- read_delim(file.path(datadir, "ddl/metadata/Wadden_metadata.csv"),delim = ";") %>%
  distinct(locatie.naam, x, y,coordinatenstelsel)
waterstanden_hw.df <- as.data.frame(left_join(waterstanden_hw.df, metadata, by='locatie.naam'))
waterstanden_lw.df <- as.data.frame(left_join(waterstanden_lw.df, metadata, by='locatie.naam'))
#' coordinaten verschillen soms een klein beetje, ik neem het gemiddelde

waterstanden_hw.df <- waterstanden_hw.df  %>%  group_by(locatie.naam, Intercept, Slope) %>% 
  summarise(
    x = mean(x), y=mean(y)
  )

waterstanden_lw.df <- waterstanden_lw.df  %>%  group_by(locatie.naam, Intercept, Slope) %>% 
  summarise(
    x = mean(x), y=mean(y)
  )

waterstanden1927 <- waterstanden_hw.df %>% mutate(hoogwater = Intercept + (Slope * 1927))

waterstanden1927.sp <- SpatialPointsDataFrame(coords= waterstanden1927[,4:5], 
                       data = waterstanden1927, 
                       proj4string = CRS(paste0('+init=EPSG:', as.character(metadata$coordinatenstelsel)[1]))) 

crs(waterstanden1927.sp)
crs(grid.sp)

waterstanden1927.sp_trans <- spTransform(waterstanden1927.sp, crs(grid.sp))

crs(waterstanden1927.sp_trans)

idw_hw_1927 <- gstat::idw(formula = hoogwater ~ 1, locations = waterstanden1927.sp_trans, newdata=grid.sp, idp=1)
idw_hw_1927.df <- as.data.frame(idw_hw_1927)



ggplot(aes(x=x1, y=x2, color=var1.pred), data = idw_hw_1927.df)+
  geom_point()+scale_color_viridis_c()+
  geom_point(aes(x=x.1, y=y.1), data=as.data.frame(waterstanden1927.sp_trans), color='red', size =2)+
  annotate('label', x= as.data.frame(waterstanden1927.sp_trans)$x.1, 
           y=as.data.frame(waterstanden1927.sp_trans)$y.1, 
           label=as.character(as.data.frame(waterstanden1927.sp_trans)$locatie.naam)) +
  theme_classic(base_size = 16)

ggplot(aes(x=x1, y=x2, color=var1.pred), data = idw_hw_1927.df)+
  geom_point()+scale_color_viridis_c()

#'Now we make a rasterlayer of the points 
#'First, create an empty raster 
r <- raster (extent (idw_hw_1927), crs = crs (idw_hw_1927), resolution = c (20, 20))

hw_1927_r <- rasterize(idw_hw_1927, r, 'var1.pred', crs=crs(idw_hw_1927m))
plot(hw_1927_r) #why is there nothing here?
plot(bathymetry1927) #this does work

summary(hw_1927_r) #There is a lot on NA values appartenly

rna <- reclassify(r, cbind(NA,0))
plot(rna) #hmm


hw_1927_r <- rasterize(x=idw_hw_1927, y=bathymetry1927) #Too much
 hw_1927_r <- raster(idw_hw_1927, res=20)
 plot(hw_1927_r)
 ?raster
  
 #'quickfix? 
 r2 <- raster(extent(waterstanden1927.sp_trans), crs = crs(waterstanden1927.sp_trans), resolution = c(20,20))
 # create a gstat object with idw parameters
 g2 <- gstat(formula = hoogwater ~ 1, data = waterstanden1927.sp_trans, set = list(idp = 1))
 # interpolate the SpatialPointsDataFrame using idw
 r3 <- interpolate(r2, g2)
 plot_hw_1927 <- plot(r3, main='Highwaterlevel1927', legend=T)  #Seems to work!
 plot_hw_1927 + points(waterstanden1927.sp_trans, pch=16, col='red') +
   text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7)

r <- raster(extent(bathymetry1927), crs = crs(waterstanden1927.sp_trans), resolution = c(20,20))
gobj1927_hw <- gstat(formula = hoogwater ~ 1, data = waterstanden1927.sp_trans, set = list(idp = 1))
r_1927_hw <- interpolate(r, gobj1927_hw) #runs 5 mins

plot(r_1927_hw, main='Highwaterlevel1927', legend=T) + points(waterstanden1927.sp_trans, pch=16, col='red') +
  text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7)

plot(r_1927_hw - bathymetry1927)
