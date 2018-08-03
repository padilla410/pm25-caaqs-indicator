
library(leaflet)
# load air zone polygons from bcmaps
## we are amenable to switching to 'sf' instead of 'sp'
#
# air_zones <- airzones(class = 'sp')
# air_zones <- spTransform(air_zones, CRS = '+proj=longlat +datum=WGS84')

# reproject airzone map

# airzone_map_2 <- st_transform(airzone_map, crs = '+proj=longlat +datum=WGS84')

# Load pm25 stations
# pm25_sta <- 

# create base map and fit to bc bounding box
m <- 
  leaflet() %>%
  addProviderTiles(leaflet::providers$CartoDB.Positron) %>%  # Add default OpenStreetMap map tiles, CartoDB.Positron
  fitBounds(-139.06, 48.30, -114.03, 60.0)

# format station data
bin_stns <- c('\u2264 50 ppb', '>50 & \u2264 56 ppb', '>56 & \u2264 63 ppb', '\u2265 63 ppb')

df_pm25_clean <- mutate(pm25_clean
                            , group = cut(rounded_value, breaks = c(0, 50, 56, 63, max(rounded_value))
                                          , labels = bin_stns))

df_plot <- left_join(df_pm25_clean, stations_clean)

# add airzones and labels
## Will add station count later on the second line
bin_az <- c(levels(pm_caaq_daily_mgmt$caaqs))
pal_az <-  colorFactor(c('#DBDBDB', '#73A5CD', '#CD7378'), domain = bin_az)

df_poly <- left_join(pm_caaq_daily_mgmt, airzone_map)

m <- 
  m %>% 
  addPolygons(data = airzone_map, weight = 2, color = 'white'
              , fillColor = '#73A5CD', label = labels_df$airzone_name)

# add airzone stations
## the app only has a select number of stations plotted (e.g., Kitimat Haisla Village is missing),
## we will discuss the details behind this later
## 

## assign a palette
pal_stn <-  colorFactor(c('#F0F0F0', '#BDBDBD', '#737373', '#252525'), domain = bin_stns)

# add HTMLescapes into here
# add popup options to get where you need to go
# this currently works but it can't find the image
E206271_annual_lineplot.svg
m <-
  m %>% 
  addMarkers(m, lng = stations_clean$longitude, lat = stations_clean$latitude, label = as.factor(stations_clean$station_name)
             , popup = 
               paste("<font size = '+2'>Station: ", stations_clean$station_name, "</font><hr>"
                             , "Air Zone: ", stations_clean$category, "<br>"))

             # popupImage('out/station_plots/E206271_annual_lineplot.svg'))
                             , "<img src = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Rlogo.png/274px-Rlogo.png'>"))
                             # , "<img src = 'out/station_plots/", stations_clean$ems_id, "_annual_lineplot.svg'>"))
                             # , "<img src = '/out/station_plots/", stations_clean$ems_id, "_annual_lineplot.svg'>", sep = ""))
                             # , "<img src = '", getwd(), "/out/station_plots/", stations_clean$ems_id, "_annual_lineplot.svg'>", sep = ""))


# add legends