#' ## Arealen
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

# source('r/testplotraster.R')

datadir <- 'p:/11202493--systeemrap-grevelingen/1_data/Wadden/'
crsdata <- CRS('+init=EPSG:28992')
# proj4wgs <- CRS('+init=EPSG:4326') #welke is het nou? 
mosaicdir <- file.path(datadir, "RWS", "bathymetrie", "processing_tiles", "mosaic")
mosaiclist <- list.files(mosaicdir)
years <- as.numeric(gsub("mosaic_|\\.tif", "", mosaiclist)) #create vector of all years with bathymetric data

#' #Water levels over time
#' This is based on Julias trendlines (made in Excel)
HWDH <-  (0.175*years-291.44)/100; #Den Helder
HWDH[1] <-  (0.1582*years[1]-266.16)/100;
LWDH <- (0.1129*years-305.54)/100;
LWDH[1] <- (0.1143*years[1]-299.88)/100;

HWH <- (0.2322*years-369.95)/100; #Harlingen
HWH[1] <- (0.2163*years[1]-357)/100;
LWH <- (0.0412*years-178.22)/100;
LWH[1] <- (0.2049*years[1]-462.37)/100;

HWWT <- (0.1825*years-281.29)/100; #West-Terschelling
HWWT[1] <- 64/100; #gemiddelde 1922-1925
LWWT <- (0.0116*years-123.92)/100;
LWWT[1] <- -101.7/100; #gemiddelde 1922-1925

# [x,y]=convertCoordinates(4.74499, 52.96436 ,'CS1.code',4326,'CS2.code',28992); %WT: 5.22003, 53.36305, H: 5.40934, 53.17563
x=c(111.9,156.5,143.9)
y=c(553.2,576.6,597.4)

HW = (HWDH+HWH)/2; # in m
LW = (LWDH+LWH)/2; # in m

OverallWaterHeight <- data.frame(years, HW, LW) #Average yearly High and low water (based on Den Helder and Harlingen only)

#' Eerst kijken of we met deze waterhoogtes voor de jaren de arealen kunnen berekenen
bathymetry1927 <- raster::raster(file.path(mosaicdir, mosaiclist[1]))
bathymetry1927 <- projectRaster(bathymetry1927, crs=28992) #might take some time
crs(bathymetry1927)

#bathymetrywgs1927 <- projectRaster(bathymetry1927, crs = proj4wgs) #Too much BUT NECESSARY
# crs(bathymetry1927) <- proj4wgs #THIS DOES NOT DO THE SAME AS ABOVE
plot(bathymetry1927)
plot(bathymetrywgs1927)
grid <- raster(extent(bathymetry1927), res(bathymetry1927)) 
gridwgs <- raster(extent(bathymetrywgs1927), res(bathymetrywgs1927)) 

(sq_km <- ncell(bathymetry1927)*res(bathymetry1927)[1]*res(bathymetry1927)[2]/1000000) #total area
area(bathymetry1927) #why does it need lon/lat coordinates if is has the resolution?
(sq_km <- ncell(bathymetrywgs1927)*res(bathymetry1927)[1]*res(bathymetry1927)[2]/1000000) #Note: resolution in m from bathymetrywgs <- impact/correct
# sum(area(bathymetrywgs1927))
# x <- area(bathymetrywgs1927)
# cellStats(x,sum)
# str(x)
conversion <- (ncell(bathymetry1927)*res(bathymetry1927)[1]*res(bathymetry1927)[2]/1000000) /
  (ncell(bathymetrywgs1927)*res(bathymetry1927)[1]*res(bathymetry1927)[2]/1000000)
(resolution <- sqrt(20^2*conversion)) #cells with this crs are 19.7 instead of 20 m resolution

#' We kijken naar verschillende gebieden
polygonpath <- "https://opengeodata.wmr.wur.nl/geoserver/WS3shp/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=WS3shp%3Aws3_tidalbasins&outputFormat=application/json"
# selection of relevant polygons done by hand in QGIS
polygonsInRaster <- c(35, 36, 37, 29, 30, 31, 32, 38, 33)

poly <- sf::st_read(polygonpath, quiet = T) %>% 
  filter(fid %in% polygonsInRaster) %>% 
  st_transform(28992)

plot(bathymetrywgs1927)
plot(bathymetry1927)

