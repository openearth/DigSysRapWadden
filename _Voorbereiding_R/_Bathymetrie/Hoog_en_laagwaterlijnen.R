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
require(readr)

#' Informatie en directories
datadir <- 'p:/11202493--systeemrap-grevelingen/1_data/Wadden/'
crsdata <- CRS('+init=EPSG:28992')
mosaicdir <- file.path(datadir, "RWS", "bathymetrie", "processing_tiles", "mosaic")
mosaiclist <- list.files(mosaicdir)
#years <- as.numeric(gsub("mosaic_|\\.tif", "", mosaiclist)) #create vector of all years with bathymetric data

#' Eerst het grid creeëren
#bathymetry1927 <- raster::raster(file.path(mosaicdir, mosaiclist[1]))  #%>% projectRaster(, crs=28992)
#(plot_bath_1927 <- plot(bathymetry1927)) #lijkt te werken 
#extent <- extent(bathymetry1927) #We need to make this into a grid

#grid_bath1927 <- data.frame(x=c(extent[1], extent[2], extent[1], extent[2]), 
#                            y=c(extent[4], extent[4], extent[3], extent[3]),
#                           r=c('NO', 'NW', 'ZO', 'ZW'))
#grid_bath1927.sp <- grid_bath1927
#coordinates(grid_bath1927.sp) <- ~x+y
#grid_bath1927.sp <- SpatialPoints(grid_bath1927[,1:2], proj4string= crs(bathymetry1927))

#grid.sp <- spsample(x = grid_bath1927.sp, n=10000, type = 'regular') 

#' Nu willen we informatie over de hoog en laagwaterniveas van de verschillende stations door de jaren 
#' Al gedaan voor 3.3 en 3.4
df.extrema <- read_delim(file.path(datadir, "RWS", "standard", paste0("extremaHLLL", "latest", ".csv")), delim = ";") 

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
#all(unique(df.extrema.jaar$jaar[df.extrema.jaar$jaar>1932])==1933:2020) #elk jaar beschikbaar tm 2020
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


doeljaren <- c("1927","1949","1971","1975","1991","2003","2009","2015", "2019") #Same as before, 2019 added

extrema <- df.extrema.jaar %>% filter(jaar %in% doeljaren) %>% 
  pivot_wider(names_from = jaar, values_from = jaargemiddelde, id_cols = c('locatie.naam', 'HL')) %>%  as.data.frame()

ws <- rbind(waterstanden_hw.df %>% mutate(HL = 'H'), waterstanden_lw.df %>% mutate(HL='L')) %>% 
  arrange(locatie.naam) 

for (doeljaar in doeljaren) {
  column_name <- doeljaar
  ws <- ws %>% mutate(!!column_name := as.numeric(doeljaar)*Slope + Intercept)
}


extrema_full <- extrema %>% mutate(across(everything(), ~ coalesce(., ws[[cur_column()]])))


#' So now we can calculate the high and low water values for each year. 
#' Next we have to assign the coordinates to the locations
#' 

metadata <- read_delim(file.path(datadir, "ddl/metadata/Wadden_metadata.csv"),delim = ";") %>%
  distinct(locatie.naam, x, y,coordinatenstelsel)
metadata <- metadata %>% group_by(locatie.naam, coordinatenstelsel) %>% summarise(
  x=mean(x), y= mean(y)
)
extrema_full_m <- as.data.frame(left_join(extrema_full, metadata, by= 'locatie.naam'))
ws_m <- as.data.frame(left_join(ws, metadata, by= 'locatie.naam'))

#waterstanden_hw.df <- as.data.frame(left_join(waterstanden_hw.df, metadata, by='locatie.naam'))
#waterstanden_lw.df <- as.data.frame(left_join(waterstanden_lw.df, metadata, by='locatie.naam'))
#' coordinaten verschillen soms een heel klein beetje, ik neem het gemiddelde

