library(sf)
library(tidyverse)
library(here)

aoi = "salzburg"
# aoi = "wuppertal"

segments = read_sf(here(paste0("data/", aoi, "_netascore.gpkg")), layer = "edge")

images = read_sf(here(paste0("data/", aoi, "_images.geojson")), int64_as_string = TRUE) |> 
  st_transform(st_crs(segments))

images$captured_at = as.POSIXct(as.numeric(images$captured_at) * 0.001, origin = "1970-01-01")

matches = st_nearest_feature(images, segments)
distances = st_distance(images, segments[matches, ], by_element = TRUE)

images$segment_id = matches
images$segment_dist = distances

segments$id = seq_len(nrow(segments))

write_sf(images, here(paste0("data/", aoi, "_images.gpkg")))
write_sf(segments, here(paste0("data/", aoi, "_netascore.gpkg")), layer = "edge")