bathymetries <- stack(file.path(mosaicdir,mosaiclist))
bathymetries <- projectRaster(bathymetries, crs=28992)
crs(bathymetries)

croppedRasters <- try(
  lapply(
    1:nrow(poly),
    function(x)   
      raster::mask(
        raster::crop(bathymetries, extent(poly[x,])), poly[x,]
      )
  )
)

TestcroppedRasters <- croppedRasters

#View(poly[1,])
#str(poly$geometry[1])
#str(bathymetrywgs)

poly_geom <- st_geometry(poly) %>% st_transform(28992)
plot(bathymetry1927)+plot(poly, add=T, border='red', lwd=2)
plot(bathymetry1927)+plot(poly_geom[1], add=T, border='red', lwd=2)
# if (!identical(crs(bathymetry1927), st_crs(poly_geom[1]))) {
#   poly_geom[1] <- st_transform(poly_geom[1], crs(bathymetry1927))
# }

# Try cropping here
bathymetry1927stars <- read_stars(file.path(mosaicdir, mosaiclist[1]))
bathymetry1927stars <- st_transform(bathymetry1927stars, 28992)

Marsdiep <- sf::st_read(polygonpath, quiet = T) %>% 
  filter(fid == 35) %>% st_geometry() 
Marsdiep <- st_transform(Marsdiep, crs(bathymetry1927stars))

Marsdiep_geom <-  st_geometry(Marsdiep)
Marsdiep_geom <- st_transform(Marsdiep_geom, crs(bathymetry1927stars))

plot(bathymetry1927)+plot(Marsdiep_geom, add=T)

ggplot() + 
  geom_stars(data=bathymetry1927stars)+
  geom_sf(Marsdiep_geom)

crop <- st_crop(bathymetry1927stars, Marsdiep_geom)


masked_bath <- mask(crop(bathymetry1927, poly[1,]),poly[1,])#This is the way, apparently
str(poly[1,])
plot(masked_bath)
cropped_bath <- crop(bahtymetry1927, extent(Marsdiep_geom))
?crop

str(poly_geom[1])
str(poly[1])
bathymetry1927_geom1 <- try(mask(crop(bathymetry1927, extent(poly[1,]), poly[1,])))
class(bathymetry1927)
class(poly_geom[1])

bathymetrywgs1927_geom1 <- crop(bathymetrywgs1927,poly_geom[1]) #why is this object not Extent? 
# Waarom werkt dit niet? 

#' Try 
#' 
crs(bathymetry1927)
bathymetry2006 <- raster::raster(file.path(mosaicdir, mosaiclist[34]))
plot(bathymetry2006)
plot(bathymetry1927)

View(bathymetry2006)
plot(bathymetry2006-bathymetry1927)
#' Dan maar eerst voor het hele gebied oppervlaktes berekenen
#'


crs(bathymetry1927) #9001

lower_threshold <- OverallWaterHeight[1,3] #Laag water 1927
upper_threshold <- OverallWaterHeight[1,2] #Hoog water 1927

#subtidal_raster1927 <- reclassify(bathymetrywgs1927, 
#                                    cbind(-Inf, lower_threshold, 1),
#                                    cbind(lower_threshold,Inf, NA))
m_inter <- cbind(from=c(-Inf,lower_threshold, upper_threshold),
           to = c(lower_threshold, upper_threshold, Inf),
           becomes = c(NA, 1, NA))
m_sub <- cbind(from=c(-Inf,lower_threshold, upper_threshold),
               to = c(lower_threshold, upper_threshold, Inf),
               becomes = c(1, NA, NA))
m_geul <- cbind(from=c(-Inf,lower_threshold-2, upper_threshold),
                to = c(lower_threshold-2, upper_threshold, Inf),
                becomes = c(1, NA, NA))
m_supra <- cbind(from=c(-Inf,lower_threshold, upper_threshold),
                 to = c(lower_threshold, upper_threshold, Inf),
                 becomes = c(NA, NA, 1))

m_all <- cbind(from=c(-Inf,lower_threshold-2, lower_threshold, upper_threshold),
               to = c(lower_threshold-2, lower_threshold, upper_threshold, Inf),
               becomes = c(1, 2, 3, 4))

