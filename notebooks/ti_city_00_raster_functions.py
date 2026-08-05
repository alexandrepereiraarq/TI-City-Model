#!/usr/bin/env python
# coding: utf-8
#!/usr/bin/env python
# coding: utf-8

"""
@author: Alexandre Pereira Santos <br>
alexandre.santos(at)lmu.de
## Tasks
- This is a collection of tested and working functions for raster and vector analysis.
- Run this code at your own risk.

## Prerequisites
- Many functions rely on rasterio.
- Calling notebooks should import: geopandas, matplotlib, osmnx, ee
"""

# Core imports required for the script to function
import json
import os
import shutil
from pathlib import Path
from typing import Optional, Tuple, Dict, Any, Union

import numpy as np
import rasterio
from rasterio.mask import mask
from rasterio.warp import calculate_default_transform, reproject, Resampling
from rasterio.features import rasterize
import rasterio.features as features
from rasterio.transform import Affine
from scipy.ndimage import distance_transform_edt, generic_filter

from shapely.geometry.polygon import Polygon
from shapely.geometry import MultiLineString, LineString, MultiPolygon, Point, MultiPoint, GeometryCollection

# GeoPandas is used extensively but we'll use string literals in type hints
# to avoid requiring it in this module
import geopandas as gpd

# For plotting functions (kept minimal since notebooks handle most plotting)
import matplotlib.pyplot as plt
from matplotlib import colors as mcolors
from matplotlib import patches as mpatches
from matplotlib.colors import LinearSegmentedColormap

from skimage.graph import route_through_array
from rasterio.plot import plotting_extent
from matplotlib.pyplot import show
import logging

# OSMnx for GIS operations
import osmnx as ox

# Google Earth Engine (commented out as it requires special initialization)
import ee
import geemap

# These should be passed as parameters or set by calling code
drop_path:  Optional[str] = None
case_city: Optional[str] = None
interim_path: Path = Path(drop_path).joinpath(case_city, 'interim') if case_city else Path('./interim')
ref_raster_path: Path = Path(f'../data/processed/{case_city}_LIM_reference_AOI_150m.tif') if case_city else Path('./reference.tif')
AOI_gdf: Optional['gpd.GeoDataFrame'] = None

from typing import List

__all__: List[str] = [
    # Core raster functions
    'clip_raster',
    'clip_raster_by_ref',    
    'extract_rasters',
    'get_transform',
    'check_negative_raster',
    'rasterise_vector',
    'reproj_match',
    'resample_raster',

    #OSM
    'getFeatures',
    'get_osm_features',

    # gee
    'gee_to_tiff',
    'export_ee_image',
    'check_image_stats',
    'get_coords',

    # Distance/utility functions
    'get_distance_raster',
    'calculate_density',
    'calculate_utility',
    'utility_from_distance',
    'convert_distance_to_utility',
    'get_weight_distance_raster',
    'calculate_suitability',
    'majority_filter',

    # Export functions
    'export_geotiff',
    'export_raster',
    'export_raster_to_ascii',
    'export_raster_to_ascii_aoi_clip',
    'export_files',

    # Plot functions (if used externally)
    'plot_ras_ras',
    'plot_vec_ras',
    'plot_vec_vec_ras_ras',
    'plot_continuous_raster',
    'plot_unique_value_raster',
    'plot_compare_rasters',
    'plot_many_rasters'
]


"""
---------------------------------------------------------------------------
Begin function definitions
---------------------------------------------------------------------------
"""

"""
---------------------------------------------------------------------------
edit functions 
"""
def getFeatures(gdf):
    """
    Function to parse features from GeoDataFrame in such a manner that rasterio wants them.

    Parameters:
    gdf (GeoDataFrame): Input GeoDataFrame containing features to be parsed.

    Returns:
    list: A list containing the parsed geometry of the first feature in the GeoDataFrame.
    """
    return [json.loads(gdf.to_json())['features'][0]['geometry']]

"""clip raster file by a vector AOI"""
def clip_raster(raster_path: str, aoi:'gpd.GeoDataFrame')-> Tuple[np.ndarray, 'Affine', dict]:
    """
    Clip a raster file by a vector Area of Interest (AOI).

    Parameters:
    raster_path (str): Path to the input raster file.
    aoi (GeoDataFrame): GeoDataFrame representing the Area of Interest.

    Returns:
    tuple: A tuple containing the clipped image, transform, and metadata.
    """
    with rasterio.open(raster_path) as in_raster:
        if in_raster.crs != aoi.crs:
            aoi = aoi.to_crs(in_raster.crs)
            print('AOI crs was changed to match raster crs', aoi.crs)

        out_image, out_transform = mask(in_raster, getFeatures(aoi), crop=True)

        out_meta = in_raster.meta.copy()
        out_meta.update({"driver": "GTiff",
                        "height": out_image.shape[1],
                        "width": out_image.shape[2],
                        "transform": out_transform})
        return out_image, out_transform, out_meta

def clip_raster_by_ref(raster_path: str, ref_raster_path: str):
    """
    Clip a raster file by the bounds of a reference raster.

    Parameters:
    raster_path (str): Path to the input raster file.
    ref_raster_path (str): Path to the reference raster file.

    Returns:
    tuple: A tuple containing the clipped image, transform, and metadata.

    Raises:
    ValueError: If the CRS of the input raster does not match the CRS of the reference raster.
    ValueError: If the input raster does not intersect the reference raster.
    """
    with rasterio.open(ref_raster_path) as ref_raster:
        ref_bounds = ref_raster.bounds
        ref_crs = ref_raster.crs
        print(ref_crs)

    with rasterio.open(raster_path) as src:
        if src.crs != ref_crs:
            raise ValueError("CRS of the input raster does not match the CRS of the reference raster.")
        print(src.crs)
        # Create a bounding box geometry from the reference raster bounds
        bbox = [
            {
                'type': 'Polygon',
                'coordinates': [
                    [
                    [ref_bounds.left, ref_bounds.bottom],
                    [ref_bounds.left, ref_bounds.top],
                    [ref_bounds.right, ref_bounds.top],
                    [ref_bounds.right, ref_bounds.bottom],
                    [ref_bounds.left, ref_bounds.bottom]
                    ]
                ]
            }
        ]
        print(bbox)
        # Clip the raster
        try:
            out_image, out_transform = mask(src, bbox, crop=True)
        except ValueError:
            raise ValueError("The input raster does not intersect the reference raster.")

        # Update the metadata
        out_meta = src.meta.copy()
        out_meta.update({
            "driver": "GTiff",
            "height": out_image.shape[1],
            "width": out_image.shape[2],
            "transform": out_transform,
            "crs": ref_crs
        })

        return out_image, out_transform, out_meta
        """Example usage
        clip_raster_by_ref('path_to_input_raster.tif', ref_raster_path, 'path_to_output_raster.tif')
        """

