# ----------------------------------------------
# BASE
# ----------------------------------------------
rm(list=ls())
source("./shared.r", chdir=TRUE, encoding = "UTF-8")
loadPackages(c("raster", 
               "rgdal", 
               "smoothr", 
               "units", 
               "lwgeom", 
               "rgeos", 
               "sf"))
# ----------------------------------------------

# ----------------------------------------------
# SETUP
# ----------------------------------------------
simplify_tol = 0.02
border_smooth = 3

cuts = c(-4.1, -4.0, -2, -1, -0.5, -0.2,
         0.2, 0.5, 1.0, 2.0, 4.0, 9999)
crumps = c(10000, 5000, 4000, 3000, 2000, 1800, 1600, 200, 200, 200, 200, 200)
f_holes = c(3001, 3000, 2000, 1000, 1000, 1000, 1000, 1000, NA, NA, NA, NA)
# ----------------------------------------------

# ----------------------------------------------
# CREATE GEOJSONS
# ----------------------------------------------
path = file.path(file.path("tmp", "data"))

files = list.files(path)

for(f in files){
    meanData = fread(file.path(path, f), skip = 1)
    metaData = fread(file.path(path, f), nrows = 1, header = F)
    meanPeriod = gsub("_", "", metaData$V1)
    basePeriod = metaData$V5
    fileName = paste0(paste(meanPeriod, basePeriod, sep = "_"), ".geojson")
    
    meanData = fread(file.path(path, f), skip = 1)
    meanData[`array(i,j)` == 9999, `array(i,j)` := NA]
    
    rasters = list()
    
    for (i in 1:length(cuts)) {
        print(paste0(i, "/", length(cuts)))
        cu = cuts[i]
        
        t = meanData[`array(i,j)` >= cu, .(lon, lat, cut = cu)]
        if(nrow(t) == 0){
            rasters[i] = list(NULL)
            next()
        }
            
        tt = rasterFromXYZ(t)  #Convert first two columns as lon-lat and third as value                
        crs(tt) = sp::CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
        print("Drop Crumps")
        tt = drop_crumbs(rasterToPolygons(tt, dissolve = TRUE),
                         set_units(crumps[i], km^2))
        rasters[i] = tt
    } 
    
    
    polys = list()
    for (i in 1:length(cuts)) {
        print(paste0(i, "/", length(cuts)))
        
        tt = rasters[[i]]
        if(is.null(tt))
            next()
            
        print("Fill Holes")
        if(!is.na(f_holes[i]))
            tt = fill_holes(tt, set_units(f_holes[i], km^2))
        print("Smooth")
        tt = smooth(tt, method = "ksmooth", smoothness=border_smooth)
        print("Simplify")
        ttd = data.frame(tt)
        tt = gSimplify(tt, tol = simplify_tol, topologyPreserve=TRUE)
        tt = SpatialPolygonsDataFrame(tt, ttd)
        polys[as.character(i)] = tt
    } 
    
    final_poly = do.call( rbind, polys )
    
    writeOGR(final_poly, file.path("tmp", fileName), layer="dfr_pg", driver="GeoJSON", overwrite_layer = TRUE)
}
# ----------------------------------------------