intertidal_raster1927 <- reclassify(bathymetry1927, m_inter)
subtidal_raster1927 <- reclassify(bathymetry1927, m_sub)
geul_raster1927 <- reclassify(bathymetry1927, m_geul)
supratidal_raster1927 <- reclassify(bathymetry1927, m_supra)
combined_raster1927 <- reclassify(bathymetry1927, m_all)

plot(intertidal_raster1927)+plot(poly_geom[1], add=T, border='red', lwd=2)
plot(subtidal_raster1927)+plot(poly_geom[1], add=T, border='red', lwd=2)
plot(geul_raster1927)+plot(poly_geom[1], add=T, border='red', lwd=2)
plot(supratidal_raster1927)+plot(poly_geom[1], add=T, border='red', lwd=2)
plot(combined_raster1927)+plot(poly_geom[1], add=T, border='red', lwd=2)

area_inter1927 <- ncell(intertidal_raster1927)*res(intertidal_raster1927)[1]*res(intertidal_raster1927)[2]/1000000 #hier pakt hij nog steeds alles..
sum(raster::area(intertidal_raster1927, na.rm=TRUE))
sum(area(intertidal_raster1927)) #deze werkt niet 
?cellStats
cellStats(intertidal_raster1927, sum, na.rm=TRUE)+ 
  cellStats(subtidal_raster1927, sum, na.rm=TRUE)+ 
  cellStats(supratidal_raster1927, sum, na.rm=TRUE)#+cellStats(geul_raster1927, sum, na.rm=TRUE)#geul already part of sub
   

area_inter1927 <- cellStats(intertidal_raster1927,sum)*res(intertidal_raster1927)[1]*res(intertidal_raster1927)[2]/1000000



area(intertidal_raster1927,sum)

cellStats(intertidal_raster1927, sum)+ 
  cellStats(subtidal_raster1927, sum)+ 
  cellStats(geul_raster1927, sum)+ 
  cellStats(supratidal_raster1927, sum)

oppervlaktewgscell <- res(bathymetrywgs1927)[1] * res(bathymetrywgs1927)[2] 

cellStats(area(bathymetrywgs1927,sum))

#' Intertidaal
#intertidal_raster1927 <- reclassify(bathymetrywgs1927, cbind(OverallWaterHeight %>% 
#                                                         filter(years==1927) %>% select(HW, LW), 1))




#' Per meetlocatie

dataHW <- data.frame(years,HWDH,HWH, HWWT)

plotHW <- ggplot(dataHW, aes(x = years)) +
  geom_line(aes(y = HWDH, color = "Den Helder"), linetype = "solid", size = 1) +
  geom_line(aes(y = HWH, color = "Harlingen"), linetype = "dashed", size = 1) +
  geom_line(aes(y = HWWT, color = "West-Terschelling"), linetype = "dotted", size = 1) +
  labs(y = "GHW [m + NAP]") +
  xlim(1925, 2025) +
  scale_color_manual(
    values = c("Den Helder" = "blue", "Harlingen" = "black", "West-Terschelling" = "green"),
    name = "Location"
  ) +
  theme_minimal() +
  theme(legend.position = "top") +
  guides(color = guide_legend(title = "Location"))

dataLW <- data.frame(years,LWDH,LWH, LWWT)
plotLW <- ggplot(dataLW, aes(x = years)) +
  geom_line(aes(y = LWDH, color = "Den Helder"), linetype = "solid", size = 1) +
  geom_line(aes(y = LWH, color = "Harlingen"), linetype = "dashed", size = 1) +
  geom_line(aes(y = LWWT, color = "West-Terschelling"), linetype = "dotted", size = 1) +
  labs(y = "GLW [m + NAP]") +
  xlim(1925, 2025) +
  scale_color_manual(
    values = c("Den Helder" = "blue", "Harlingen" = "black", "West-Terschelling" = "green"),
    name = "Location"
  ) +
  theme_minimal() +
  theme(legend.position = "top") +
  guides(color = guide_legend(title = "Location"))

dataGS <- data.frame(years, GSDH = HWDH-LWDH, GSH = HWH - LWH, GSWT = HWWT - LWWT)
plotGS <- ggplot(dataGS, aes(x = years)) +
  geom_line(aes(y = GSDH, color = "Den Helder"), linetype = "solid", size = 1) +
  geom_line(aes(y = GSH, color = "Harlingen"), linetype = "dashed", size = 1) +
  geom_line(aes(y = GSWT, color = "West-Terschelling"), linetype = "dotted", size = 1) +
  labs(y = "Getijslag [m]") +
  xlim(1925, 2025) +
  scale_color_manual(
    values = c("Den Helder" = "blue", "Harlingen" = "black", "West-Terschelling" = "green"),
    name = "Location"
  ) +
  theme_minimal() +
  theme(legend.position = "top") +
  guides(color = guide_legend(title = "Location"))

