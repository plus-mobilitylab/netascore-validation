# Validating bikeability indices of NetAScore

This repository contains code for validation of the bikeability index computed by [NetAScore](https://github.com/plus-mobilitylab/netascore). All **data and results** are provided in a [Zenodo repository](http://doi.org/10.5281/zenodo.10724362) which supplements the scientific paper. 

The evaluation study is based on streetview imagery. In an online survey participants are asked to rate the sampled images in terms of bikeability. Their ratings are then compared to the bikeability index of NetAScore for the street segment shown in the image. Additionally, expert ratings and feedback were collected during the 2023 CRBAM conference in Wuppertal, Germany.

This repository consists of two parts:

1. code for **sampling streetview imagery** from Mapillary
2. code for **assessing results** from the online survey and conference workshops


## Image sampling

The individual steps of the sampling workflow are described in more detail below.

### 1. Get the network data

The input data are the street networks of two cities, Salzburg in Austria and Wuppertal in Germany, assessed by [NetAScore](https://github.com/plus-mobilitylab/netascore). The edges in the street network are individual street segments with a bikeability index assigned. The GPKG files of the assessed networks can be found at: http://doi.org/10.5281/zenodo.10724362

### 2. Pre-process the network

The street networks are pre-processed as follows:

- Only relevant attribute columns of the street segments are selected. These include the length, the bikeability index, and the considered indicators. For the index and all directional indicators we only select the values computed for the forward direction.
- Pseudo nodes are removed. This are nodes with only one incoming and one outgoing edge. We only remove them if these edges have equal values for all indicators.
- The CRS of the network is transformed to EPSG:4326, to match the CRS of the Mapillary images.
- Two additional attributes are computed for each street segment: compass angle between the startpoint and endpoint, and circuity (i.e. the ratio between street length and straight-line distance between startpoint and endpoint).

**Corresponding script**: [preprocess.R](1_image_sampling/preprocess.R)

### 3. Retrieve metadata of all images

We call the Mapillary Tiles API to retrieve the metadata of all images inside the bounding boxes of the cities. These metadata include the index, location, date, and compass angle of the images.

**Corresponding script**: [get_mapillary_tiles.py](1_image_sampling/get_mapillary_tiles.py)

### 4. Match images to the network

Each image is matched to its nearest street segment in the network. Two additional attributes are stored for each image: the distance between the image location and the matched street segment, and the difference between the compass angle of the image and the compass angle of the matched street segment.

**Corresponding script**: [match.R](1_image_sampling/match.R)

### 5. Create the sampling pool

First, we filter the images according to the following rules:

- Images should be taken within 10 meters from its nearest street segment in the network.
- The difference in compass angle between the image and its nearest street segment should not be more than 45 degrees.
- Images should not be panoramic, i.e. made by fish-eye cameras.
- Images should be captured after January 1st 2020.

We then filter select only those street segments that have at least one matching image. In addition, we use the following rules to further filter the street segments:

- Street segments should be longer than 25 meters.
- The circuity of street segments should not be higher than 1.2, to avoid segments with sharp corners.
- Street segments should be labeled by NetAScore as being legally accessible by bicycle.
- Street segments should have a valid value for each of the considered indicators, i.e. no missing data.

**Corresponding script**: [filter.R](1_image_sampling/filter.R)

### 6. Sample

We first define five classes of similar bikeability indices: very unbikeable [0,0.2], unbikeable (0.2,0.4], moderate (0.4,0.6], bikeable (0.6,0.8] and very bikeable (0.8,1]. For each bikeability class we sample 25 street segments. We do this in an iterative way, sampling one street segment at a time. Every other street segment intersecting with a 100 meter buffer around the sampled segment is removed from the pool, to avoid ending up with many nearby segments in the sample. For each sampled street segment, we select the most recent image among all images matched to that segment. If there are multiple most recent images, we select the one closest to the startpoint of the street segment.

**Corresponding script**: [sample.R](1_image_sampling/sample.R)

### 7. Retrieve the image files

We call the Mapillary Graph API to retrieve all sampled images as JPEG files.

**Corresponding script**: [get_mapillary_images.py](1_image_sampling/get_mapillary_images.py)

### 8. Manual filtering

We manually remove images from the sample set due to one or more of the following reasons:

- bad quality (sharpness)
- view largely covered by a car dashboard, rearview mirror, or windshield wiper
- image is not centered on the road segment itself
- ambiguity: multiple road segments are visible, without clear focus
- showing a road segment which obviously is not accessible by bicycle, e.g. a motorway or hiking trail

### 9. Sample final image set

The last step is sampling of the final image set which is then used in the online survey. For this we expect all images being sorted into subdirectories according to their bikeability class (of NetAScore bike index): folders `c1` to `c5`. The sample set we used in our evaluation study is available at http://doi.org/10.5281/zenodo.10724362 in `5_images_full_sample`.

The final sample is generated as random choice from available images with the following criteria:

- we want to generate 5 survey pages, each consisting of 10 images
- each image is only included once
- each page should contain two images per bikeability class

The order of images shown per page should be individually randomized per user by the survey software.

**Corresponding script**: [final_sample.ipynb](1_image_sampling/final_sample.ipynb)



## Result assessment

### 1. Assessment of image-based bikeability ratings

This part of the workflow forms the core of our result assessment. We use results from the online survey, digitized bikeability ratings of experts collected during the conference, and the Geopackage files created during image sampling. All input data is found in the [Zenodo repository](http://doi.org/10.5281/zenodo.10724362) (`2_data/2_image_sampling`, `3_images` and the CSV-files in `4_results`). If you replicate the folder structure of the repository locally, the script should be able to access all required data. Outputs are generated in a subdirectory next to the code file named `output`.

With the assessment script we generate several plots that visualize bikeability ratings including their statistical dispersion. We add modeled bikeability as red line to these diagrams for reference. The document is structured with section headings referring to the subset of data and type of assessment at hand. We further compute correlation metrics and provide a scatterplot with linear regression in the subsection "Correlation".

**Corresponding script**: [img-assessment.ipynb](2_result_assessment/img-assessment.ipynb)

### 2. Assessment of indicator ratings

Indicators were rated by experts during the conference workshop at CRBAM 2023. Digitized results are available from the [Zenodo repository](http://doi.org/10.5281/zenodo.10724362) (in `4_results/4_indicators_workshop.csv`). The script creates plots of all indicator ratings. For reference we include markers representing normalized weights of the NetAScore default bikeability profile. Outputs are generated in a subdirectory next to the code file named `output`.

**Corresponding script**: [indicator-assessment.ipynb](2_result_assessment/indicator-assessment.ipynb)
