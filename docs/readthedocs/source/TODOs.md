# TODO Items

---

## measureModulated.m
`Path: src\support\PAFunctions\measureModulated.m`

- TODO: The calibration for channel power measurements assumes a narrowband device where the losses of the signal bandwidth can be approximated to the center frequency

---

## runPAMeasurement.m
`Path: src\support\PAFunctions\runPAMeasurement.m`

- TODO: Verify if gate PSU data is saved to results table in individual PSU channel columns app Application object containing hardware interfaces user settings and UI components None (Results are saved to the users machine and updated in the application UI)

---

## cleanfigure.m
`Path: src\support\SupportFunctions\matlab2tikz\cleanfigure.m`

- TODO: 3D simplification of frontal 2D projection This requires the full transformation rather than the projection as we have to calculate the inverse transformation to project back into 3D
- TODO: If targetResolution is a scalar W and H are determined differently on different environments (octave local vs Travis) It is unclear why as this even happens if Units and Position are matching Could it be that the set(gcfUnitsInches) is not taken into consideration for Position directly after setting it

---

## matlab2tikz.m
`Path: src\support\SupportFunctions\matlab2tikz\matlab2tikz.m`

- TODO fix for octave
- TODO: could move this check into drawHggroup Need to verify how hgtransform behaves though (priority LOW)
- TODO: use proper grid ordering
- TODO: deal with axis image axis square etc (540)
- TODO: translate the style of tick labels fully (font weight )
- TODO Dont hardcode 10 but extract from parent axes of h
- TODO: First increment the counter then use it such that the pattern is the same everywhere
- TODO: scale maxChunkLength with the number of columns in the data array
- TODO: is the above crcr compatible with pgfplots 112 TODO: is a patch table externalizable
- TODO: this function can probably be split further just look at all those parameters being passed
- TODO: probably this should be integrated with getAndCheckDefault etc
- TODO: is this dead code
- TODO: write a drawArrow() Handle all info info directly without using handleAllChildren() since HG2 does not have children (so no shortcut) It would be good if drawArrow() was callable on a matlabgraphicsshapeTextArrow object to draw the arrow part
- TODO: rewrite drawTextarrow Handle all info info directly without using handleAllChildren() since HG2 does not have children (so no shortcut) as used for scribetextarrow
- TODO: remove grids in spectrogram by either removing grid command or adding: gridnone fromin axis options handling of huge data amounts in LaTeX
- TODO: size of the box (eg using node attributes minimum width height) Alignment of the resized box
- TODO handle Curvature 08 04
- TODO: check against getMarkerOptions() for duplicated code
- TODO: we need to set the scatter source
- TODO Get this in order as soon as Pgfplots can do scatter rgb See eg http:texstackexchangecomquestions197270 and 433
- TODO: warn the user about this It is not currently supported
- TODO Hm cant deal with this m2t col rgb2colorliteral(m2t cData(k:)) str strcat(str sprintf( sn col))
- TODO Get rid of code duplication with drawAxes
- TODO Get rid of code duplication with drawAxes
- TODO: wait for pgfplots to implement other base values (see 438)
- TODO Get rid of code duplication with drawAxes
- TODO: shouldnt this be addplot table instead
- TODO: handle baseplane with stem3()
- TODO: account for hgtransform
- TODO: scale the arrows more rigorously to match MATLAB behavior Currently this is quite hard to do since the size of the arrows is defined in pgfplots in absolute units (here we specify that those should be scaled updown according to the data) while the data itself is in axis coordinates (or some scaled variant) Ie we need the physical dimensions of the axis to compute the correct scaling There is a MaxHeadSize property that plays a role MaxHeadSize is said to be relative to the length of the quiver in the MATLAB documentation However in practice there seems to be a SQRT involved somewhere (eg if u2 v2 2 all MHS values 1sqrt(2) are capped to 1sqrt(2)) NOTE: set(h MaxHeadSize) is bugged in HG1 (not in HG2 or Octave) according to http:wwwmathworkscommatlabcentralanswers96754
- TODO HG2: colorbar ticks and colorbar tick labels
- TODO move to top
- TODO: just pass out the lStyle instead of legendOpts
- TODO: Implement these The position could be determined by means of Position andor OuterPosition of the legend handle in fact this could be made a general principle for all legend placements
- TODO: shouldnt this include units
- TODO: check if relevant Axes or all Axes are better

---

## formatWhitespace.m
`Path: src\support\SupportFunctions\matlab2tikz\dev\formatWhitespace.m`

- TODO: open file if it isnt open in the editor already

---

## getEnvironment.m
`Path: src\support\SupportFunctions\matlab2tikz\private\getEnvironment.m`

- TODO: Unify private getEnvironment functions

