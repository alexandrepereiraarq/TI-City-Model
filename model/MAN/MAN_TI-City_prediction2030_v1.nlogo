;;.....................................................................
;; CHANGELOG FROM ORIGINAL CODE
;; Original developed by Dr Felix Agyemang felix.agyemang@manchester.ac.uk
;; original publication: DOI 10.1177/23998083211068843
;; Modified by Dr. Alexandre Pereira Santos alexandre.santos@lmu.de from 10.2024 to 04.2025
;; 1. adjusted variable naming for consistency
;; 2. separated inputs for more than one case study removing 'Accra' from them.
;; 3. added comments to the code, notably marking those lines commented out in the original and highlighting changes implemented in this revision.
;; 4. renamed prox-bu2015-dataset to bu2015-dist-dataset for consistency with the 2000 dataset
;; 5. renamed the load-prox-bu2015 to load-bu2015-dist for clarity
;; 6. adjusted the number of patches and households [tbi]
;; 7. created the load-attractive2000 function
;; 8. created the load-income function
;; 9. created the load-bu2000 function
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
;;.....................................................................

extensions [ gis ]

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

  ;; PROPERTIES ;; APS: created subtitle for organisation
  slope_max
  develop_prob
  exclusion-dataset
  ;;the-row
  rows
  select-mode

  ;; APS: agent utility weights
  ;; low income agents
  liu-suburb liu-neigbhour liu-bu liu-cbd liu-mall liu-markets liu-road liu-density liu-schools liu-attractive liu-health liu-random
  ;; middle income agents
  miu-suburb miu-neigbhour miu-bu miu-cbd miu-mall miu-markets miu-road miu-density miu-schools miu-attractive miu-health miu-random
  ;; high income agents
  hiu-suburb hiu-neigbhour hiu-bu hiu-cbd hiu-mall hiu-markets hiu-road hiu-density hiu-schools hiu-attractive hiu-health hiu-random

]

;;.....................................................................
;;.....................................................................


;; DEFINE PARCEL ATTRIBUTES
patches-own [
  ;; PROPERTIES READ FROM INPUTS APS included subtitle for better organisation
  airport
  airport-dist
  nom-airport-dist
  attractive2000 ;; APS: commented on the original
  attractive2015
  bu2000 ;; proximity to 2000 built-up;; APS: renamed for consistency with bu2015
  bu2015 ;; proximity to 2015 built-up
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

  ;; CALCULATED PROPERTIES ;; APS included subtitle for better organisation
  ;;attract2000-area
  attract2015-area
  informality
  informal_avail ;; informal lands that are available for development
  suitability

  ;; MOVEMENT VALUES  ;; APS included subtitle for better organisation
  LI-movement ;; FA: whether or not low income household has moved to a parcel
  HI-movement ;; FA: whether or not high income household has moveed to a parcel
  MI-movement ;; FA: whether or not mid income household has moved to a parcel
  pHED-movement ;; FA: whether or not high end estate developer has moved to a parcel
  pMED-movement ;; FA: whether or not mid end estate developer has moved to a parcel

  new-urban ;; FA: all new developments

  ;; UTILITY FUNCTION VALUES   ;; APS included subtitle for better organisation
  ULI ;; utility for low income households
  UHI ;; utility for high income households
  UMI ;; Utility for mid income households
  UHED ;; Utility for High end estate developers
  UMED ;; Utility for mid end estate developers
  first-n-ULI ;; whether the patch has one of the highest low income utility
  first-n-UHI ;; whether the patch has one of the highest high income utility
  first-n-UMI ;; whether the patch has one of the highest middle income utility
  first-n-UHED ;; whether the patch has one of the highest utilities for high end estate developers
  first-n-UMED ;; whether the patch has one of the highest utilities for mid end estate developers

  ;; DEBUGGING INPUTS     ;; APS: INCLUDED THIS, REMOVE LATER

]
;;................................................................................................
;;................................................................................................


