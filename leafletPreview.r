# ----------------------------------------------
# BASE
# ----------------------------------------------
rm(list=ls())
source("./shared.r", chdir=TRUE, encoding = "UTF-8")
loadPackages(c("leaflet",
               "rgdal"))
# ----------------------------------------------

# ----------------------------------------------
# SETUP
# ----------------------------------------------
list.files("tmp")
jsonFile = "August2020_1951-1980.geojson"
# ----------------------------------------------

# ----------------------------------------------
# SHOW IN LEAFLET MAP
# ----------------------------------------------
polys = readOGR(file.path("tmp", jsonFile))

leaflet_map = leaflet() %>% addProviderTiles("CartoDB.Positron")

leaflet_map = leaflet_map %>%
    addPolygons(data = polys, color = "blue", stroke = T)
leaflet_map
# ----------------------------------------------