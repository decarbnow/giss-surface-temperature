# ----------------------------------------------
# BASE
# ----------------------------------------------
rm(list=ls())
source("./shared.r", chdir=TRUE, encoding = "UTF-8")
loadPackages(c("leaflet",
               "rgdal",
               "viridis"))
# ----------------------------------------------

# ----------------------------------------------
# SETUP
# ----------------------------------------------
list.files("tmp")
jsonFile = "September2020_1951-1980.geojson"
# ----------------------------------------------

# ----------------------------------------------
# SHOW IN LEAFLET MAP
# ----------------------------------------------
polys = readOGR(file.path("tmp", jsonFile))

pal <- colorNumeric(
    palette = "Set2",
    domain = polys$value)

leaflet_map = leaflet() %>% addProviderTiles("CartoDB.Positron")


leaflet_map = leaflet_map %>%
    addPolygons(data = polys, 
                color = c("brown", "purple", "red", "green",
                          "blue", "yellow", "black", "gray", 
                          "brown", "orange", "white", "black"), 
                popup = paste("Value:", polys$value),
                stroke = FALSE) 
    
leaflet_map
# ----------------------------------------------