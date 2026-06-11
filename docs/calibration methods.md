# Ti-City Model calibration methods

# Methods

---- 

## Monte Carlo simulations- [Ti-City Model calibration methods](#ti-city-model-calibration-methods)
- [Ti-City Model calibration methods](#ti-city-model-calibration-methods)
- [Methods](#methods)
  - [Monte Carlo simulations- Ti-City Model calibration methods](#monte-carlo-simulations--ti-city-model-calibration-methods)
    - [Requirements](#requirements)
    - [Assumptions](#assumptions)
    - [Caveats](#caveats)
  - [Decision trees](#decision-trees)
    - [Requirements](#requirements-1)
    - [Assumptions](#assumptions-1)
    - [Caveats](#caveats-1)
  - [Bayesian hierarchical model](#bayesian-hierarchical-model)
    - [Requirements](#requirements-2)
    - [Assumptions](#assumptions-2)
    - [Caveats](#caveats-2)
  - [Method name](#method-name)
    - [Requirements](#requirements-3)
    - [Assumptions](#assumptions-3)
    - [Caveats](#caveats-3)

Reference publication: Varquez ACG, Dong S, Hanaoka S, Kanda M. Evaluating future railway-induced urban growth of twelve cities using multiple SLEUTH models with open-source geospatial inputs. Sustainable Cities and Society. 2023;91:104442. [doi:10.1016/j.scs.2023.104442](https://linkinghub.elsevier.com/retrieve/pii/S2210670723000537)

Calibration goal: agreement between the predicted (NetLogo output) and reference 2025 (HDI downscaled population) SEP population distribution

### Requirements
-  Location factor raster layers
-  2025 reference population distribution per SEP class
-  Utility function
-  Agreement metric calculation (r2, in Python?)
-  Long development time
-  High computing power/time (Lotta's computer is great)
-  Multiple model runs with each configuration to deal with inherent randomness (starting config + agent choice algorithm)

### Assumptions
- Varying the weights for each location factor and each agent class generates different simulated SEP population distributions
- Each SEP class has a different utility function (determined by its weight factors)
- 

### Caveats
- Multiple weights configurations might lead to similar results (non-exclusive) 

---- 

## Decision trees
Reference publication: Robertson C, Safta C, Collier N, Ozik J, Ray J. Bayesian Calibration of Stochastic Agent Based Model via Random Forest. Statistics in Medicine. 2025;44(6):e70029. doi:10.1002/sim.70029
Calibration goal: agreement between the predicted (NetLogo output) and reference 2025 (HDI downscaled population) SEP population distribution under high-dimensionality (six agent classes x 21 spatial layers = )

### Requirements
-  Run RF against the 2025 reference SEP population
-  A large enough population per SEP class (> 1,000)
-  Short implementation/development time

### Assumptions
- Forest configurations allow estimating the weights (variable importance) for each spatial factors
- The weights would explain the utility choice (but we do have other factors in the decision)
- Each agent occupies a niche that is sufficiently different from the other classes

### Caveats
- Overfitting might be an issue
- Class imbalance might be another issue (work around: run binary classification for each class separately)
- Simulation independent: might add noise or work better for validation

---- 

## Bayesian hierarchical model
Reference publication: 
Calibration goal:

### Requirements
-  Calculate a regression for the reference 2025 population (against all spatial factors)
-  

### Assumptions
- 
### Caveats
- 

---- 

## Method name
Reference publication: 
Calibration goal:

### Requirements
-  
### Assumptions
- 
### Caveats
- 