#waterstanden_hw.df <- waterstanden_hw.df  %>%  group_by(locatie.naam, Intercept, Slope) %>% 
#  summarise(
#    x = mean(x), y=mean(y)
#  )

#waterstanden_lw.df <- waterstanden_lw.df  %>%  group_by(locatie.naam, Intercept, Slope) %>% 
#  summarise(
#    x = mean(x), y=mean(y)
#  )

#waterstanden1927 <- waterstanden_hw.df %>% mutate(hoogwater = Intercept + (Slope * 1927))

#waterstanden1927 <- left_join(waterstanden1927, 
#                              waterstanden_lw.df %>% 
#                                mutate(laagwater = Intercept + (Slope * 1927)) %>% 
#                                select(laagwater),
#                              by='locatie.naam'
#)

#waterstanden1927.sp <- SpatialPointsDataFrame(coords= waterstanden1927[,4:5], 
#                       data = waterstanden1927, 
#                       proj4string = CRS(paste0('+init=EPSG:', as.character(metadata$coordinatenstelsel)[1]))) 

#crs(waterstanden1927.sp)
#crs(grid.sp)

#waterstanden1927.sp_trans <- spTransform(waterstanden1927.sp, crs(grid.sp))

#crs(waterstanden1927.sp_trans)

#idw_hw_1927 <- gstat::idw(formula = hoogwater ~ 1, locations = waterstanden1927.sp_trans, newdata=grid.sp, idp=1)
#idw_hw_1927.df <- as.data.frame(idw_hw_1927)



#ggplot(aes(x=x1, y=x2, color=var1.pred), data = idw_hw_1927.df)+
#  geom_point()+scale_color_viridis_c()+
#  geom_point(aes(x=x.1, y=y.1), data=as.data.frame(waterstanden1927.sp_trans), color='red', size =2)+
#  annotate('label', x= as.data.frame(waterstanden1927.sp_trans)$x.1, 
#           y=as.data.frame(waterstanden1927.sp_trans)$y.1, 
#           label=as.character(as.data.frame(waterstanden1927.sp_trans)$locatie.naam)) +
#  theme_classic(base_size = 16)



#'Now we make a rasterlayer of the points 
#'First, create an empty raster 

#r <- raster (extent (idw_hw_1927), crs = crs (idw_hw_1927), resolution = c (20, 20))

#hw_1927_r <- rasterize(idw_hw_1927, r, 'var1.pred', crs=crs(idw_hw_1927m))
#plot(hw_1927_r) #why is there nothing here?
#plot(bathymetry1927) #this does work

#summary(hw_1927_r) #There is a lot on NA values appartenly



 #hw_1927_r <- rasterize(x=idw_hw_1927, y=bathymetry1927) #Too much
 #hw_1927_r <- raster(idw_hw_1927, res=20)
 #plot(hw_1927_r)

 #'quickfix? 
 # r2 <- raster(extent(waterstanden1927.sp_trans), crs = crs(waterstanden1927.sp_trans), resolution = c(20,20))
 # create a gstat object with idw parameters
 #g2 <- gstat(formula = hoogwater ~ 1, data = waterstanden1927.sp_trans, set = list(idp = 1))
 # interpolate the SpatialPointsDataFrame using idw
 #r3 <- interpolate(r2, g2)
 #plot_hw_1927 <- plot(r3, main='Highwaterlevel1927', legend=T)  #Seems to work!
 #plot_hw_1927 + points(waterstanden1927.sp_trans, pch=16, col='red') +
   #text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7)

#r <- raster(extent(bathymetry1927), crs = crs(waterstanden1927.sp_trans), resolution = c(20,20))
#gobj1927_hw <- gstat(formula = hoogwater ~ 1, data = waterstanden1927.sp_trans, set = list(idp = 1))
#r_1927_hw <- interpolate(r, gobj1927_hw) #runs 5 mins

