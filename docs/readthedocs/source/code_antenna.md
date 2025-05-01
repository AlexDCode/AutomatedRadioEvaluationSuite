# Antenna Functions

## createAntennaParametersTable.m
`File path: src\support\AntennaFunctions\createAntennaParametersTable.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This function creates a parameter sweep table for antenna testing, generating all possible combinations of Theta and Phi.


```{admonition} Input
:class: note

- Theta      - Vector of theta angles (in degrees).
- Phi        - Vector of phi angles (in degrees).
- 
```

```{admonition} Output
:class: note

- paramTable - A table containing all combinations of Theta in (degrees) and Phi in (degrees).
- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
- 
```

## createAntennaResultsTable.m
`File path: src\support\AntennaFunctions\createAntennaResultsTable.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This function initializes the results table for storing
antenna test measurements.


```{admonition} Input
:class: note

- totalMeasurements: Number of measurements (rows) to allocate
- 
```

```{admonition} Output
:class: note

- ResultsTable: Preallocated table with the following columns:
- - Theta (deg)
- - Phi (deg)
- - Frequency (MHz)
- - Gain (dBi)
- - Return Loss (dB)
- - Return Loss (deg)
- - Return Loss Reference (dB)
- - Return Loss Reference (deg)
- - Path Loss (dB)
- - Path Loss (deg)
- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
- 
```

## measureAntennaGain.m
`File path: src\support\AntennaFunctions\measureAntennaGain.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This function calculates the gain of a test antenna in decibels
relative to an isotropic radiator (dBi) based on the input frequency,
S-parameters, and spacing between the antennas. The function offers
two ways of calculating antenna gain. If both test antennas are
identical the function uses the Two-Antenna method (Friss Equation),
else the Comparison Antenna Method is used, using the provided
reference gain and frequency.

INPUT PARAMETERS
TestFrequency:  A scalar or vector of frequency values in (Hz) at
which the antenna gain is measured.
sParameter_dB:  A scalar or vector of S21 in (dB) values
representing the magnitude of power transfer
between two antennas.
Spacing:        A scalar, the distance in (m) between the two
antennas being tested.
RefGain:        A vector containing the reference antenna gain.
RefFreq:        A vector containing the reference frequencies.

OUTPUT PARAMETERS
antennaGain:    Vector containing the antenna gain in (dBi) of the
test antenna.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


## measureSParameters.m
`File path: src\support\AntennaFunctions\measureSParameters.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Measure 2-port S-Parameters (Magnitude in dB and Phase in degrees)
Supports smoothed or raw measurements using FDATA/SDATA.

INPUTS:
VNA                - Instrument object for the VNA
smoothingPercentage - Percentage smoothing aperture (0 = off)

OUTPUTS:
sParameters_dB     - Cell array of magnitude data (in dB)
sParameters_Phase  - Cell array of phase data (in degrees)
freqValues         - Frequency sweep values (Hz)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


## plotAntenna2DRadiationPattern.m
`File path: src\support\AntennaFunctions\plotAntenna2DRadiationPattern.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This function plots the 2D antenna measurement data:
- Gain vs. Frequency at a fixed theta/phi angle
- Gain vs. Angle at a fixed frequency
- Return Loss vs. Frequency
- 2D polar radiation pattern (θ and φ cuts)

INPUT PARAMETERS:
app:  Application object containing antenna data and plot handles.

This function:
- Extracts data based on selected θ, φ, and frequency values
- Updates four app axes with corresponding gain and return loss
- Enhances axes visuals using helper formatting functions
- Catches and displays errors using the app's error handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


## plotAntenna3DRadiationPattern.m
`File path: src\support\AntennaFunctions\plotAntenna3DRadiationPattern.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This function plots the 3D antenna radiation pattern for a given
frequency:
- 3D Radiation Pattern based on theta, phi, and magnitude values.
- The plot uses the Antenna Toolbox's internal spherical renderer
for polar axes.

INPUT PARAMETERS:
app: Application object containing antenna data and plot handles.

This function:
- Extracts gain data based on the selected frequency
- Ensures the angle data is consistent
- Creates a 3D radiation pattern plot
- Enhances axes visuals using helper formatting functions
- Catches and displays errors using the app's error handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


## plotReferenceAntenna.m
`File path: src\support\AntennaFunctions\plotReferenceAntenna.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This function plots the gain and return loss characteristics of
the reference antenna over frequency. Used as a baseline for
comparison with DUT measurements.

INPUT PARAMETERS:
app:  Application object containing the reference antenna data and
plot handles.

The function performs the following actions:
- Clears the existing Gain vs Frequency and Return Loss plots
- Plots the reference antenna gain in (dBi) over frequency in (MHz)
- Plots the return loss in (dB) over frequency in (MHz)
- Enhances plot appearance using a standardized format
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


## runAntennaMeasurement.m
`File path: src\support\AntennaFunctions\runAntennaMeasurement.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This function executes a full antenna gain measurement sweep by
controlling a dual-axis positioner (Theta and Phi) and capturing RF
gain and return loss data from a VNA across a defined frequency
range.

INPUT PARAMETERS:
app:  Application object containing: hardware interfaces,
user-defined settings, UI components, and other setup parameters.

PROCESS OVERVIEW:
1. Initializes sweep parameters based on UI input:
- Frequency range and sweep points
- Theta and Phi angle vectors
2. Generates a parameter sweep table for all Theta/Phi
combinations.
3. For each test position:
- Rotates the table and tower to the specified angles
- Waits for motors to finish moving
- Checks for user stop request
- Measures S-parameters using the VNA
- Calculates antenna gain
- Stores results: frequency, gain, return loss, path loss
4. Returns the positioners to 0°.
5. If not stopped by the user:
- Saves results to disk
- Loads data back into the app
- Plots the 2D antenna gain measurement

OUTPUT PARAMETERS:
None

ERROR HANDLING:
Any error is caught and displayed via the app interface.
Positioners are stopped safely on user interruption or error.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


## setLinearSlider.m
`File path: src\support\AntennaFunctions\setLinearSlider.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This function sets the speed preset of the linear slider, and moves
it to the target position specified by the user.

INPUT PARAMETERS
speedPreset:    Takes integers [1,8] with 8 the maximum speed and 1
the minimum speed
targetPosition: Position to move linear slider into.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


## validateAntennaMeasurement.m
`File path: src\support\AntennaFunctions\validateAntennaMeasurement.m`

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
This function validates the configuration of antenna test setup
settings based on the user's inputs.

It checks for the following conditions:
- Whether the VNA, EMCenter, EMSlider are connected.
- Whether the start and end frequencies are set and different.
- Whether the number of sweep points is set.
- Whether the antenna physical size is specified.
- Whether the turntable settings (scan mode, start angle, step
angle, end angle) are configured.
- Whether the tower settings (scan mode, start angle, step angle,
end angle) are configured.

If any of these conditions fail, the function will display
appropriate messages and prompt the user to correct the
configuration.

INSTRUMENTS
Vector Network Analyzer: PNA-L N5232B
EMCenter
EMSlider

INPUT PARAMETERS
app:       The application object containing the antenna setup
configuration and associated parameters.

OUTPUT PARAMETERS
isValid:   A boolean value indicating whether the antenna setup
configuration is valid (true) or not (false).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


