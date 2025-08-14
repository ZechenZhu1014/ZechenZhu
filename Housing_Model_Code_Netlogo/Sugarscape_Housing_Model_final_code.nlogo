;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                             Sugarscape Housing Model                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Breed
breed [families family]
breed [houses house]
breed [developers developer]

; Global variables
globals [
  number-of-houses             ;; total count of houses in the world
  dead-count                   ;; number of houses removed this tick
  housing-transactions         ;; transactions per tick
  gini-index-reserve           ;; accumulator for Gini calculation
  lorenz-points                ;; list of Lorenz curve points
  gini-index                   ;; Index of gini 0-1
]

; Houses
houses-own [
  house-value                  ;; current market value
  house-owner-id               ;; family ID owning this house (nobody if vacant)
  vacancy-ticks                ;; number of ticks the house has remained vacant
]

; Families
families-own [
  wealth                       ;; the real-world wealth value of the family
  sugar                        ;; sugar carried
  metabolism                   ;; sugar lost per tick
  vision                       ;; the vision that the families can see. The range of vision is a circle.
  age                          ;; the current age of this turtle (in ticks)
  max-age                      ;; the age at which this turtle will die of natural causes
  income                       ;; annual income
  mortgage                     ;; outstanding mortgage balance
  annual-loan-repayment        ;; payment due this year
  loan-years-left              ;; remaining years of loan repayment
]

; Developers
developers-own [
  sugar
  metabolism
  vision-dev
  age
  max-age
]

