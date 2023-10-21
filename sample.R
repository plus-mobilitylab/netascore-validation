library(sf)
library(tidyverse)
library(here)

aoi = "salzburg"
# aoi = "wuppertal"

n = 25
d = 100
classes = list(c(0.0, 0.2), c(0.2, 0.4), c(0.4, 0.6), c(0.6, 0.8), c(0.8, 1.0))

segments = read_sf(here(paste0("data/", aoi, "_pool.gpkg")), layer = "segments")
images = read_sf(here(paste0("data/", aoi, "_pool.gpkg")), layer = "images")

image_groups = split(images$id, as.factor(images$segment_id))
group_names = as.integer(names(image_groups))
group_values = unname(image_groups)
grouped_images = tibble(segment_id = group_names, all_images = group_values)

segments = segments |>
  left_join(grouped_images, by = join_by(id == segment_id))

images$date = as.Date(images$captured_at, '%Y-%m-%d')

sample_segments = function(segments, n = 1, l = 0, u = 1, d = 250) {
  init_pool = filter(segments, index > l & index <= u)
  current_pool = init_pool
  vars = c("bicycle_infrastructure", "designated_route", "road_category", "max_speed", "pavement", "gradient")
  sample = c()
  for (i in c(1:n)) {
    if (nrow(current_pool) < 1) {
      message("Pool reset at iteration ", i)
      current_pool = init_pool[!init_pool$id %in% sample, ]
      if (nrow(current_pool) < 1) {
        stop("Not enough segments in pool to take sample of size ", n)
      }
    }
    if (nrow(current_pool) == 1) {
      idx = current_pool$id
    } else {
      idx = sample(current_pool$id, 1)
    }
    obj = filter(current_pool, id == idx)
    geom = st_geometry(obj)
    nbrs = st_intersects(st_buffer(geom, d), current_pool)[[1]]
    current_pool = current_pool[-nbrs, ]
    dups = apply(do.call("rbind", lapply(vars, \(x) current_pool[[x]] == obj[[x]])), 2, all)
    current_pool = current_pool[!dups, ]
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
    start = st_cast(st_geometry(segment), "POINT")[1]
    selection[i] = pool[st_nearest_feature(start, pool), ]$id
  }
  selection
}

main = function(i) {
  lower = classes[[i]][1]
  upper = classes[[i]][2]
  sample = sample_segments(segments, n, lower, upper, d)
  sample$image_id = select_images(sample, images)
  sample$sample_id = paste0(aoi, i, "i", seq_len(n))
  sample
}

sample = bind_rows(lapply(seq_along(classes), main))

sample$all_images = do.call("c", lapply(sample$all_images, \(x) paste(x, collapse = ",")))
sample = select(sample, id, sample_id, image_id, all_images, everything())

selection = filter(images) |>
  inner_join(select(st_drop_geometry(sample), sample_id, image_id), by = join_by(id == image_id)) |>
  select(id, sample_id, segment_id, everything())

write_sf(sample, here(paste0("data/", aoi, "_sample.gpkg")), layer = "segments")
write_sf(selection, here(paste0("data/", aoi, "_sample.gpkg")), layer = "images")
