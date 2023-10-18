library(sf)
library(tidyverse)
library(here)

aoi = "salzburg"
# aoi = "wuppertal"

segments = read_sf(here(paste0("data/", aoi, "_netascore_filtered.gpkg")))
images = read_sf(here(paste0("data/", aoi, "_images_filtered.gpkg")))

image_groups = split(images$id, as.factor(images$segment_id))
group_names = as.integer(names(image_groups))
group_values = unname(image_groups)
grouped_images = tibble(segment_id = group_names, all_images = group_values)

segments = segments |>
  left_join(grouped_images, by = join_by(id == segment_id))

images$date = as.Date(images$captured_at, '%Y-%m-%d')

sample_segments = function(segments, n = 1, lower = 0, upper = 1, d = 250) {
  pool = filter(segments, index > lower & index <= upper)
  sample = c()
  for (i in c(1:n)) {
    if (nrow(pool) < 1) {
      message("Sampling cannot continue at iteration ", i, " since pool is empty")
      break
    } else if (nrow(pool) == 1) {
      idx = pool$id
    } else {
      idx = sample(pool$id, 1)  
    }
    obj = filter(pool, id == idx)
    geom = st_geometry(obj)
    nbrs = st_intersects(st_buffer(geom, d), pool)[[1]]
    pool = pool[-nbrs, ]
    vars = c("bicycle_infrastructure", "designated_route", "road_category", "max_speed", "pavement", "gradient")
    dups = apply(do.call("rbind", lapply(vars, \(x) pool[[x]] == obj[[x]])), 2, all)
    pool = pool[!dups, ]
    sample[i] = idx
  }
  segments[segments$id %in% sample, ]
}

select_images = function(segments, images) {
  selection = c()
  for (i in seq_len(nrow(segments))) {
    segment = segments[i, ]
    pool = images[images$id %in% segment$all_images[[1]], ]
    pool = pool[pool$date == max(pool$date), ]
    cent = st_centroid(st_geometry(segment))
    selection[i] = pool[st_nearest_feature(cent, pool), ]$id
  }
  selection
}

main = function(bounds) {
  sample = sample_segments(segments, n = 10, lower = bounds[1], upper = bounds[2])
  sample$image_id = select_images(sample, images)
  sample
}

bounds = list(c(0.0, 0.2), c(0.2, 0.4), c(0.4, 0.6), c(0.6, 0.8), c(0.8, 1.0))
sample = bind_rows(lapply(bounds, main))

sample$segment_id = sample$id
sample$id = paste(rep(seq(1:5), rep(10, 5)), rep(seq(1:10), 5), sep = "_")
sample$all_images = do.call("c", lapply(sample$all_images, \(x) paste(x, collapse = ",")))
sample = select(sample, id, segment_id, everything())

write_sf(sample, here(paste0("data/", aoi, "_sample.gpkg")))