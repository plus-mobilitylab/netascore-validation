library(sf)
library(tidyverse)
library(here)

aoi = "salzburg"
# aoi = "wuppertal"

segments = read_sf(here(paste0("data/", aoi, "_netascore.gpkg")), layer = "edge")
images = read_sf(here(paste0("data/", aoi, "_images.gpkg")))

filtered_images = images |>
  filter(segment_dist <= 10) |>
  filter(!is_pano)

filtered_segments = segments |>
  filter(id %in% filtered_images$segment_id) |>
  filter(access_bicycle_ft & access_bicycle_tf) |>
  filter(length < 200) |>
  filter(!is.na(bicycle_infrastructure_ft)) |>
  filter(!is.na(designated_route_ft)) |>
  filter(!is.na(road_category)) |>
  filter(!is.na(max_speed_ft)) |>
  filter(!is.na(pavement)) |>
  filter(!is.na(gradient_ft)) |>
  mutate(directional = index_bike_ft != index_bike_tf) |>
  rename(index = index_bike_ft, robustness = index_bike_ft_robustness, bicycle_infrastructure = bicycle_infrastructure_ft, designated_route = designated_route_ft, max_speed = max_speed_ft, gradient = gradient_ft) |>
  select(id, osm_id, from_node, to_node, index, robustness, directional, bicycle_infrastructure, designated_route, road_category, max_speed, pavement, gradient)

filtered_images = filtered_images |>
  filter(segment_id %in% filtered_segments$id)

write_sf(filtered_images, here(paste0("data/", aoi, "_images_filtered.gpkg")))
write_sf(filtered_segments, here(paste0("data/", aoi, "_netascore_filtered.gpkg")))