#' Ook voor laagwater
##gobj1927_lw <- gstat(formula= laagwater~1, data =waterstanden1927.sp_trans, set=list(idp=1))
#r_1927_lw <- interpolate(r, gobj1927_lw)
#plot(r_1927_hw, main='Highwaterlevel1927', legend=T) + points(waterstanden1927.sp_trans, pch=16, col='red') +
#  text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7)
#plot(r_1927_lw, main='Lowwaterlevel1927', legend=T) + points(waterstanden1927.sp_trans, pch=16, col='red') +
#  text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7)

#plot(r_1927_hw - bathymetry1927) #This is great, we can extract them from each other, automatically shwos the appreciated extend because of NA values

#' De effecten per locatie doven vrij snel uit, dus ik kijk even verder naar de idw-waarde
#idw1 <- r_1927_hw
#idw5 <- interpolate(r, gstat(formula = hoogwater ~ 1, data = waterstanden1927.sp_trans, set = list(idp = 5)))
#idw2 <- interpolate(r, gstat(formula = hoogwater ~ 1, data = waterstanden1927.sp_trans, set = list(idp = 2)))
#idw3 <- interpolate(r, gstat(formula = hoogwater ~ 1, data = waterstanden1927.sp_trans, set = list(idp = 3)))

#par(mfrow=c(1,2))

#plot_idw1 <- plot(idw1, main='Highwaterlevel1927', legend=T) + points(waterstanden1927.sp_trans, pch=16, col='red') +
  #text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7)
#plot_idw5 <- plot(idw5, main='Highwaterlevel1927', legend=T) + points(waterstanden1927.sp_trans, pch=16, col='red') +
  #text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7) #That seems too high
#plot_idw2 <- plot(idw2, main='Highwaterlevel1927', legend=T) + points(waterstanden1927.sp_trans, pch=16, col='red') +
  #text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7)#Seems fine, lets try 3 as well
#plot_idw3 <- plot(idw3, main='Highwaterlevel1927', legend=T) + points(waterstanden1927.sp_trans, pch=16, col='red') +
  #text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7) #Borders seem to strong, for example for Texel Noordzee/Terschelling and Terschelling Noordzee/Nes
#plot(idw1, main='Highwaterlevel1927', legend=T) + points(waterstanden1927.sp_trans, pch=16, col='red') +
  #text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7) - plot(idw2, main='Highwaterlevel1927', legend=T) + points(waterstanden1927.sp_trans, pch=16, col='red') +
  #text(waterstanden1927.sp_trans, labels = waterstanden1927.sp_trans$locatie.naam, cex = 0.7)

#' To get a feeling for the best idw, I used the intertides tool to draw an image of mean high and low water levels in 2019.
#' This image is on a 100m grid, because the site was unstable and lower resoluitons took longer
#' I think it gives a good idea though. 
##bathymetry2019 <- raster::raster(file.path(mosaicdir, mosaiclist[47]))
#plot(bathymetry2019)

#for (jaar in doeljaren){
#  level <- waterstanden_hw.df$Intercept +waterstanden_hw.df$Slope * as.numeric(jaar)
#  waterstanden_hw.df[[jaar]] <- level
#}

#waterstanden_hw.df <- waterstanden_hw.df %>% mutate(level = 'hoogwater') %>% as.data.frame()


#for (jaar in doeljaren){
#  level <- waterstanden_lw.df$Intercept +waterstanden_lw.df$Slope * as.numeric(jaar)
#  waterstanden_lw.df[[jaar]] <- level
#}

#waterstanden_lw.df <- waterstanden_lw.df %>% mutate(level = 'laagwater') %>% as.data.frame()

#waterstanden_df <- rbind(waterstanden_hw.df, waterstanden_lw.df) %>% 
#  rename(HL = level) %>% 
#  pivot_longer(cols=unlist(doeljaren[1:9]), names_to = 'jaar', values_to = 'waterlevel')%>% 
#  mutate(ind = paste0(HL, as.character(jaar)))

#nrow(waterstanden_df)==length(unique(waterstanden_df$jaar))*
#  length(unique(waterstanden_df$locatie.naam))*length(unique(waterstanden_df$HL)) 