"""extract the raster values"""
def extract_rasters(raster, values):
    """
    Extract raster values based on a list of threshold values.

    Parameters:
    raster (array): Input raster data.
    values (list): List of threshold values for extraction.

    Returns:
    list: A list of masks corresponding to the extracted values.
    """
    #creating an empty list to store the extracted values
    extracted_rasters = [] #maybe this would be best as a dictionary
    #looping through the values list
    if len(values) == 1:
        #creating a mask for the raster
        mask = raster == values[0]
        #appending the extracted values to the list
        extracted_rasters.append(mask)
    else:
        mask0 = raster == values[0]
        extracted_rasters.append(mask0)
        for value in range(1, len(values)):
            #creating a mask for the raster
            mask = (raster <= values[value]) & (raster > 0)
            #appending the extracted values to the list
            mask = np.where(mask==np.nan, 0, mask)
            extracted_rasters.append(mask)
    #returning the list of extracted values
    return extracted_rasters

def get_transform(raster):
    transform = raster.transform
    cell_width = transform[0]
    cell_height = -transform[4]
    area = cell_height*cell_width
    return cell_height, cell_width, area


def check_negative_raster(
    r: str,
    path: Path = interim_path,
    ref_raster_path: Path = ref_raster_path
    ) -> None:
    with rasterio.open(path / r, 'r') as raster:
        array = raster.read(1)
        raster_data_type = raster.dtypes[0]
        #print(np.nanmin(slope_array), np.nanmax(slope_array))
        if np.nanmin(array) < 0:
            array = np.where((array< 0), 0, array) #&(array!=-9999)
            print('+There were negative values in the', r, 'but now the minimum value is', np.nanmin(array))
            # export the corrected raster
            with rasterio.open(ref_raster_path, 'r') as reference:
                try:
                    new_name = str(r.split('.')[0] + '_new_150m.tif')
                    with rasterio.open(path/new_name, "w", 
                                    driver='GTiff', # APS 11.12.204 changed from 'AAIGrid' to 'GTiff'
                                    height = reference.shape[0], 
                                    width=reference.shape[1],
                                    count=1, 
                                    dtype=raster_data_type,
                                    crs=reference.crs, 
                                    transform = reference.transform) as dest:
                        dest.write(array.astype(raster_data_type), indexes=1)

                        print('+The', r, 'raster was exported to', new_name)
                        # move the old raster to the '_old' folder and rename the new raster

                    old_folder = path / '_old'
                    old_folder.mkdir(exist_ok=True)
                    old_raster = old_folder/r
                    print(old_raster)

                    if os.path.exists(old_raster): os.remove(old_raster)
                    path_as_string = str(path / r)

                    shutil.move(path/r, old_folder/r)

                    new_raster_old_name = path / new_name
                    new_raster_new_name = Path(path_as_string)
                    new_raster_old_name.rename(new_raster_new_name)

                except Exception as e:
                    print(e)
                    print('****There was an error exporting the', r, 'raster to ASCII')
        else:
            print('-There are no negative values in the', r, 'raster')


"""
---------------------------------------------------------------------------
rasterise functions
"""

"""rasterise function"""
def rasterise_vector(vector, ref_raster_path, col=None, default_value=0, dtype=rasterio.int16):

    # if a column is specified, use it to rasterize the vector
    if col:
        shapes = ((geom,value) for geom, value in zip(vector.geometry, vector[col]))
    else: 
        shapes = vector.geometry.values
    with rasterio.open(ref_raster_path, 'r') as ref_raster:
        # Rasterize the vector layer, script from https://pygis.io/docs/e_raster_rasterize.html    
        raster = features.rasterize(shapes,
                        out_shape=ref_raster.shape,
                        transform=ref_raster.transform,
                        out = None,
                        #nodata=-9999, # not sure why this is not working
                        default_value=default_value,
                        all_touched=True,
                        dtype=dtype)

    return raster

"""distance function"""
def get_distance_raster(gdf: 'gpd.GeoDataFrame', ref_raster_path: str) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:

    # Filter major elments 
    major_gdf = gdf[gdf['major'] == 1]

    # Get the geometry of the major roads
    major_geom = [shapes for shapes in major_gdf.geometry]

    with rasterio.open(ref_raster_path, 'r') as ref_raster:    
        # Rasterize the major roads, script from https://pygis.io/docs/e_raster_rasterize.html
        major_raster = features.rasterize(major_geom,
                                        out_shape = ref_raster.shape,
                                        fill = 0,
                                        out = None,
                                        transform = ref_raster.transform,
                                        all_touched = True,
                                        default_value = 1,
                                        dtype = None)

        # Get the geometry of the all roads
        full_geom = [shapes for shapes in gdf.geometry]

        full_raster = features.rasterize(full_geom,
                                        out_shape = ref_raster.shape,
                                        fill = 0,
                                        out = None,
                                        transform = ref_raster.transform,
                                        all_touched = True,
                                        default_value = 1,
                                        dtype = None)

    # Invert the raster: roads (value == 1) become 0, non-roads become 1
    inverted_raster = np.where(major_raster == 1, 0, 1)

    # Calculate the distance to the nearest road for each cell
    distance_raster = distance_transform_edt(inverted_raster)
    # Assuming the raster's resolution is in meters, the distance_to_roads array now contains the distance in meters to the nearest road for each cell

    distance_raster = np.asarray(distance_raster, dtype=float)

    min_val = np.nanmin(distance_raster, axis=None)
    max_val = np.nanmax(distance_raster, axis=None)

    if max_val == min_val:
        distance_raster_normalized = np.zeros_like(distance_raster)
    else:
        # normalize the raster by the min-max method
        distance_raster_normalized = (distance_raster - min_val) / (max_val - min_val)
    
    #distance_raster_normalized = (distance_raster - np.nanmin(distance_raster))/(np.nanmax(distance_raster) - np.nanmin(distance_raster))

    # alternatively normalize the raster with the z-score method
    #distance_raster_normalized = (distance_raster - np.nanmean(distance_raster))/np.nanstd(distance_raster)

    # two output options, one with all the rasters, the other only with the distance ones
    return major_raster, full_raster, distance_raster, distance_raster_normalized
    #return distance_raster, distance_raster_normalized


"""density function"""
def calculate_density(image_path:'Path', aoi_gdf:'gpd.GeoDataFrame', pop_extract=False):
    """
    Load population raster, clip to AOI, and calculate normalized density

    Parameters:
    -----------
    image_path : pathlib.Path
        Path to the population raster file
        It should be a valid raster in a **projected** CRS
    aoi_gdf : GeoDataFrame
        Area of interest as a GeoDataFrame

    Returns:
    --------
    tuple
        (density_fill, pop_raster_area, pop_transform) # previously: also pop_raster_height, pop_raster_width, 
    """

    with rasterio.open(image_path, 'r') as pop_raster:
        # APS: It is is not necessary to check if the CRS are the same, as the getFeatures function does it for us        
        print(pop_raster.crs)
        # clip the raster to the AOI
        pop_array, pop_transform = mask(pop_raster, getFeatures(aoi_gdf), crop=True)

        # calculate the area of the pixels in the rasters using the affine information
        # pop_raster_height = pop_array.shape[1] # we get these properties straight out of the raster's transform
        # pop_raster_width = pop_array.shape[2]
        print('height: ', pop_transform[0], 
              '\nwidth: ', -pop_transform[4])
        pop_raster_area = round(pop_transform[0]*(-pop_transform[4]), 2)

        # calculate the population density
        density = pop_array / pop_raster_area

        # normalize the density
        density_normal = np.round(
                (density - np.nanmin(density))/(np.nanmax(density) - np.nanmin(density)),
                4
        )

        # replace NaN values with 0
        density_fill = np.where(np.isnan(density_normal), 0, density_normal)
    if pop_extract:
        return density_fill, pop_raster_area, pop_transform, pop_array
    else:
        return density_fill, pop_raster_area, pop_transform # pop_raster_height, pop_raster_width, 



