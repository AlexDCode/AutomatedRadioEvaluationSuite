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

This function initializes and preallocates a results table for storing antenna test measurements. The results table is designed to hold various antenna parameters for a given number of measurements. It contains the following columns:

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

This function calculates the gain of a test antenna in decibels relative to an isotropic radiator (dBi). The gain is computed based on the input test frequency, S-parameters, and the spacing between the antennas. The function calculates the antenna gain using one of two methods:

- **Comparison Antenna Method**: If reference gain and frequency values are provided, the antenna gain is calculated by interpolating the reference gain at the test frequencies.
- **Two-Antenna Method**: If no reference data is provided, the function assumes the test antennas are identical.

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

This function measures 2-port S-parameters (S11, S21, S22) with magnitude in dB and phase in degrees using a Vector Network Analyzer (VNA). Depending on the `smoothingPercentage` input, the function reads either smoothed or raw measurement data.

- **Smoothed Data**: If smoothing is enabled (smoothingPercentage > 0), the function retrieves the smoothed magnitude and phase data.
- **Raw Data**: If smoothing is disabled (smoothingPercentage == 0), the function retrieves raw data in the form of complex S-parameters and calculates the magnitude and phase from the complex data.

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

This function generates and displays several 2D plots related to antenna measurements. It extracts the relevant antenna data based on user-selected θ, φ, and frequency values. It updates four axes in the application UI to display the following plots:

- Gain vs. Frequency at a fixed theta/phi angle.
- Gain vs. Angle (both θ and φ cuts) at a fixed frequency.
- Return Loss vs. Frequency at a fixed θ/φ angle.
- Polar Radiation Pattern (θ and φ cuts).

```{admonition} Input
:class: note

- app  - Application object containing the antenna measurement data and plot handles.
```

## plotAntenna3DRadiationPattern.m
`File path: src\support\AntennaFunctions\plotAntenna3DRadiationPattern.m`

**DESCRIPTION:**

This function generates a 3D radiation pattern plot for the antenna based on the specified frequency. It uses the Antenna Toolbox's internal spherical renderer to plot a 3D radiation pattern based on theta, phi, and gain values in the application UI. The function:

- Extracts the antenna gain data for the specified frequency.
- Ensures consistency in angle data (handling edge cases like -180 and 180 degrees).
- Creates and displays the 3D radiation pattern plot.
- Displays appropriate error or warning messages if data is inconsistent or invalid.

```{admonition} Input
:class: note

- app  - Application object containing the antenna measurement data and plot handles.
```

## plotReferenceAntenna.m
`File path: src\support\AntennaFunctions\plotReferenceAntenna.m`

**DESCRIPTION:**

Plots the reference antenna's gain and return loss versus frequency, serving as a baseline for comparison with DUT (Device Under Test) measurements. The function does the following:

- Clears existing plots for gain and return loss.
- Plots gain (dBi) vs frequency (MHz) for the reference antenna.
- Plots return loss (dB) vs frequency (MHz).
- Enhances visual appearance of plots using standardized formatting.

```{admonition} Input
:class: note

- app - Application object containing the reference antenna measurement data and associated plot handles.
```

```{admonition} Output
:class: note

- None
```

## runAntennaMeasurement.m
`File path: src\support\AntennaFunctions\runAntennaMeasurement.m`

**DESCRIPTION:**

Executes a full 2D antenna gain measurement sweep using a dual-axis positioner (Theta and Phi) and a VNA. The function automates rotation, measurement, data logging, and visualization of antenna radiation patterns. The sweep is performed across a user-defined frequency range and angular grid, capturing S-parameters and calculating gain, return loss, and path loss. Data is saved to disk and loaded into the app for plotting.

```{admonition} Input
:class: note

- app - Application object that holds hardware interfaces, user settings, UI elements, and measurement parameters.
- PROCESS OVERVIEW:
- 1. Extracts sweep settings from the UI (frequency, angles, speeds).
- 2. Generates a grid of measurement points (Theta, Phi).
- 3. For each position:
- - Rotates table and tower to target angles
- - Waits for motors to finish
- - Aborts early if user requests stop
- - Measures S-parameters via VNA
- - Computes antenna gain
- - Stores measurement data (gain, return loss, path loss)
- 4. Returns positioners to 0° after sweep
- 5. If completed:
- - Saves data to disk
- - Loads results into app
- - Plots 2D radiation pattern
- ERROR HANDLING:
- - Errors are caught and reported via the app interface.
- - Positioners are safely stopped in case of interruption or failure.
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