; Patches
patches-own [
  psugar           ;; the amount of sugar on this patch
  max-psugar       ;; the maximum amount of sugar that can be on this patch
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Setup Procedures                                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  if maximum-sugar-endowment <= minimum-sugar-endowment [
    user-message "Oops: the maximum-sugar-endowment must be larger than the minimum-sugar-endowment"
    stop
  ]
  clear-all
  create-families initial-population [ setup-families ]
  create-developers initial-developers [ setup-developers ]
  setup-patches
  setup-houses
  reset-ticks
  update-lorenz-and-gini ;; Lorenz curve and Gini index curve
  plot-housing-price
  plot-wealth-distribution
  plot-housing-transactions
end

; Initialize a family agent
to setup-families
  set color red
  set shape "circle"
  move-to one-of patches with [not any? other turtles-here]
  ;; assign wealth distribution
  let wealth-random random-float 100                                                             ;; Draw a random number between 0 and 100 to select a wealth bracket
  if wealth-random < 10 [ set wealth random-in-range 20000 50000 ]                               ;; 10% of families get a low initial wealth between 20k and 50k
  if wealth-random >= 10 and wealth-random < 25 [ set wealth random-in-range 50000 150000 ]      ;; Next 15% (i.e. 10–25) get moderate wealth between 50k and 150k
  if wealth-random >= 25 and wealth-random < 50 [ set wealth random-in-range 150000 600000 ]     ;; Next 25% (25–50) get mid-to-upper wealth between 150k and 600k
  if wealth-random >= 50 and wealth-random < 75 [ set wealth random-in-range 600000 1200000 ]    ;; Next 25% (50–75) get higher wealth between 600k and 1.2M
  if wealth-random >= 75 [ set wealth random-in-range 1200000 2300000 ]                          ;; Top 25% (75–100) get the highest wealth between 1.2M and 2.3M

  ;; Initial settings
  set income random-normal 90000 15000
  set sugar random-in-range minimum-sugar-endowment maximum-sugar-endowment
  set metabolism random-in-range 1 4
  set max-age random-in-range 60 100
  set age 30
  set vision random-in-range 1 6
  set mortgage 0
  set annual-loan-repayment 0
  set loan-years-left 0
end

; Initialize a developer agent
to setup-developers
  set color green
  set shape "triangle"
  set size 2
  move-to one-of patches with [not any? other turtles-here]
  set sugar random-in-range minimum-sugar-endowment maximum-sugar-endowment
  set metabolism random-in-range 1 4
  set max-age random-in-range 60 100
  set age 0
  set vision-dev random-in-range 6 10
end

; Load sugar distribution and color patches
to setup-patches
  file-open "sugar-map.txt"
  foreach sort patches [ p ->
    ask p [
      set max-psugar file-read
      set psugar max-psugar
      patch-recolor
    ]
  ]
  file-close
end

; Place initial houses based on local sugar
to setup-houses
  repeat initial-houses [
    let p one-of patches with [not any? turtles-here and not any? houses-here]
    if p != nobody [
      ask p [ sprout-houses 1 [ create-house-on-patch ]]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Run Procedures                                                          ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  if not any? families [
    stop
  ]
  set housing-transactions 0
  ;; depreciate vacant houses
  ask houses with [house-owner-id = nobody] [
    depreciate-vacant-houses
  ]
  ;; regrow and recolor patches
  ask patches [
    patch-growback
    patch-recolor
  ]
  ;; process families & developers
  ask families   [ process-family ]
  ask developers [ process-developer ]
  ask houses [ process-house ]
  ;; rebuild
  repeat dead-count [
    ask one-of developers [
      replenish-vacant-houses 1
    ]
  ]
  set dead-count 0
  ;; stats & plots
  update-lorenz-and-gini
  plot-lorenz-curve
  plot-gini-index
  plot-housing-price
  plot-wealth-distribution
  plot-housing-transactions
  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Patch Procedures                                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to patch-recolor
  set pcolor (yellow + 4.9 - psugar)
end

to patch-growback ;; patch procedure
  ;; gradually grow back all of the sugar for the patch
  set psugar min (list max-psugar (psugar + 1))
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Methods                                                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Method to standardize house creation
to create-house-on-patch
  set shape "house"
  set color blue
  set size 1.8
  set house-owner-id nobody
  set vacancy-ticks 0
  if psugar = 0 [ set house-value random-in-range 200000 400000 ]        ;; No sugar here: cheapest houses, value 200k–400k
  if psugar = 1 [ set house-value random-in-range 400000 600000 ]        ;; Low sugar level: value 400k–600k
  if psugar = 2 [ set house-value random-in-range 600000 800000 ]        ;; Moderate sugar level: value 600k–800k
  if psugar = 3 [ set house-value random-in-range 800000 1000000 ]       ;; High sugar level: value 800k–1M
  if psugar >= 4 [ set house-value random-in-range 1000000 2000000 ]     ;; Very high sugar level: premium houses, value 1M-2M
end

to process-family
  ;; Settings
  if mortgage > 0 and loan-years-left > 0 [
    let r annual-repayment-rate
    set annual-loan-repayment
      mortgage * r * ((1 + r) ^ loan-years-left) / (((1 + r) ^ loan-years-left) - 1)
  set wealth wealth - annual-loan-repayment
  set mortgage mortgage - annual-loan-repayment
  set loan-years-left loan-years-left - 1
  if mortgage <= 0 [
    set mortgage 0
    set loan-years-left 0
    set annual-loan-repayment 0
  ]
]
  set wealth wealth + income
  ;; Actions
  turtle-move
  turtle-eat
  income-change
  death-for-house
  ; visualization
  if visualization-mode = "none"      [ no-visualization ]
  if visualization-mode = "vision"    [ color-agents-by-vision ]
  if visualization-mode = "metabolism"[ color-agents-by-metabolism ]
  if visualization-mode = "wealth"    [ color-agents-by-wealth min [wealth] of families max [wealth] of families ]
end

to process-developer
  set age age + 1
  turtle-move
  turtle-eat
  death-for-developer

end

to income-change
  if age >= 20 and age <= 45 [ set income income * 1.03 ]
  if age >= 65           [ set income income * 0.8 ]
  set age age + 1
end

to depreciate-vacant-houses
  set house-value house-value * 0.98            ;; depreciate vacant houses by 2% per tick
  set house-value max list house-value 10000    ;; Prevent the house’s value from dropping below a minimum of 10k
end

to death-for-house
  if sugar <= 0 or age > max-age or wealth < 0 [
    ask houses with [ house-owner-id = [who] of myself ] [
      reset-house
    ]
    hatch 1 [ setup-families ]
    die
  ]
end

to death-for-developer
  if sugar <= 0 or age > max-age [
    hatch 1 [ setup-developers ]
    die
  ]
end

;; mark house reset on family death or foreclosure
to reset-house
  set color blue
  set house-owner-id nobody
  set vacancy-ticks 0
end

;; Vacant house update and possible removal
to process-house
  ifelse color = blue [
    set vacancy-ticks vacancy-ticks + 1
    if vacancy-ticks >= vacancy-threshold [
      set dead-count dead-count + 1
      die
    ]
  ] [
    set vacancy-ticks 0
  ]
end

;; Create new vacant houses
to replenish-vacant-houses [ n ]
  repeat n [
    let available-patches patches in-radius vision-dev with [not any? turtles-here and not any? houses-here]
    let local-houses houses-on (patches in-radius vision-dev)
    if any? available-patches [
      ask one-of available-patches [
        ;; If there are existing houses nearby, use their mean price for the new house
        if any? local-houses [
          let avg-price mean [house-value] of local-houses
          sprout-houses 1 [
            set shape "house"
            set color blue
            set size 1.8
            set house-owner-id nobody
            set vacancy-ticks 0
            set house-value avg-price   ;; set new house value to local average
          ]
        ]
        if not any? local-houses [
          sprout-houses 1 [
            create-house-on-patch
          ]
        ]
      ]
    ]
  ]
end

; Methods of movement
to turtle-move
  if breed = families [
    attempt-sell-house
    let move-candidates patches in-radius vision with [not any? families-here]
    let visible-houses houses-on move-candidates
    let unowned-houses visible-houses with [color = blue]
    ifelse any? unowned-houses [
      let target min-one-of unowned-houses [distance myself]
      let price [house-value] of target
      ifelse wealth >= price [
        complete-cash-purchase target price
      ] [
        ifelse (wealth >= price * loan-refusal-probability) and (mortgage = 0) [
          complete-mortgage-purchase target price
        ] [
          move-to-max-sugar-patch move-candidates
        ]
      ]
    ] [
      move-to-max-sugar-patch move-candidates
    ]
  ]
  if breed = developers [
    let move-candidates patches in-radius vision-dev with [not any? families-here and not any? houses-here]
    move-to-max-sugar-patch move-candidates
  ]
end

to turtle-eat ;; turtle procedure
  ;; metabolize some sugar, and eat all the sugar on the current patch
  set sugar (sugar - metabolism + psugar)
  set psugar 0
end

;; The way to move to the next patch
to move-to-max-sugar-patch [candidates]
  let possible-winners candidates with-max [psugar]
  if any? possible-winners [
    move-to min-one-of possible-winners [distance myself]
  ]
end

; Methods to the trade of houses
;; i) Sell house
;;   - Locate the house currently owned by this family (if any)
;;   - Calculate a 3% markup to determine the selling price
;;   - Search for a buyer within `vision` who can afford the asking price and does not already own a house
;;   - If a buyer is found, transfer the buyer into the house, deduct their wealth, credit the seller’s wealth,
;;     update the house’s owner ID, color, value, and increment the transaction count
;;   - Stop further actions for this turtle after a successful sale
to attempt-sell-house
  let my-house one-of houses with [house-owner-id = [who] of myself]
  if my-house != nobody [
    let price      [house-value] of my-house
    let sell-price price * 1.03
    let buyer one-of families in-radius vision with [
      self != myself
      and wealth >= sell-price
      and not any? houses with [house-owner-id = [who] of myself]
    ]
    if buyer != nobody [
      ask buyer [
        set wealth wealth - sell-price
        move-to my-house
      ]
      set wealth wealth + sell-price
      ask my-house [
        set house-owner-id [who] of buyer
        set color brown - 2
        set house-value sell-price
        set housing-transactions housing-transactions + 1
      ]
      stop
    ]
  ]
end

;; ii) Purchase houses by cash
;;   - Move the family directly into the target house
;;   - Subtract the full purchase price from the family’s wealth
;;   - Update the house’s owner ID, mark it as owned (color change), and increment the transaction count
to complete-cash-purchase [ target price ]
  move-to target
  set wealth wealth - price
  ask target [
    set color brown
    set house-owner-id [who] of myself
    set housing-transactions housing-transactions + 1
  ]
end

;; iii) Purchase houses by loan
;;   - Move the family into the target house immediately
;;   - Deduct the down-payment (fraction determined by `loan-refusal-probability`) from their wealth
;;   - Compute the loan principal (price minus down-payment)
;;   - Calculate the total repayment over the loan term with compound interest
;;   - Use the annuity formula to derive a fixed annual payment
;;   - Set the family’s `mortgage`, `annual-loan-repayment`, and `loan-years-left` accordingly
;;   - Update the house’s owner ID, mark it as owned (color change), and increment the transaction count
to complete-mortgage-purchase [ target price ]
  move-to target
  set wealth wealth - (price * loan-refusal-probability)
  let loan-amount    price * (1 - loan-refusal-probability)
  let total-repayment loan-amount * (1 + annual-repayment-rate) ^ 30
  let annual-repayment (loan-amount * annual-repayment-rate * ((1 + annual-repayment-rate) ^ 30))
                         / (((1 + annual-repayment-rate) ^ 30) - 1)
  set mortgage mortgage + total-repayment
  set annual-loan-repayment annual-repayment
  set loan-years-left 30
  ask target [
    set color brown
    set house-owner-id [who] of myself
    set housing-transactions housing-transactions + 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Utility Functions                                                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report random-in-range [low high]
  report low + random (high - low + 1)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Visualization                                                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to no-visualization
  set color red
end

to color-agents-by-vision
  set color red - (vision - 3.5)
end

to color-agents-by-metabolism
  set color red + (metabolism - 2.5)
end

to color-agents-by-wealth [minw maxw]
  set color scale-color red wealth minw maxw
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Plotting & Distribution Analysis                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to plot-housing-price
  set-current-plot "Average Housing Price Fluctuation"
  set-current-plot-pen "Average Price"
  plot mean [house-value] of houses
end

to plot-wealth-distribution
  set-current-plot "Wealth Distribution"
  clear-plot
  set-histogram-num-bars 10
  let max-wealth max [wealth] of families
  if max-wealth = 0 [ set max-wealth 1 ]
  set-plot-x-range 0 (max-wealth + 1)
  set-plot-pen-interval (max-wealth + 1) / 10
  histogram [wealth] of families
end

to plot-housing-transactions
  set-current-plot "Transaction Volume Plot"
  set-current-plot-pen "Transaction Count"
  plot housing-transactions
end

to update-lorenz-and-gini
  let wealths sort [ wealth ] of families
  let n length wealths
  if n = 0 [
    set lorenz-points []
    set gini-index 0
    stop
  ]
  let total sum wealths
  let cum 0
  set lorenz-points []
  foreach wealths [ x ->
    set cum cum + x
    set lorenz-points lput (cum / total) lorenz-points
  ]
  let S sum lorenz-points
  set gini-index 1 - 2 * ( S / n )
end

to plot-lorenz-curve
  set-current-plot "Lorenz curve"
  clear-plot
  set-plot-x-range 0 100
  set-plot-y-range 0 100
  set-current-plot-pen "equal"
  plotxy 0 0
  plotxy 100 100
  set-current-plot-pen "lorenz"
  let n length lorenz-points
  let idx 0
  foreach lorenz-points [ L ->
    set idx idx + 1
    plotxy (idx / n * 100) (L * 100)
  ]
end

to plot-gini-index
  set-current-plot "Gini index vs. time"
  set-current-plot-pen "Gini"
  plot gini-index
end
@#$#@#$#@
GRAPHICS-WINDOW
300
10
708
419
-1
-1
8.0
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
49
0
49
1
1
1
ticks
30.0

BUTTON
10
315
90
355
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
100
315
190
355
NIL
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

BUTTON
200
315
290
355
go once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

CHOOSER
10
365
290
410
visualization-mode
visualization-mode
"none" "vision" "metabolism" "wealth"
0

SLIDER
10
10
290
43
initial-population
initial-population
10
1000
30.0
10
1
NIL
HORIZONTAL

SLIDER
10
130
290
163
minimum-sugar-endowment
minimum-sugar-endowment
0
200
30.0
1
1
NIL
HORIZONTAL

PLOT
300
440
505
590
Lorenz curve
Pop %
Wealth %
0.0
100.0
0.0
100.0
false
true
"" ""
PENS
"equal" 100.0 0 -16777216 true ";; draw a straight line from lower left to upper right\nset-current-plot-pen \"equal\"\nplot 0\nplot 100" ""
"lorenz" 1.0 0 -2674135 true "" ""

PLOT
515
440
710
590
Gini index vs. time
Time
Gini
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"Gini" 1.0 0 -13345367 true "" ""

SLIDER
10
165
290
198
maximum-sugar-endowment
maximum-sugar-endowment
0
200
60.0
1
1
NIL
HORIZONTAL

SLIDER
10
80
290
113
initial-houses
initial-houses
10
1000
30.0
10
1
NIL
HORIZONTAL

PLOT
715
10
1130
220
Average Housing Price Fluctuation
NIL
NIL
0.0
200.0
0.0
50.0
true
true
"" ""
PENS
"Average Price" 1.0 0 -13345367 true "" ""

SLIDER
10
45
290
78
initial-developers
initial-developers
1
10
3.0
1
1
NIL
HORIZONTAL

PLOT
720
440
920
590
Wealth Distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"wealth" 1.0 1 -16777216 true "" "plot-wealth-distribution"

PLOT
935
440
1135
590
Transaction Volume Plot
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Transaction Count" 1.0 0 -16777216 true "" ""

SLIDER
10
270
290
303
loan-refusal-probability
loan-refusal-probability
0.3
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
10
200
290
233
vacancy-threshold
vacancy-threshold
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
10
235
290
268
annual-repayment-rate
annual-repayment-rate
0.1
0.5
0.5
0.01
1
NIL
HORIZONTAL

PLOT
715
225
1130
420
Min/Max Housing Pricing
NIL
NIL
0.0
200.0
0.0
50.0
true
true
"" ""
PENS
"Minimum Price" 1.0 0 -13840069 true "" "plot min [house-value] of houses"
"Maximum Price" 1.0 0 -2674135 true "" "plot max [house-value] of houses"

@#$#@#$#@
## WHAT IS IT?

This third model in the NetLogo Sugarscape suite implements Epstein & Axtell's Sugarscape Wealth Distribution model, as described in chapter 2 of their book Growing Artificial Societies: Social Science from the Bottom Up. It provides a ground-up simulation of inequality in wealth. Only a minority of the population have above average wealth, while most agents have wealth near the same level as the initial endowment.

The inequity of the resulting distribution can be described graphically by the Lorenz curve and quantitatively by the Gini coefficient.

## HOW IT WORKS

Each patch contains some sugar, the maximum amount of which is predetermined. At each tick, each patch regains one unit of sugar, until it reaches the maximum amount.
The amount of sugar a patch currently contains is indicated by its color; the darker the yellow, the more sugar.

At setup, agents are placed at random within the world. Each agent can only see a certain distance horizontally and vertically. At each tick, each agent will move to the nearest unoccupied location within their vision range with the most sugar, and collect all the sugar there.  If its current location has as much or more sugar than any unoccupied location it can see, it will stay put.

Agents also use (and thus lose) a certain amount of sugar each tick, based on their metabolism rates. If an agent runs out of sugar, it dies.

Each agent also has a maximum age, which is assigned randomly from the range 60 to 100 ticks.  When the agent reaches an age beyond its maximum age, it dies.

Whenever an agent dies (either from starvation or old age), a new randomly initialized agent is created somewhere in the world; hence, in this model the global population count stays constant.

## HOW TO USE IT

The INITIAL-POPULATION slider sets how many agents are in the world.

The MINIMUM-SUGAR-ENDOWMENT and MAXIMUM-SUGAR-ENDOWMENT sliders set the initial amount of sugar ("wealth") each agent has when it hatches. The actual value is randomly chosen from the given range.

Press SETUP to populate the world with agents and import the sugar map data. GO will run the simulation continuously, while GO ONCE will run one tick.

The VISUALIZATION chooser gives different visualization options and may be changed while the GO button is pressed. When NO-VISUALIZATION is selected all the agents will be red. When COLOR-AGENTS-BY-VISION is selected the agents with the longest vision will be darkest and, similarly, when COLOR-AGENTS-BY-METABOLISM is selected the agents with the lowest metabolism will be darkest.

The WEALTH-DISTRIBUTION histogram on the right shows the distribution of wealth.

The LORENZ CURVE plot shows what percent of the wealth is held by what percent of the population, and the the GINI-INDEX V. TIME plot shows a measure of the inequity of the distribution over time.  A GINI-INDEX of 0 equates to everyone having the exact same amount of wealth (collected sugar), and a GINI-INDEX of 1 equates to the most skewed wealth distribution possible, where a single person has all the sugar, and no one else has any.

## THINGS TO NOTICE

After running the model for a while, the wealth distribution histogram shows that there are many more agents with low wealth than agents with high wealth.

Some agents will have less than the minimum initial wealth (MINIMUM-SUGAR-ENDOWMENT), if the minimum initial wealth was greater than 0.

## THINGS TO TRY

How does the initial population affect the wealth distribution? How long does it take for the skewed distribution to emerge?

How is the wealth distribution affected when you change the initial endowments of wealth?

## NETLOGO FEATURES

All of the Sugarscape models create the world by using `file-read` to import data from an external file, `sugar-map.txt`. This file defines both the initial and the maximum sugar value for each patch in the world.

Since agents cannot see diagonally we cannot use `in-radius` to find the patches in the agents' vision.  Instead, we use `at-points`.

## RELATED MODELS

Other models in the NetLogo Sugarscape suite include:

* Sugarscape 1 Immediate Growback
* Sugarscape 2 Constant Growback

For more explanation of the Lorenz curve and the Gini index, see the Info tab of the Wealth Distribution model.  (That model is also based on Epstein and Axtell's Sugarscape model, but more loosely.)

## CREDITS AND REFERENCES

Epstein, J. and Axtell, R. (1996). Growing Artificial Societies: Social Science from the Bottom Up.  Washington, D.C.: Brookings Institution Press.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Li, J. and Wilensky, U. (2009).  NetLogo Sugarscape 3 Wealth Distribution model.  http://ccl.northwestern.edu/netlogo/models/Sugarscape3WealthDistribution.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2009 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2009 Cite: Li, J. -->
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
1
@#$#@#$#@