"""
---------------------------------------------------------------------------
get OSM features
"""

def get_osm_features(tags:'dict', col_list:'list', geom_type:'str', major_dict:'dict', aoi:'gpd.GeoDataFrame'):
    aoi_coords = aoi.to_crs(epsg='4326').envelope #type: ignore
    # updating the feature_from_bbox method to OSMnx 2 synthax. The old one (with north, south, east, and west) is deprecated.
    # updated synthax is bbox=(left, bottom, right, top)

    temp_places = ox.features_from_bbox(bbox=(aoi_coords.bounds.values[0][0], # left
                                            aoi_coords.bounds.values[0][1], # old south, now bottom
                                            aoi_coords.bounds.values[0][2], # old east, now right
                                            aoi_coords.bounds.values[0][3]), # old north, now top
                                            tags=tags)
    """
    old synthax, keeping for reference 
    # temp_places = ox.features_from_bbox(bbox=(aoi_coords.bounds.values[0][3], # north
    #                                           aoi_coords.bounds.values[0][1], # south 
    #                                           aoi_coords.bounds.values[0][2], # east 
    #                                           aoi_coords.bounds.values[0][0]), # west 
    #                                          tags=tags)
    """
    temp_places.reset_index(inplace=True)

    geom_list = []

    for feature in temp_places["geometry"]:
            if isinstance(feature, Polygon):
                    geom_list.append('Polygon')
            elif isinstance(feature, MultiPolygon):
                    geom_list.append('MultiPolygon')
            elif isinstance(feature, LineString):
                    geom_list.append('LineString')
            elif isinstance(feature, MultiLineString):
                    geom_list.append('MultiLineString')
            elif isinstance(feature, GeometryCollection):
                    for geom in feature.geoms:
                        if isinstance(geom, Polygon):
                            geom_list.append('Polygon')
                        elif isinstance(geom, MultiPolygon):
                            geom_list.append('MultiPolygon')
                        elif isinstance(geom, LineString):
                            geom_list.append('LineString')
                        elif isinstance(geom, MultiLineString):
                            geom_list.append('MultiLineString')
                        elif isinstance(geom, Point):
                            geom_list.append('Point')
                        elif isinstance(geom, MultiPoint):
                            geom_list.append('Point')
            elif isinstance(feature, MultiPoint):
                    geom_list.append('Point')
            elif isinstance(feature, Point):
                    geom_list.append('Point')

    if (geom_type == 'Mixed') & ('Polygon' in geom_list) & ('Point' in geom_list): # I am not sure we need this. Perhaps leave only the "catch all" conversion to points as the default
        temp_places["geometry"] = temp_places.centroid 
        temp_places = temp_places.loc[:, col_list]
        #temp_places.drop_duplicates('osmid',inplace=True)
        print('Attention: Mixed geometry types found, will be converted to points')
    elif (geom_type == 'Mixed'):
        print(temp_places["geometry"].type.unique())
        temp_places["geometry"] = temp_places.centroid 
        temp_places = temp_places.loc[:, col_list]
        print('Attention: Mixed geometry types found, only centroids will be fetched')
    elif (geom_type == 'Polygon') & ('Polygon' in geom_list) & ('MultiPolygon' in geom_list):
        print('Attention: Mixed geometry types found, converting MultiPolygons to Polygons with explode')
        # converting MultiPolygons to Polygons
        temp_places.loc[(temp_places.geometry.type=='MultiPolygon'), 'geometry'] = temp_places.loc[(temp_places.geometry.type=='MultiPolygon')].explode(ignore_index=True).geometry
        print('Geometry types after first cleanup',temp_places["geometry"].type.unique())
        if 'MultiPolygon' in temp_places.geometry.type.unique():
            print('Attention: Some MultiPolygons could not be converted to Polygons, dropping them')
            temp_places = temp_places.loc[(temp_places.geometry.type!='MultiPolygon'), col_list]
            print('Geometry types after dropping cleanup',temp_places["geometry"].type.unique())
        # checking if there are other geometry types
        if ('Point' in geom_list) | ('MultiPoint' in geom_list) | ('GeometryCollection' in geom_list):
            print('Attention: Mixed geometry types found, dropping non-Polygon geometries')
            temp_places = temp_places.loc[temp_places.geometry.type.isin(['Polygon', 'MultiPolygon']), col_list]

        #temp_places = temp_places.explode(index_parts=False)
        temp_places = temp_places.loc[:, col_list]

    else: 
          temp_places = temp_places.loc[(temp_places.geometry.type==geom_type), col_list]

    print('Features fetched',temp_places.shape[0])

    # filtering out the repeated entries
    temp_places.drop_duplicates('id', inplace=True) # the calls to drop_duplicates are separate to avoid getting the union of all conditions
    temp_places.drop_duplicates('geometry', inplace=True) # 
    temp_places.loc[temp_places['name'].notnull(),:].drop_duplicates('name', inplace=True) # 

    print('Features without duplicates',temp_places.shape[0])
    #convert the CRS of roads to the same as AOI
    temp_places.to_crs(aoi.crs,inplace=True) # type: ignore

    # clip features to the AOI
    places = gpd.clip(temp_places, mask=aoi, keep_geom_type=True)

    places['major'] = 0

    # identify major features based on the criteria dictionary
    for key, value in major_dict.items():
        places.loc[places[key].isin(value), 'major'] = 1
        #places.loc[(key == value), 'major'] = 1
        #places['major'] = places[key].apply(lambda x: 1 if x in value else None) #else 0

    return places


"""
---------------------------------------------------------------------------
utility functions
"""