grid.arrange(plotLW,plotHW,plotGS, ncol=3)

#' Eerst maar eens kijken of we binnen een bepaald gebied (polygoon) voor een specifiek jaar de verschillende arealen kunnen bepalen.
#' Daarvoor hebben we de hoog- en laagwaterwaarden nodig varierend over tijd, alsook de diepte profielen voor ieder jaar. 
#' 
#' 
#' alternative: interpp()

LW_long <- gather(dataLW, 'Location', 'level_lw', c('LWDH', 'LWH', 'LWWT'))
HW_long <- gather(dataHW, 'Location', 'level_hw', c('HWDH', 'HWH', 'HWWT'))
HWLW <- cbind(LW_long, HW_long[,3])

HWLW <- HWLW %>%
  mutate(Location = case_when(
    Location == "LWDH" ~ "Den Helder",
    Location == "LWH"  ~ "Harlingen",
    Location == "LWWT" ~ "West-Terschelling",
    TRUE ~ Location  # Keep other values as they are
  ))

HWLW$Location <- as.factor(HWLW$Location)

coordinates <- data.frame(Location = levels(HWLW$Location),
                          x=x, y=y)
coordinates$Location <- as.factor(coordinates$Location)
HWLW <- merge(HWLW, coordinates)
colnames(HWLW)[4] <- "level_hw"

try1927 <- filter(HWLW, years==1927)
try1927$lon <- c(4.74499, 5.22003, 5.40934)
try1927$lat <- c(52.96436, 53.36305, 53.17563)
# coordinates(try1927) <- c("x", "y")

#' ISSUES WITH GSTAT AND CRS, MAYBE TRY SOMETHING ELSE <-- Later
#proj4string(high_water_model) <- proj4wgs #does not work for gstat
# high_water_frame <- predict(high_water_model, newdata = as.data.frame(grid))

#grid_points <- SpatialPointsDataFrame(
#  coords = grid,
#  data = data.frame(ID = 1:length(grid)), 
#  proj4string  = proj4wgs# Match the CRS 
#)

#grid_points <- spTransform(grid_points, proj4wgs)

#high_water_model$variogram$crs <- proj4wgs

#' Create a spatialpointsdf

coordinates(try1927) <- c('x', 'y')
crs(try1927) <- proj4wgs

grid_x <- seq(xmin(bathymetry1927), xmax(bathymetry1927), length.out = 100)
grid_y <- seq(ymin(bathymetry1927), ymax(bathymetry1927), length.out = 100) #1000 (and 10000) was too much

gridnew <- expand.grid(x = grid_x, y = grid_y)
plot(gridnew)
plot(bathymetry1927)

newgrid <- gridnew  %>% filter(x>120000 | y<610000) %>%  filter(x<180000 | y> 580000)

plot(bathymetry1927)
plot(newgrid)
?gstat()
newgrdcoor <- newgrid
coordinates(newgrdcoor) <- c('x', 'y')
as.data.frame(try1927)
hwm1927 <- gstat(formula = level_hw ~1, data=as.data.frame(try1927))
hwf1927 <- predict(hwm1927, newdata= newgrdcoor)

high_water_model_new <- gstat(
  formula = level_hw ~ 1,
  data = try1927,
  locations = as.data.frame(coordinates(try1927)),
  set = list(crs = proj4wgs)
)



#high_water_frame <- predict(high_water_model, newdata = grid_points)
newgrid_sp <- SpatialPointsDataFrame(
  coords = newgrid[, c("x", "y")],
  data = data.frame(ID = 1:nrow(newgrid)),  # Add an ID column or any other data you need
  proj4string = proj4wgs  
)

high_water_frame <- predict(high_water_model_new, newdata = newgrid_sp)
crs(high_water_model_new)

high_water_model_new$variogram$crs <- proj4wgs
high_water_frame <- predict(high_water_model_new, newdata = newgrid_sp) #Why is this not working?

