# TI-City-Model.v1.5


### What is it?
The repository contains an extension for the TI-City Model.
The original model was developed by Dr Felix Agyemang and simulated future residential development in an African city (Accra).
It is being extended by Dr Alexandre Pereira Santos for the simulation of future urban development in megacities in Asia, especially Manila, Mumbai, and Jakarta. See the [changelog](https://gitlab.lrz.de/0000000001364670/ti-city-model/-/blob/main/docs/changelog.md) for all modifications.

The model, which is named TI-City, combines agent-based and cellular automata modelling techniques to predict the geospatial behaviour of key urban development actors, including households, real estate developers and government.

The model is implemented in NetLogo programming platform and the input preparation scripts in Python.
This repository loosely follows the structure from CookieCutter Data science and has the following segments:
- data: stores all the data necessary for the different case studies. These are organised as "in_" when used for inputs and "out_" when they host the outputs.
- model: the NetLogo implementation for each case study. 
1. We identify the cases through the first three letters from the city name, i.e., ACC = Accra, MUM = Mumbai, JAK = Jakarta, and MAN = Manila. 
2. Additionally, "_validation" identifies the initial run of the model, aiming at predicting the current urban structure from past data. 
3. Similarly, "_predictionYYYY" includes the extrapolation of those dynamics to the future.
- notebooks: include the data preparation and input validation scripts developed in Python.

### How it works

TI-City has several key parameters. This includes:
 
1. A development control parameter, which accounts for more stringent or liberal regulatory contexts (i.e., control how much informality is permitted);
2. Projected market demand for plots from four household agent types;
3. Estimated share of households in deprived, low-, middle-, and high-income classes; 
4. Estimated demand for plots from real estate developers; 
5. Estimated share of real estate developers targeting middle and high income buyers; 
6. Land prices and affordability 
7. Utility of land parcels; and 
8. The sensitivity of development to slope. 

The model computes the suitability and utility of a given parcel for each income group by considering the geographical characteristics of the parcel. In calculating utility, the model accounts for the parcel’s geographical characteristics weighted differently depending on the income group of prospective inhabitants. The utility is dynamically updated during the simulation based on the income characteristics in the geographic neighbourhood of each cell.
 

### How to use it

1. Select the simulation period. The unit is in years.
2. Select the number of households to simulate using the household slider.
3. Split households in deprived-, low-, middle-, and high income classes using the sliders. The sum of the three proportions should be equal to 100 percent.
4. Select the number of real estate developers to simulate.
5. Split real estate developers into middle and high end suppliers. The sum of the two proportions should be equal to 100 percent.
6. Select slope coefficient, which determines the extent to which development patterns are influenced by slope. This is modelled after SLEUTH.
7. Select critical slope. This is the percent slope value beyond which development cannot occur. It may be derived from local urban development policies and regulations.
8. Select development control value. This determines the extent to which development conforms to government regulation/local plan. The lower the value the weaker the development control.
9. Provide the model input layers (see below)

### Input layers
The model takes several georeferenced rasters as inputs. These layers should be prepared externally, but the scripts in the 'notebooks' folder support that effort. It is critical that the layers have the same extent, are in the same geographic projection and coordinate system and have been co-registered. The values for these layers should also match the model implementation and are noted below. They can be categorical (indicated by discrete numerical values), or normalised continuous values (from 0-1). They include:

1. Administrative units (categorical, 1-n, where n is the number of districts)
2. Distance to urban features (i.e., roads, schools, health centres, malls,  attractive areas, suburban centres, waterways, and CBDs [continuous and normalised]).
3. Population density (continuous and normalised)
5. Real estate prices (categorical, 1-n, where n are the agent classes)
6. Slope (continuous, in percent)
8. Urbanisation for the reference year (or two, if calibration and prediction are to be compared [categorical, with 1 = urban and 0 = non-urban])
9. An exclusion layer (categorical, with 0 = urbanisation is allowed and 1 = urbanisation not permitted)

### Things to notice

The spatial resolution of the model as applied to Accra is 200m. This is about 50 times larger than the average size of land parcels in the city. To apply the model to Accra using the available data, the parcel enlargement factor should be considered in determining the number of households and real estate developers to simulate.

To adapt the model to any other city, consider the spatial resolution of the data and the extent to which is enlarges or reduces actual sizes of land parcels. Like the case of Accra, this could influence the number of households and real estate developers to simulate.


#### Key for income status predictions:
0 = undeveloped lands;
1 = Low income;
2 = Middle income;
3 = High income;
4 = seed year built-up.


#### Key for legal status predictions:
0 = undeveloped lands;
1 = informal development;
2 = formal development;
6 = seed year built-up. 


### Things to try

Consider adjusting some of the parameters. For instance, what happens with strong development control or what happens if there is a higher share of middle or high income households?

Experiment with data from a different city.


### Extending the model




### Related model

SLEUTH


### How to cite it

The original model may be cited as follows: <br>
Agyemang, F.S., Silva, E., & Fox, S. (2021). Modelling and simulating ‘informal urbanization’: An integrated ABM and CA model of urban residential growth in Ghana. Environment and Planning B: Urban Analytics and City Science. https://doi.org/10.1177%2F23998083211068843. <br>
If you use any of the changes included here, please cite this repository as the source.<br>

### References

Agyemang, F.S., Silva, E., & Fox, S. (2021). Modelling and simulating ‘informal urbanization’: An integrated ABM and CA model of urban residential growth in Ghana. Accepted for publication in Environment and Planning B: Urban Analytics and City Science.

Clarke, K. C., Hoppen, S., & Gaydos, L. (1997). A self-modifying cellular automaton model of historical urbanization in the San Francisco Bay area. Environment and Planning B: Planning and Design, 24(2), 247-261.

Zhou, Y. (2015). Urban growth model in Netlogo. Available at: http://www.gisagents.org/2015/09/urban-growth-model-in-netlogo.html

### Contact

For the original model: Dr Felix S. K Agyemang; School of Geographical Sciences; Unversity of Bristol, felix.agyemang@manchester.ac.uk, https://research-information.bris.ac.uk/en/persons/felix-s-k-agyemang
For the extension: Dr Alexandre Pereira Santos; Department of Geography, Ludwig-Maximilians-Universität in Munich, [alexandre.santos@lmu.de](mailto:alexandre.santos@lmu.de).
