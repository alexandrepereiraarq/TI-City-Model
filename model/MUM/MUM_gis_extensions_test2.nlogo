extensions [gis]

globals [
;; DATASETS ;; APS: created subtitle for organisation, organised alphabetically
  road-dataset
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
]

patches-own[
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
  density-flip ;; APS: commented for troubleshooting
  exclusion
  income-patch ;; APS: created patches-own
  healthfacilities
  landvalue
  markets
  neighbourhood
  ;;neighbourhood2000
  nom-neighbourhood
  road ;;proximity to road
  road-presence ;; whether or not there is road
  suburb
  suburb-area ;; to define patches within a specified radius of suburbs
  shoppingmall
  schools
  slope
  slope-pct
  nom-slope
  structureplan
  tenure
  urban
  ;;urban2000

  suitability
  ULI
]



to setup
  ca
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
  load-nom-neighbourhood
  ;;load-ULI

end


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

to load-nom-neighbourhood
 ask patches [set nom-neighbourhood ((neighbourhood)/(8))]
end

to test-input
  ca
  (ifelse
  select-model = "airport" [
      load-airport
      ask patches [set airport airport + 2
      set pcolor scale-color green airport 0 10
      ]
      ;gis:paint airport-dataset 0
    ]
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
      ;;gis:paint schools-dataset 0
      set pcolor scale-color green schools 0 10
    ]
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


    ;;[load-urban2015]
  )
end

;;load distance to airport
to load-airport
  set airport-dataset gis:load-dataset "data/in_mumbai/airport.asc" ;; APS: renamed to include folder
  gis:apply-raster airport-dataset airport
  ;;gis:paint airport-dataset 0
end

;; APS: created this function, even if it is only used in the calibration run. We might just call it when we want to.
;;load distance to attractive neighbourhood for the earlier year of the simulation
to load-attractive2000
  set attractive2000-dataset gis:load-dataset "data/in_mumbai/attractive2000.asc" ;; APS: renamed to include folder
  gis:apply-raster attractive2000-dataset attractive2000
end

;;load distance to attractive neighbourhood for the later year of the simulation
to load-attractive2015
  set attractive2015-dataset gis:load-dataset "data/in_mumbai/attractive2015.asc" ;; APS: renamed to include folder
  gis:apply-raster attractive2015-dataset attractive2015
end

;; APS: created this function, even if it is only used in the calibration run. We might just call it when we want to.
;; load distance to built-up areas for the earlier year of the simulation
to load-bu2000-dist
  set bu2000-dist-dataset gis:load-dataset "data/in_mumbai/bu2000_dist.asc" ;; APS: renamed to include folder
  gis:apply-raster bu2000-dist-dataset bu2000
end

;; load distance to built-up areas for the later year of the simulation
to load-bu2015-dist
  set bu2015-dist-dataset gis:load-dataset "data/in_mumbai/bu2015_dist.asc" ;; APS: renamed to include folder
  gis:apply-raster bu2015-dist-dataset bu2015
end

;;load distance to CBD
to load-cbd
  set cbd-dataset gis:load-dataset "data/in_mumbai/cbd.asc" ;; APS: renamed to include folder
  gis:apply-raster cbd-dataset cbd
end

;; load population densityfor the latter year in the simulation
to load-density2000; APS: renamed for consistency
  set density2000-dataset gis:load-dataset "data/in_mumbai/density2000.asc" ;; APS: renamed to include folder, density from 2015
  gis:apply-raster density2000-dataset density
  ;; ask patches [set density-flip (1 - density)] ;; set patch values for density-flip
end

;; load population densityfor the latter year in the simulation
to load-density2015; APS: renamed for consistency
  set density2015-dataset gis:load-dataset "data/in_mumbai/density2015.asc" ;; APS: renamed to include folder, density from 2015
  gis:apply-raster density2015-dataset density
  ;;gis:paint density2015-dataset 0
  ;; ask patches [set density-flip (1 - density)] ;; set patch values for density-flip
end

;; load administrative districts
to load-districts
  set districts-dataset gis:load-dataset "data/in_mumbai/districts.asc" ;; APS: renamed to include folder
  gis:apply-raster districts-dataset districts
  ;;gis:paint districts-dataset 0
end

;;load exclusion layer
to load-exclusion
  set exclusion-dataset gis:load-dataset "data/in_mumbai/exclusion.asc" ;; APS: renamed to include folder
  gis:apply-raster exclusion-dataset exclusion
  ;;gis:paint exclusion-dataset 0
end

;;load distance to health facilities
to load-healthfacilities
  set healthfacilities-dataset gis:load-dataset "data/in_mumbai/healthfacilities.asc" ;; APS: renamed to include folder
  gis:apply-raster healthfacilities-dataset healthfacilities
  ;;gis:paint healthfacilities-dataset 0
end

;; APS: created this function as as stub. Test generating the income with their location at a later stage
to load-income
  set income-dataset gis:load-dataset "data/in_mumbai/income.asc" ;; APS: renamed to include folder
  gis:apply-raster income-dataset income-patch
end

;; load land values
to load-landvalue
  ;;set landvalus-dataset gis:load-dataset "data/in_mumbai/landvalue_idw.asc"
  set landvalue-dataset gis:load-dataset "data/in_mumbai/landvalue.asc" ;; APS: renamed to include folder
  gis:apply-raster landvalue-dataset landvalue
  ;;gis:paint landvalues-dataset 0
