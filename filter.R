library(sf)
library(tidyverse)
library(here)

aoi = "salzburg"
# aoi = "wuppertal"

segments = read_sf(here(paste0("data/", aoi, "_segments.gpkg")))
images = read_sf(here(paste0("data/", aoi, "_images.gpkg")))

filtered_images = images |>
  filter(segment_dist <= 10) |>
  filter(compass_angle >= 0) |>
  filter(angle_diff <= 45) |>
  filter(!is_pano) |>
  filter(captured_at >= as.POSIXct("2020-01-01"))

filtered_segments = segments |>
  filter(id %in% filtered_images$segment_id) |>
  filter(length > 25) |>
  filter(circuity <= 1.2) |>
  filter(access) |>
  filter(!is.na(bicycle_infrastructure)) |>
  filter(!is.na(designated_route)) |>
  filter(!is.na(road_category)) |>
  filter(!is.na(max_speed)) |>
  filter(!is.na(pavement)) |>
  filter(!is.na(gradient))

filtered_images = filtered_images |>
  filter(segment_id %in% filtered_segments$id)

write_sf(filtered_segments, here(paste0("data/", aoi, "_pool.gpkg")), layer = "segments")
write_sf(filtered_images, here(paste0("data/", aoi, "_pool.gpkg")), layer = "images")