#Maak raster
bathymetry1927 <- raster::raster(file.path(mosaicdir, mosaiclist[1]))
r <- raster(extent(bathymetry1927), crs = crs(bathymetry1927), resolution = c(20,20)) 

r_lowres <- raster(extent(bathymetry1927), crs = crs(bathymetry1927), resolution = c(200,200)) 

#'Maak gstat objects
#'
#spdfs <- list()
#for (indicator in unique(waterstanden_df$ind)) {
#  spdfs[[indicator]] <- SpatialPointsDataFrame(
#    coords = waterstanden_df %>% filter(ind == indicator) %>% select(x,y),
#    data = waterstanden_df %>% filter(ind == indicator),
#    proj4string = CRS(paste0('+init=EPSG:', as.character(metadata$coordinatenstelsel)[1]))
#  )
#}
#spdfs_trans <- list()
#for (indicator in unique(waterstanden_df$ind)){
#  spdfs_trans[indicator] <- spTransform(spdfs[[indicator]], crs(bathymetry1927))
#}
#
#objs <- list()
#for (indicator in unique(waterstanden_df$ind)){
#  gobjs[[indicator]]<- gstat(formula= waterlevel~1, data =spdfs_trans[[indicator]], set=list(idp=1))
#}

# The following is more efficient 
extrema_full_l <- extrema_full_m %>% 
  pivot_longer(cols= doeljaren, names_to = 'jaar', values_to = 'level') %>% 
  mutate(ind = paste0(jaar,HL))

ws_l <- ws_m %>% 
  pivot_longer(cols = doeljaren, names_to = 'jaar', values_to = 'level') %>% 
  mutate(ind = paste0(jaar, HL))

#' This is now for extrema
spdfs <- list()
spdfs_trans <- list()
gobjs <- list()

unique_indicators <- unique(extrema_full_l$ind)

for (indicator in unique_indicators) {
  # Creating SpatialPointsDataFrame
  spdfs[[indicator]] <- SpatialPointsDataFrame(
    coords = extrema_full_l %>% filter(ind == indicator) %>% select(x, y),
    data = extrema_full_l %>% filter(ind == indicator),
    proj4string = CRS(paste0('+init=EPSG:', as.character(metadata$coordinatenstelsel)[1]))
  )
  # Coordinate Transformation
  spdfs_trans[[indicator]] <- spTransform(spdfs[[indicator]], crs(bathymetry1927))
  # Make Gstat objects 
  gobjs[[indicator]] <- gstat(formula = level ~ 1, data = spdfs_trans[[indicator]], set = list(idp = 3))
}

r_lw2019 <- interpolate(r, gobjlaagwater2019) 
r_hw2019 <- interpolate(r, gobjhoogwater2019)

plot(r_lw2019, main='lowwater 2019', legend=T) + points(spdfs_trans[[1]], pch=16, col='red')+
  text(spdfs_trans[[1]], labels = spdfs_trans[[1]]$locatie.naam, cex = 0.7)
plot(r_hw2019, main='highwater 2019', legend=T) + points(spdfs_trans[[1]], pch=16, col='red')+
  text(spdfs_trans[[1]], labels = spdfs_trans[[1]]$locatie.naam, cex = 0.7)

#' I want to compare this with intertides output, to assess the idw-value 
it_high_20m <- raster::raster(file.path(datadir, "RWS/hoogLaagWaters/intertides_output/Mean_High_20m_2019.asc"))
it_low_20m <- raster::raster(file.path(datadir, "RWS/hoogLaagWaters/intertides_output/Mean_Low_20m_2019.asc"))

crs(it_high_20m) <- crs(r_hw2019)
crs(it_low_20m) <- crs(r_lw2019)

#it_high_20m@data@values <- it_high_20m@data@values/100
#it_low_20m@data@values <- it_low_20m@data@values/100


#plot(it_high_20m - r_hw2019) #This works!
#plot(it_low_20m - r_lw2019)

