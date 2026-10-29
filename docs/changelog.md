# TA-City-Model
# Changelog

This log tracks the changes from TI-City (implemented by [Dr Felix Agyemang](mailto:felix.agyemang@manchester.ac.uk)) to **TA-City** (implemented by [Dr Alexandre Pereira Santos](mailto:asantos@uni-bonn.de)).<br>
TI-City publication (2023): DOI [10.1177/23998083211068843](https://journals.sagepub.com/doi/10.1177/23998083211068843)
TA-City model publication (2026): DOI [TBD]()

CHANGELOG FROM TI-City CODE
1. adjusted variable naming for consistency
2. separated inputs for more than one case study removing 'Accra' from them.
3. added comments to the code, notably marking those lines commented out in the original and highlighting changes implemented in this revision.
4. renamed prox-bu2015-dataset to bu2015-dist-dataset for consistency with the 2000 dataset
5. renamed the load-prox-bu2015 to load-bu2015-dist for clarity
6. adjusted the number of patches and households
7. created the load-attractive2000 function
8. created the load-income function
9. created the load-bu2000 function
10. renamed the 'density 'global to 'density2015'
11. created the density2000-dataset global
12. created the income-dataset global
13. created the income-patch patches-own
14. renamed the 'landvaluse-dataset 'global to 'landvalue-dataset'
15. renamed the 'splan-dataset 'global to 'structureplan-dataset'
16. renamed the 'splan 'patches-own to 'structureplan'
17. organised the globals, patches-own, and functions alphabetically. Names follow the variable name, when possible, adding year for disambiguation.
18. created subcategories for  globals, patches-own, and functions
19. created the set-weights function, which makes assigning the weights in the utility functions more transparent. It includes 39 additional global variables. I also re-ordered the utility functions weighting for consistency (now all income levels follow the same order).
20. adjusted the interface
21. created the calibration/prediction button and associated functions
- renamed the global attractive-2015 to attractive
- renamed the global bu2015 to bu
22.  added a water parameter to the inputs
- added water weight parameters to LI, MI, and HI agents
- added a load-water function, water-dateset global, and water patch-own
23.  added urban-type patch-own (0 = non-urban, 1 = low income, 2 = medium income, 3 = high income, 4 =  deprived, 5 = seed year built-up)
24.  updated the income export function using gis extension
25.  added informal-status patch-own (0 = non-urban, 1 = informal, 2 = formal, 4 = seed year built-up)
26.  created a new agent class: deprived income. created its associates variables (dpu-suburb dpu-neigbhour dpu-bu dpu-cbd dpu-mall dpu-markets dpu-road dpu-density dpu-schools dpu-attractive dpu-health dpu-random dpu-water) and functions () 
27.  created a scenario selector to implement the shared socioeconomic pathways (SSPs, see)
- created separate parameterisation for the exclusion layer , with the necessary raster dataset loading functions
- created new parameterisation for each scenario 
29. add developer agents weights to the the set-weights function
- mi-red-suburb mi-red-neigbhour mi-red-bu mi-red-cbd mi-red-mall mi-red-markets mi-red-road mi-red-density mi-red-schools mi-red-attractive mi-red-health mi-red-random mi-red-water
- hi-red-suburb hi-red-neigbhour hi-red-bu hi-red-cbd hi-red-mall hi-red-markets hi-red-road hi-red-density hi-red-schools hi-red-attractive hi-red-health hi-red-random hi-red-water
30. expand the dpu-rad, li-rad, mi-rad, hi-rad, mi-red-rad, and hi-red-rad as variables. They are set in set-weights and define the search radius for the neighbourhood functions
31. defined dpu-maxof, liu-maxof, miu-maxof, and hiu-maxof as variables. It is declared in set-weights and defines the number of cells on the top of the utility distribution that an agent might randomly select to settle
32. defined hi-red-maxof, mi-red-maxof. maxof as variables. It is declared in set-weights and defines the number of cells on the top of the utility distribution that a real-estate developer agent might randomly select to develop.
33. created the RED-on? and neighbour-on? switches, for calibration/sensitivity testing.
34. adjusted the set-weights function to use the CSV extension to fetch the weights from an external file in "./data/in/weights.csv"
35. created the export-income-status-as-asc-tick function to export outputs for every tick2.  
36. replaced the fixed allocation with a dynamic one, now uses a fraction of remaining agents for each class (avoiding insufficient agent allocation error)
37. re-labeled date-dependent file names. From "2000" to "early" and "2015" to "late", retaining two calibration years, but making them flexible for other specifications.
    1.  Model file names (use underscore e.g., "attractive_early.asc")
    2.  Model functions (for consistency, using dashes, e.g., "load-attractive-early")
    3.  ASCII file names 
    4.  Python renaming dicts in ti_city_10_check_inputs_quality_and_copy.ipynb
38. (v29) Updated the neighbourhood functions:
    1.  Remove redundant tests
    2.  Enforced priority ordering (high SEP overrides middle, low, and deprived and so on)
    3.  Added tracking mechanisms to the neighbourhood changes
39. (v30) Implemented an exposure layer ("exposed.asc"). Values are 0 = no exposure, 1 = low exposure, 2 = moderate exposure and 3 = high exposure. Subsequent changes to:
    1.  Add exposed-dataset to globals.
    2.  Add exposed to patches-own.
    3.  Add exposed weights to globals (e.g., dpu-exposed, liu-exposed, etc.).
    4.  Add load-exposed procedure.
    5.  Update set-weights to assign exposed weights from the CSV 
    6.  Update utility functions (load-UDP, load-ULI, load-UMI, load-UHI, load-UMED, load-UHED) to include exposed.
    7.  Call load-exposed in setup
40. (v31) Adjusted the set-scenarios function to work with an external CSV file (similar to set-weights)
41. Included the real state development agents in the weights CSV file and adjusted the set-weights procedure accordingly
42. Adjusted the set-weights procedure to work with a different weight set for each scenario. The weight files must be indicated in the scenarios.csv
43. (v32) Troubleshot set-weights functions
44. Standardised the exclusion and weights file naming, following a linear scenario naming convention (exclusion_s1.asc, weights_s1.csv,then _s2, _s3, and _s4)
45. (v33) Replaced simulation-period slider with an input (making the interface more thematically grouped)
46. Updated export functions and included a switch to make the export-per-tick optional
47. (v34) updated model GUI
48. (v35) created 13.08.2026, not sure why
49. (v36) removed former scenario 3 (S3) from Jakarta simulations. Previous S4 will take its number, with updated parameter for percent-low-income-households and percent-mid-income-households
50. created the scenario for calibration (S0)
51. (v37) created after error on saving NetLogo file
52. corrected make-households NetLogo procedure; it had an bug when creating the li-households that resulted in fewer than  household-number being allocated
53. (v38) corrected allocation function in make-X-household-development functions. They previously allowed for the selection of the same cell by multiple agents, as the set of cells to be settled was evaluated only once per agent class and not per individual agents. Performance has decreased signficantly with the per-agent evaluation.
54. (v39) replaced the agent-centred allocation functions to a patch-centred approach. Aims at speeding allocation while keeping stochastic behaviour.<br>
**New block:**
```
 to make-deprived-household-development
 ask patches with [first-n-UDP = 1] [set first-n-UDP 0]
 let remaining-ticks (simulation-period - ticks)
 let remaining-deprived count households with [(income-status = 1) and (DPH-movement = 0)]
 let x 0
 ifelse remaining-ticks > 0 [
     set x min (list (ceiling (remaining-deprived / remaining-ticks)) remaining-deprived)
   ] [
     set x remaining-deprived
   ]

   let d patches with [(urban = 0) and (new-urban = 0) and (suitability = 1) and (landvalue <= 2)]
   if count d > 0 [
    ask max-n-of (min (list (round (x * dpu-maxof)) count d)) d [UDP] [set first-n-UDP 1]

    ;; free patches among the utility-ranked set — ONE scan
    let f patches with [(first-n-UDP = 1) and (DP-movement = 0) and (LI-movement = 0) and
     (HI-movement = 0) and (MI-movement = 0) and (pMED-movement = 0) and (pHED-movement = 0)]
    set available-first-n-UDP count f

    ;; candidate households — hoisted pool, consumed without replacement
    let pool households with [income-status = 1 and DPH-movement = 0]

    if x > 0 and count f >= 1 and count pool >= 1 [
      let agents-to-allocate min (list x count f count pool)

      ask n-of agents-to-allocate f [
        let hh one-of pool
        ask hh [
          move-to myself
          set DPH-movement 1
          set color 17
        ]
        set pcolor 17
        set DP-movement 1
        set new-urban 1
        set urban-type 1
        if informality = 1 [ set informal-status 1 ]
      ]
    ]
  ]
end
```
55.  Added round function in the make-households and make-developer procedures to avoid non-integer errors later.
56.  Corrected a new re-allocation bug in the new make-development blocks
57.  Corrected under-allocation from new RED developer procedures - residual at 0.21 %
58.  Adjusted make-hi-income to catch all remaining households (independent of percentage) during agent creation
59.  (v40) adjusting make-mi-RED-development procedure to remove residuals. 
     1. patch-driven one-to-one allocation;60. 
     2. pre-drawn estate sizes with household discounting; 
     3. estates built only where they fully fit (largest-first); 
     4. centre protection (disjoint estates); 
     5. per-tick flag resets (first-n-UMED and others first-n-); 
     6. RED priority over households; 
     7. mi-red-rad 2 → 3.
60. 
.....................................................................