"""calculate the utility"""
def calculate_utility(
    raster_dict: Dict[str, np.ndarray],
    wt_dict: Dict[str, float],
    suitability: Optional[np.ndarray] = None
) -> Dict[str, np.ndarray]:
  '''
    This function calculates the utility of each layer in the raster_dict based on the weights in the wt_dict.
    The utility is calculated as the sum of the product of the weight and the normalized layer for each layer.
    The total utility is calculated as the sum of the utility of all layers.

    Parameters:
    raster_dict (dict): A dictionary of the layers in the raster data.
    wt_dict (dict): A dictionary of the weights for each layer.

    Returns:
    utility_dict (dict): A dictionary of numpy arrays with the utility for each layer and the total

  ''' 
  utility_dict = {}

  # Loop through each layer and its corresponding weight
  for key, value in wt_dict.items():
    layer = None
    try:
      # Initialize the utility array with zeros
      utility_array = np.zeros_like(list(raster_dict.values())[0],dtype=np.float64)
      weight = value

      layer = raster_dict[key]
      #print(key, value)

      # Calculate the utility for the current layer and add it to the utility array
      utility_array += (layer * weight) #APS: 12.03.2025 converted the TI-City model utility to be directly proportional to the layer value
      utility_dict[key] = utility_array
    except:
      print('Error calculating utility for', layer)
  try:
    if type(suitability) == np.ndarray:
      utility_dict['suitability'] = suitability
      # calculate the total utility
      utility_dict['total'] = np.sum(list(utility_dict.values()), axis=0)

      # calculate the total utility in suitable areas	
      utility_dict['total_suitable'] = np.where(suitability == 1, utility_dict['total'], 0)
      utility_dict['total_suitable'] = (utility_dict['total_suitable'] - np.nanmin(utility_dict['total_suitable'])) / (np.nanmax(utility_dict['total_suitable']) - np.nanmin(utility_dict['total']))

    elif suitability == None:
      # calculate the total utility
      utility_dict['total'] = np.sum(list(utility_dict.values()), axis=0)

      # normalize the total and the total_suitable utility
      utility_dict['total'] = (utility_dict['total'] - np.nanmin(utility_dict['total'])) / (np.nanmax(utility_dict['total']) - np.nanmin(utility_dict['total']))
      #utility_dict['total_suitable_normalized'] = np.where(utility_dict['total_suitable'] > 0,utility_dict['total_suitable'] > 0, np.nan) 
      #utility_dict['total_suitable_normalized'] = (utility_dict['total_suitable_normalized'] - np.nanmin(utility_dict['total_suitable_normalized'])) / (np.nanmax(utility_dict['total_suitable_normalized']) - np.nanmin(utility_dict['total_suitable_normalized']))

    return utility_dict
  except Exception as e:
    print('error:', e)
    return utility_dict

"""utility from distance function"""
def utility_from_distance(distance_raster, density_boolean=False):
    no_file_list = []
    try:
        raster = distance_raster
        # calculate the complement of cost layers
        #if (layer != 'bu2000_dist') and (layer != 'bu2015_dist'):    
        if (density_boolean==True):
            raster = np.where(raster <= 0, 0, raster)
        else:                
            #raster = np.where(raster <= 0, np.nanmax(raster), raster)
            raster_complement = 1 - raster
            raster = raster_complement
        # normalize the raster values if they are greater than 1
        if np.nanmax(raster) > 1:
            raster = (raster - np.nanmin(raster))/(np.nanmax(raster) - np.nanmin(raster))

        print('shape:',raster.shape)                
        return raster

    except:
        print('*** not a valid raster file:', distance_raster)
        no_file_list.append(distance_raster)
        return None


def convert_distance_to_utility(raster_file_path, density_boolean=False):
    no_file_list = []
    with rasterio.open(raster_file_path, 'r') as src:
        raster = src.read(1)
        try:
            # calculate the complement of cost layers
            #if (layer != 'bu2000_dist') and (layer != 'bu2015_dist'):    
            if (density_boolean==True):
                raster = np.where(raster <= 0, 0, raster)
            else:                
                #raster = np.where(raster <= 0, np.nanmax(raster), raster)
                raster_complement = 1 - raster
                raster = raster_complement
            # normalize the raster values if they are greater than 1
            if np.nanmax(raster) > 1:
                raster = (raster - np.nanmin(raster))/(np.nanmax(raster) - np.nanmin(raster))

            print('shape:',raster.shape)                
            return raster

        except:
            print('*** not a valid raster file:', raster)
            no_file_list.append(raster)
            return None


"""cost-distance function"""
# I am testing alternatives below.

def get_weight_distance_raster(
    path_raster: np.ndarray,
    gdf_origin_points: 'gpd.GeoDataFrame',
    slope_raster_path: str,
    ref_raster_path: Path = ref_raster_path,
    wt_roads: float = 1,
    wt_no_roads: float = 100,
    wt_slope: float = 1) -> Tuple[np.ndarray, np.ndarray]:
    """Calculate accumulated cost raster using origin points and road density.

    Parameters:
        roads_full_raster: Pre-calculated raster of road network
        gdf_origin_points: GeoDataFrame containing origin points
        slope_raster_path: Path to slope raster file
        ref_raster_path: Path to reference raster for alignment
        wt_roads: Weight for road cells (default=1)
        wt_no_roads: Weight for non-road cells (default=100)
        wt_slope: Weight multiplier for slope influence (default=1)

    Returns:
        Accumulated cost raster and normalized accumulated cost raster
    """

    # Validate inputs
    if path_raster is None:
        raise ValueError("path_raster must be provided and be a numpy array")
    if gdf_origin_points is None or len(gdf_origin_points) == 0:
        raise ValueError("gdf_origin_points must be provided and contain at least one point")
    if slope_raster_path is None:
        raise ValueError("slope_raster_path must be provided")

    # Read slope raster
    with rasterio.open(slope_raster_path) as src:
        slope_raster = src.read(1)
        #print('slope:',slope_raster.shape)
    # Normalize slope to 0-1 range
    slope_normalized = (slope_raster - np.min(slope_raster)) / (np.max(slope_raster) - np.min(slope_raster))
    #print('slope normal:',slope_normalized.shape)
    print('path',path_raster.shape)
    # Create and immediately close temporary files to get their paths

    # Save source (origin points) and cost rasters to temporary files
    with rasterio.open(ref_raster_path) as ref:
        profile = ref.profile.copy()
        out_shape = (ref.height, ref.width)

        # Rasterize origin points
        origin_points_raster = features.rasterize([(geom, 1) for geom in gdf_origin_points.geometry], #type: ignore
                                                  out_shape = out_shape,
                                                  #out_shape=ref.shape,
                                                  transform=ref.transform,
                                                  fill=0,
                                                  dtype=rasterio.float32)
        print('origin:',origin_points_raster.shape) #type: ignore

    # Create combined cost surface incorporating roads and slope
    # Base cost from roads
    cost_surface = np.where(path_raster == 1, wt_roads, wt_no_roads)
    # Add slope influence
    cost_surface = cost_surface * (1 + slope_normalized * wt_slope)
    print('cost:',cost_surface.shape)

    # Find the least-cost path using Dijkstra's algorithm

    # Convert origin points to indices
    origin_indices = [tuple(ind) for ind in np.stack(np.where(origin_points_raster == 1), axis=1)]
    if len(origin_indices) == 0:
        raise ValueError("No origin points found in the rasterized origin points.")
    #print('origin length', len(origin_indices),
    #        ', \norigin first index:',origin_indices[0],
    #        ', \norigin last index:',origin_indices[-1],
    #        ', \norigin type',type(origin_indices[-1]))
    # print(type(origin_indices))

    # Calculate the destination as the point with the highest density in the path_raster
    densest_point_index = np.argmax(path_raster)
    destination = np.unravel_index(densest_point_index, path_raster.shape)
    print('densest_point:', destination)

    # Initialize an empty array to store the accumulated cost
    accumulated_cost_raster = np.zeros_like(cost_surface)
    #print('empty cost raster:',accumulated_cost_raster.shape)

    # iterate over the origin points
    for i in range(len(origin_indices)):
        origin = origin_indices[i]
        print('origin:',origin, i,'/',len(origin_indices))
        # Find the indices of the cells with the minimum cost path
        #for origin in origin_indices: #[1:10]
        print('origin:',origin, '\ndestination:',destination)
        # Find the indices of the cells with the minimum cost path
        indices, weight = route_through_array(cost_surface, 
                                                tuple(origin), 
                                                end=destination, 
                                                fully_connected=True, 
                                                geometric=True)
        #print('indices:',len(indices), '\nweight:',weight)
        # add the minimum cost paths to the accumulated cost raster
        #indices = np.stack(indices, axis=-1)
        path = np.zeros_like(cost_surface)
        # propagate the values of the path to all cells in it
        # v = weight / len(indices) # let's try to use the weight of the path instead of the average
        v = weight
        for i in indices:
            #print('i:',i, type(i), 'v:',v)
            path[i] = v
        #path[indices[0], indices[1]] = weight
        #print('path:',path.max())

        # add the path to the accumulated cost raster
        accumulated_cost_raster += path

    # Set no-data values
    accumulated_cost_raster = np.where(accumulated_cost_raster == np.inf, -9999, accumulated_cost_raster)

    # Calculate a normalized version of the accumulated cost raster
    accumulated_cost_raster_normalized = (accumulated_cost_raster - np.nanmin(accumulated_cost_raster)) / (np.nanmax(accumulated_cost_raster) - np.nanmin(accumulated_cost_raster))

    return accumulated_cost_raster, accumulated_cost_raster_normalized