;; CREATE HOUSEHOLDS AND DEVELOPERS
breed [ households household ]
households-own [
  income-status
  income
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
  ;; low income agents
  set liu-suburb 8
  set liu-neigbhour 7
  set liu-bu 9
  set liu-cbd 7
  set liu-mall 2
  set liu-markets 7
  set liu-road 8
  set liu-density 9
  set liu-schools 4
  set liu-attractive 2
  set liu-health 4
  set liu-random 1

  ;; middle income agents
  set miu-suburb 6
  set miu-neigbhour 7
  set miu-bu 7
  set miu-cbd 4
  set miu-mall 7
  set miu-markets 7
  set miu-road 6
  set miu-density 6
  set miu-schools 4
  set miu-attractive 7
  set miu-health 4
  set miu-random 1

  ;; high income agents
  set hiu-suburb 5
  set hiu-neigbhour 7
  set hiu-bu 2
  set hiu-cbd 7
  set hiu-mall 9
  set hiu-markets 6
  set hiu-road 5
  set hiu-density 1
  set hiu-schools 4
  set hiu-attractive 10
  set hiu-health 3
  set hiu-random 1

end


to make-households

  ;;.. creation of households
  let i household-number
  create-households i [
  ;;..specification of representation shape
    set shape "person"
    set color white
    set size 1
  ]
  ask turtles [setxy 70 387] ;APS look into this

  ;;.. create socio-economic characteristics of households
  ;;.. create households with low income-status
  let j percent-low-income-households
  let x (j / 100) * i
  ask n-of x households [
    set income-status 1]

  ;;.. create middle-income households
  let a percent-mid-income-households
  let b (a  / 100) * i
  ask n-of b households with [income-status != 1]
  [set income-status 2]

  ;;.. create high-income households
  let h percent-high-income-households
  let c (h / 100) * i
  ask n-of c households with [income-status = 0]
  [set income-status 3]


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
;;..........................................................
;;..........................................................

;; INITIALIZE THE MODEL
to set-up
  ca
  ;;gis:load-coordinate-system ("data\\in\\.prj")
  make-households
  make-developers
  ;;load-urban2000 APS: comented on the original
  load-urban2015
  ;; ask patches [ifelse urban = 1 [ set pcolor brown ] [set pcolor green]] ;; APS: commented on the original and included in the load-urban functions
  load-roads
  load-healthfacilities
  load-suburban
  load-shoppingmalls
  load-markets
  load-airport
  load-cbd
  load-districts
  load-density2000 ;; APS: included for consistency
  load-density2015
  load-bu2015-dist
  ;;load-bu2000 APS: comented on the original
  load-neighbourhood
  ;;load-neighbourhood2000 APS: comented on the original
  load-landvalue ;; APS: renamed for consistency with the variable name
  load-structureplan;; APS: renamed for consistency with the variable name
  ;;load-income APS: comented on the original
  load-schools
  load-tenure
  ;;load-attractive2000  APS: comented on the original
  load-attractive2015
  load-exclusion
  load-slope
  load-suitability
  load-informality
  load-informal-avail
  activate-development-control
  load-nom-neighbourhood
  load-ULI
  load-UHI
  load-UMI
  load-UMED
  load-UHED
  ;;load-developers-utility APS: comented on the original
  ;;load-income APS: comented on the original
  ;;load-suburb-area APS: comented on the original
  set-weights
  reset-ticks
end
;;...................................................
;;...................................................


;;  RUN THE MODEL
to go
  ifelse ticks = simulation-period
  [stop]
  [
    make-high-income-household-development
    make-mid-income-household-development
    make-low-income-household-development
    make-high-end-RED
    make-mid-end-RED
    update-neighbourhood
  ]
  tick
end
;;.................................................................................
;;.................................................................................
;; EDITS BY ALEXANDRE P SANTOS.....................................................

to experiment-urban
  ca
  load-urban2015
  ask patches [ifelse urban = 1 [ set pcolor brown ] [set pcolor green]]
  reset-ticks
end

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
      ask patches[set attractive2015 (1 - attractive2015) * 2]
      gis:paint attractive2015-dataset 0]
    select-model = "bu2000-dist"[
      ca
      load-bu2000-dist
      ask patches [set bu2000 (1 - bu2000) * 9]
      gis:paint bu2000-dist-dataset 0]
    select-model = "bu2015-dist"[
      ca
      load-bu2015-dist
      ask patches [set bu2015 (1 - bu2015) * 9]
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



    ;;[load-urban2015]
  )

  ;; load-bu2015-dist
  ;; load-density2015
  ;; load-districts
  ;; load-exclusion
  ;; load-landvalue
  ;; load-roads
  ;; load-splan
  ;; load-slope
  ;; load-tenure


end

;;.................................................................................
;;.................................................................................

