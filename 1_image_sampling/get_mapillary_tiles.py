# Retrieving locations and indices of all mapillary images inside a spatial bounding box.
# Script adapted from https://gist.github.com/cbeddow/74b3bb7f7d69f52a7b0fc0e221be5ff5

import mercantile, requests, json, dotenv, os
from vt2geojson.tools import vt_bytes_to_geojson

aoi = "salzburg"
# aoi = "wuppertal"

dotenv.load_dotenv()
token = os.getenv("MAPILLARY_ACCESS_TOKEN") # Mapillary access token taken from .env file

output = {"type": "FeatureCollection", "features": []} # Initialize output object

# Set bounding box.
boxes = {
  "salzburg": [12.96967,47.74066,13.14292,47.86570],
  "wuppertal": [6.996377, 51.154541, 7.330450, 51.327968]
}
west, south, east, north = boxes[aoi]

tiles = list(mercantile.tiles(west, south, east, north, 14)) # Vector tiles covering the bbox

# Call Mapillary tile API for each of the vector tiles.
# Convert response to GeoJSON format.
for tile in tiles:
  url_base = "https://tiles.mapillary.com/maps/vtp/mly1_public/2"
  url_full = f"{url_base}/{tile.z}/{tile.x}/{tile.y}?access_token={token}"
  response = requests.get(url_full)
  data = vt_bytes_to_geojson(response.content, tile.x, tile.y, tile.z, layer = "image")
  for feature in data["features"]:
    feature["properties"]["compass_angle"] = round(feature["properties"]["compass_angle"], 1)
    output["features"].append(feature)

# Save output to file.
with open(f"data/{aoi}_images.geojson", "w") as f:
  json.dump(output, f)