"""suitability"""
def calculate_suitability(slope_raster_path, exclusion_file, urban_raster):

    '''Calculate the suitability raster based on the slope raster, exclusion file, and urban raster.	'
    Parameters:
    slope_raster_path (str): The path to the slope raster file, in percent.
    exclusion_file (str): The path to a SLEUTH-like exclusion file, where 1 = excluded, and 0 = non-excluded areas.
    urban_raster (str): The path to the urban raster file, where 1 = urban, and 0 = not urban.

    Returns:
    suitability_array (np.ndarray): A 2D array representing the suitability raster

    '''
    try:
        with rasterio.open(slope_raster_path) as src:
            slope_array = src.read(1)
            slope_meta = src.meta
            slope_transform = src.transform
            slope_max = np.nanmax(slope_array)
            develop_prob = []
            critical_slope = 25
            slope_coefficient = 11
            for a in range(critical_slope):
                b = (critical_slope - a) / critical_slope
                develop_prob.append(b ** (slope_coefficient/200))
            for i in range(int(slope_max - critical_slope)):
                develop_prob.append(0)
            #plot_continuous_raster(slope_array, 'Slope')
        # create an array of zeros to store the develop probability with the same shape as the slope array
        develop_prob_array = np.zeros(slope_array.shape, dtype=np.float32)

        # loop through the slope array and calculate the develop probability of each cell
        for i in range(slope_array.shape[0]):
            for j in range(slope_array.shape[1]):
                if slope_array[i,j] < critical_slope:
                    slope = slope_array[i,j]
                    develop_prob_array[i,j] = ((critical_slope - slope) / critical_slope) ** (slope_coefficient / 200)
        #for i in develop_prob:
            #print(round(i, 4))
        #plot_continuous_raster(develop_prob_array)

        # set suitability values 
        # generate a random raster from 0 to 1 with the dimensions of the slope raster
        rand_array = np.random.rand(slope_array.shape[0], slope_array.shape[1])
        suitability_array = np.where(rand_array <= develop_prob_array, 1, 0)

        with rasterio.open(exclusion_file) as src:
            exclusion_array = src.read(1)
            suitability_array = np.where(exclusion_array == 1, 0, suitability_array)

        with rasterio.open(urban_raster) as src:
            urban_array = src.read(1)
            suitability_array = np.where(urban_array == 1, 0, suitability_array)

        #plot_continuous_raster(suitability_array)
        return suitability_array
    except Exception as e:
        print(e)


"""
---------------------------------------------------------------------------
transform & project functions
"""

"""transform functions"""
def reproj_match(infile, match, outfile, resampling=Resampling.nearest):
    # code from https://pygis.io/docs/e_raster_resample.html
    """Reproject a file to match the shape and projection of existing raster. 

    Parameters
    ----------
    infile : (string) path to input file to reproject
    match : (string) path to raster with desired shape and projection 
    outfile : (string) path to output file tif
    """
    # open input
    with rasterio.open(infile) as src:

        # open input to match
        with rasterio.open(match) as match:
            dst_crs = match.crs

            # calculate the output transform matrix
            dst_transform, dst_width, dst_height = calculate_default_transform(
                src.crs,     # input CRS
                dst_crs,     # output CRS
                match.width,   # input width
                match.height,  # input height 
                *match.bounds,  # unpacks input outer boundaries (left, bottom, right, top)
            )

        # set properties for output
        dst_kwargs = src.meta.copy()
        dst_kwargs.update({"crs": dst_crs,
                           "transform": dst_transform,
                           "width": dst_width,
                           "height": dst_height,
                           "nodata": 0})
        print("Coregistered to shape:", dst_height,dst_width,'\n Affine',dst_transform)
        # open output
        with rasterio.open(outfile, "w", **dst_kwargs) as dst:
            # iterate through bands and write using reproject function
            for i in range(1, src.count + 1):
                reproject(
                    source=rasterio.band(src, i),
                    destination=rasterio.band(dst, i),
                    src_transform=src.transform,
                    src_crs=src.crs,
                    dst_transform=dst_transform,
                    dst_crs=dst_crs,
                    resampling=resampling)

"""majority filter function"""
def majority_filter(raster_data, size=3, threshold=0.5):
    def _majority_func(values):
        values = values[values > 0]  # Exclude no-data values (assuming they are 0)
        if len(values) == 0:
            return 0  # Return no-data if all values are no-data 
            # calculate urban surface area in proportion to the pixel's area 
            # (e.g., if the pixel is 150m x 150m (area = 22500 m²), 
            # with 100 m² of urban surface, then the proportion is 100/22500 = 0.0044)

        values = values / (150 * 150)  # Normalize by pixel area
        if np.sum(values) > threshold:
            return 1  # Classify as urban if the proportion exceeds the threshold
        else:
            return 0  # Classify as non-urban otherwise
        #return np.bincount(values.astype(int)).argmax()  # Return the most common value
    # if the majority_func is greater than a threshold (e.g., 100), then classify the cell as urban (1), otherwise non-urban (0)
    
    filtered_data = generic_filter(raster_data, _majority_func, size=size)
    return filtered_data


"""#### ATTENTIONT ####
# this function is not working as expected
# it takes very long to run and bloats the raster file
"""

def resample_raster(coarse, fine, coarse_transform=None, fine_transform=None, resampling=Resampling.bilinear):
    # code from https://rasterio.readthedocs.io/en/stable/topics/resampling.html

    if coarse_transform is None: 
        coarse_transform = coarse.transform
        print('Coarse transform',coarse_transform)
    if fine_transform is None: 
        fine_transform = fine.transform
        print('Fine transform',fine_transform)

    fine_area = fine_transform[0]*(-fine_transform[4])
    coarse_area = coarse_transform[0]*(-coarse_transform[4])
    #coarse_height, coarse_width, coarse_area = get_transform(coarse)
    #fine_height, fine_width, fine_area = get_transform(fine)
    upscale_factor = ((coarse_area)/(fine_area))**0.5 # getting the square root of the ratio of the areas

    print('Coarse area',coarse_area,
          '\nFine area', fine_area, 
          '\nUpscale factor',upscale_factor,'\n')

    resampled_raster = coarse.read(coarse.count, 
                                   out_shape=(int(coarse.height * upscale_factor), 
                                              int(coarse.width * upscale_factor)), 
                                              resampling=resampling)

    resampled_transform = coarse.transform * coarse.transform.scale(
        (coarse.width / resampled_raster.shape[-1]),
        (coarse.height / resampled_raster.shape[-2])
    )
    return resampled_raster, resampled_transform


