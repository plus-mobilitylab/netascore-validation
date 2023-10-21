library(sf)
library(tidyverse)
library(here)

aoi = "salzburg"
# aoi = "wuppertal"

segments = read_sf(here(paste0("data/", aoi, "_segments.gpkg"))) |>
  arrange(id)

images = read_sf(here(paste0("data/", aoi, "_images.geojson")), int64_as_string = TRUE) |> 
  st_transform(st_crs(segments))

images$captured_at = as.POSIXct(as.numeric(images$captured_at) * 0.001, origin = "1970-01-01")

matches = st_nearest_feature(images, segments)
distances = st_distance(images, segments[matches, ], by_element = TRUE)

images$segment_id = matches
images$segment_dist = distances

image_angles = images$compass_angle
segment_angles = segments[matches, ]$angle
angle_diffs_a = abs(segment_angles - image_angles)
angle_diffs_b = segment_angles + (360 - image_angles)
angle_diffs_c = image_angles + (360 - segment_angles)
angle_diffs = mapply(min, angle_diffs_a, angle_diffs_b, angle_diffs_c, SIMPLIFY = TRUE)

images$angle_diff = angle_diffs

write_sf(images, here(paste0("data/", aoi, "_images.gpkg")))