;; LOAD DATASETS
; APS: re-ordered the functions alphabetically

;;load distance to airport
to load-airport
  set airport-dataset gis:load-dataset "data/in/airport.asc" ;; APS: renamed to include folder
  gis:apply-raster airport-dataset airport
  ;;gis:paint airport-dataset 0
end

;; APS: created this function, even if it is only used in the calibration run. We might just call it when we want to.
;;load distance to attractive neighbourhood for the earlier year of the simulation
to load-attractive2000
  set attractive2000-dataset gis:load-dataset "data/in/attractive2000.asc" ;; APS: renamed to include folder
  gis:apply-raster attractive2000-dataset attractive2000
end

;;load distance to attractive neighbourhood for the later year of the simulation
to load-attractive2015
  set attractive2015-dataset gis:load-dataset "data/in/attractive2015.asc" ;; APS: renamed to include folder
  gis:apply-raster attractive2015-dataset attractive2015
end

;; APS: created this function, even if it is only used in the calibration run. We might just call it when we want to.
;; load distance to built-up areas for the earlier year of the simulation
to load-bu2000-dist
  set bu2000-dist-dataset gis:load-dataset "data/in/bu2000_dist.asc" ;; APS: renamed to include folder
  gis:apply-raster bu2000-dist-dataset bu2000
end

;; load distance to built-up areas for the later year of the simulation
to load-bu2015-dist
  set bu2015-dist-dataset gis:load-dataset "data/in/bu2015_dist.asc" ;; APS: renamed to include folder
  gis:apply-raster bu2015-dist-dataset bu2015
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

;;.................................................

;;load built-up status of parcels for the earlier year of the simulation ;; APS: created  a new function to load the 2000 dataset as well
to load-urban2000
  set urban2000-dataset gis:load-dataset "data/in/urban2000.asc" ;; APS: renamed to include folder, urban features  from 2015
  gis:apply-raster urban2000-dataset urban
   gis:set-world-envelope gis:envelope-of urban2000-dataset
  ask patches [ifelse urban = 1 [ set pcolor brown ] [set pcolor green]]
end

;;load built-up status of parcels
to load-urban2015
  set urban2015-dataset gis:load-dataset "data/in/urban2015.asc" ;; APS: renamed to include folder, urban features  from 2015
  gis:apply-raster urban2015-dataset urban
   gis:set-world-envelope gis:envelope-of urban2015-dataset
  ask patches [ifelse urban = 1 [ set pcolor brown ] [set pcolor green]]
end

;;Count and set the number of neighbouring parcels that are built-up
to load-neighbourhood
  ask patches [set neighbourhood
    count neighbors with [urban = 1]]
end


;;.......................................................................
;;.......................................................................


;; COMPUTE THE SUITABILITY OF PARCELS
to load-suitability
  set slope_max max [slope] of patches
  set develop_prob [] ;; APS: initializes a list called develop_prob
  let a 0
  while [a <= critical_slope][ ;; APS:  The code loops through values of a from 0 to critical_slope
    let b (critical_slope - a) / critical_slope ;; APS: Calculates a normalized value b that ranges from 1 (when a = 0) to 0 (when a = critical_slope). This essentially creates a probability scaling factor for slopes below the critical_slope.
    set develop_prob lput (b ^ (slope_coefficient / 200)) develop_prob ;; APS: Appends (lput) a development probability for each slope based on the value of b and the slope_coefficient. The term (b ^ (slope_coefficient / 200)) reduces the development probability as slope increases.
    set a a + 1]
  let i 1
  while [i <= (slope_max - critical_slope)][ ;; APS: Loops to add zeros to the develop_prob list for slopes greater than critical_slope.
    set develop_prob lput 0 develop_prob ;; APS: Appends a zero to the develop_prob list, indicating no development probability for slopes beyond the critical_slope.
    set i i + 1]

  ask patches [
    let y random-float 1 ;; APS: Generates a random number y between 0 and 1 for each patch.
    ifelse y < item slope  develop_prob ;; APS: Compares the random number y to the development probability for the patch's slope (obtained from the develop_prob list). If y is less than the probability:
    [set suitability 1] ;; APS: The patch is deemed suitable for development (suitability = 1).
    [set suitability 0] ;; APS: Otherwise, the patch is unsuitable for development
    if exclusion = 1 [set suitability 0]
    if urban = 1 [set suitability 0]
  ]
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
  ;; ask patches with [(suitability = 1) and (structureplan != 1 and structureplan != 4 and structureplan != 0)]
  ask patches with [(suitability = 1) and (structureplan != 1)] ;; APS: structureplan is now a binary variable, where 0 = settlement allowed, and 1 = settlement not allowed
    [set informality 1]
