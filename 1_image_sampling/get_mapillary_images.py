# Retrieving sampled images from mapillary.
# Script adapted from https://gist.github.com/cbeddow/79d68aa6ed0f028d8dbfdad2a4142cf5

import requests, dotenv, os, json
import geopandas as gpd

aoi = "salzburg"
# aoi = "wuppertal"

dotenv.load_dotenv()
token = os.getenv("MAPILLARY_ACCESS_TOKEN") # Mapillary access token taken from .env file

sample = gpd.read_file(f"data/{aoi}_sample.gpkg", layer = "segments") # Sampled segments with assigned images

for image_id, sample_id in zip(sample["image_id"], sample["sample_id"]):
  url_base = "https://graph.mapillary.com"
  url_full = f"{url_base}/{image_id}?access_token={token}&fields=thumb_original_url"
  response = requests.get(url_full).json()
  image_url = response["thumb_original_url"]
  with open(f"img/{sample_id}.jpg", "wb") as handler:
    image_data = requests.get(image_url, stream = True).content
    handler.write(image_data)
