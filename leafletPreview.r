# ----------------------------------------------
# SHOW IN LEAFLET MAP
# ----------------------------------------------
list.files("tmp")
jsonFile = "September2020_1951-1980.geojson"

polys = readOGR(file.path("tmp", jsonFile))
poly_colors = c("brown", "purple", "red", "green", "blue", "yellow", "black", "gray", "brown", "orange", "purple", "brown")

leaflet_map = leaflet() %>% addProviderTiles("CartoDB.Positron")

leaflet_map = leaflet_map %>%
    addPolygons(data = polys, color = "blue", stroke = T)
leaflet_map
# ----------------------------------------------