#dif_idw1_high <- r_hw2019 - it_high_20m
#dif_idw1_low <- r_lw2019 - it_low_20m

#plot(r_hw2019)
#plot(it_high_20m)

#spdfs_trans[['hoogwater2019']]
#gobjs[[indicator]] <- gstat(formula = waterlevel ~ 1, data = spdfs_trans[[indicator]], set = list(idp = 1))

gobjs_idw_hw <- list()
gobjs_idw_lw <- list()
r_idw_hw <- list()
r_idw_lw <- list()

for (idw in 1:3){
  gobjs_idw_hw[[idw]] <- gstat(formula = level ~ 1, data = spdfs_trans[['2019H']], set = list(idp = idw))
  gobjs_idw_lw[[idw]] <- gstat(formula = level ~ 1, data = spdfs_trans[['2019L']], set = list(idp = idw))
    print(paste0('start interpolating idp = ', as.character(idw)))
    r_idw_hw[[idw]] <- interpolate(r, gobjs_idw_hw[[idw]])
    r_idw_lw[[idw]] <- interpolate(r, gobjs_idw_lw[[idw]])
      r_idw_hw[[idw]]@data@values <- r_idw_hw[[idw]]@data@values*100
      r_idw_lw[[idw]]@data@values <- r_idw_lw[[idw]]@data@values*100
}

for (i in 1:3){
  plot(r_idw_hw[[i]])
  plot(r_idw_lw[[i]])
} #idw 1 is not multiplied (and does not contain values)


for (i in 1:3){
  plot(it_high_20m - r_idw_hw[[i]], zlim=c(-30,30))+title(paste0('Highwater idw = ', as.character(i)))
  plot(it_low_20m - r_idw_lw[[i]], zlim = c(-30,30))+title(paste0('Lowwater idw = ', as.character(i)))
}


## compare with ws for 2019 
spdfs_c <- list()
spdfs_trans_c <- list()

ind_c <- c('2019H', '2019L')

for (indicator in ind_c) {
  # Creating SpatialPointsDataFrame
  spdfs_c[[indicator]] <- SpatialPointsDataFrame(
    coords = ws_l %>% filter(ind == indicator) %>% select(x, y),
    data = ws_l %>% filter(ind == indicator),
    proj4string = CRS(paste0('+init=EPSG:', as.character(metadata$coordinatenstelsel)[1]))
  )
  # Coordinate Transformation
  spdfs_trans_c[[indicator]] <- spTransform(spdfs_c[[indicator]], crs(bathymetry1927))
}

gobjs_idw_hw_c <- list()
gobjs_idw_lw_c <- list()
r_idw_hw_c <- list()
r_idw_lw_c <- list()

for (idw in 1:3){
  gobjs_idw_hw_c[[idw]] <- gstat(formula = level ~ 1, data = spdfs_trans_c[['2019H']], set = list(idp = idw))
  gobjs_idw_lw_c[[idw]] <- gstat(formula = level ~ 1, data = spdfs_trans_c[['2019L']], set = list(idp = idw))
  print(paste0('start interpolating idp = ', as.character(idw)))
  r_idw_hw_c[[idw]] <- interpolate(r, gobjs_idw_hw_c[[idw]])
  r_idw_lw_c[[idw]] <- interpolate(r, gobjs_idw_lw_c[[idw]])
  r_idw_hw_c[[idw]]@data@values <- r_idw_hw_c[[idw]]@data@values*100
  r_idw_lw_c[[idw]]@data@values <- r_idw_lw_c[[idw]]@data@values*100
}

for (i in 1:3){
  plot(it_high_20m - r_idw_hw_c[[i]], zlim=c(-30,30))+title(paste0('Highwater idw = ', as.character(i), ' lm'))
  plot(it_low_20m - r_idw_lw_c[[i]], zlim = c(-30,30))+title(paste0('Lowwater idw = ', as.character(i), ' lm'))
}

#' Upon visual inspection here, i would suggest using idw = 3, and i think it makes sense to use actual
#' data of the available years, rather than using the trendline to predict values for every year