end


;;Display areas liable to informal development
to display-areas-liable-to-informality
  let i count patches with [(informality = 1) and (suitability = 1) and (urban = 0)]
  let j (development_control / 100) * i
  ;;ask n-of j patches with [informality = 1 and splan != 7] [set pcolor red]
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
to activate-development-control
  let i count patches with[(informality = 1) and (suitability = 1) and (urban = 0)]
  let j (development_control / 100) * i
  ask n-of j patches with [(informality = 1) and (suitability = 1) and (urban = 0)]
  [set suitability 0]
end
;;.......................................................................................
;;.......................................................................................


;; COMPUTE PARCEL UTILITY BY INCOME STATUS
;; load low income households utility for each parcel
to load-ULI
  ask patches [
    set ULI (((1 - suburb) * liu-suburb) + (nom-neighbourhood * liu-neigbhour) + ((1 - bu2015) * liu-bu) +
      ((1 - cbd) * liu-cbd) + ((1 - shoppingmall) * liu-mall) + ((1 - markets) * liu-markets) +
      ((1 - road) * liu-road) + (density * liu-density) + ((1 - schools) * liu-schools) +
      ((1 - attractive2015) * liu-attractive) + ((1 - healthfacilities) * liu-health ) + ((random-float 0.1) * liu-random))
  ]
end

;;............................................................................................................


;;load mid income household utility for each patch / parcel
to load-UMI
  ask patches [
    set UMI (((1 - suburb) * miu-suburb) + (nom-neighbourhood * miu-neigbhour) +  ((1 - bu2015) * miu-bu) +
      ((1 - cbd) * miu-cbd) + ((1 - shoppingmall) * miu-mall) + ((1 - markets) * miu-markets) +
      ((1 - road) * miu-road) + (density * miu-density) + ((1 - schools) * miu-schools) +
      ((1 - attractive2015) * miu-attractive) + ((1 - healthfacilities) * miu-health) + ((random-float 0.1) * miu-random))
  ]
end

;;load high income household utility for each parcel
to load-UHI
  ask patches [
    set UHI (((1 - suburb) * hiu-suburb) + ((1 - nom-neighbourhood) * hiu-neigbhour) + ((1 - bu2015) * hiu-bu) +
      ((1 - cbd) * hiu-cbd) + ((1 - shoppingmall) * hiu-mall) + ((1 - markets) * hiu-markets) +
      ((1 - road) * hiu-road) + (density * hiu-density) + ((1 - schools) * hiu-schools) +
      ((1 - attractive2015) * hiu-attractive) + ((1 - healthfacilities) * hiu-health) + ((random-float 0.1) * hiu-random))
  ]
end
;;.........................................................................

;; compute utility for middle end real estate developers
to load-UMED
  ask patches [
    set UMED (((1 - road) * 8) + ((1 - suburb) * 7) + ((1 - attractive2015) * 7) + ((1 - nom-slope) * 7) + ((1 - schools) * 5))
  ]
end

;; compute utility for high end real estate developers
to load-UHED
  ask patches [
    set UHED (((1 - road) * 8) + ((1 - suburb) * 6) + ((1 - attractive2015) * 10) + ((1 - schools) * 5))
  ]
end
;;........................................................................................................................................
;;........................................................................................................................................


;; PARCEL SELECTION/DEVELOPMENT BY HOUSEHOLDS
;; Development by low income households
to make-low-income-household-development
  let i household-number
  let n percent-low-income-households
  let x ((i / simulation-period) * ( n / 100)) ;; the number of low-income households who enter the market annually between 2000 and 2010

  let d patches with [(urban = 0) and (new-urban = 0) and (suitability = 1) and (landvalue < 2)]

  ;;ask max-n-of (x + (count d) / 20) d [ULI] [set first-n-ULI 1]

  ask max-n-of (x * 3) d [ULI] [set first-n-ULI 1]

  ask n-of x households with [income-status = 1 and LIH-movement = 0][
    move-to one-of patches with
    [((first-n-ULI = 1) and (LI-movement = 0) and (HI-movement = 0) and
      (MI-movement = 0) and (pMED-movement = 0) and (pHED-movement = 0))]

    ask patch-here
    [(set pcolor yellow) (set LI-movement 1) (set new-urban 1)]

    set LIH-movement 1
    set color yellow
  ]