high_water_model_new <- sf::st_stransform(high_water_model_new, crs=proj4wgs)

# Create a new SpatialPointsDataFrame for high water level locations with the desired CRS
high_water_locations <- SpatialPointsDataFrame(
  coords = try1927[, c("x", "y")],  
  data = data.frame(level_hw = try1927$level_hw),  # Include any additional data as needed
  proj4string = proj4wgs,
  set = list(crs = proj4wgs)
)

# Create a new gstat model with the desired CRS
high_water_model_new <- gstat(
  formula = level_hw ~ 1,
  data = high_water_locations,
  set = list(crs = proj4wgs)
)

# Predict with the new model using your grid_points
high_water_frame <- predict(high_water_model_new, newdata = SpatialPointsDataFrame)

high_water_frame <- predict(high_water_model, newdata = grid_points)
proj4string(high_water_frame) <- crs_wgs84
high_water_frame_wgs84 <- projectRaster(high_water_frame, crs = crs_wgs84)


str(high_water_model)

#' Try interp() function from akima
#' 
require(akima)
data(akima)
str(akima)
str(akima)
?interp
akima.li <- interp(akima$x, akima$y, akima$z)
image(akima.li$x, akima.li$y, akima.li$z)

try1927 <- filter(HWLW, years==1927)
try1927$lon <- c(4.74499, 5.22003, 5.40934)
try1927$lat <- c(52.96436, 53.36305, 53.17563)

high_water_locations <- SpatialPointsDataFrame(
  coords = try1927[, c("x", "y")],  
  data = data.frame(level_hw = try1927$level_hw),  # Include any additional data as needed
  proj4string = crsdata
)

#bathymetry1927
#xy <- xyFromCell(bathymetry1927, cell = 1:ncell(bathymetry1927))

#' high_water_interp1927 <- interp(x = try1927$x, y = try1927$y, z = try1927$level_hw, xo = xy[,1], yo = xy[,2], duplicate = "mean") # size 18626451.5 Gb LOL
#' samplenr <- sample(1:nrow(xy), 5000, replace = F)
#' xysam_inclbound <- xy[samplenr,] #will only include corners, not other boundaries


# newgridwgs <- SpatialPointsDataFrame(
#  coords = newgrid,  # Assuming your try1927 data frame has "x" and "y" columns
#  data = data.frame(level_hw = try1927$level_hw),  # Include any additional data as needed
#  proj4string = proj4wgs
# )


#coordinates(try1927) <- c("lat", "lon")
#proj4string(try1927) <- CRS("+init=epsg:4326") 


#coordinates(newgrid) <- c("x", "y")
#proj4string(newgrid) <- CRS("+init=epsg:4326") 
plot(newgrid)
plot(bathymetry1927, add=T)

high_water_interp1927 <- interp(x = try1927$lon, y = try1927$lat, z = try1927$level_hw, xo = newgrid$x, yo = newgrid$y)

plot(high_water_interp1927)

str(high_water_interp1927$z)
?interp()

image(high_water_interp1927$z)

plot(high_water_interp1927$z)
all(high_water_interp1927$z[,1]==0)

str(try1927$level_hw)
str(akima$x)
high_water_interp1927_2 <- interp(x = try1927$x, y = try1927$y, z = try1927$level_hw)
image(high_water_interp1927_2)
View(high_water_interp1927_2)
x_jitter <- jitter(x)
y_jitter <- jitter(y)
F <- akima:interp(x_jitter*1000000, y_jitter*1000000, c(HWDH[1], HWH[1], HWWT[1])*1000000)
newgridwgs <- SpatialPointsDataFrame(
    coords = coordinates(try1927extend[,5:6]),  # Assuming your try1927 data frame has "x" and "y" columns
    data = try1927extend,  # Include any additional data as needed
    proj4string = crsdata
   )

extent(newgridwgs)
df_madeup <- data.frame(Location='Elfenland', years=1927, level_lw=-0.8, level_hw=0.5, x=120, y=580)

try1927extend <- data.frame(rbind(try1927,df_madeup))
Frame <- akima::interp(x=sort(try1927$x), y=sort(try1927$y), z=sort(try1927$level_hw), x0=c(110, 140, 170), y0=c(550, 575, 600))

Frame <- akima::interp(x=try1927extend$x, y=try1927extend$y, z=try1927extend$level_hw)