watervlakken <- list()
for (object in unique_indicators){
  print(paste0('start idw for ', object))
  watervlakken[[object]] <- interpolate(r, gobjs[[object]])
} #Takes about 90 mins to run

for (indicator in unique_indicators) {
  if (!inMemory(watervlakken[[indicator]])){
    print(paste0('start idw interpolation for ', indicator))
    gc()
    watervlakken[[indicator]] <- interpolate(r, gobjs[[indicator]])
  }
}

#' Save the large file!
# save(watervlakken, file = 'watervlakken.Rdata')
# load('watervlakken.Rdata')

#vlakfigs <- list()
#for (vlak in unique(waterstanden_df$ind)){
#  vlakfigs[[vlak]] <- plot(watervlakken[[vlak]], main = as.character(vlak))+points(spdfs_trans[[1]], pch=16, col='red')+
#    text(spdfs_trans[[1]], labels = spdfs_trans[[1]]$locatie.naam, cex = 0.7)
#} #This does not work (because plot() objects cannot be stored?)


## LOWRES watervlakken
watervlakken_lowres <- list()

for (object in unique_indicators){
  print(paste0('start idw for ', object))
  watervlakken_lowres[[object]] <- interpolate(r_lowres, gobjs[[object]])
}


#' Now we want to create separate values for the different arealen: geul, subtidal, intertidal and supratitidal
#' Here we try this

matrix <- cbind(from=c(-Inf,0),
                to = c(0, Inf),
                becomes = c(0, 1))
matrix_inv <- cbind(from=c(-Inf,0),
                    to = c(0, Inf),
                    becomes = c(1, 0))
#matrices are used to define which part is set at 0 or at 1, based on water depth
#start for 2019

bathymetry2019 <-raster::raster(file.path(mosaicdir, mosaiclist[47]))

plot(bathymetry2019)
plot(bathymetry2019-5)
plot(watervlakken[["laagwater2019"]])
plot(watervlakken[["laagwater2019"]]-bathymetry2019)



subtidal_2019 <- reclassify(watervlakken[["2019L"]]-bathymetry2019, matrix)#correct
geul_2019_1 <- reclassify(bathymetry2019+5, matrix_inv) #correct
geul_2019_2 <- reclassify((watervlakken[["2019L"]]-2)-bathymetry2019, matrix) #correct
supratidal_2019 <- reclassify(bathymetry2019-watervlakken[['2019H']], matrix) #correct
#intertidal_2019 <- reclassify(watervlakken[["2019L"]]-bathymetry2019, matrix_inv)-
#  reclassify(bathymetry2019-watervlakken[['2019H']], matrix_inv) #This looks good, but 0s are intertidal here

intertidal_2019 <- reclassify(reclassify(watervlakken[["2019L"]]-bathymetry2019, matrix_inv)-
                                reclassify(bathymetry2019-watervlakken[['2019H']], matrix_inv), 
                              rcl = cbind(from = c(-Inf, -.01, .01),to = c(-.01, .01, Inf), become = c(0,1,0)))


plot(subtidal_2019)
plot(geul_2019_1)
plot(geul_2019_2)
plot(intertidal_2019)
plot(supratidal_2019)

geul_2019_1@data@values

str(intertidal_2019)
sum(subtidal_2019@data@values[!is.na(subtidal_2019@data@values)])*400/1000000
sum(geul_2019_1@data@values[!is.na(geul_2019_1@data@values)])*400/1000000
sum(geul_2019_2@data@values[!is.na(geul_2019_2@data@values)])*400/1000000
sum(supratidal_2019@data@values[!is.na(supratidal_2019@data@values)])*400/1000000
sum(intertidal_2019@data@values[!is.na(intertidal_2019@data@values)])*400/1000000

#This seems to work and returns areas. Lets try to make a function to do this.

