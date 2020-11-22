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
jsonFile = "October2020_1951-1980_worked.geojson"
# ----------------------------------------------

# ----------------------------------------------
# SHOW IN LEAFLET MAP
# ----------------------------------------------
plotPoly = readOGR(file.path("tmp", jsonFile))

leaflet_map = leaflet() %>% addProviderTiles("CartoDB.Positron")


leaflet_map = leaflet_map %>%
    addPolygons(data = plotPoly, 
                #color = "blue",
                color = c("brown", "purple", "red", "green",
                          "blue", "yellow", "black", "gray",
                          "brown", "orange", "white", "black"),
                popup = paste("Value:", plotPoly$value),
                stroke = FALSE) 
    
leaflet_map
# ----------------------------------------------