Frame <- akima:interp(newgridwgs,try1927extend$level_hw)
image(Frame)
plot(try1927$x, try1927$y)

?SpatialPointsDataFrame
coords(bathymetry1927)
str(bathymetry1927)
Frame <- akima:interp(newgridwgs, level_hw)
str(try1927)

interp_lw <- akima::interp(x = try1927$x, y = try1927$y, z = try1927$level_lw)
#'Back to gstat()
#' We will be using the idw() function for in gstat(), which does a inverse distance weighted interpolation
#' 
try1927 <- as.data.frame(try1927)
sp1927 <- try1927 
coordinates(sp1927) <- ~x + y
sp1927 <- st_transform(sp1927, crsdata)

grid <- spsample(x = sp1927, n=10000, type = 'regular') #'this takes 1000 points for the area within the spatial points

idw_lw <- gstat::idw(formula = level_lw ~ 1, locations = sp1927, newdata=grid, idp=1)

head(idw_lw@data)

#'Plotting
idw_lw.df <- as.data.frame(idw_lw)

ggplot(aes(x=x1, y=x2, color=var1.pred), data = idw_lw.df)+
  geom_point()+scale_color_viridis_c()+
  geom_point(aes(x=x, y=y), data=try1927, color='black', size =2)+
  annotate('label', x= try1927$x, y=try1927$y, label=as.character(try1927$Location))+
  scale_x_continuous(expand = expand_scale(mult = c(0.2, .2))) +
  scale_y_continuous(expand = expand_scale(mult = c(0.1, .1))) +
  theme_classic(base_size = 16)

#' Now, lets see if we can do this for all known locations
#' This following is already executed for 3.3 and 3.4
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

lmL <- lm(jaargemiddelde ~ jaar * locatie.naam, data=waterstanden %>% filter(HL== 'L'))

waterstanden_lw.df <- data.frame(locatie.naam = unique(waterstanden$locatie.naam),
                                 Intercept = unname(summary(lmL)$coefficients[,1])[c(1,(3):(n+1))],
                                 Slope = unname(summary(lmL)$coefficients[,1])[c(2,(n+2):(2*n))])

#' So now we can calculate the high and low water values for each year. 
#' Next we have to assign the coordinates to the locations
#' 

metadata <- read_delim(file.path(datadir, "ddl/metadata/Wadden_metadata.csv"),delim = ";") %>%
  distinct(locatie.naam, x, y,coordinatenstelsel)
waterstanden_hw.df <- left_join(waterstanden_hw.df, metadata, by='locatie.naam')
waterstanden_lw.df <- left_join(waterstanden_lw.df, metadata, by='locatie.naam')
#' coordinaten verschillen soms een klein beetje, ik neem het gemiddelde

waterstanden_hw.df <- waterstanden_hw.df  %>%  group_by(locatie.naam, Intercept, Slope) %>% 
  summarise(
  x = mean(x), y=mean(y)
)

waterstanden1927 <- waterstanden_hw.df %>% mutate(hoogwater = Intercept + (Slope * 1927)) %>% 


ws_hw.sp <- waterstanden_hw.df %>%  sf::st_as_sf(coords = c("x", "y"), crs = 25831) %>%  st_transform(crs(bathymetry1927))

ws_hw.sp_1927 <- as.data.frame(ws_hw.sp) %>% mutate(hoogwater = Intercept + Slope*1927) #wait, why is this incorrect?
# CONTINUE ANYWAYS, VALUES ARE INCORRECT
coordinates(ws_hw.sp_1927) <- ~ geometry
geometry(ws_hw.sp_1927)
ws_hw.sp_1927$geometry
#' Now we can use the idw function again
#' First make a grid of the whole wadden sea
#' 
#' #  The following works but takes way too long
#bath_1927.stars <- read_stars(file.path(mosaicdir, mosaiclist[1]))
#bath_1927.sf <- st_as_sf(bath_1927.stars)
#bath_1927.sf <- st_transform(bath_1927.sf, crs(ws_hw.sp))

# grid <- st_sample(x = bathymetry1927, n=10000, type = 'regular') #'this takes 1000 points for the area within the spatial points

idw_lw <- gstat::idw(formula = hoogwater ~ 1, locations = ws_hw.sp %>% mutate(hoogwater = Intercept + Slope*1927), newdata=bath_1927.sf, idp=1)
