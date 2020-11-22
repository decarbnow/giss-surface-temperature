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

# Set ridiculous cuts
initCuts = c(-20, -10, -7, -5.0, -4.0, 
             -2, -1, -0.5, -0.2, 0.2, 
             0.5, 1.0, 2.0, 4.0, 5.0, 
             7, 10, 20)

# initCrumps = c(10000, 10000, 10000, 10000, 10000,
#                10000, 10000, 5000, 4000, 3000, 
#                2000, 1800, 1600, 1300, 200, 
#                200, 200, 200)

initCrumps = rep(500, length(initCuts))

initFHoles = c(3001, 3001, 3001, 3001, 3001,
               3000, 2000, 1000, 1000, 1000, 
               1000, 1000, 1000, NA, NA, 
               NA, NA, NA)
# ----------------------------------------------

# ----------------------------------------------
# CREATE GEOJSONS
# ----------------------------------------------
crumps = data.table(value = initCuts,
                    crumps = initCrumps)

f_holes = data.table(value = initCuts,
                     f_holes = initFHoles)

path = file.path(file.path("tmp", "data"))

files = list.files(path)

for(f in files){
    meanData = fread(file.path(path, f), skip = 1)
    metaData = fread(file.path(path, f), nrows = 1, header = F)
    meanPeriod = gsub("_", "", metaData$V1)
    basePeriod = metaData$V5
    fileName = paste0(paste(meanPeriod, basePeriod, sep = "_"), ".geojson")
    print(paste("creating", fileName, "..."))
    meanData = fread(file.path(path, f), skip = 1)
    meanData = meanData[`array(i,j)` != 9999]
    
    meanData[, value := cut(`array(i,j)`, 
                            breaks = initCuts,
                            labels = initCuts[-18],
                            include.lowest = T)]
    
    meanData = meanData[order(value)]
    
    meanData$value = as.numeric(as.character(meanData$value))
    rasters = list()
    
    for (v in unique(meanData$value)) {
        t = meanData[value >= v, .(lon, lat, value = v)]
        if(nrow(t) == 0){
            rasters[i] = list(NULL)
            print("Skipping", v)
            next()
        }
            
        tt = rasterFromXYZ(t)  #Convert first two columns as lon-lat and third as value                
        crs(tt) = sp::CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
        print("Drop Crumps")
        ttr = drop_crumbs(rasterToPolygons(tt, dissolve = TRUE),
                          set_units(crumps[value == v]$crumps, km^2))
        # if(is.null(ttr))
        #     ttr = rasterToPolygons(tt, dissolve = TRUE)
        
        rasters[as.character(v)] = ttr
    } 
    
    
    polys = list()
    for (n in names(rasters)) {
        tt = rasters[[n]]
            
        print("Fill Holes")
        if(!is.na(f_holes[value == as.numeric(n)]$f_holes))
            tt = fill_holes(tt, set_units(f_holes[value == as.numeric(n)]$f_holes, km^2))
        print("Smooth")
        tt = smooth(tt, method = "ksmooth", smoothness = border_smooth)
        print("Simplify")
        ttd = data.frame(tt)
        tt = gSimplify(tt, tol = simplify_tol, topologyPreserve = TRUE)
        tt = SpatialPolygonsDataFrame(tt, ttd)
        polys[as.character(n)] = tt
    } 
    
    polys_sf = list()
    for(p in names(polys)){
        polys_sf[[p]] = st_as_sf(polys[[p]])
    }
    
    final_poly = do.call( rbind, polys_sf )
    
    done = NULL
    for(v in final_poly$value){
        done = c(done, v)
        diff = st_difference(final_poly[final_poly$value == v,]$geometry,
                             st_union(final_poly[!(final_poly$value %in% done),]$geometry))
        if(length(diff) == 0){
            print("No rows left. Skipping")
            next()
        }
        final_poly[final_poly$value == v,]$geometry = diff
    }
    
    st_write(final_poly, 
             dsn = file.path("tmp", fileName), 
             layer="dfr_pg", 
             driver="GeoJSON", 
             delete_dsn = TRUE)
}
# ----------------------------------------------