end

;;..................................................................


;; Development by middle income households
to make-mid-income-household-development
  let i household-number
  let n percent-mid-income-households
  let x ((i / simulation-period) * ( n / 100))
  let d patches with [(urban = 0) and (new-urban = 0) and (suitability = 1) and (landvalue < 3)]


  ask max-n-of (x * 3) d [UMI] [set first-n-UMI 1]

  ask n-of x households with [income-status = 2 and MIH-movement = 0] [

    move-to one-of patches with [(first-n-UMI = 1) and (MI-movement = 0)
        and (HI-movement = 0) and (LI-movement = 0) and (pMED-movement = 0) and (pHED-movement = 0)]

    ask patch-here
      [(set pcolor orange) (set MI-movement 1) (set new-urban 1)]
    set MIH-movement 1
    set color orange
    ]
end
;;........................................................................................................................................


;;Make high income development
to make-high-income-household-development
  let i household-number
  let n percent-high-income-households
  let x ((i / simulation-period) * ( n / 100))
  let d patches with [(urban = 0) and (new-urban = 0) and (suitability = 1)]

  ask max-n-of (x * 3) d [UHI] [set first-n-UHI 1]


  ask n-of x households with [income-status = 3 and HIH-movement = 0] [
    move-to one-of patches with [(first-n-UHI = 1) and
        (HI-movement = 0) and (MI-movement = 0)and (LI-movement = 0) and (pMED-movement = 0) and (pHED-movement = 0)]

    ask patch-here [(set pcolor blue) (set HI-movement 1) (set new-urban 1)]
    set HIH-movement 1
    set color blue
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

  ask max-n-of (x * 2) d [UHED] [set first-n-UHED 1]

  ask n-of x developers with [(class = 3) and (HED-movement = 0)] [
    move-to one-of patches with [(first-n-UHED = 1) and (pHED-movement = 0)
    and (pMED-movement = 0) and (HI-movement = 0)and (MI-movement = 0)and (LI-movement = 0)]

    ask patch-here
    [
      ask n-of q patches in-radius 2
      [
        if suitability = 1 and urban = 0 and new-urban = 0
        [
          (set pcolor blue) (set pHED-movement 1) (set new-urban 1)
        ]
      ]
      set pcolor blue
      set new-urban 1
      set pHED-movement 1
    ]
    (set HED-movement 1)  (set color blue)
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

  ask max-n-of (x * 2) d [UMED] [set first-n-UMED 1]


  ask n-of x developers with [class = 2 and MED-movement = 0] [
    move-to one-of patches with
    [
      (first-n-UMED = 1) and (pMED-movement = 0) and (pHED-movement = 0)
      and (HI-movement = 0)and (MI-movement = 0)and (LI-movement = 0)
    ]

    ask patch-here
    [
      ask n-of w patches in-radius 3
      [
        if suitability = 1 and urban = 0 and new-urban = 0
        [
          (set pcolor orange) (set pMED-movement 1) (set new-urban 1)
        ]
      ]
      set pcolor orange
      set pMED-movement 1
      set new-urban 1
    ]
    (set MED-movement 1) (set color orange)
  ]
 ;;..............................................................................................................
end
;;...................................................................................................................................................
;;...................................................................................................................................................


;;UPDATE-NEIGHBOURHOOD
to update-neighbourhood

  ask patches with [(new-urban = 0) and (suitability = 1)] [ if ((count neighbors with [LI-movement = 1] >= 3 ) and (first-n-ULI = 0))
    [
    set first-n-ULI 1
    set landvalue 1
    set first-n-UMI 0
    set first-n-UHI 0
    ]
    if ((count neighbors with [LI-movement = 1] >= 3 ) and (landvalue > 1))
    [
      set landvalue 1
      set first-n-ULI 1
      set first-n-UMI 0
      set first-n-UHI 0
    ]

    if ((count neighbors with [HI-movement = 1] >= 3) and (first-n-UHI = 0))
    [
      set first-n-UHI 1
      set first-n-ULI 0
      set first-n-UMI 0
    ]

    if ((count neighbors with [MI-movement = 1] >= 3 ) and (first-n-UMI = 0))
    [
      set first-n-UMI 1
      set landvalue 2
      set first-n-UHI 0
      set first-n-ULI 0
    ]

    if ((count neighbors with [MI-movement = 1] >= 3 ) and (landvalue > 2))
    [
      set landvalue 2
      set first-n-UMI 1
      set first-n-UHI 0
      set first-n-ULI 0
    ]
  ]

end
;;......................................................................................
;;......................................................................................


;; EXPORT OUTPUT
to export-output-income-status
  file-close
  ;;file-delete "Output/Income_status/urban_expansion_income_2030.asc"
  ;;file-open "Output/Income_status/urban_expansion_income_2030.asc"
  ;;file-delete "data/out_mumbai/MUM_expansion_income_2023.asc"
  file-open "data/out/expansion_income_2023.asc"
  file-print "ncols         595   \r\n"
  file-print "nrows         846   \r\n"
  file-print "xllcorner     253336.3548   \r\n"
  file-print "yllcorner     2041831.0224   \r\n"
  file-print "cellsize 150   \r\n"
  file-print  "NODATA_value  -9999   \r\n"

  let i 845
  while [i > -1]
    [ set rows []
      set rows patches with [pycor = i]
        foreach sort-on [pxcor] rows [ ?1 -> ask ?1 [
        if pcolor = yellow [file-write 1] ;; low income
        if pcolor = orange [file-write 2] ;; middle income
        if pcolor = blue [file-write 3] ;; high income
        if pcolor = green [file-write 0] ;; undeveloped lands
      if pcolor = brown [file-write 4] ] ] ;; seed year built-up
     file-print "   "
     set i i - 1]
end

to export-output-legal-status
  file-close
  ;;file-delete "Output/formality_status/formality_2030.asc"
  ;;file-open "Output/formality_status/formality_2030.asc"
  file-open "data/out/expansion_formality_2023.asc"
  file-print "ncols         595   \r\n"
  file-print "nrows         846   \r\n"
  file-print "xllcorner     253336.3548   \r\n"
  file-print "yllcorner     2041831.0224   \r\n"
  file-print "cellsize 150   \r\n"
  file-print  "NODATA_value  -9999   \r\n"

  let i 845
  while [i > -1]
    [ set rows []
      set rows patches with [pycor = i]
      foreach sort-on [pxcor] rows [ ?1 -> ask ?1 [
        if new-urban = 1 and informality = 1 [file-write 1] ;; informal development
        if new-urban = 1 and informality = 0 [file-write 2] ;; formal development
        if pcolor = green [file-write 0] ;; undeveloped lands
        if pcolor = brown [file-write 6] ] ] ;; seed year built-up
     file-print "   \r\n"
     set i i - 1]

end
@#$#@#$#@
GRAPHICS-WINDOW
300
11
1154
1098
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
845
0
1077
0
0
1
ticks
30.0

BUTTON
214
10
283
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
217
53
280
86
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
5
327
177
360
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
5
358
177
391
critical_slope
critical_slope
1
100
20.0
1
1
NIL
HORIZONTAL

BUTTON
6
469
134
502
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
5
392
191
425
development_control
development_control
0
100
10.0
1
1
50
HORIZONTAL

BUTTON
5
434
223
467
Display areas liable to informality
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
50000
22320.0
100
1
NIL
HORIZONTAL

SLIDER
8
46
212
79
percent-low-income-households
percent-low-income-households
0
100
52.0
1
1
NIL
HORIZONTAL

SLIDER
7
117
199
150
percent-high-income-households
percent-high-income-households
0
100
9.0
1
1
NIL
HORIZONTAL

SLIDER
8
82
199
115
percent-mid-income-households
percent-mid-income-households
0
100
39.0
1
1
NIL
HORIZONTAL

PLOT
1163
10
1347
206
Percent Informal
Years
Percent
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot ((count patches with [(informality = 1) and (new-urban = 1)]) / (1 + count patches with [new-urban = 1])) * 100"

MONITOR
1192
206
1297
251
Percent Informal
((count patches with [(informality = 1) and (new-urban = 1)]) / (1 + count patches with [new-urban = 1])) * 100
2
1
11

PLOT
1359
10
1791
207
Percent Informal of Income Types
Years
percent
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Low-Income Informal" 1.0 0 -2674135 true "" "plot ((count patches with [LI-movement = 1 and informality = 1]) / (1 + count patches with [LI-movement = 1])) * 100"
"High-Income Informal" 1.0 0 -13345367 true "" "plot (((count patches with [HI-movement = 1 and informality = 1]) + (count patches with [pHED-movement = 1 and informality = 1])) / ((1 + count patches with [HI-movement = 1]) + (count patches with [pHED-movement = 1]))) * 100"
"Mid-Income Informal" 1.0 0 -955883 true "" "plot (((count patches with [MI-movement = 1 and informality = 1]) + (count patches with [pMED-movement = 1 and informality = 1])) / ((1 + count patches with [MI-movement = 1]) + (count patches with [pMED-movement = 1]))) * 100"

MONITOR
1359
205
1488
250
Low-Income Informal
((count patches with [LI-movement = 1 and informality = 1]) / (1 + count patches with [LI-movement = 1])) * 100
2
1
11

MONITOR
1659
206
1791
251
High-Income Informal
(((count patches with [HI-movement = 1 and informality = 1]) + (count patches with [pHED-movement = 1 and informality = 1])) / ((1 + count patches with [HI-movement = 1]) + (count patches with [pHED-movement = 1]))) * 100
2
1
11

MONITOR
1512
206
1638
251
Mid-Income Informal
(((count patches with [MI-movement = 1 and informality = 1]) + (count patches with [pMED-movement = 1 and informality = 1])) / ((1 + count patches with [MI-movement = 1]) + (count patches with [pMED-movement = 1]))) * 100
2
1
11

PLOT
1161
254
1344
451
Percent Urbanized
years
percent
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot (count patches with [new-urban = 1] + count patches with [urban = 1]) / (1 + count patches with [districts > 0]) * 100"

MONITOR
1203
450
1317
495
Percent Urbanized
(count patches with [new-urban = 1] + count patches with [urban = 1]) / (1 + count patches with [districts > 0]) * 100
2
1
11

BUTTON
5
505
175
538
Export income prediction
export-output-income-status
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
1162
504
1591
715
Contribution to Informal Development
Years
Contribution (%)
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Low-income" 1.0 0 -2674135 true "" "plot ((count patches with [LI-movement = 1 and informal_avail = 1]) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100"
"Mid-income" 1.0 0 -955883 true "" "plot (((count patches with [MI-movement = 1 and informal_avail = 1]) + (count patches with [pMED-movement = 1 and informal_avail = 1])) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100"
"High-income" 1.0 0 -13345367 true "" "plot (((count patches with [HI-movement = 1 and informal_avail = 1]) + (count patches with [pHED-movement = 1 and informal_avail = 1])) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100"

MONITOR
1692
506
1796
551
Low-income
((count patches with [LI-movement = 1 and informal_avail = 1]) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100
2
1
11

MONITOR
1692
561
1797
606
Mid-income
(((count patches with [MI-movement = 1 and informal_avail = 1]) + (count patches with [pMED-movement = 1 and informal_avail = 1])) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100
2
1
11

MONITOR
1693
617
1799
662
High-income
(((count patches with [HI-movement = 1 and informal_avail = 1]) + (count patches with [pHED-movement = 1 and informal_avail = 1])) / (1 + count patches with [ new-urban = 1 and informal_avail = 1])) * 100
2
1
11

SLIDER
7
152
40
325
estate-developer-number
estate-developer-number
10
1000
200.0
10
1
NIL
VERTICAL

SLIDER
50
152
83
325
percent-high-end-developers
percent-high-end-developers
0
100
29.0
1
1
NIL
VERTICAL

SLIDER
92
152
125
326
percent-mid-end-developers
percent-mid-end-developers
0
100
70.0
1
1
NIL
VERTICAL

BUTTON
3
541
197
574
Export legal status prediction
export-output-legal-status
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
161
151
194
325
simulation-period
simulation-period
1
50
15.0
1
1
NIL
VERTICAL

BUTTON
217
93
280
126
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
202
165
294
210
select-model
select-model
"airport" "attractive2015" "bu2000-dist" "bu2015-dist" "density2000" "density2015" "districts" "exclusion" "income" "landvalue" "road-presence" "slope" "tenure" "urban" "structureplan"
4

BUTTON
205
128
299
161
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
