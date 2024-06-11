extensions [nw matrix rnd] ;package required for built-in network generation

breed [people person]
undirected-link-breed [active-links active-link]
undirected-link-breed [inactive-links inactive-link]

Globals [

  stagesList ;list of disease stages
  TPM ; transition probability matrix
  TTM ; transition time matrix
]

turtles-own[
  CurrentStage; disease stage of infected node ; disease stage of suscpetible node is "uninfected"
  NextStage
  StageCounter; keep track of time in current stage
  HIV?           ;keeps track of whether the person has HIV or not (boolean value- true/false)
  HCV?           ;same for HCV
  InfectedContacts    ;the number of infected contacts a person has
]



to setup
  clear-all                  ;clears any previously generated turtles/ makes a blank slate
  random-seed 47822
  setupGlobals
  setupNetwork     ;calls the procedure/function which will generate the contact network
  setupPeople                ;Initialize the population and individual characteristics
  reset-ticks                ;resets timesteps to 0
end

to setupNetwork
  nw:generate-preferential-attachment people inactive-links population.size contacts_per_day / 2
  ask people [
    set HIV? false                     ;initializes all people's HIV? characteristic to false
    set HCV? false                     ;     "       "    "      HCV?       "           "
    set shape "person"                      ;sets shape of the people
    set color green                         ;initializes color of all people
    setxy  random-xcor random-ycor          ;places people at random locations
    set size 1                              ;sets size of each person on display
    set currentStage "uninfected"
    set nextStage "uninfected"
  ]
end

to setupGlobals
  set stagesList [0 1 ]
  set TPM matrix:from-row-list (list(list (1 - (HCV.risk.among.HIV * Transmission.risk.HCV)) (HCV.risk.among.HIV * Transmission.risk.HCV) ) [0 1 ] );TPM[i,j]= probability of going from stage i to stage j; probability of 1 indictes there is only 1 disease stage it can transmision next
  set TTM matrix:from-row-list [[1 1 ] [1 1 ] ]; TTM[i,j]= average time it takes to go from stage i to stage j;
end

to setupPeople
  ;set initial infections
  ask n-of initial.infections people [
    set HIV? true
    set HCV? true
    set currentStage 1
    ;setLabel
    setColor
    setNextStage
  ]
end


to simulate
  ;stopping condition - simulation stops when it reaches 10 years (3650 ticks)
  if ticks = 3650
  [stop]
  ifelse ((count people with [HIV? = true or HCV? = true]) / count people > SHinitiation) [applyStableHousing] [applyNeedleSharing] ;applies intervention under certain condition
  ask people with [HIV? = true or HCV? = true] [
    updateStage
    updateStageCounter
  ]
  ask people with [HIV? = false and HCV? = false] [    ;asks susceptible population
    CountInfectedContacts     ;calls function to count infected contacts of each person
    InfectSusceptibles        ;calls function that calculates whether a person gets infected or not
  ]
  tick                       ;advances the timestep (in this case one day)
end

to CountInfectedContacts

  set InfectedContacts  count active-link-neighbors with [HIV? = true or HCV? = true]  ;counts the number of infected neighbors of the person

end

to InfectSusceptibles
  if random-float 1 < 1 - (1 - transmission.risk.HIV) ^ (InfectedContacts) [   ;probability of transmission HIV
    set HIV? true
    set currentStage 0
    ;setLabel
    setColor
    setNextStage
  ]
  if random-float 1 < 1 - (1 - transmission.risk.HCV) ^ (InfectedContacts) [   ;probability of transmission HCV
    set HCV? true
    set currentStage 1
    ;setLabel
    setColor
    setNextStage
  ]
end

to updateStageCounter
  set StageCounter StageCounter + 1
  if currentStage = 1[
    set HCV? true
  ]
  setColor
  ;setLabel
end

to updateStage
  if StageCounter >= matrix:get TTM  currentStage nextStage[
    set currentStage nextStage
    setNextStage
    set StageCounter 0
  ]
end