"""
---------------------------------------------------------------------------
gee related functions
"""
def gee_to_tiff(input_layer, out_folder, output_filename, crs, roi):
    #projection = input_layer.projection().getInfo()

    try:
        if not os.path.exists(out_folder):
            os.mkdir(out_folder)

        # Export a GEE layer to raster Gtiff
        geemap.ee_export_image_to_drive(
            input_layer,
            description=output_filename,
            folder=out_folder,
            maxPixels=1e13, #ressamples to a low resolution
            region = roi,
            crs = crs, #projection['crs'],
            fileFormat = 'GeoTIFF',
            scale = 10           
        )
        #raster = 
        #return raster
    except Exception as e:
        print("An error has occurred:", e)

def export_ee_image(image, filename, roi): #crs, projection, removed these arguments as they caused a resampling error
    try: 
        task = ee.batch.Export.image.toDrive( #type: ignore
            image=image,
            description=filename,
            folder='gee_exports',
            region=roi,
            #crs=crs,
            #crsTransform=projection['transform'],
            maxPixels=1e13, #type: ignore
            fileFormat='GeoTIFF',
            formatOptions={
                'cloudOptimized': False
            }
        )
        task.start()
        logging.info(f'Exporting {filename} to Google Drive')
        return task
    except Exception as e:
        logging.error(f'An error has occurred: {e}')
        return None


"""check image stats before export"""
def check_image_stats(image, roi): 
    stats = image.reduceRegion(
        reducer=ee.Reducer.minMax(),
        geometry=roi,
        scale=250,
        maxPixels=1e9       
    )
    return stats.getInfo()


""" extract coordinates from the bounding box"""
def get_coords(gdf):
    coords = gdf.envelope #.to_crs(epsg='4326') the CRS is defined at the import
    epsg_coords = coords.crs.to_epsg()
    transform = [coords.bounds.values[0][0], coords.bounds.values[0][1], coords.bounds.values[0][2], coords.bounds.values[0][3]]
    roi = ee.Geometry.BBox(west=transform[0], south=transform[1], east=transform[2], north=transform[3])
    rec_roi = ee.Geometry.Rectangle(transform[0],transform[1],transform[2],transform[3])
    coi = roi.centroid(maxError=1)
    return epsg_coords, roi, rec_roi, coi


"""
---------------------------------------------------------------------------
plot functions
"""
"""plot two raster side by side"""

def plot_ras_ras(raster1, raster2, title1:'str'='some title', title2:'str'='some other title', AOI_gdf:'gpd.GeoDataFrame'= gpd.GeoDataFrame()):
    fig, ax = plt.subplots(nrows=1, ncols = 2, figsize = (10, 10))
    '''if raster1.crs != None:
        AOI_gdf.to_crs(raster1.crs).plot(ax=ax[0],  alpha=0.5, color='lightgray', zorder=1)
        AOI_gdf.to_crs(raster2.crs).plot(ax=ax[1],  alpha=0.5, color='lightgray', zorder=1)
    else:'''
    AOI_gdf.plot(ax=ax[0],  alpha=0.5, color='lightgray', zorder=1)
    AOI_gdf.plot(ax=ax[1],  alpha=0.5, color='lightgray', zorder=1)

    show(raster1, ax = ax[0])
    show(raster2, ax = ax[1])

    ax[0].set_title(title1)
    ax[1].set_title(title2)

    plt.gca() 
    plt.show()

"""plot a vector and a raster side by side"""
def plot_vec_ras(vector, raster, title, AOI_gdf:'gpd.GeoDataFrame'= gpd.GeoDataFrame()):
    fig, ax = plt.subplots(nrows=1, ncols = 2, figsize = (15, 15))
    vector.plot(ax=ax[0],color='tomato', linewidth=1, zorder=2)
    AOI_gdf.plot(ax=ax[0],  alpha=0.5, color='lightgray', zorder=1)

    AOI_gdf.plot(ax=ax[1],  alpha=0.5, color='lightgray', zorder=1)
    show(raster, ax = ax[1])

    ax[0].set_title( title)
    #ax[0].set_axis_off()
    plt.gca() 
    plt.show()


"""plot two vectors and two rasters side by side"""
def plot_vec_vec_ras_ras(vector, dist_raster, norm_raster, title, AOI_gdf:'gpd.GeoDataFrame'= gpd.GeoDataFrame()):
    fig, ax = plt.subplots(nrows=1, ncols = 4, figsize = (10, 40))
    vector.plot('major',ax=ax[0],color='grey', linewidth=1, zorder=1)
    vector.loc[vector.major==0].plot(ax=ax[1],color='lightgrey', zorder=3)
    vector.loc[vector.major==1].plot(ax=ax[1],color='tomato', zorder=4)
    AOI_gdf.plot(ax=ax[0],  alpha=0.5, color='lightgray', zorder=1)
    AOI_gdf.plot(ax=ax[1],  alpha=0.5, color='lightgray', zorder=1)
    show(dist_raster, ax = ax[2])
    show(norm_raster, ax = ax[3])

    ax[0].set_title('All '+ title + ' vector')
    ax[1].set_title('Major '+ title + ' vector')
    ax[2].set_title('Distance to \nmajor '+ title + ' (m)')
    ax[3].set_title('Distance to \nmajor '+ title + ' normalized')

    plt.gca() 
    plt.show()

"""plot a unique value raster (categorical data)"""
def plot_unique_value_raster(raster, ax=None, title=None, colors=None):
    if type(raster) == np.ndarray:
        array = raster
    else:
        array = raster.read(1)
    if ax is None:
        fig, ax = plt.subplots(figsize=(5, 5))

    # get and check unique values to include in the legend
    unique_values = np.unique(array)
    print('Unique values',unique_values,'\nMin value',np.min(array),', Type:',unique_values[0].dtype)

    try:
        # Define a custom color map for integer values
        import random 
        if len(unique_values) > 200:
            print('Too many unique values to plot')
            raise ValueError("Too many unique values to plot")
        if colors != None:
            if len(colors) != len(unique_values):
                raise IndexError('The numbers of colours is not the same as the values. \nColours:',len(colors), 'Values:', len(unique_values))
            else:
                cmap = LinearSegmentedColormap("color_list", colors, N=len(unique_values))
                value_to_color = {val: colors[i] for i, val in enumerate(unique_values)}
        else:
            get_colors = lambda n: ["#%06x" % random.randint(0, 0xFFFFFF) for _ in range(n)]
            colors = get_colors(len(unique_values))

            # Ensure the number of colors matches the number of unique values
            if len(unique_values) > len(colors):
                raise ValueError("Not enough colors for the number of unique values.")

            # Create a mapping from unique values to colors
            value_to_color = {val: colors[i] for i, val in enumerate(unique_values)}

            # Create a ListedColormap using the mapped colors
            cmap = mcolors.ListedColormap([value_to_color[val] for val in unique_values])

        show(array, ax=ax, cmap=cmap, title=title) # any ideas why this is not plotting correctly?

        # Create legend patches
        patches = [mpatches.Patch(color=value_to_color[val], label=val) for val in unique_values] 
        if len(unique_values) > 10:
            print('Too many unique values to plot a legend')
        else:
            ax.legend(handles=patches, loc='upper right')
        plt.show()
    except Exception as e:
        print('Error:',e)
        show(array, ax=ax, title=title)