end

;;load distance to markets
to load-markets
  set markets-dataset gis:load-dataset "data/in_mumbai/markets.asc" ;; APS: renamed to include folder
  gis:apply-raster markets-dataset markets
  ;;gis:paint markets-dataset 0
end

;; load road lines (in raster format) ;; APS: disentangled from load-roads for clarity
to load-road-presence
  set road-presence-dataset gis:load-dataset "data/in_mumbai/road-presence.asc" ;; APS: renamed to include folder
  gis:apply-raster road-presence-dataset road-presence
end

;;load distance to roads
to load-roads
  set roads-dataset gis:load-dataset "data/in_mumbai/roads.asc" ;; APS: renamed to include folder
  gis:apply-raster roads-dataset road
  load-road-presence
  ;;gis:paint roads-dataset 0
end

;;load distance to schools
to load-schools
  set schools-dataset gis:load-dataset "data/in_mumbai/schools.asc" ;; APS: renamed to include folder
  gis:apply-raster schools-dataset schools
  ;;gis:paint schools-dataset 0
end


;;load distance to shopping malls
to load-shoppingmalls
  set shoppingmalls-dataset gis:load-dataset "data/in_mumbai/shoppingmalls.asc" ;; APS: renamed to include folder
  gis:apply-raster shoppingmalls-dataset shoppingmall
  ;;gis:paint shoppingmalls-dataset 0
end

;;load slope
to load-slope
  set slope-dataset gis:load-dataset "data/in_mumbai/slope.asc" ;; APS: renamed to include folder, slope in percent
  gis:apply-raster slope-dataset slope ;;slope-pct
  ;;ask patches [set slope (slope-pct * 100) ]
  ;;gis:paint slope-dataset 0
end


;;load local plan
to load-structureplan
  set structureplan-dataset gis:load-dataset "data/in_mumbai/structureplan.asc" ;; APS: renamed to include folder
  gis:apply-raster structureplan-dataset structureplan
  ;;gis:paint structureplan-dataset 0
end

;;load distance to suburban centers
to load-suburban ;; APS: renamed for consistency with variable name
  set suburban-dataset gis:load-dataset "data/in_mumbai/suburban.asc" ;; APS: renamed to include folder
  gis:apply-raster suburban-dataset suburb
  ;;gis:paint suburban-dataset 0
end

;; land title registration status
to load-tenure
  set tenure-dataset gis:load-dataset "data/in_mumbai/tenure.asc" ;; APS: renamed to include folder
  gis:apply-raster tenure-dataset tenure
  ;;gis:paint title-dataset 0
end

;;.................................................

;;load built-up status of parcels for the earlier year of the simulation ;; APS: created  a new function to load the 2000 dataset as well
to load-urban2000
  set urban2000-dataset gis:load-dataset "data/in_mumbai/urban2000.asc" ;; APS: renamed to include folder, urban features  from 2015
  gis:apply-raster urban2000-dataset urban
   gis:set-world-envelope gis:envelope-of urban2000-dataset
  ask patches [ifelse urban = 1 [ set pcolor brown ] [set pcolor green]]
end

;;load built-up status of parcels
to load-urban2015
  set urban2015-dataset gis:load-dataset "data/in_mumbai/urban2015.asc" ;; APS: renamed to include folder, urban features  from 2015
  gis:apply-raster urban2015-dataset urban
   gis:set-world-envelope gis:envelope-of urban2015-dataset
  ask patches [ifelse urban = 1 [ set pcolor brown ] [set pcolor green]]
end

;;Count and set the number of neighbouring parcels that are built-up
to load-neighbourhood
  ask patches [set neighbourhood
    count neighbors with [urban = 1]]
end

to display_suitability
  ask patches [ifelse suitability = 1
    [set pcolor white][set pcolor black]
  ]
end
to display_density
  ask patches [set pcolor scale-color red density 0 10 ]
end


to display_bu
  ask patches [set pcolor scale-color red bu2015 0 10 ]
end


to load-ULI
  ask patches [
    set ULI ( (nom-neighbourhood * 7) + ((1 - bu2015) * 9) + ((1 - cbd) * 5) + (1 - shoppingmall) +
      ((1 - markets) * 6) + ((1 - road) * 8) + (density * 2) + ((1 - schools) * 2) + ((1 - attractive2015) * 2) + (1 - healthfacilities) + (random-float 0.1))
  ] ;((1 - suburb) * 10) +
end


@#$#@#$#@
GRAPHICS-WINDOW
210
10
813
867
-1
-1
1.0
1
10
1
1
1
0
1
1
1
0
594
0
847
0
0
1
ticks
30.0

BUTTON
31
25
94
58
NIL
setup
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
28
69
166
114
select-model
select-model
"airport" "attractive2015" "bu2000-dist" "bu2015-dist" "density2000" "density2015" "districts" "exclusion" "income" "landvalue" "road-presence" "schools" "slope" "tenure" "urban"
1

SLIDER
35
133
207
166
critical_slope
critical_slope
0
100
22.0
1
1
NIL
HORIZONTAL

SLIDER
33
176
205
209
slope_coefficient
slope_coefficient
0
100
11.0
1
1
NIL
HORIZONTAL

BUTTON
46
298
138
331
NIL
display_bu
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
46
339
163
372
NIL
display_density
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
48
259
177
292
display suitability
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

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