to setNextStage
  let pairs (map list stagesList matrix:get-row TPM currentStage); map list item weights (creates a one-to-one map between elments in item and wieghts  - then this map can be used for randomly picking a value
                                                                 ;print pairs
  set NextStage  first rnd:weighted-one-of-list pairs [ [p] -> last p ] ;; picks a stage weighted by the probability of transition
                                                                        ;print NextStage
end

to applyNeedleSharing
  ask n-of count active-links active-links [
    set breed inactive-links
    set color grey
  ]
  ask n-of (proportionSharingNeedles * count inactive-links) inactive-links [
    set breed active-links
    set color pink
  ]
end

to applyStableHousing
  ask n-of count active-links active-links [
    set breed inactive-links
    set color grey
  ]
  ask n-of ((1 - needleSharingReduction) * proportionSharingNeedles * count inactive-links ) inactive-links [
    set breed active-links
    set color white
  ]
end

;to setLabel
;  ifelse HIV? = true and HCV? = true   ;sets label based on infection stage
;    [set label 2]
;    [ifelse HCV? = true
;      [set label 1]
;      [if HIV? = true
;        [set label 0]]]
;end

to setColor
  ifelse HIV? = true and HCV? = true
    [set color red]
    [ifelse HCV? = true
      [set color orange]
      [if HIV? = true
        [set color yellow]]]
end
























;beyond this point is code to make the turtle display and layout look good.

;;;;;; LAYOUT ;;;;;;
to do-layout
  repeat 100[
    layout-spring turtles with [ any? link-neighbors ] links 0.4 6 1
    ; display  ;; so we get smooth animation
  ]
end

;CREDITS FOR BELOW
; Copyright 2005 Uri Wilensky.
; See Info tab for full copyright and license.
to layout
  ;; the number 3 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 3 [
    ;; the more turtles we have to fit into the same amount of space,
    ;; the smaller the inputs to layout-spring we'll need to use
    let factor sqrt count turtles
    ;; numbers here are arbitrarily chosen for pleasing appearance
    layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    ; display  ;; for smooth animation
  ]
  ;; don't bump the edges of the world
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  ;; big jumps look funny, so only adjust a little each time
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask turtles [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end
to-report limit-magnitude [number limit]
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

INPUTBOX
22
10
177
70
population.size
1000.0
1
0
Number

INPUTBOX
21
73
176
133
contacts_per_day
4.0
1
0
Number

INPUTBOX
20
134
175
194
initial.infections
1.0
1
0
Number

INPUTBOX
19
196
174
256
transmission.risk.HIV
0.0057
1
0
Number

BUTTON
103
377
181
410
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

BUTTON
105
457
182
490
NIL
simulate\n
T
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
104
416
182
449
NIL
layout
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
819
11
1408
580
Number infected
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total Infected" 1.0 0 -16777216 true "" "plot count turtles with [HIV? = true or HCV? = true]"
"HIV & HCV" 1.0 0 -2674135 true "" "plot count turtles with [HIV? = true and HCV? = true]"
"HIV-Only" 1.0 0 -1184463 true "" "plot count turtles with [HIV? = true]"
"HCV-Only" 1.0 0 -955883 true "" "plot count turtles with [HCV? = true]"

INPUTBOX
655
165
810
225
proportionSharingNeedles
0.3
1
0
Number

INPUTBOX
655
68
810
128
SHinitiation
1.0
1
0
Number

MONITOR
656
293
811
338
Propotion HIV or HCV
count people with [HIV? = true or HCV? = true] / count people
3
1
11

INPUTBOX
19
254
174
314
Transmission.risk.HCV
0.0035
1
0
Number

INPUTBOX
19
315
174
375
HCV.risk.among.HIV
2.5
1
0
Number

TEXTBOX
659
10
809
66
Stable housing provided when x proportion of people are infected with either HIV or HCV.
11
0.0
1

TEXTBOX
658
134
808
162
Proportion Needle Sharing Basecase
11
0.0
1

INPUTBOX
656
227
810
287
NeedleSharingReduction
0.83
1
0
Number

MONITOR
656
342
811
387
Proportion HIV and HCV
count people with [HIV? = true and HCV? = true] / count people
3
1
11

MONITOR
657
392
811
437
Proportion HIV
count people with [HIV? = true] / count people
3
1
11

MONITOR
657
442
811
487
Propotion HCV
count people with [HCV? = true] / count people
3
1
11

@#$#@#$#@
## WHAT IS IT?

Observe the proportion infected under different network configurations for same prpotion vaccinated 

## CREDITS AND REFERENCES

MIE 290H, UMass Amherst
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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>simulate</go>
    <metric>count people with [infected? = true] / count people</metric>
    <enumeratedValueSet variable="transmission.risk">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contacts_per_day">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial.infections">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population.size">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="networktype">
      <value value="&quot;PA&quot;"/>
      <value value="&quot;WS&quot;"/>
      <value value="&quot;R&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proportionSocialDistancing">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SDinitiation">
      <value value="0.01"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