"""plot a continuous value raster"""
def plot_continuous_raster(raster,title=None):
    if type(raster) == np.ndarray:
        array = raster
    else:
        array = raster.read(1)
    print('Min value:',np.min(array),', Max value:',np.max(array))
    fig, ax = plt.subplots(figsize=(5, 5))
    cmap = 'viridis'
    norm = mcolors.Normalize(vmin=np.min(array), vmax=np.max(array))
    show(array, ax=ax, cmap=cmap, norm=norm, title=title)
    sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
    sm.set_array([])
    cbar = plt.colorbar(sm, ax=ax)
    cbar.set_label('Value')

from rasterio.plot import show, plotting_extent
"""compares rasters in a matrix"""
def plot_compare_rasters(vector:gpd.GeoDataFrame = gpd.GeoDataFrame(), 
                         roads_vector:'gpd.GeoDataFrame'= gpd.GeoDataFrame(), 
                         dist_raster: np.ndarray = np.zeros((0, 0), dtype=np.float64),
                         norm_raster:np.ndarray = np.zeros((0, 0), dtype=np.float64), 
                         title:str='Some title', 
                         AOI_gdf:gpd.GeoDataFrame = gpd.GeoDataFrame(), 
                         ref_raster_path:Path = Path('./')):
    with rasterio.open(ref_raster_path) as src:
        plot_transform = src.transform
    plot_extent = plotting_extent(dist_raster, plot_transform)

    fig, ax = plt.subplots(nrows=1, ncols = 3, figsize = (10, 40))
    fig.set_dpi(150.0) 

    # first graph, only vectors
    vector.loc[vector.major==0].plot(ax=ax[0],color='lightgrey', zorder=1)
    roads_vector.loc[roads_vector.major==1].plot(ax=ax[0],color = 'grey',zorder=2)
    vector.loc[vector.major==1].plot(ax=ax[0],color='tomato', zorder=3)
    AOI_gdf.plot(ax=ax[0],  alpha=0.5, color='lightgray', zorder=1)

    # second graph, Euclidian distance
    #p1 = rasterio.plot.show(dist_raster,transform = plot_transform, ax = ax[1], with_bounds=plot_extent)
    p1 = show(dist_raster, transform=plot_transform, ax=ax[1], extent=plot_extent)
    AOI_gdf.plot(ax=p1,  alpha=0.5, color='lightgray', zorder=1)
    vector.loc[vector.major==1].plot(ax=p1,color='lightgray', markersize=1, zorder=3, alpha=0.5)
    roads_vector.loc[roads_vector.major==1].plot(ax=p1,color='darkgrey', linewidth=1, zorder=2, alpha=0.5)

    #third graph, cost distance
    #p2 = rasterio.plot.show(norm_raster, transform = plot_transform, ax = ax[2], with_bounds=plot_extent)
    p2 = show(norm_raster, transform=plot_transform, ax=ax[2], extent=plot_extent)
    AOI_gdf.plot(ax=p2,  alpha=0.5, color='lightgray', zorder=1)
    vector.loc[vector.major==1].plot(ax=p2,color='lightgray', markersize =1, zorder=3, alpha=0.5)
    roads_vector.loc[roads_vector.major==1].plot(ax=p2,color='darkgrey', linewidth=1, zorder=2, alpha=0.5)

    ax[0].set_title('Major '+ title + ' vector')
    ax[1].set_title('Euclidian'+ title)
    ax[2].set_title('Cost '+ title)

    plt.gca() 
    plt.show()


""" iterate through the utility dictionary and plot the calculated utility"""
def plot_many_rasters(raster_dict, fig_title, ref_raster_path=None, subplot_title=' utility'):
    # this function takes in a raster dict with a key as the title and the value as a numpy 2D array
    # it 'simply' counts the rasters and creates a subplot for each one
    # future work should include detecting the data type (e.g., continuous versus unique values) and plotting accordingly

    # set up a figure with placeholders for the subplots
    #count the number of items in the dict
    n = len(raster_dict)
    #print(n)
    text_size = 8
    # get the number of rows and columns for the subplots
    if n % 4 == 0:
        rows = n // 4
    else:
        rows = n // 4 + 1

    cols = 4
    fig, ax = plt.subplots(nrows=rows, ncols=cols,figsize=(12, 10))
    # add a fig title
    fig.suptitle(fig_title, fontsize=10)
    plot_transform = None
    # get the extent of the reference raster
    if ref_raster_path != None:
        with rasterio.open(ref_raster_path) as src:
            plot_transform = src.transform

    #plot_extent = plotting_extent(dist_raster, plot_transform)

    plt.tick_params(left = False, right = False , labelleft = False , 
                    labelbottom = False, bottom = False) 

    # iterate through the rows and cols and plot the utility array in each
    for i in range(rows):
        for j in range(cols):
            # get the key of the utility array
            arr_number = i*cols+j
            if arr_number < n:
                key = list(raster_dict.keys())[arr_number]
                # plot the utility array using the plot_continuous_raster function
                cmap = 'viridis'
                array = raster_dict[key]
                title = key + subplot_title


                norm = mcolors.Normalize(vmin=np.min(array), vmax=np.max(array))
                if ref_raster_path != None:
                    plot_extent = plotting_extent(array, plot_transform)
                    show(array, ax=ax[i,j], cmap=cmap, norm=norm, title=title, extent=plot_extent)
                else:
                    show(array, ax=ax[i,j], cmap=cmap, norm=norm, title=title)
                sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
                sm.set_array([])
                cbar = plt.colorbar(sm, ax=ax[i,j])
                cbar.ax.tick_params(labelsize=text_size)
                cbar.set_label('Value', fontsize=text_size)
                #cbar.ax.tick_params(labelsize=7)
                ax[i,j].set_xticks([])
                ax[i,j].set_yticks([])
                ax[i,j].title.set_size(text_size)
            else:
                ax[i,j].set_xticks([])
                ax[i,j].set_yticks([])
                for spine in ax[i,j].spines.values():spine.set_visible(False)
    plt.tight_layout()
    # plot the utility array


"""
---------------------------------------------------------------------------
export functions
"""

""" export raster as geotiff """
def export_geotiff(raster, out_transform, out_meta, export_path,data_type=rasterio.int16):
    print(export_path)
    # export the clipped raster
    out_meta.update({"driver": "GTiff",
                     "dtype" : data_type,
                     "height": out_meta['height'],
                     "width": out_meta['width'],
                     "transform": out_transform})
    with rasterio.open(export_path, "w", **out_meta) as dest:
        dest.write(raster, indexes=1)

