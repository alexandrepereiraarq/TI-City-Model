;;.....................................................................
;; CHANGELOG FROM ORIGINAL CODE
;; Original developed by Dr Felix Agyemang felix.agyemang@manchester.ac.uk
;; original publication: DOI 10.1177/23998083211068843
;; Modified by Dr. Alexandre Pereira Santos alexandre.santos@lmu.de from 10.2024 to 04.2025
;; 1.  adjusted variable naming for consistency
;; 2.  separated inputs for more than one case study removing 'Accra' from them.
;; 3.  added comments to the code, notably marking those lines commented out in the original and highlighting changes implemented in this revision.
;; 4.  renamed prox-bu2015-dataset to bu2015-dist-dataset for consistency with the 2000 dataset
;; 5.  renamed the load-prox-bu2015 to load-bu2015-dist for clarity
;; 6.  adjusted the number of patches and households
;; 7.  created the load-attractive2000 function
;; 8.  created the load-income function
;; 9.  created the load-bu2000 function
;; 10. renamed the 'density 'global to 'density2015'
;; 11. created the density2000-dataset global
;; 12. created the income-dataset global
;; 13. created the income-patch patches-own
;; 14. renamed the 'landvaluse-dataset 'global to 'landvalue-dataset'
;; 15. renamed the 'splan-dataset 'global to 'structureplan-dataset'
;; 16. renamed the 'splan 'patches-own to 'structureplan'
;; 17. organised the globals, patches-own, and functions alphabetically. Names follow the variable name, when possible, adding year for disambiguation.
;; 18. created subcategories for  globals, patches-own, and functions
;; 19. created the set-weights function, which makes assigning the weights in the utility functions more transparent. It includes 39 additional global variables. I also re-ordered the utility functions weighting for consistency (now all income levels follow the same order).
;; 20. adjusted the interface
;; 21. created the calibration/prediction button and associated functions
;; 21a renamed the global attractive-2015 to attractive
;; 21b renamed the global bu2015 to bu
;; 23. added a water parameter to the inputs
;; 23a added water weight parameters to LI, MI, and HI agents
;; 23b added a load-water function, water-dateset global, and water patch-own
;; 24. added urban-type patch-own (0 = non-urban, 1 = low income, 2 = medium income, 3 = high income, 4 =  deprived, 5 = seed year built-up)
;; 25. updated the income export function using gis extension
;; 26. added informal-status patch-own (0 = non-urban, 1 = informal, 2 = formal, 4 = seed year built-up)
;; 27. created a new agent class: deprived income. created its associates
;;     variables (dpu-suburb dpu-neigbhour dpu-bu dpu-cbd dpu-mall dpu-markets dpu-road dpu-density dpu-schools dpu-attractive dpu-health dpu-random dpu-water dpu-maxof)
;;     and functions (load-UDP, make-deprived-household-development)
;; 28. created a scenario selector (scenario) to implement the shared socioeconomic pathways (SSPs, see https://en.wikipedia.org/wiki/Shared_Socioeconomic_Pathways)
;; 28a created separate parameterisation for the exclusion layer, with the necessary raster dataset loading functions
;; 28b created new parameterisation for each scenario (see set-scenarios function)
;; 29. add developer agents weights to the the set-weights function
;;     mi-red-suburb mi-red-neigbhour mi-red-bu mi-red-cbd mi-red-mall mi-red-markets mi-red-road mi-red-density mi-red-schools mi-red-attractive mi-red-health mi-red-random mi-red-water
;;     hi-red-suburb hi-red-neigbhour hi-red-bu hi-red-cbd hi-red-mall hi-red-markets hi-red-road hi-red-density hi-red-schools hi-red-attractive hi-red-health hi-red-random hi-red-water
;; 30. expand the dpu-rad, li-rad, mi-rad, hi-rad, mi-red-rad, and hi-red-rad as variables. They are set in set-weights and define the search radius for the neighbourhood functions
;; 31. defined dpu-maxof, liu-maxof, miu-maxof, and hiu-maxof as variables. It is declared in set-weights and defines the number of cells on the top of the utility distribution that an agent might randomly select to settle
;; 32. defined hi-red-maxof, mi-red-maxof. maxof as variables. It is declared in set-weights and defines the number of cells on the top of the utility distribution that a real-estate developer agent might randomly select to develop.
;; 33. created the RED-on? and neighbour-on? switches, for calibration/sensitivity testing.
;; 34. adjusted the set-weights function to use the CSV extension to fetch the weights from an external file in "./data/in/weights.csv"
;;.....................................................................

extensions [ gis csv ]

globals [road-dataset
  ;; DATASETS ;; APS: created subtitle for organisation, organised alphabetically
  airport-dataset
  airport-vector
  attractive2000-dataset ;; APS: this dataset is only loaded for the calibration model
  attractive2015-dataset
  bu2000-dist-dataset ;; APS: this dataset is only loaded for the calibration model
  bu2015-dist-dataset
  cbd-dataset
  districts-dataset
  density2000-dataset
  density2015-dataset
  healthfacilities-dataset
  income-dataset
  markets-dataset
  landvalue-dataset
  urban2015-dataset
  urban2000-dataset
  road-presence-dataset
  roads-dataset
  schools-dataset
  shoppingmalls-dataset
  slope-dataset
  suburban-dataset
  structureplan-dataset
  tenure-dataset
  water-dataset ;; APS: created to support attracting development to the coastline
  ssp-dataset ;; APS: created to support scenario implementation

  ;; PROPERTIES ;; APS: created subtitle for organisation
  slope_max
  develop_prob
  exclusion-dataset
  ;;the-row
  rows
  select-mode
  total-avail-patches
  available-first-n-UDP
  available-first-n-ULI
  available-first-n-UMI
  available-first-n-UHI

  ;; APS: agent utility weights
  ;; deprived agents
  dpu-suburb dpu-neigbhour dpu-bu dpu-cbd dpu-mall dpu-markets dpu-road dpu-density dpu-schools dpu-attractive dpu-health dpu-random dpu-water
  dpu-maxof dp-rad
  ;; low income agents
  liu-suburb liu-neigbhour liu-bu liu-cbd liu-mall liu-markets liu-road liu-density liu-schools liu-attractive liu-health liu-random liu-water
  liu-maxof li-rad
  ;; middle income agents
  miu-suburb miu-neigbhour miu-bu miu-cbd miu-mall miu-markets miu-road miu-density miu-schools miu-attractive miu-health miu-random miu-water
  miu-maxof mi-rad
  ;; high income agents
  hiu-suburb hiu-neigbhour hiu-bu hiu-cbd hiu-mall hiu-markets hiu-road hiu-density hiu-schools hiu-attractive hiu-health hiu-random hiu-water
  hiu-maxof hi-rad
  ;; middle-end real estate developer agents
  mi-red-suburb mi-red-neigbhour mi-red-bu mi-red-cbd mi-red-mall mi-red-markets mi-red-road mi-red-density mi-red-schools mi-red-attractive mi-red-health mi-red-random mi-red-water mi-red-nom-slope
  mi-red-maxof mi-red-rad
  ;; high-end real estate developer agents
  hi-red-maxof hi-red-rad
  hi-red-suburb hi-red-neigbhour hi-red-bu hi-red-cbd hi-red-mall hi-red-markets hi-red-road hi-red-density hi-red-schools hi-red-attractive hi-red-health hi-red-random hi-red-water hi-red-nom-slope
  dp-w-list li-w-list mi-w-list hi-w-list

]

;;.....................................................................
;;.....................................................................


;; DEFINE PARCEL ATTRIBUTES
patches-own [
  ;; PROPERTIES READ FROM INPUTS APS included subtitle for better organisation
  airport
  airport-dist
  nom-airport-dist
  attractive
  bu;; proximity to built-up. The reference year is defined by the "calibrate?" switch
  cbd
  districts
  density
  density-flip
  exclusion
  income-patch ;; APS: created patches-own
  healthfacilities
  landvalue
  markets
  neighbourhood
  water
  ;;neighbourhood2000

  nom-neighbourhood
  road ;; FA: proximity to road
  road-presence ;; FA: whether or not there is road
  suburb
  suburb-area ;; FA: to define patches within a specified radius of suburbs
  shoppingmall
  schools
  slope
  slope-pct
  nom-slope
  structureplan
  tenure
  urban
  ;;urban2000

  ;; CALCULATED PROPERTIES
  ;;attract2000-area
  attract-area
  informality
  informal_avail ;; informal lands that are available for development
  suitability
  households-left-to-settle

  ;; MOVEMENT VALUES
  LI-movement ;; FA: whether or not low income household has moved to a parcel
  HI-movement ;; FA: whether or not high income household has moveed to a parcel
  MI-movement ;; FA: whether or not mid income household has moved to a parcel
  DP-movement ;; APS: whether or not deprived household has moved to a parcel
  pHED-movement ;; FA: whether or not high end estate developer has moved to a parcel
  pMED-movement ;; FA: whether or not mid end estate developer has moved to a parcel

  new-urban ;; FA: all new developments
  urban-type ;; APS: reports the urban (income) status of the patch, similar to the colors.
  informal-status ;; APS: reports the informal status of the patch, similar to the colors.

  ;; UTILITY FUNCTION VALUES
  UDP ;; APS: utility for deprived households
  ULI ;; utility for low income households
  UHI ;; utility for high income households
  UMI ;; Utility for mid income households
  UHED ;; Utility for High end estate developers
  UMED ;; Utility for mid end estate developers
  first-n-UDP ;; whether the patch has one of the highest deprived utility
  first-n-ULI ;; whether the patch has one of the highest low income utility
  first-n-UHI ;; whether the patch has one of the highest high income utility
  first-n-UMI ;; whether the patch has one of the highest middle income utility
  first-n-UHED ;; whether the patch has one of the highest utilities for high end estate developers
  first-n-UMED ;; whether the patch has one of the highest utilities for mid end estate developers
]
;;................................................................................................
;;................................................................................................


;; CREATE HOUSEHOLDS AND DEVELOPERS
breed [ households household ]
households-own [
  income-status
  income
  DPH-movement
  LIH-movement
  HIH-movement
  MIH-movement
]
;;.................................................

breed [ developers developer ]
developers-own [
  class
HED-movement
MED-movement]
;;.................................................

;; APS: new function to help set the weights
to set-weights
  set [dp-w-list li-w-list mi-w-list hi-w-list] [[][][][]]
  ;; code based on https://github.com/NetLogo/models/blob/master/Code%20Examples/Extensions%20Examples/csv/CSV%20Example.nlogo
  file-close-all ;; Close any open files
  file-open "./data/in/weights.csv"
  let data csv:from-file  "./data/in/weights.csv"
  let dp-weight item 1 data ;; I skip the first row as it contains only the headers
  let li-weight item 2 data
  let mi-weight item 3 data
  let hi-weight item 4 data

  ;; deprived agents
  let i 0
  repeat length dp-weight [
    let w item i dp-weight
    if i > 0 [set dp-w-list lput w dp-w-list] ;; I skip the first column, as it contains the line header (e.g., 'dp')
    set i i + 1
  ]
  set [ dpu-suburb dpu-neigbhour dpu-bu dpu-cbd dpu-mall dpu-markets dpu-road dpu-density dpu-schools dpu-attractive dpu-health dpu-random dpu-water ] dp-w-list
  set dpu-maxof 2
  set dp-rad 2

  ;; low income agents
  set i 0
  repeat length li-weight [
    let w item i li-weight
    if i > 0 [set li-w-list lput w li-w-list]
    set i i + 1
  ]
  set [ liu-suburb liu-neigbhour liu-bu liu-cbd liu-mall liu-markets liu-road liu-density liu-schools liu-attractive liu-health liu-random liu-water ] li-w-list
  set liu-maxof 1.5
  set li-rad 1

  ;; middle income agents
  set i 0
  repeat length mi-weight [
    let w item i mi-weight
    if i > 0 [set mi-w-list lput w mi-w-list]
    set i i + 1
  ]
  set [ miu-suburb miu-neigbhour miu-bu miu-cbd miu-mall miu-markets miu-road miu-density miu-schools miu-attractive miu-health miu-random miu-water ] mi-w-list
  set miu-maxof 1.5
  set mi-rad 3

  ;; high income agents
  set i 0
  repeat length hi-weight [
    let w item i hi-weight
    if i > 0 [set hi-w-list lput w hi-w-list]
    set i i + 1
  ]
  set [ hiu-suburb hiu-neigbhour hiu-bu hiu-cbd hiu-mall hiu-markets hiu-road hiu-density hiu-schools hiu-attractive hiu-health hiu-random hiu-water ] hi-w-list
  set hiu-maxof 4
  set hi-rad 3

  ;; mid RED
  set [mi-red-suburb mi-red-neigbhour mi-red-bu mi-red-cbd mi-red-mall mi-red-markets mi-red-road mi-red-density mi-red-schools mi-red-attractive mi-red-health mi-red-random mi-red-water mi-red-nom-slope]
  [7 0 0 0 0 0 8 0 5 7 0 0 0 7]
  set mi-red-maxof 2
  set mi-red-rad 2

  ;; high RED
  set [hi-red-suburb hi-red-neigbhour hi-red-bu hi-red-cbd hi-red-mall hi-red-markets hi-red-road hi-red-density hi-red-schools hi-red-attractive hi-red-health hi-red-random hi-red-water hi-red-nom-slope]
  [6 0 0 0 0 0 8 0 5 10 0 0 0 0]
  set hi-red-maxof 2
  set hi-red-rad 2

  file-close

  ;;set [ dpu-suburb dpu-neigbhour dpu-bu dpu-cbd dpu-mall dpu-markets dpu-road dpu-density dpu-schools dpu-attractive dpu-health dpu-random dpu-water ]
  ;; [ 3 9 9 4 2 7 3 9 4 2 2 1 10 ] ;; APS: 17.12.2024
  ;;[3 10 10 2 1 7 20 9 4 2 2 1 10] ;; APS 07.03.2025
  ;;[1 9 9 1 1 9 30 9 1 1 1 1 9] ;; APS 12.03.2025

  ;; low income agents
  ;;set [ liu-suburb liu-neigbhour liu-bu liu-cbd liu-mall liu-markets liu-road liu-density liu-schools liu-attractive liu-health liu-random liu-water ]
  ;;[ 8 7 9 7 2 7 8 9 4 2 4 1 7 ] ;; APS: 17.12.2024
  ;;[8 7 9 7 1 7 90 9 4 2 4 1 3]
  ;;[9 3 9 9 1 9 80 9 1 1 3 1 0]


  ;; middle income agents
  ;;set [ miu-suburb miu-neigbhour miu-bu miu-cbd miu-mall miu-markets miu-road miu-density miu-schools miu-attractive miu-health miu-random miu-water ]
  ;;[ 6 7 7 4 7 7 6 6 4 7 4 1 5 ]
  ;;[6 7 7 4 7 7 50 6 4 7 4 1 3]
  ;;[3 3 3 3 9 9 60 3 1 9 3 1 0]


  ;; high income agents
  ;;set [ hiu-suburb hiu-neigbhour hiu-bu hiu-cbd hiu-mall hiu-markets hiu-road hiu-density hiu-schools hiu-attractive hiu-health hiu-random hiu-water ]
  ;;[ 5 7 2 7 9 6 5 1 4 10 3 1 8 ]
  ;;[5 7 1 7 10 4 20 1 4 10 3 1 8]
  ;;[3 3 1 9 9 3 50 1 1 9 3 1 0]

end

to set-scenarios
;; Standard scenario
  (ifelse
    scenario = "standard"
    [ set
      [ household-number percent-deprived-households percent-low-income-households percent-mid-income-households percent-high-income-households slope_coefficient critical_slope development_control]
      [  33334 10 43 20 27 80 17 50 ]
      load-exclusion
    ] ;; standard true
    [ ifelse scenario = "SSP1" ;; standard else
      [ set
        [ household-number percent-deprived-households percent-low-income-households percent-mid-income-households percent-high-income-households slope_coefficient critical_slope development_control]
        [ 34768 7 23 33 37 80 17 80 ]
        load-ssp1
      ] ;; SSP1 true (standard false)
      [ ifelse scenario = "SSP2" ;; SSP1 else
        [ set
          [ household-number percent-deprived-households percent-low-income-households percent-mid-income-households percent-high-income-households slope_coefficient critical_slope development_control]
          [ 33334 13 48 20 19 80 25 50 ]
          load-ssp2
        ]  ;; SSP2 true
        [ if scenario = "SSP3" ;; SSP2 else
          [ set
            [ household-number percent-deprived-households percent-low-income-households percent-mid-income-households percent-high-income-households slope_coefficient critical_slope development_control]
            [ 32073 20 60 10 10 80 35 30 ]
            load-ssp3
          ] ;; SSP3 true
        ] ;; closing SSP3
      ] ;; closing SSP2
    ] ;; closing SSP1
  )
end



to make-households

  ;;.. creation of households
  let i household-number
  create-households i [

  ;;..specification of representation shape
    set shape "person"
    set color white
    set size 1
    set income-status 0

  ]
  ask turtles [setxy 70 387] ;APS look into this

  ;;.. create socio-economic characteristics of households
  ;;.. create households with low income-status
  let a percent-low-income-households
  let LI-number (a / 100) * i
  ask n-of LI-number households [set income-status 1]

  ;;.. create middle-income households
  let b percent-mid-income-households
  let MI-number (b  / 100) * i
  ask n-of MI-number households with [income-status = 0] ;;[income-status != 1]
  [set income-status 2]

  ;;.. create high-income households
  let c percent-high-income-households
  let HI-number (c / 100) * i
  ask n-of HI-number households with [income-status = 0] ;;[(income-status) !=1 and income-status != 2]
  [set income-status 3]

  ;;.. APS: create households with deprived-status
  let d percent-deprived-households
  let DP-number (d / 100) * i
  ask n-of DP-number households with [income-status = 0]
  [ set income-status 4]

end
;;.......................................................................


to make-developers
  let i estate-developer-number
  create-developers i [
    set shape "person"
    setxy 76 391
    set color blue
    set size 1]

    ;; create mid-end-developers
      let j percent-mid-end-developers
  let w (j / 100) * i
  ask n-of w developers [
    set class 2]

  ;;.. create high-end-developers
  let a percent-high-end-developers
  let b (a  / 100) * i
  ask n-of b developers with [class = 0]
    [set class 3]

end

to do-calculations
  ;; ...............................................................................
  ;; calculations
  make-households
  make-developers
  set-scenarios
  load-suitability
  load-informality
  load-informal-avail
  activate-development-control
  load-nom-neighbourhood
  load-UDP
  load-ULI
  load-UHI
  load-UMI
  load-UMED
  load-UHED
  set-weights;; APS: added weight-setting function
  ;;load-developers-utility APS: comented on the original
  ;;load-income APS: comented on the original
  ;;load-suburb-area APS: comented on the original
end
;;..........................................................
;;..........................................................

;; INITIALIZE THE MODEL
to set-up
  ca
  ;; ...............................................................................
  ;; loading GIS layers
  ;; APS: created a switch that chooses between calibration and prediction
  ;;gis:load-coordinate-system ("data\\in\\.prj")
  (ifelse calibrate?
    ;; calibration function calls
    [load-urban2000
      load-density2000
      load-bu2000-dist
      load-attractive2000  ]
    ;; prediction function calls
    [ load-urban2015
      load-density2015
      load-bu2015-dist
      load-attractive2015])
  load-roads
  load-healthfacilities
  load-suburban
  load-shoppingmalls
  load-markets
  load-airport
  load-cbd
  load-districts
  load-neighbourhood
  load-landvalue ;; APS: renamed for consistency with the variable name
  load-structureplan;; APS: renamed for consistency with the variable name
  ;;load-income APS: comented on the original
  load-schools
  ;; load-tenure ;; APS 16.10.2025: does this have any influence?
  load-slope
  load-water ;; APS: implemented this
  make-households
  make-developers
  set-scenarios
  load-suitability
  load-informality
  load-informal-avail
  activate-development-control
  set-weights;; APS: added weight-setting function
  load-nom-neighbourhood
  load-UDP
  load-ULI
  load-UHI
  load-UMI
  load-UMED
  load-UHED

  ;;load-developers-utility APS: comented on the original
  ;;load-income APS: comented on the original
  ;;load-suburb-area APS: comented on the original
  ;;do-calculations
  reset-ticks
end
;;...................................................
;;...................................................


;;  RUN THE MODEL
to go
  ifelse ticks = simulation-period
  [stop]
  [
    count-patches
    make-high-income-household-development
    make-mid-income-household-development
    make-low-income-household-development
    make-deprived-household-development
    if RED-on? [
      make-high-end-RED
      make-mid-end-RED]
    if neighbour-on? [
      update-neighbourhood]
  ]
  tick
end


;;.................................................................................

;; LOAD DATASETS
; APS: re-ordered the functions alphabetically

;;load distance to airport
to load-airport
  set airport-dataset gis:load-dataset "data/in/airport.asc" ;; APS: renamed to include folder
  gis:apply-raster airport-dataset airport
  ;;gis:paint airport-dataset 0
end

;; APS: created this function, used in the calibration run.
;;load distance to attractive neighbourhood for the earlier year of the simulation
to load-attractive2000
  set attractive2000-dataset gis:load-dataset "data/in/attractive2000.asc" ;; APS: renamed to include folder
  gis:apply-raster attractive2000-dataset attractive
end

;;load distance to attractive neighbourhood for the later year of the simulation
to load-attractive2015
  set attractive2015-dataset gis:load-dataset "data/in/attractive2015.asc" ;; APS: renamed to include folder
  gis:apply-raster attractive2015-dataset attractive
end

;; APS: created this function, used in the calibration run.
;; load distance to built-up areas for the earlier year of the simulation
to load-bu2000-dist
  set bu2000-dist-dataset gis:load-dataset "data/in/bu2000_dist.asc" ;; APS: renamed to include folder
  gis:apply-raster bu2000-dist-dataset bu
  ;;ask patches [set bu (1 - bu)]
end

;; load distance to built-up areas for the later year of the simulation
to load-bu2015-dist
  set bu2015-dist-dataset gis:load-dataset "data/in/bu2015_dist.asc" ;; APS: renamed to include folder
  gis:apply-raster bu2015-dist-dataset bu
  ;;ask patches [set bu (1 - bu)]
end

;;load distance to CBD
to load-cbd
  set cbd-dataset gis:load-dataset "data/in/cbd.asc" ;; APS: renamed to include folder
  gis:apply-raster cbd-dataset cbd
end

;; load population densityfor the latter year in the simulation
to load-density2000; APS: renamed for consistency
  set density2000-dataset gis:load-dataset "data/in/density2000.asc" ;; APS: renamed to include folder, density from 2015
  gis:apply-raster density2000-dataset density
  ;; ask patches [set density-flip (1 - density)] ;; set patch values for density-flip
end

;; load population densityfor the latter year in the simulation
to load-density2015; APS: renamed for consistency
  set density2015-dataset gis:load-dataset "data/in/density2015.asc" ;; APS: renamed to include folder, density from 2015
  gis:apply-raster density2015-dataset density
  ;;gis:paint density2015-dataset 0
  ;; ask patches [set density-flip (1 - density)] ;; set patch values for density-flip
end

;; load administrative districts
to load-districts
  set districts-dataset gis:load-dataset "data/in/districts.asc" ;; APS: renamed to include folder
  gis:apply-raster districts-dataset districts
  ;;gis:paint districts-dataset 0
end

;;load exclusion layer
to load-exclusion
  set exclusion-dataset gis:load-dataset "data/in/exclusion.asc" ;; APS: renamed to include folder
  gis:apply-raster exclusion-dataset exclusion
  ask patches [if exclusion = 1 [ set pcolor 9 ]]
  ;;gis:paint exclusion-dataset 0
end

;;load distance to health facilities
to load-healthfacilities
  set healthfacilities-dataset gis:load-dataset "data/in/healthfacilities.asc" ;; APS: renamed to include folder
  gis:apply-raster healthfacilities-dataset healthfacilities
  ;;gis:paint healthfacilities-dataset 0
end

;; APS: created this function as as stub. Test generating the income with their location at a later stage
to load-income
  set income-dataset gis:load-dataset "data/in/income.asc" ;; APS: renamed to include folder
  gis:apply-raster income-dataset income-patch
end

;; load land values
to load-landvalue
  ;;set landvalus-dataset gis:load-dataset "data/in/landvalue_idw.asc"
  set landvalue-dataset gis:load-dataset "data/in/landvalue.asc" ;; APS: renamed to include folder
  gis:apply-raster landvalue-dataset landvalue
  ;;gis:paint landvalues-dataset 0
end

;;load distance to markets
to load-markets
  set markets-dataset gis:load-dataset "data/in/markets.asc" ;; APS: renamed to include folder
  gis:apply-raster markets-dataset markets
  ;;gis:paint markets-dataset 0
end

;; load road lines (in raster format) ;; APS: disentangled from load-roads for clarity
to load-road-presence
  set road-presence-dataset gis:load-dataset "data/in/road-presence.asc" ;; APS: renamed to include folder
  gis:apply-raster road-presence-dataset road-presence
end

;;load distance to roads
to load-roads
  set roads-dataset gis:load-dataset "data/in/roads.asc" ;; APS: renamed to include folder
  gis:apply-raster roads-dataset road
  load-road-presence
  ;;gis:paint roads-dataset 0
end

;;load distance to schools
to load-schools
  set schools-dataset gis:load-dataset "data/in/schools.asc" ;; APS: renamed to include folder
  gis:apply-raster schools-dataset schools
  ;;gis:paint schools-dataset 0
end


;;load distance to shopping malls
to load-shoppingmalls
  set shoppingmalls-dataset gis:load-dataset "data/in/shoppingmalls.asc" ;; APS: renamed to include folder
  gis:apply-raster shoppingmalls-dataset shoppingmall
  ;;gis:paint shoppingmalls-dataset 0
end

;;load slope
to load-slope
  set slope-dataset gis:load-dataset "data/in/slope.asc" ;; APS: renamed to include folder, slope in percent
  gis:apply-raster slope-dataset slope ;;slope-pct
  ;;ask patches [set slope (slope-pct * 100) ]
  ;;gis:paint slope-dataset 0
end


;;load local plan
to load-structureplan
  set structureplan-dataset gis:load-dataset "data/in/structureplan.asc" ;; APS: renamed to include folder
  gis:apply-raster structureplan-dataset structureplan
  ;;gis:paint structureplan-dataset 0
end

;;load distance to suburban centers
to load-suburban ;; APS: renamed for consistency with variable name
  set suburban-dataset gis:load-dataset "data/in/suburban.asc" ;; APS: renamed to include folder
  gis:apply-raster suburban-dataset suburb
  ;;gis:paint suburban-dataset 0
end

;; land title registration status
to load-tenure
  set tenure-dataset gis:load-dataset "data/in/tenure.asc" ;; APS: renamed to include folder
  gis:apply-raster tenure-dataset tenure
  ;;gis:paint title-dataset 0
end


;;load built-up status of parcels for the earlier year of the simulation
;; APS: created  a new function to load the 2000 dataset as well
to load-urban2000
  set urban2000-dataset gis:load-dataset "data/in/urban2000.asc" ;; APS: renamed to include folder, urban features  from 2000
  gis:apply-raster urban2000-dataset urban
   gis:set-world-envelope gis:envelope-of urban2000-dataset
  ask patches [
    ifelse urban = 1
    [ set pcolor 49
      set urban-type 5]
    [set pcolor 75
      set urban-type 0]]
end

;;load built-up status of parcels
to load-urban2015
  set urban2015-dataset gis:load-dataset "data/in/urban2015.asc" ;; APS: renamed to include folder, urban features  from 2015
  gis:apply-raster urban2015-dataset urban
   gis:set-world-envelope gis:envelope-of urban2015-dataset
    ask patches [
    ifelse urban = 1
    [ set pcolor 49
      set urban-type 5]
    [set pcolor 75
      set urban-type 0]]
end

to load-water ;; APS: created the load-water function
  set water-dataset gis:load-dataset "data/in/water.asc"
  gis:apply-raster water-dataset water
end

;;Count and set the number of neighbouring parcels that are built-up
to load-neighbourhood
  ask patches [set neighbourhood
    count neighbors with [urban = 1]]
end

;; APS: created scenario with different exclusion layers
to load-ssp1
  set ssp-dataset gis:load-dataset "data/in/exclusion_ssp1.asc" ;; APS: renamed to include folder
  gis:apply-raster ssp-dataset exclusion
  ask patches [if exclusion = 1 [ set pcolor 9 ]]
end

to load-ssp2
  set ssp-dataset gis:load-dataset "data/in/exclusion_ssp2.asc" ;; APS: renamed to include folder
  gis:apply-raster ssp-dataset exclusion
  ask patches [if exclusion = 1 [ set pcolor 9 ]]
end

to load-ssp3
  set ssp-dataset gis:load-dataset "data/in/exclusion_ssp3.asc" ;; APS: renamed to include folder
  gis:apply-raster ssp-dataset exclusion
  ask patches [if exclusion = 1 [ set pcolor 9 ]]
end


;;.......................................................................
;;.......................................................................


;; COMPUTE THE SUITABILITY OF PARCELS
to load-suitability
  set slope_max max [slope] of patches
  set develop_prob [] ;; APS: initializes a list called develop_prob
  let a 0
  while [a <= critical_slope][ ;; APS:  The code loops through values of a from 0 to critical_slope
    let b (critical_slope - a) / critical_slope
    ;; APS: Calculates a normalized value b that ranges from 1 (when a = 0) to 0 (when a = critical_slope).
    ;; This creates a probability scaling factor for slopes below the critical_slope.
    set develop_prob lput (b ^ (slope_coefficient / 200)) develop_prob
    ;; APS: Appends (lput) a development probability for each slope based on the value of b and the slope_coefficient.
    ;; The term (b ^ (slope_coefficient / 200)) reduces the development probability as slope increases.
    set a a + 1]

  ;; Add zeros for slopes > critical_slope
  let extra_zeros slope_max - critical_slope
  repeat extra_zeros [
    set develop_prob lput 0 develop_prob
  ]

  ask patches [
    let y random-float 1 ;; APS: Generates a random number y between 0 and 1 for each patch.
    ifelse y < item slope develop_prob
    ;; APS: Compares the random number y to the development probability for the patch's slope (obtained from the develop_prob list).
    ;; If y is less than the probability:
    [set suitability 1] ;; APS: The patch is deemed suitable for development (suitability = 1).
    [set suitability 0] ;; APS: Otherwise, the patch is unsuitable for development
    if exclusion = 1 [set suitability 0]
    if urban = 1 [set suitability 0]
  ]

  ;; APS: 12.12.2024 testing new suitability function with road influence
  ;; Assign suitability to patches with road influence
  ;; APS: 13.12.2024 rolling back the suitability function to the original method. We will restrict the patches available via the exclusion layer (i.e., urban areas generated in SLEUTH).
  ;;ask patches [
    ;; Compute the complement of the road variable
    ;;let road_complement (1 - road)

    ;; Power-law transformation of the road complement
    ;;let power_exponent 2
    ;;let road_modifier road_complement ^ power_exponent

    ;; Normalize road_modifier to range [0, 1] (optional for consistency)
    ;;let normalized_road_modifier road_modifier / (1 + road_modifier)

    ;; Weighted combination of slope and road influence
    ;;let weighted_probability ((item slope develop_prob) + 2 * normalized_road_modifier) / 3

    ;; Calculate combined suitability probability
    ;;let random_value random-float 1
    ;;ifelse random_value < weighted_probability [
      ;;set suitability 1 ;; Suitable for development
    ;;] [
      ;;set suitability 0 ;; Not suitable for development
    ;;]

    ;; Exclude specific patches
    ;;if exclusion = 1 [ set suitability 0 ]
    ;;if urban = 1 [ set suitability 0 ]
  ;;]
end
;;.....................................................................

;; Display suitability
to display_suitability
  ask patches [ifelse suitability = 1
    [set pcolor white][set pcolor black]
  ]
end
;;.....................................................................

;; normalize slope
to load-nom-slope
  ask patches [
    let i max [slope] of patches
    let j min [slope] of patches
    set nom-slope ((slope - j) / (i - j))
  ]
end

;; normalize neighbourhood
to load-nom-neighbourhood
 ask patches [set nom-neighbourhood ((neighbourhood)/(8))]
end
;;......................................................................................
;;......................................................................................


;; COMPUTE LEGAL STATUS OF PARCELS
;;Load areas liable to informal development
to load-informality
  ask patches with [(suitability = 1) and (structureplan = 1)] ;; APS: structureplan is now a binary variable, where 0 = settlement allowed, and 1 = settlement not allowed
    [set informality 1]
end


;;Display areas liable to informal development
to display-areas-liable-to-informality
  let i count patches with [(informality = 1) and (suitability = 1) and (urban = 0)]
  let j (development_control / 100) * i
  ask n-of j patches with [(informality = 1) and (suitability = 1) and (urban = 0)] [set pcolor red]
end


;;load informal lands that are available for development
to load-informal-avail
  let i count patches with [(informality = 1) and (suitability = 1) and (urban = 0)]
  let j (development_control / 100) * i

  ask n-of j patches with [(informality = 1) and (suitability = 1) and (urban = 0)]
    [set informal_avail 1]
   ;; exclude the specified proportion of informal lands from development
end
;;..............................................................................
;;..............................................................................


;;ACTIVATE DEVELOPMENT CONTROL
;; APS: I am unsure of the usefulness of this function, since it is the opposite of the load-informal-avail function
to activate-development-control
  let i count patches with[(informality = 1) and (suitability = 1) and (urban = 0)]
  let j (development_control / 100) * i
  ask n-of j patches with [(informality = 1) and (suitability = 1) and (urban = 0)]
  [set suitability 0]
end
;;.......................................................................................
;;.......................................................................................


;; COMPUTE PARCEL UTILITY BY INCOME STATUS

;; APS: load deprived households utility for each parcel
;; APS: 11.03.2025 refactored the utility functions to take in positive values (instead of distances to them)
to load-UDP
  ask patches [
    set UDP ((suburb * dpu-suburb)  + (bu * dpu-bu) + ;+ (nom-neighbourhood * dpu-neigbhour)
      (cbd * dpu-cbd) + (shoppingmall * dpu-mall) + (markets * dpu-markets) +
      (road * dpu-road) + (density * dpu-density) + (schools * dpu-schools) +
      (attractive * dpu-attractive) + (healthfacilities * dpu-health ) + ((random-float 0.1) * dpu-random) +
      (water * dpu-water ) ) ;; APS: added a water parameter to the utility functions
  ]
end

;; load low income households utility for each parcel
to load-ULI
  ask patches [
    set ULI ((suburb * liu-suburb) + (bu * liu-bu) + ;+ (nom-neighbourhood * liu-neigbhour)
      (cbd * liu-cbd) + (shoppingmall * liu-mall) + (markets * liu-markets) +
      (road * liu-road) + (density * liu-density) + (schools * liu-schools) +
      (attractive * liu-attractive) + (healthfacilities * liu-health ) + ((random-float 0.1) * liu-random) +
      (water * liu-water ) ) ;; APS: added a water parameter to the utility functions
  ]
end

;;............................................................................................................


;;load mid income household utility for each patch / parcel
to load-UMI
  ask patches [
    set UMI ((suburb * miu-suburb) +  (bu * miu-bu) + ;+ (nom-neighbourhood * miu-neigbhour)
      (cbd * miu-cbd) + (shoppingmall * miu-mall) + (markets * miu-markets) +
      (road * miu-road) + (density * miu-density) + (schools * miu-schools) +
      (attractive * miu-attractive) + (healthfacilities * miu-health) + ((random-float 0.1) * miu-random) +
      (water * miu-water)) ;; APS: added a water parameter to the utility functions

    ;; APS: 13.12.2024 implementing a normalisation function to the utility. This is not seem necessary, as only the top patches are picked for each agent type.
    ;;let max_UMI max [UMI] of patches
    ;;let min_UMI min [UMI] of patches
    ;;let normalised_UMI ( UMI - min_UMI ) / ( max_UMI - min_UMI )
    ;;set UMI normalised_UMI
  ]
end

;;load high income household utility for each parcel
to load-UHI
  ask patches [
    ;; APS: added a water parameter to the utility functions
    set UHI ((suburb * hiu-suburb) + (bu * hiu-bu) + (cbd * hiu-cbd) + (shoppingmall * hiu-mall) + (markets * hiu-markets) + (road * hiu-road) + (density * hiu-density) + (schools * hiu-schools) + (attractive * hiu-attractive) + (healthfacilities * hiu-health) + ((random-float 0.1) * hiu-random) + (water * hiu-water))
    ;; set UHI ((suburb * hiu-suburb) + (nom-neighbourhood * hiu-neigbhour) + (bu * hiu-bu) + (cbd * hiu-cbd) + (shoppingmall * hiu-mall) + (markets * hiu-markets) + (road * hiu-road) + (density * hiu-density) + (schools * hiu-schools) + (attractive * hiu-attractive) + (healthfacilities * hiu-health) + ((random-float 0.1) * hiu-random) + (water * hiu-water))
    ;; include a neighbourhood to calculate UHI

  ]
end
;;.........................................................................

;; compute utility for middle end real estate developers
;; APS: 11.03.2025 refactored the utility functions to take in positive values (instead of distances to them)
to load-UMED
  ask patches [
    ;set UMED ((road * 8) + (suburb * 7) + (attractive * 7) + ((1 - nom-slope) * 7) + (schools * 5))
    ;; APS: extending the real estate developer agents utility functions to all utility layers
    set UMED ((suburb * mi-red-suburb) + (nom-neighbourhood * mi-red-neigbhour) + (bu * mi-red-bu) +
      (cbd * mi-red-cbd) + (shoppingmall * mi-red-mall) + (markets * mi-red-markets) +
      (road * mi-red-road) + (density * mi-red-density) + (schools * mi-red-schools) +
      (attractive * mi-red-attractive) + (healthfacilities * mi-red-health) + ((random-float 0.1) * mi-red-random) +
      (water * mi-red-water) + ((1 - nom-slope) * mi-red-nom-slope))
  ]
end

;; compute utility for high end real estate developers
to load-UHED
  ask patches [
    ;; set UHED ((road * 8) + (suburb * 6) + (attractive * 10) + (schools * 5))
    set UHED ((suburb * hi-red-suburb) + (nom-neighbourhood * hi-red-neigbhour) + (bu * hi-red-bu) +
      (cbd * hi-red-cbd) + (shoppingmall * hi-red-mall) + (markets * hi-red-markets) +
      (road * hi-red-road) + (density * hi-red-density) + (schools * hi-red-schools) +
      (attractive * hi-red-attractive) + (healthfacilities * hi-red-health) + ((random-float 0.1) * hi-red-random) +
      (water * hi-red-water) + ((1 - nom-slope) * hi-red-nom-slope))
  ]
end
;;........................................................................................................................................

;;.....................................................................

to display-UDP
  ask patches [
    let max_UDP max [UDP] of patches
    let top_UDP (0.7 * max_UDP)
    ;; let min_UDP min [UDP] of patches
    ifelse UDP > top_UDP
       [set pcolor 49]
       [set pcolor 39]
       ;;[set pcolor 29]
     ]
end
;;.....................................................................
;;........................................................................................................................................

to count-patches
  set total-avail-patches patches with [( urban = 0 ) and ( new-urban = 0 ) and ( suitability = 1 )]

end

;; PARCEL SELECTION/DEVELOPMENT BY HOUSEHOLDS
;; Development by deprived households
to make-deprived-household-development
  let i household-number
  let n percent-deprived-households
  ;; APS: this function calls for a fixed ammount of HH every tick, which causes a crash when numbers become low...
  ;; this should not be happening...
  let x ((i / simulation-period) * ( n / 100)) ;; the number of deprived households who enter the market annually in the simulation period

  let d patches with [( urban = 0 ) and ( new-urban = 0 ) and ( suitability = 1 ) and ( landvalue <= 2 ) ] ;;and (UDP > 0) APS: why is UDP 0 for the patches??
  if (count d) > 0 [
    ;; APS: 13/03/2025 limiting the number of available patches to settle
    ;;  set dpu-maxof 0.3
    ask max-n-of ((x * dpu-maxof)) d [UDP] [set first-n-UDP 1] ;; this is setting the number of high-utility cells as the same as x times the max-off factor

    let f patches with [((first-n-UDP = 1) and (DP-movement = 0) and (LI-movement = 0) and (HI-movement = 0) and
      (MI-movement = 0) and (pMED-movement = 0) and (pHED-movement = 0))]

    set available-first-n-UDP count f
    if available-first-n-UDP  >= 1 [ ;; APS: adding this test to avoid breaking the model run when an agent class has no cells available
      ask n-of x households with [income-status = 4 and DPH-movement = 0][
        move-to one-of f
        ask patch-here [
          (set pcolor pink) (set DP-movement 1) (set new-urban 1) (set urban-type 4)
          if informality = 1 [ set informal-status 1 ]
        ]

        set DPH-movement 1
        set color pink
      ]
    ]
  ]
end

;; Development by low income households
to make-low-income-household-development
  let i household-number
  let n percent-low-income-households
  let x ((i / simulation-period) * ( n / 100)) ;; the number of low-income households who enter the market annually in the simulation period (e.g., between 2000 and 2010)

  let d patches with [(urban = 0) and (new-urban = 0) and (suitability = 1) and (landvalue < 2)] ;;and (ULI > 0)

  ;;ask max-n-of (x + (count d) / 20) d [ULI] [set first-n-ULI 1]
  if (count d) > 0 [
    ask max-n-of (x * liu-maxof) d [ULI] [set first-n-ULI 1]
    let f patches with
    [((first-n-ULI = 1) and (DP-movement = 0) and (LI-movement = 0) and (HI-movement = 0) and
      (MI-movement = 0) and (pMED-movement = 0) and (pHED-movement = 0))]
    set available-first-n-ULI count f

    ask n-of x households with [income-status = 1 and LIH-movement = 0][
      move-to one-of f
      ask patch-here [
        (set pcolor yellow) (set LI-movement 1) (set new-urban 1) (set urban-type 1)
        if informality = 1 [ set informal-status 1 ]
      ]

      set LIH-movement 1
      set color yellow
    ]
  ]
end

;;..................................................................


;; Development by middle income households
to make-mid-income-household-development
  let i household-number
  let n percent-mid-income-households
  let x ((i / simulation-period) * ( n / 100))
  let d patches with [(urban = 0) and (new-urban = 0) and (suitability = 1) and (landvalue <= 3) ] ;;and (UMI > 0)
  if ( count d ) > 0 [
    ask max-n-of (x * miu-maxof) d [UMI] [set first-n-UMI 1] ;; APS: This command selects 3 patches of the set d with the highest UMI and sets their first-n-UMI to 1
    let f patches with [(first-n-UMI = 1) and (MI-movement = 0) and
        (DP-movement = 0) and (HI-movement = 0) and (LI-movement = 0) and (pMED-movement = 0) and (pHED-movement = 0)]
    set available-first-n-UMI count f

    ask n-of x households with [income-status = 2 and MIH-movement = 0] [
      move-to one-of f

      ask patch-here [
        (set pcolor orange) (set MI-movement 1) (set new-urban 1) (set urban-type 2)
        if informality = 1 [ set informal-status 1 ]
      ]
      set MIH-movement 1
      set color orange
    ]
  ]
end
;;........................................................................................................................................


;;Make high income development
to make-high-income-household-development
  let i household-number
  let n percent-high-income-households
  let x ((i / simulation-period) * ( n / 100))
  let d patches with [(urban = 0) and (new-urban = 0) and (suitability = 1) ] ;;and (UHI > 0)
  if (count d) > 0 [
    ask max-n-of (x * hiu-maxof) d [UHI] [set first-n-UHI 1]
    let f patches with [(first-n-UHI = 1) and
      (DP-movement = 0) and (HI-movement = 0) and (MI-movement = 0)and (LI-movement = 0) and (pMED-movement = 0) and (pHED-movement = 0)]
    set available-first-n-UHI count f

    ask n-of x households with [income-status = 3 and HIH-movement = 0] [
      move-to one-of f

      ask patch-here [
        (set pcolor blue) (set HI-movement 1) (set new-urban 1) (set urban-type 3)
        if informality = 1 [ set informal-status 1 ]
      ]
      set HIH-movement 1
      set color blue
    ]
  ]
end

;; Developments by mid end real estate developers
to make-mid-end-RED
  let i estate-developer-number
  let n percent-mid-end-developers
  let x ((i / simulation-period) * ( n / 100))
  let y (median [UMI] of patches with [suitability = 1 and districts > 0])
  let w (2 + random 6)

  let d patches with [(urban = 0) and (new-urban = 0) and (suitability = 1)]

  ;;ask max-n-of (x + (count d)/ 20) d [UMED] [set first-n-UMED 1]

  ask max-n-of (x * mi-red-maxof) d [UMED] [set first-n-UMED 1]


  ask n-of x developers with [class = 2 and MED-movement = 0] [
    move-to one-of patches with
    [
      (first-n-UMED = 1) and (pMED-movement = 0) and (pHED-movement = 0)
      and (HI-movement = 0)and (MI-movement = 0)and (LI-movement = 0)
    ]

    ask patch-here
    [
      ask n-of w patches in-radius mi-red-rad
      [
        if suitability = 1 and urban = 0 and new-urban = 0
        [
          (set pcolor orange) (set pMED-movement 1) (set new-urban 1) (set urban-type 2)
          if informality = 1 [ set informal-status 1 ]
        ]
      ]
      set pcolor orange
      set pMED-movement 1
      set new-urban 1
      set urban-type 1
      if informality = 1 [ set informal-status 1 ]
    ]
    (set MED-movement 1) (set color orange)
  ]
end

;; Developments by high-end real estate developers
to make-high-end-RED
   let i estate-developer-number
  let n percent-high-end-developers
  let x ((i / simulation-period) * ( n / 100))
  let y (median [UHED] of patches with [ suitability = 1 and districts > 0])
  let q (2 + random 4)

  let d patches with [(urban = 0) and (new-urban = 0) and (suitability = 1)]

  ask max-n-of (x * hi-red-maxof) d [UHED] [set first-n-UHED 1]

  ask n-of x developers with [(class = 3) and (HED-movement = 0)] [
    move-to one-of patches with [(first-n-UHED = 1) and (pHED-movement = 0)
    and (pMED-movement = 0) and (HI-movement = 0) and (MI-movement = 0) and (LI-movement = 0)]

    ask patch-here
    [
      ask n-of q patches in-radius hi-red-rad
      [
        if suitability = 1 and urban = 0 and new-urban = 0
        [
          (set pcolor blue) (set pHED-movement 1) (set new-urban 1) (set urban-type 3)
          if informality = 1 [ set informal-status 1 ]
        ]
      ]
      set pcolor blue
      set new-urban 1
      set pHED-movement 1
      set urban-type 1
      if informality = 1 [ set informal-status 1 ]
    ]
    (set HED-movement 1)  (set color blue)
  ]
end


;;...................................................................................................................................................
;;...................................................................................................................................................


;;UPDATE-NEIGHBOURHOOD
to update-neighbourhood

  ask patches with [(new-urban = 0) and (suitability = 1)] [
    if ((count neighbors with [DP-movement = 1] >= 3 ) and (first-n-UDP = 0))
    [
      set first-n-UDP 1
      set landvalue 1
      set first-n-ULI 0
      set first-n-UMI 0
      set first-n-UHI 0
    ]
    if ((count neighbors with [DP-movement = 1] >= 3 ) and (landvalue > 1))
    [
      set landvalue 1
      set first-n-ULI 0
      set first-n-UDP 1
      set first-n-UMI 0
      set first-n-UHI 0
    ]
    if ((count neighbors with [LI-movement = 1] >= 3 ) and (first-n-ULI = 0))
    [
      set first-n-ULI 1
      set landvalue 1
      set first-n-UDP 0
      set first-n-UMI 0
      set first-n-UHI 0
    ]
    if ((count neighbors with [LI-movement = 1] >= 3 ) and (landvalue > 1))
    [
      set landvalue 1
      set first-n-ULI 1
      set first-n-UDP 0
      set first-n-UMI 0
      set first-n-UHI 0
    ]

    if ((count neighbors with [HI-movement = 1] >= 3) and (first-n-UHI = 0))
    [
      set first-n-UHI 1
      set first-n-UDP 0
      set first-n-ULI 0
      set first-n-UMI 0
    ]

    if ((count neighbors with [MI-movement = 1] >= 3 ) and (first-n-UMI = 0))
    [
      set first-n-UMI 1
      set landvalue 2
      set first-n-UDP 0
      set first-n-UHI 0
      set first-n-ULI 0
    ]

    if ((count neighbors with [MI-movement = 1] >= 3 ) and (landvalue > 2))
    [
      set landvalue 2
      set first-n-UMI 1
      set first-n-UDP 0
      set first-n-UHI 0
      set first-n-ULI 0
    ]
  ]

end
;;......................................................................................
;;......................................................................................


;; EXPORT OUTPUT
;; APS: 12.12.2024 new export function, seeks to correct errors
to export-income-status-as-asc
  ;; Save the raster dataset as an ASCII grid
  let raster gis:patch-dataset urban-type
  let file-name "data/out/expansion_income_2050.asc"
  gis:store-dataset raster file-name
end

to export-informal-status-as-asc
  ;; get the informal status of each patch
  let raster gis:patch-dataset informal-status
  let file-name "data/out/expansion_informal_2050.asc"
  gis:store-dataset raster file-name
end


;;.................................................................................
;; APS: created a function to troble-shoot the inputs

to experiment-urban ;;APS: simply tests the urban inputs
  ca
  load-urban2015
  ask patches [ifelse urban = 1 [ set pcolor brown ] [set pcolor green]]
  reset-ticks
end


;; APS: implements simple tests for every input individually. Allows to check if the data is displaying as it should and if simple math is working.
to test-input
  ca
  (ifelse
  select-model = "airport" [
      load-airport
      ask patches [set airport airport + 2]
      gis:paint airport-dataset 0]
    select-model = "attractive2015" [
      ca
      load-attractive2015
      ask patches[set attractive (1 - attractive) * 2]
      gis:paint attractive2015-dataset 0]
    select-model = "bu2000-dist"[
      ca
      load-bu2000-dist
      ask patches
      [
        set bu (1 - bu)
        set bu (1 - bu) * 9
      ]
      gis:paint bu2000-dist-dataset 0]
    select-model = "bu2015-dist"[
      ca
      load-bu2015-dist
      ask patches [
        ;;set bu (1 - bu)
        set bu (1 - bu) * 9
      ]
      gis:paint bu2015-dist-dataset 0]
    select-model = "cbd" [
      ca
      load-cbd
      ask patches[set cbd (1 - cbd) * 5]
      gis:paint cbd-dataset 0]
    select-model = "density2000" [
      ca
      load-density2000
      ask patches [set density density * 2]
      gis:paint density2000-dataset 0]
    select-model = "density2015" [
      ca
      load-density2015
      ;;ask patches [set density density + 2]
      gis:paint density2015-dataset 0]
    select-model = "districts" [
      ca
      load-districts
      gis:paint districts-dataset 0]
    select-model = "exclusion" [
      ca
      load-exclusion
      gis:paint exclusion-dataset 0]
    select-model = "healthfacilities" [
      ca
      load-healthfacilities
      ask patches[set healthfacilities 1 - healthfacilities]
      gis:paint healthfacilities-dataset 0]
    select-model = "income" [
      ca
      load-income
      gis:paint income-dataset 0]
    select-model = "landvalue" [
      ca
      load-landvalue
      gis:paint landvalue-dataset 0]
    select-model = "markets" [
      ca
      load-markets
      gis:paint markets-dataset 0
      ask patches [
        set markets (1 - markets) * 6]]
    select-model = "road-presence" [
      ca
      load-road-presence
      gis:paint road-presence-dataset 0]
    select-model = "roads" [
      ca
      load-roads
      gis:paint roads-dataset 0
      ask patches [
        set road (1 - road) * 8]]
    select-model = "schools" [
      ca
      load-schools
      ask patches[set schools (1 - schools) * 2]
      gis:paint schools-dataset 0]
    select-model = "shoppingmalls" [
      ca
      load-shoppingmalls
      ask patches[set shoppingmall 1 - shoppingmall]
      gis:paint shoppingmalls-dataset 0]
    select-model = "slope" [
      ca
      load-slope
      gis:paint slope-dataset 0]
    select-model = "suburban" [
      ca
      load-suburban
      ask patches[set suburb (1 - suburb) * 10]
      gis:paint suburban-dataset 0
    ]
    select-model = "tenure" [
      ca
      load-tenure
      ask patches[
        set tenure (tenure * 2)
        (ifelse
        tenure = 1 [ set pcolor red ]
        tenure = 0 [ set pcolor blue ]
        tenure < 0 [set pcolor white ])
      ]
      ;;gis:paint tenure-dataset 0
    ]
    select-model = "urban2000" [
      ca
      load-urban2000
      gis:paint urban2000-dataset 0]

    select-model = "urban2015" [
      ca
      load-urban2015
      gis:paint urban2015-dataset 0]

    select-model = "structureplan" [
      ca
      load-structureplan
      gis:paint structureplan-dataset 0]
    select-model = "water" [
      ca
      load-water
      gis:paint water-dataset 0]
  )
end
;; APS: end my edits
;;.................................................................................
@#$#@#$#@
GRAPHICS-WINDOW
321
10
1101
699
-1
-1
1.0
1
10
1
1
1
0
0
0
1
0
771
0
679
0
0
1
ticks
30.0

BUTTON
220
10
289
43
Set-up
set-up
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
221
48
288
81
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
8
361
205
394
slope_coefficient
slope_coefficient
1
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
6
396
206
429
critical_slope
critical_slope
1
100
35.0
1
1
NIL
HORIZONTAL

BUTTON
208
562
314
595
Display suitability
display_suitability
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
432
206
465
development_control
development_control
0
100
30.0
1
1
NIL
HORIZONTAL

BUTTON
207
525
314
558
Display informality
display-areas-liable-to-informality
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
11
213
44
household-number
household-number
100
200000
32073.0
100
1
NIL
HORIZONTAL

SLIDER
9
105
202
138
percent-low-income-households
percent-low-income-households
0
100
60.0
1
1
NIL
HORIZONTAL

SLIDER
8
176
200
209
percent-high-income-households
percent-high-income-households
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
9
141
200
174
percent-mid-income-households
percent-mid-income-households
0
100
10.0
1
1
NIL
HORIZONTAL

PLOT
866
249
1050
445
Percent Informal
Years
Percent
0.0
10.0
0.0
30.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot ((count patches with [(informality = 1) and (new-urban = 1)]) / (1 + count patches with [new-urban = 1])) * 100"

MONITOR
895
445
1001
490
Percent Informal
((count patches with [(informality = 1) and (new-urban = 1)]) / (1 + count patches with [new-urban = 1])) * 100
2
1
11

PLOT
1049
501
1481
645
Percent Informal of Income Types
Years
percent
0.0
10.0
0.0
30.0
true
true
"" ""
PENS
"Low-Income Informal" 1.0 0 -2139308 true "" "plot ((count patches with [LI-movement = 1 and informality = 1]) / (1 + count patches with [LI-movement = 1])) * 100"
"Mid-Income Informal" 1.0 0 -955883 true "" "plot (((count patches with [MI-movement = 1 and informality = 1]) + (count patches with [pMED-movement = 1 and informality = 1])) / ((1 + count patches with [MI-movement = 1]) + (count patches with [pMED-movement = 1]))) * 100"
"High-Income Informal" 1.0 0 -13345367 true "" "plot (((count patches with [HI-movement = 1 and informality = 1]) + (count patches with [pHED-movement = 1 and informality = 1])) / ((1 + count patches with [HI-movement = 1]) + (count patches with [pHED-movement = 1]))) * 100"
"Deprived Informal" 1.0 0 -7500403 true "" "plot ((count patches with [DP-movement = 1 and informality = 1]) / (1 + count patches with [DP-movement = 1])) * 100"

MONITOR
1488
502
1624
547
Low-Income Informal
((count patches with [LI-movement = 1 and informality = 1]) / (1 + count patches with [LI-movement = 1])) * 100
2
1
11

MONITOR
1488
601
1620
646
High-Income Informal
(((count patches with [HI-movement = 1 and informality = 1]) + (count patches with [pHED-movement = 1 and informality = 1])) / ((1 + count patches with [HI-movement = 1]) + (count patches with [pHED-movement = 1]))) * 100
2
1
11

MONITOR
1488
552
1622
597
Mid-Income Informal
(((count patches with [MI-movement = 1 and informality = 1]) + (count patches with [pMED-movement = 1 and informality = 1])) / ((1 + count patches with [MI-movement = 1]) + (count patches with [pMED-movement = 1]))) * 100
2
1
11

PLOT
866
10
1049
207
Percent Urbanized
years
percent
0.0
10.0
20.0
50.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot (count patches with [new-urban = 1] + count patches with [urban = 1]) / (1 + count patches with [districts > 0]) * 100"

MONITOR
867
206
982
251
Percent Urbanized
(count patches with [new-urban = 1] + count patches with [urban = 1]) / (1 + count patches with [districts > 0]) * 100
2
1
11

PLOT
1051
649
1480
798
Contribution to Informal Development
Years
Contribution (%)
0.0
10.0
0.0
50.0
true
true
"" ""
PENS
"Low-income" 1.0 0 -2674135 true "" "plot ((count patches with [LI-movement = 1 and informal_avail = 1]) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100"
"Mid-income" 1.0 0 -955883 true "" "plot (((count patches with [MI-movement = 1 and informal_avail = 1]) + (count patches with [pMED-movement = 1 and informal_avail = 1])) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100"
"High-income" 1.0 0 -13345367 true "" "plot (((count patches with [HI-movement = 1 and informal_avail = 1]) + (count patches with [pHED-movement = 1 and informal_avail = 1])) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100"
"Deprived" 1.0 0 -7500403 true "" "plot ((count patches with [DP-movement = 1 and informal_avail = 1]) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100"

MONITOR
1496
652
1614
697
Low-income contr.
((count patches with [LI-movement = 1 and informal_avail = 1]) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100
2
1
11

MONITOR
1496
701
1615
746
Mid-income contr.
(((count patches with [MI-movement = 1 and informal_avail = 1]) + (count patches with [pMED-movement = 1 and informal_avail = 1])) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100
2
1
11

MONITOR
1497
752
1617
797
High-income contr.
(((count patches with [HI-movement = 1 and informal_avail = 1]) + (count patches with [pHED-movement = 1 and informal_avail = 1])) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100
2
1
11

SLIDER
8
216
206
249
estate-developer-number
estate-developer-number
10
1000
10.0
10
1
NIL
HORIZONTAL

SLIDER
7
251
207
284
percent-high-end-developers
percent-high-end-developers
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
7
288
207
321
percent-mid-end-developers
percent-mid-end-developers
0
100
67.0
1
1
NIL
HORIZONTAL

SLIDER
7
324
206
357
simulation-period
simulation-period
1
50
25.0
1
1
NIL
HORIZONTAL

BUTTON
9
621
72
654
EU
experiment-urban
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
107
652
199
697
select-model
select-model
"airport" "attractive2015" "bu2000-dist" "bu2015-dist" "density2000" "density2015" "districts" "exclusion" "income" "landvalue" "road-presence" "slope" "tenure" "urban" "structureplan" "water"
3

BUTTON
9
661
103
694
Test inputs
test-input
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
210
106
319
139
calibrate?
calibrate?
1
1
-1000

BUTTON
9
522
134
556
export income ASCII
export-income-status-as-asc
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1062
10
1495
208
Contribution to Urbanisation
years
percent
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Low-income urbanisation" 1.0 0 -1604481 true "" "plot ((count patches with [LI-movement = 1 and new-urban = 1]) / (1 + count patches with [ new-urban = 1])) * 100"
"Middle-income urbanisation" 1.0 0 -955883 true "" "plot (((count patches with [MI-movement = 1 and new-urban = 1]) + (count patches with [pMED-movement = 1 and new-urban = 1])) / (1 + count patches with [ new-urban = 1 ])) * 100"
"High-income urbanisation" 1.0 0 -13345367 true "" "plot (((count patches with [HI-movement = 1 and new-urban = 1]) + (count patches with [pHED-movement = 1 and new-urban = 1])) / (1 + count patches with [ new-urban = 1 ])) * 100"
"Deprived urbanisation" 1.0 0 -7500403 true "" "plot ((count patches with [DP-movement = 1 and new-urban = 1]) / (1 + count patches with [ new-urban = 1])) * 100"

BUTTON
9
559
134
593
export informal ASCII
export-informal-status-as-asc 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
8
471
146
516
scenario
scenario
"standard" "SSP1" "SSP2" "SSP3"
3

SLIDER
9
67
205
100
percent-deprived-households
percent-deprived-households
0
100
20.0
1
1
NIL
HORIZONTAL

MONITOR
869
501
932
546
HH deprived
count households with [income-status = 4]
17
1
11

MONITOR
871
550
932
595
HH LI
count households with [income-status = 1]
17
1
11

MONITOR
871
601
932
646
HH MI
count households with [income-status = 2]
17
1
11

MONITOR
873
652
930
697
HH HI
count households with [income-status = 3]
17
1
11

MONITOR
989
206
1046
251
suit-left
(count patches with [ suitability = 1 ] - count patches with [new-urban = 1])
17
1
11

MONITOR
1233
212
1303
257
LI hh left
(count households with [income-status = 1 and LIH-movement = 0] )
17
1
11

MONITOR
1308
211
1386
256
MI HH left
(count households with [(income-status = 2) and (MIH-movement = 0)] )
17
1
11

MONITOR
1393
212
1466
257
HI HH left
(count households with [(income-status = 3) and (HIH-movement = 0)] )
17
1
11

MONITOR
1153
212
1229
257
DP HH left
(count households with [(income-status = 4) and (DPH-movement = 0)] )
17
1
11

BUTTON
208
597
314
630
Display UDP
display-UDP
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
210
142
313
175
RED-on?
RED-on?
0
1
-1000

SWITCH
210
178
317
211
neighbour-on?
neighbour-on?
0
1
-1000

MONITOR
1063
260
1151
305
Avail. patches
count total-avail-patches
17
1
11

MONITOR
1155
260
1229
305
first-n-UDP
count patches with [first-n-UDP = 1]
17
1
11

MONITOR
1233
260
1302
305
first-n-ULI
count patches with [first-n-ULI = 1]
17
1
11

MONITOR
1309
261
1386
306
first-n-UMI 
count patches with [first-n-UMI = 1]
17
1
11

MONITOR
1393
261
1466
306
first-n-UHI
count patches with [first-n-UHI = 1]
17
1
11

MONITOR
1234
309
1304
354
av-ULI
available-first-n-ULI
17
1
11

MONITOR
1310
309
1386
354
av-UMI
available-first-n-UMI
17
1
11

MONITOR
1394
309
1465
354
av-UHI
available-first-n-UHI
17
1
11

MONITOR
1156
309
1230
354
av-UDP
available-first-n-UDP
17
1
11

BUTTON
219
223
274
256
DC
do-calculations
NIL
1
T
OBSERVER
NIL
1
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model is named TI-City, which represents the "The Informal City". It is designed to predict 1) the locations, 2) legal status, and 3) economic status of future residential developments in an African city.

TI-City combines agent-based and cellular automata modelling techniques to predict the geospatial behaviour of key urban development actors, including households, real estate developers and government.

To demonstrate the utility of the model, it has been applied to Accra city-region, Ghana, which is one of the largest city-regions in Africa. See Agyemang et al (2022) for the underlying paper.

The model can be useful to African urban studies scholars, environmental and climate scientist, as well as city planners and urban policy makers in Africa.


## HOW IT WORKS

TI-City has several key parameters. This includes:
 
1. A development control parameter, which accounts for diverse regulatory contexts;

2. Projected market demand for plots from households; 

3. Estimated share of households in low-, middle-, and high-income classes; 

4. Estimated demand for plots from real estate developers; 

5. Estimated share of real estate developers targeting middle and high income buyers; 

6. Land prices and affordability
 
7. Utility of land parcels; and 

8. The sensitivity of development to slope. 

The model computes the suitability and utility of a given parcel for each income group by considering the geographical characteristics of the parcel. In calculating utility, the model accounts for the parcel’s geographical characteristics weighted differently depending on the income group of prospective inhabitants. The utility is dynamically updated during the simulation based on the income characteristics in the geographic neighbourhood of each cell.
 

## HOW TO USE IT

1. Select the simulation period. The unit is in years.

2. Select the number of households to simulate using the household slider.

3. Split households in low-, middle-, and high income classes using the sliders. The sum of the three proportions should be equal to 100 percent.

4. Select the number of real estate developers to simulate.

5. Split real estate developers into middle and high end suppliers. The sum of the two proportions should be equal to 100 percent.

6. Select slope coefficient, which determines the extent to which development patterns are influenced by slope. This is modelled after SLEUTH.

7. Select critical slope. This is the percent slope value beyond which development cannot occur. It may be derived from local urban development policies and regulations.

8. Select development control value. This determines the extent to which development conforms to government regulation/local plan. The lower the value the weaker the development control.


## THINGS TO NOTICE

The spatial resolution of the model as applied to Accra is 200m. This is about 50 times larger than the average size of land parcels in the city. To apply the model to Accra using the available data, the parcel enlargement factor should be considered in determining the number of households and real estate developers to simulate.

To adapt the model to any other city, consider the spatial resolution of the data and the extent to which is enlarges or reduces actual sizes of land parcels. Like the case of Accra, this could influence the number of households and real estate developers to simulate.

#### Key for income status predictions:
0 = undeveloped lands
1 = Low income
2 = Middle income
3 = High income
4 = seed year built-up

#### Key for legal status predictions:
0 = undeveloped lands
1 = informal development
2 = formal development
6 = seed year built-up 
 


## THINGS TO TRY

Consider adjusting some of the parameters. For instance, what happens with strong development control or what happens if there is a higher share of middle or high income households?

Experiment with data from a different city.


## EXTENDING THE MODEL

Generalize TI-City as a global urban expansion model. There are ongoing plans to do this.

Integrate residential relocation and densification (vertical development) into the model.

Weight the influence of slope by the socio-economic characteristics of neighbourhoods and prospective inhabitants.



## RELATED MODELS

SLEUTH


## HOW TO CITE THE MODEL

Agyemang, F.S., Silva, E., & Fox, S. (2022). Modelling and simulating ‘informal urbanization’: An integrated agent-based and cellular automata model of urban residential growth in Ghana. Environment and Planning B: Urban Analytics and City Science. https://doi.org/10.1177%2F23998083211068843



## CREDITS AND REFERENCES

Agyemang, F.S., Silva, E., & Fox, S. (2021). Modelling and simulating ‘informal urbanization’: An integrated ABM and CA model of urban residential growth in Ghana. Accepted for publication in Environment and Planning B.

Clarke, K. C., Hoppen, S., & Gaydos, L. (1997). A self-modifying cellular automaton model of historical urbanization in the San Francisco Bay area. Environment and Planning B: Planning and Design, 24(2), 247-261.

Zhou, Y. (2015). Urban growth model in Netlogo. Available at: http://www.gisagents.org/2015/09/urban-growth-model-in-netlogo.html

## CONTACT


Dr Felix S. K Agyemang 
School of Geographical Sciences
Unversity of Bristol

Email: felix.agyemang@bristol.ac.uk

Profile: https://research-information.bris.ac.uk/en/persons/felix-s-k-agyemang
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
