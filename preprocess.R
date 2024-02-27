library(sf)
library(sfnetworks)
library(tidyverse)
library(tidygraph)
library(here)
library(units)

aoi = "salzburg"
# aoi = "wuppertal"

edges = read_sf(here(paste0("data/", aoi, "_netascore.gpkg")), layer = "edge") |>
  mutate(directional = index_bike_ft != index_bike_tf) |>
  rename(index = index_bike_ft, access = access_bicycle_ft, bicycle_infrastructure = bicycle_infrastructure_ft, designated_route = designated_route_ft, max_speed = max_speed_ft, gradient = gradient_ft) |>
  select(length, access, directional, index, bicycle_infrastructure, designated_route, road_category, max_speed, pavement, gradient)

eqattrs = colnames(edges)[!colnames(edges) %in% c("length", "geom")]

original_network = as_sfnetwork(edges)
smoothed_network = convert(original_network, to_spatial_smooth, summarise_attributes = list(length = "sum", "first"), require_equal = eqattrs, .clean = TRUE)

segments = smoothed_network |>
  activate("edges") |>
  morph(to_spatial_transformed, 4326) |>
  mutate(angle = drop_units(edge_azimuth(degrees = TRUE))) |>
  mutate(angle = sapply(angle, \(x) ifelse(x < 0, 360 + x, x))) |>
  mutate(angle = round(angle, 1)) |>
  unmorph() |>
  mutate(circuity = edge_circuity()) |>
  mutate(circuity = round(circuity, 1)) |>
  mutate(length = round(length, 1)) |>
  st_as_sf() |>
  select(!c(from, to)) |>
  mutate(id = seq_len(n())) |>
  select(id, length, angle, circuity, everything())

write_sf(segments, here(paste0("data/", aoi, "_segments.gpkg")))