""" export rasters as geotiff using a reference raster to copy the metadata """
def export_raster(
    raster: np.ndarray,
    url: Path,
    data_type: str = rasterio.int16,
    ref_raster_path: Path = ref_raster_path
    ) -> None:
    with rasterio.open(ref_raster_path, 'r') as ref_raster:
        with rasterio.open(
            url, "w",
            driver = "GTiff",
            crs = ref_raster.crs,
            transform = ref_raster.transform,
            dtype = data_type,
            count = 1,
            width = ref_raster.width,
            height = ref_raster.height) as dst:
            dst.write(raster, indexes = 1)

""" export raster as ascii files
it requires the definition of a reference raster to copy the metadata
"""
def export_raster_to_ascii(raster_obj, export_path, ref_raster_path=ref_raster_path,raster_data_type=rasterio.int16): 
    if raster_data_type == 'int16':
        raster_data_type = rasterio.int16
    elif raster_data_type == 'float32':
        raster_data_type = rasterio.float32
    elif raster_data_type == 'float64':
        raster_data_type = rasterio.float64
    with rasterio.open(ref_raster_path, 'r') as reference:
        with rasterio.open(export_path, "w", 
                           driver='AAIGrid',
                           height=reference.shape[0], 
                           width=reference.shape[1],
                           count=1, 
                           dtype=raster_data_type,
                           crs=reference.crs, 
                           transform = reference.transform,
                           nodata=-9999) as dest:
            dest.write(raster_obj.astype(raster_data_type), indexes=1)

""" export rasters to ascii and clip them to the AOI"""
def export_raster_to_ascii_aoi_clip(raster_obj, export_path, aoi, ref_raster_path=ref_raster_path,raster_data_type=rasterio.int16):
    raster_obj, raster_transform = mask(raster_obj, getFeatures(aoi), crop=True)
    # out_image, out_transform = mask(in_raster, getFeatures(aoi), crop=True)
    with rasterio.open(ref_raster_path, 'r') as ref_raster:
        with rasterio.open(export_path, "w", 
                           driver='AAIGrid',
                           height = raster_transform.shape[0], 
                           width=raster_transform.shape[1],\
                            count=1,
                            dtype=raster_data_type,
                            crs=ref_raster.crs, 
                            transform = raster_transform.transform) as dest:
            dest.write(raster_obj.astype(raster_data_type), indexes=1)

""" export vector and raster files """
def export_files(
    gdf: Optional['gpd.GeoDataFrame'] = None,
    major_raster: Optional[np.ndarray] = None,
    full_raster: Optional[np.ndarray] = None,
    distance_raster: Optional[np.ndarray] = None,
    distance_normal: Optional[np.ndarray] = None,
    utility_raster: Optional[np.ndarray] = None,
    out_path: Path = Path('./'),
    file_name: str = 'out_file'
) -> None:
    """
    Export vector and raster files to specified paths.

    Parameters:
    -----------
    gdf : GeoDataFrame, optional
        The GeoDataFrame to export as a shapefile.
    major_raster : numpy.ndarray, optional
        The major raster to export as a GeoTIFF.
    full_raster : numpy.ndarray, optional
        The full raster to export as a GeoTIFF.
    distance_raster : numpy.ndarray, optional
        The distance raster to export as a GeoTIFF.
    distance_normal : numpy.ndarray, optional
        The normalized distance raster to export as a GeoTIFF.
    utility_raster : numpy.ndarray, optional
        The utility raster to export as a GeoTIFF.
    out_path : pathlib.Path, optional
        The output directory path. Defaults to the current directory.
    file_name : str, optional
        The base name for the output files. Defaults to 'out_file'.
    Returns:
    --------
    None
    """
    try:
        if gdf is not None:
            if gdf.geometry.type.unique()[0] == 'Polygon':
                gdf_vector_file = file_name + '_A.shp'
            elif gdf.geometry.type.unique()[0] == 'Point':
                gdf_vector_file = file_name + '_P.shp'
            elif gdf.geometry.type.unique()[0] == 'LineString':
                gdf_vector_file = file_name + '_L.shp'
            else:
                print('Geometry type for', gdf.geometry.type.unique()[0], 'not supported for export')
                return
            gdf_url = out_path/gdf_vector_file
            gdf.to_file(gdf_url, driver='ESRI Shapefile')

        if major_raster is not None:
            major_raster_file = file_name + '_major_150m.tif'
            major_url = out_path/major_raster_file

            export_raster(raster = major_raster,
                        url = major_url, # type: Path
                        data_type=rasterio.int16,
                        ref_raster_path=ref_raster_path)

            """ 
            ***** APS 17.10.2025: I am removing all ASCII exports as they are now covered by a batch conversion funtion at the end of the notebook *****
            #major_ascii_url = out_path/(major_raster_file.split('.')[0] + '.asc')
            #export_raster_to_ascii(raster_obj = major_raster, 
            #                    export_path = major_ascii_url, 
            #                    ref_raster_path=ref_raster_path,
            #                    raster_data_type=rasterio.int16)
            """

        if full_raster is not None:
            full_raster_file = file_name + '_all_150m.tif'
            full_url = out_path/full_raster_file
            export_raster(raster = full_raster,
                        url = full_url,
                        data_type=rasterio.int16,
                        ref_raster_path=ref_raster_path)

            """
            full_ascii_url = out_path/(full_raster_file.split('.')[0] + '.asc')
            #export_raster_to_ascii(raster_obj = full_raster, 
            #                    export_path = full_ascii_url, 
            #                    ref_raster_path=ref_raster_path,
            #                    raster_data_type=rasterio.int16)
            """

        if distance_raster is not None:
            distance_raster_file = file_name + '_distance_150m.tif'
            distance_url = out_path/distance_raster_file
            export_raster(raster = distance_raster,
                        url = distance_url,
                        data_type=rasterio.float32,
                        ref_raster_path=ref_raster_path)

            """
            distance_ascii_url = out_path/(distance_raster_file.split('.')[0] + '.asc')
            #export_raster_to_ascii(raster_obj = distance_raster, 
            #                    export_path = distance_ascii_url, 
            #                    ref_raster_path=ref_raster_path,
            #                    raster_data_type=rasterio.float32)
            """

        if distance_normal is not None:
            normalized_raster_file = file_name + '_distance_normal_150m.tif'
            normalized_url = out_path / normalized_raster_file
            export_raster(raster = distance_normal,
                        url = normalized_url,
                        data_type = rasterio.float32,
                        ref_raster_path = ref_raster_path)
            """
            normal_ascii_url = out_path/(normalized_raster_file.split('.')[0] + '.asc')
            #export_raster_to_ascii(raster_obj = distance_normal, 
            #                    export_path = normal_ascii_url, 
            #                    ref_raster_path=ref_raster_path,
            #                    raster_data_type=rasterio.float32)
            """
        if utility_raster is not None:
            utility_raster_file = file_name + '_utility_150m.tif'
            utility_url = out_path/utility_raster_file

            export_raster(raster = utility_raster,
                        url = utility_url,
                        data_type=rasterio.float32,
                        ref_raster_path=ref_raster_path)
    except Exception as e:
        print('Error exporting files:',e)