require(sf)
require(raster)

horizontaleresolutie = 20 #m

profielenFilename <- "p:/11202493--systeemrap-grevelingen/1_data/Wadden/Profielen_Wadden/all_profiles_georeferenced.shp"

# run testplotraster to create rasterlayer "bathymetry"

profielen <- sf::st_read(profielenFilename)
testprofiel = profielen %>% 
  # filter(layer == profielen$layer[1]) %>% 
  st_transform(28992) # this is in meters !

# testprofiel2 <- as(testprofiel, 'Spatial') #werkt niet

testprofiel2 = sf::st_line_sample(
  testprofiel, 
  type = 'regular', 
  density = units::set_units(horizontaleresolutie, m)) #%>%
  # st_transform(9001) # is crs of bathymetry, but very strange results...

names <- testprofiel %>% distinct(Id, layer) # !!! check volgorde

# check id 

coordinates <- purrr::map_df(
  testprofiel2, 
  function(x) as_tibble(st_coordinates(x)) %>% select(-L1),
  .id = "id"
  )

ggplot(coordinates, aes(x = X, y = Y)) +
  geom_point(size = 0.5, shape = ".") +
  coord_equal()

epsgRD <- "+proj=sterea +lat_0=52.1561605555556 +lon_0=5.38763888888889 +k=0.9999079 +x_0=155000 +y_0=463000 +ellps=bessel +towgs84=565.4171,50.3319,465.5524,1.9342,-1.6677,9.1019,4.0725 +units=m +no_defs +type=crs"
bathymetryRD <- projectRaster(bathymetry, crs = epsgRD)

crs(bathymetryRD) # niet correct
crs(bathymetryRD) <- "+init=epsg:28992"
st_crs(testprofiel2)

profiel_test <- raster::extract(bathymetryRD, coordinates[coordinates$id ==6,c(2,3)], method = "bilinear")

plot(profiel_test)

profiel_test_df <- tibble(
  x = horizontaleresolutie*seq(1:length(profiel_test)),
  y = profiel_test
  )
 
ggplot(profiel_test_df, aes(x,y)) + 
  geom_line(aes(), size = 1) +
  xlab("distance in m") +
  ylab("depth in m")

# uitbreiden met map() functie om voor alle profielen en bathymetrien te doen. 
# bathymetriene moeten ook nog ingelezen worden. 