arealen_per_doeljaar <- function(doeljaar){
  bath <- raster::raster(paste0(mosaicdir,'/mosaic_', as.character(jaar),'.tif'))
  geul <- reclassify(bath+5, matrix_inv) 
  #or geul <- reclassify((watervlakken[[paste0("laagwater", as.character(jaar))]]-2)-bath, matrix)
  subtidal <- reclassify(watervlakken[[paste0("laagwater", as.character(jaar))]]-bath, matrix)
  intertidal <- reclassify(watervlakken[[paste0("laagwater", as.character(jaar))]]-bath, matrix_inv)-
    reclassify(bath-watervlakken[[paste0("hoogwater", as.character(jaar))]], matrix_inv)
  supratidal <- reclassify(bath-watervlakken[[paste0("hoogwater", as.character(jaar))]], matrix)
}


arealen <- list()
for (jaar in doeljaren){
  print(jaar)
  arealen[[jaar]] <- arealen_per_doeljaar(jaar)
} #something goes wrong, because the watervlakken of 1991 are in a weird location. 
#' Code itsels seems fine though 

#' Voordat we de arealen berekenen, willen we eerst de kaarten (bathymetrie, hoogwater en laagwater opknippen in de deelgebieden en deel-deelgebieden). 
#' Dit willen we doen voor ieder doeljaar

polygonpath <- "https://opengeodata.wmr.wur.nl/geoserver/WS3shp/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=WS3shp%3Aws3_tidalbasins&outputFormat=application/json"
polygonsInRaster <- c(35, 36, 37, 29, 30, 31, 32, 38, 33)
poly <- sf::st_read(polygonpath, quiet = T) %>% 
  filter(fid %in% polygonsInRaster) %>% 
  st_transform(crs(bathymetry1927))
#' Dit wordt al eerder gedaan als het goed is. 
#' Daarbij willen we ook de deelgebieden (van Marsdiep) uit de Kombergingsrapportage gebruiken. 
deelgebieden <- c('Balgzand', 'Boontjes', 'DooveBalg', 'Scheurrak', 'Texelstroom', 'Zwanenbalg')
deelgebieden_sf <- list()

for (deelgebied in deelgebieden){
  deelgebieden_sf[[deelgebied]] <- read_table(
    paste0("N:/Projects/11209000/11209267/B. Measurements and calculations/01. Kombergingsrapportage/",
           as.character(deelgebied),".pol"),
                                  skip = 7, col_names = c('x', 'y'))
  deelgebieden_sf[[deelgebied]] <- deelgebieden_sf[[deelgebied]] %>% st_as_sf(coords=c('x', 'y'), crs= 9001) %>% 
    st_combine() %>% st_cast("POLYGON") 
  deelgebieden_sf[[deelgebied]] <- deelgebieden_sf[[deelgebied]] %>% st_sf(var = 1, deelgebieden_sf[[deelgebied]])
}

lagen <- as.data.frame(jaar=doeljaren,
                       bathymetry = bathymetries)

#bathymetries <- stack(file.path(mosaicdir,mosaiclist[mosaiclist %in% paste0(rep('mosaic_', length(doeljaren)),
#                                                                            doeljaren, 
#                                                                            rep('.tif', length(doeljaren)))]))

for (jaar in doeljaren) {
  bathy[[jaar]] <- raster::raster(file.path(mosaicdir, paste0('mosaic_', as.character(jaar), '.tif')))
}

lagen <- list(jaar=doeljaren, bathymetry = bathy, hoogwater = watervlakken[1:9], laagwater = watervlakken[10:18])

#' Nu willen we per jaar de areaalgebieden beschrijven. 
#' 

