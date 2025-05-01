# Antenna Functions

## createAntennaParametersTable.m
`File path: src\support\AntennaFunctions\createAntennaParametersTable.m`

**DESCRIPTION:**

This function generates a table of all possible combinations of Theta and Phi angles for antenna testing. The function ensures that the input angles are properly processed and sorted for efficient use in antenna measurements.

```{admonition} Input
:class: note

- Theta      - A vector of theta angles (in degrees). The angles can range from -180 to 180.
- Phi        - A vector of phi angles (in degrees). The angles can range from -180 to 180.
```

```{admonition} Output
:class: note

- ParametersTable - A table containing all combinations of Theta in (degrees) and Phi in (degrees).
```

## createAntennaResultsTable.m
`File path: src\support\AntennaFunctions\createAntennaResultsTable.m`

**DESCRIPTION:**

This function initializes and preallocates a results table for storing antenna test measurements. The results table is designed to hold various antenna parameters for a given number of measurements. It contains the following columns.

- Theta (deg): The theta angle in degrees.
- Phi (deg): The phi angle in degrees.
- Frequency (MHz): The frequency in MHz.
- Gain (dBi): The gain in decibels isotropic (dBi).
- Return Loss (dB): The return loss in decibels.
- Return Loss (deg): The return loss in degrees.
- Return Loss Reference (dB): The reference return loss in decibels.
- Return Loss Reference (deg): The reference return loss in degrees.
- Path Loss (dB): The path loss in decibels.
- Path Loss (deg): The path loss in degrees.

```{admonition} Input
:class: note

- totalMeasurements - The total number of measurements (rows) to allocate in the results table.
```

```{admonition} Output
:class: note

- ResultsTable      - The preallocated table.
```

## measureAntennaGain.m
`File path: src\support\AntennaFunctions\measureAntennaGain.m`

**DESCRIPTION:**

This function calculates the gain of a test antenna in decibels relative to an isotropic radiator (dBi). The gain is computed based on the input test frequency, S-parameters, and the spacing between the antennas. The function calculates the antenna gain using one of two methods: values with the free-space path loss (FSPL) and interpolating the reference gain at the test frequencies. Friss Equation (adjusted by FSPL).

- **Comparison Antenna Method**: If reference gain and frequency values are provided, the antenna gain is calculated by adjusting the S-parameter
- **Two-Antenna Method**: If no reference data is provided, the function assumes the test antennas are identical and calculates the gain using the

```{admonition} Input
:class: note

- TestFrequency   - A scalar or vector of frequency values in Hz at which the antenna gain is measured.
- sParameter_dB   - A scalar or vector of S21 values (in dB), representing the magnitude of power transfer between two antennas.
- Spacing         - A scalar value representing the distance in meters between the two antennas being tested.
- ReferenceGain   - (Optional) A vector of reference antenna gain values (in dBi). Used for the Comparison Antenna Method.
- ReferenceFrequency - (Optional) A vector of frequencies (in Hz) corresponding to the reference antenna gain values.
```

```{admonition} Output
:class: note

- antennaGain     - A vector containing the calculated antenna gain in dBi for the test antenna, at the specified test frequencies.
```

## measureSParameters.m
`File path: src\support\AntennaFunctions\measureSParameters.m`

**DESCRIPTION:**

This function measures 2-port S-parameters (S11, S21, S22) with magnitude in dB and phase in degrees using a Vector Network Analyzer (VNA). Depending on the `smoothingPercentage` input, the function reads either smoothed or raw measurement data. magnitude and phase data (using `FDATA`). of complex S-parameters (using `SDATA`) and calculates the magnitude and phase from the complex data.

- **Smoothed Data**: If smoothing is enabled (smoothingPercentage > 0), the function retrieves the smoothed
- **Raw Data**: If smoothing is disabled (smoothingPercentage == 0), the function retrieves raw data in the form

```{admonition} Input
:class: note

- VNA                 - The instrument object for the VNA, used for communication and measurement control.
- smoothingPercentage - The percentage of smoothing applied to the S-parameters data.
```

```{admonition} Output
:class: note

- sParamdB            - A cell array containing the magnitude data (in dB) for each S-parameter.
- sParamPhase         - A cell array containing the phase data (in degrees) for each S-parameter.
- freqValues          - A vector containing the frequency sweep values (in Hz) corresponding to the S-parameters.
```

## plotAntenna2DRadiationPattern.m
`File path: src\support\AntennaFunctions\plotAntenna2DRadiationPattern.m`

**DESCRIPTION:**

This function plots the 2D antenna measurement data:

- Gain vs. Frequency at a fixed theta/phi angle
- Gain vs. Angle at a fixed frequency
- Return Loss vs. Frequency
- 2D polar radiation pattern (θ and φ cuts)

```{admonition} Input
:class: note

- app  - Application object containing antenna data and plot handles.
- This function:
- - Extracts data based on selected θ, φ, and frequency values
- - Updates four app axes with corresponding gain and return loss
- - Enhances axes visuals using helper formatting functions
- - Catches and displays errors using the app's error handler
```

## plotAntenna3DRadiationPattern.m
`File path: src\support\AntennaFunctions\plotAntenna3DRadiationPattern.m`

**DESCRIPTION:**

This function plots the 3D antenna radiation pattern for a given frequency: for polar axes.

- 3D Radiation Pattern based on theta, phi, and magnitude values.
- The plot uses the Antenna Toolbox's internal spherical renderer

```{admonition} Input
:class: note

- app  - Application object containing antenna data and plot handles.
- This function:
- - Extracts gain data based on the selected frequency
- - Ensures the angle data is consistent
- - Creates a 3D radiation pattern plot
- - Enhances axes visuals using helper formatting functions
- - Catches and displays errors using the app's error handler
```

## plotReferenceAntenna.m
`File path: src\support\AntennaFunctions\plotReferenceAntenna.m`

**DESCRIPTION:**

This function plots the gain and return loss characteristics of the reference antenna over frequency. Used as a baseline for comparison with DUT measurements.

```{admonition} Input
:class: note

- app - Application object containing the reference antenna data and plot handles.
- The function performs the following actions:
- - Clears the existing Gain vs Frequency and Return Loss plots
- - Plots the reference antenna gain in (dBi) over frequency in (MHz)
- - Plots the return loss in (dB) over frequency in (MHz)
- - Enhances plot appearance using a standardized format
```

## runAntennaMeasurement.m
`File path: src\support\AntennaFunctions\runAntennaMeasurement.m`

**DESCRIPTION:**

This function executes a full antenna gain measurement sweep by controlling a dual-axis positioner (Theta and Phi) and capturing RF gain and return loss data from a VNA across a defined frequency range.

```{admonition} Input
:class: note

- app   - Application object containing the hardware interfaces, user-defined settings, UI components, and other setup parameters.
```

```{admonition} Output
:class: note

- None
- PROCESS OVERVIEW:
- 1. Initializes sweep parameters based on UI input:
- - Frequency range and sweep points
- - Theta and Phi angle vectors
- 2. Generates a parameter sweep table for all Theta/Phi
- combinations.
- 3. For each test position:
- - Rotates the table and tower to the specified angles
- - Waits for motors to finish moving
- - Checks for user stop request
- - Measures S-parameters using the VNA
- - Calculates antenna gain
- - Stores results: frequency, gain, return loss, path loss
- 4. Returns the positioners to 0°.
- 5. If not stopped by the user:
- - Saves results to disk
- - Loads data back into the app
- - Plots the 2D antenna gain measurement
- ERROR HANDLING:
- Any error is caught and displayed via the app interface.
- Positioners are stopped safely on user interruption or error.
```

## setLinearSlider.m
`File path: src\support\AntennaFunctions\setLinearSlider.m`

**DESCRIPTION:**

This function controls the movement of the EMCenter linear slider by setting its speed preset and moving it to a user-specified target position. Once the speed is set, the slider will move smoothly to the specified target position, ensuring precise control over the motion.

```{admonition} Input
:class: note

- speedPreset    - An integer between 1 (slowest) and 8 (fastest) that sets the speed of the linear slider.
- targetPosition - Target position in cm (0 - 200 cm) for the slider to move to.
```

## validateAntennaMeasurement.m
`File path: src\support\AntennaFunctions\validateAntennaMeasurement.m`

**DESCRIPTION:**

This function performs the following validation checks on the antenna test setup. If any condition is not met, the function displays an appropriate message and prompts the user to correct the configuration.

- Whether the VNA, EMCenter, and EMSlider are connected.
- Whether the start and end frequencies are specified and not equal.
- Whether the number of sweep points is defined.
- Whether the antenna's physical size is specified.
- Whether the turntable scan settings (mode, start angle, step angle, end angle) are configured.
- Whether the tower scan settings (mode, start angle, step angle, end angle) are configured.

```{admonition} Input
:class: note

- app     - Application object containing the antenna setup configuration.
```

```{admonition} Output
:class: note

- isValid - Logical value. `true` if the configuration is valid; otherwise, `false`.
```