for (i in 1:length(doeljaren)){
  lagen$subtidal[[i]] <- reclassify(lagen$laagwater[[i]] - lagen$bathymetry[[i]], matrix)
  #lagen$geul[[i]] <- reclassify(lagen$bathymetry[[i]]+5, matrix_inv)
  lagen$geul[[i]] <- reclassify((lagen$laagwater[[i]]-2)-lagen$bathymetry[[i]],matrix)
  lagen$supratidal[[i]] <- reclassify(lagen$bathymetry[[i]]-lagen$hoogwater[[i]], matrix)
  lagen$intertidal[[i]] <- reclassify(reclassify(lagen$laagwater[[i]]-lagen$bathymetry[[i]], matrix_inv)-
    reclassify(lagen$bathymetry[[i]]-lagen$hoogwater[[i]], matrix_inv),rcl =cbind(from = c(-Inf, -.01, .01),to = c(-.01, .01, Inf), become = c(0,1,0)))
}

#REMOVE AFTER THIS WORKS
for (i in 1:4){
  lagen$subtidal[[i+5]] <- reclassify(lagen$laagwater[[i+5]] - lagen$bathymetry[[i+5]], matrix)
  #lagen$geul[[i]] <- reclassify(lagen$bathymetry[[i]]+5, matrix_inv)
  lagen$geul[[i+5]] <- reclassify((lagen$laagwater[[i+5]]-2)-lagen$bathymetry[[i+5]],matrix)
  lagen$supratidal[[i+5]] <- reclassify(lagen$bathymetry[[i+5]]-lagen$hoogwater[[i+5]], matrix)
  lagen$intertidal[[i+5]] <- reclassify(reclassify(lagen$laagwater[[i+5]]-lagen$bathymetry[[i+5]], matrix_inv)-
                                        reclassify(lagen$bathymetry[[i+5]]-lagen$hoogwater[[i+5]], matrix_inv),rcl =cbind(from = c(-Inf, -.01, .01),to = c(-.01, .01, Inf), become = c(0,1,0)))
}




for (deelgebied in deelgebieden){
  assign(paste0('lagen_', deelgebied)) <- list()
}

Boontjes <- list()

for (jaar in doeljaren){
  
  intertidalarea <- raster::mask(raster::crop(lagen$, Zwanenbalgpol.df),Zwanenbalgpol.df)
  
}


# alternatively, we look at the shapefiles made by Julia
Zwanenbalg <- read_table("N:/Projects/11209000/11209267/B. Measurements and calculations/01. Kombergingsrapportage/Zwanenbalg.pol",
                         skip = 7)
colnames(Zwanenbalg) <- c('x', 'y')
Zwanenbalgpol <- Zwanenbalg %>% st_as_sf(coords=c('x', 'y'), crs= 9001) %>% st_combine() %>% st_cast("POLYGON")
Zwanenbalgpol.df <- st_sf(var = 1, Zwanenbalgpol)


plot(intertidal_2019)+plot(Zwanenbalgpol, add=T, border='red', lwd=2)

st_crop(intertidal_2019, st_bbox(Zwanenbalgpol),Zwanenbalgpol) #doesnt work
st_crop(intertidal_2019, Zwanenbalgpol) #doesnt work
bathymetry2019
intertial_2019.sf <- st_as_sf(intertidal_2019) #doesnt work

plot(raster::crop(intertidal_2019, Zwanenbalgpol.df))+plot(Zwanenbalgpol, add=T, border='red', lwd=2)
intertidal_2019_zwanenbalg_crop <- raster::crop(intertidal_2019, Zwanenbalgpol.df)
intertidal_2019_zwanenbalg_mask <- raster::mask(intertidal_2019_zwanenbalg_crop, Zwanenbalgpol.df)
intertidalarea2019 <- raster::mask(raster::crop(intertidal_2019, Zwanenbalgpol.df),Zwanenbalgpol.df)
plot(intertidalarea2019)
plot(intertidal_2019_zwanenbalg_mask) #This works 

length(intertidal_2019_zwanenbalg_mask@data@values[!is.na(intertidal_2019_zwanenbalg_mask@data@values) & intertidal_2019_zwanenbalg_mask@data@values==0])*400/1000000


Deelgebied_per_ <- try(
  lapply(
    1:nrow(poly),
    function(x)   
      raster::mask(
        raster::crop(bathymetries, extent(poly[x,])), poly[x,]
      )
  )
)




