# Antenna Functions

---

## createAntennaParametersTable.m
`Path: src\support\AntennaFunctions\createAntennaParametersTable.m`

**Description:**

This function generates a table of all possible combinations of $\theta$ and $\phi$ angles for antenna testing. The function ensures that the input angles are properly processed and sorted for efficient use in antenna measurements.

```{admonition} Input Parameters
:class: tip
- Theta      - A vector of theta angles (in degrees). The angles can range from -180 to 180.
- Phi        - A vector of phi angles (in degrees). The angles can range from -180 to 180.
```

```{admonition} Output Parameters
:class: tip
- ParametersTable - A table containing all combinations of Theta in (degrees) and Phi in (degrees).
```

---

## createAntennaResultsTable.m
`Path: src\support\AntennaFunctions\createAntennaResultsTable.m`

**Description:**

This function initializes and preallocates a results table for storing antenna test measurements. The results table is designed to hold various antenna parameters for a given number of measurements. It contains the following columns:

- Theta (deg)
- Phi (deg)
- Frequency (MHz)
- Gain (dBi)
- Return Loss (dB)
- Return Loss (deg)
- Return Loss Reference (dB)
- Return Loss Reference (deg)
- Path Loss (dB)
- Path Loss (deg)

```{admonition} Input Parameters
:class: tip
- totalMeasurements - The total number of measurements (rows) to allocate in the results table.
```

```{admonition} Output Parameters
:class: tip
- ResultsTable      - The preallocated table.
```

---

## makeAntenna3DRadiationPattern.m
`Path: src\support\AntennaFunctions\makeAntenna3DRadiationPattern.m`

**Description:**

This function generates a 3D radiation pattern plot for antennas in App Designer environments. It creates a visually informative 3D representation of radiation patterns without dependencies on internal MATLAB functions. The function: NOTES: * Theta = 0° points along positive z-axis * Theta = 90°, Phi = 0° points along positive x-axis * Theta = 90°, Phi = 90° points along positive y-axis

- Renders a 3D surface representation of radiation pattern data
- Draws reference coordinate system with x, y, z axes and plane indicators
- Creates interactive elements (data tips) for measurements
- Provides visual indicators for azimuth and elevation angles
- Supports proper scaling and normalization of magnitude data
- Magnitude should be a matrix where dimensions match the length of Phi and Theta vectors
- The function automatically normalizes the pattern for visualization
- Colors represent magnitude values according to the default jet colormap
- Coordinate system follows standard spherical conventions:

```{admonition} Input Parameters
:class: tip
- app       - App Designer application object containing the UI components
- axes      - Target UIAxes object where the pattern will be rendered
- Magnitude - Matrix of magnitude values (typically in dBi) corresponding to the pattern
- Theta     - Vector of theta angles in degrees (elevation angle, 0-180°)
- Phi       - Vector of phi angles in degrees (azimuth angle, 0-360°)
```

```{admonition} Output Parameters
:class: tip
- None. The function modifies the provided axes object directly.
```

---

## measureAntennaGain.m
`Path: src\support\AntennaFunctions\measureAntennaGain.m`

**Description:**

This function calculates the gain of a test antenna in decibels relative to an isotropic radiator (dBi). The gain is computed based on the input test frequency, S-parameters, and the spacing between the antennas. The function calculates the antenna gain using one of two methods:

- **Comparison Antenna Method**: If reference gain and frequency values are provided, the antenna gain is calculated by interpolating the reference gain at the test frequencies.
- **Two Antenna Method**: If no reference data is provided, the function assumes the test antennas are identical.

```{admonition} Input Parameters
:class: tip
- TestFrequency   - A scalar or vector of frequency values in Hz at which the antenna gain is measured.
- sParameter_dB   - A scalar or vector of S21 values (in dB), representing the magnitude of power transfer between two antennas.
- Spacing         - A scalar value representing the distance in meters between the two antennas being tested.
- ReferenceGain   - (Optional) A vector of reference antenna gain values (in dBi). Used for the Comparison Antenna Method.
- ReferenceFrequency - (Optional) A vector of frequencies (in Hz) corresponding to the reference antenna gain values.
```

```{admonition} Output Parameters
:class: tip
- antennaGain     - A vector containing the calculated antenna gain in dBi for the test antenna, at the specified test frequencies.
```

---

## measureSParameters.m
`Path: src\support\AntennaFunctions\measureSParameters.m`

**Description:**

This function measures 2-port S-parameters (S11, S21, S22) with magnitude in dB and phase in degrees using a Vector Network Analyzer (VNA). Depending on the `smoothingPercentage` input, the function reads either smoothed or raw measurement data.

- **Smoothed Data**: If smoothing is enabled (smoothingPercentage > 0), the function retrieves the smoothed magnitude and phase data.
- **Raw Data**: If smoothing is disabled (smoothingPercentage = 0), the function retrieves raw data in the form of complex S Parameters and calculates the magnitude and phase from the complex data.

```{admonition} Input Parameters
:class: tip
- VNA                 - The instrument object for the VNA, used for communication and measurement control.
- smoothingPercentage - The percentage of smoothing applied to the S-parameters data.
```

```{admonition} Output Parameters
:class: tip
- sParamdB            - A cell array containing the magnitude data (in dB) for each S-parameter.
- sParamPhase         - A cell array containing the phase data (in degrees) for each S-parameter.
- freqValues          - A vector containing the frequency sweep values (in Hz) corresponding to the S-parameters.
```

---

## plotAntenna2DRadiationPattern.m
`Path: src\support\AntennaFunctions\plotAntenna2DRadiationPattern.m`

**Description:**

This function generates and displays several 2D plots related to antenna measurements. It extracts the relevant antenna data based on user-selected $\theta$, $\phi$, and frequency values. It updates four axes in the application UI to display the following plots:

- Gain vs. Frequency at a fixed $\theta$/$\phi$ angle.
- Gain vs. Angle ($\theta$ and $\phi$ cuts) at a fixed frequency.
- Return Loss vs. Frequency at a fixed $\theta$/$\phi$ angle.
- Polar Radiation Pattern ($\theta$ and $\phi$ cuts).

```{admonition} Input Parameters
:class: tip
- app  - Application object containing the antenna measurement data and plot handles.
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## plotAntenna3DRadiationPattern.m
`Path: src\support\AntennaFunctions\plotAntenna3DRadiationPattern.m`

**Description:**

This function generates a 3D radiation pattern plot for the antenna based on the specified frequency. It creates a 3D visualization of the antenna's radiation characteristics using theta, phi, and gain values from the application data. The function:

- Extracts the antenna gain data for the selected frequency
- Processes angle data for consistent representation
- Creates a properly formatted gain matrix
- Renders the 3D radiation pattern with appropriate visual elements
- Displays appropriate error or warning messages if data is inconsistent or invalid.

```{admonition} Input Parameters
:class: tip
- app  - Application object containing the antenna measurement data and UI components.
```

```{admonition} Output Parameters
:class: tip
- None - The function updates the application's UI components directly.
```

---

## plotReferenceAntenna.m
`Path: src\support\AntennaFunctions\plotReferenceAntenna.m`

**Description:**

Plots the reference antenna's gain and return loss versus frequency, serving as a baseline for comparison with DUT (Device Under Test) measurements. The function:

- Clears existing plots for gain and return loss.
- Plots gain (dBi) vs frequency (MHz).
- Plots return loss (dB) vs frequency (MHz).
- Enhances visual appearance of plots using standardized formatting.

```{admonition} Input Parameters
:class: tip
- app - Application object containing the reference antenna measurement data and associated plot handles.
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## runAntennaMeasurement.m
`Path: src\support\AntennaFunctions\runAntennaMeasurement.m`

**Description:**

This function executes a 2D antenna gain measurement sweep using a dual-axis positioner (Theta and Phi) and a VNA. The function automates rotation, measurement, data logging, and visualization of antenna radiation patterns. The sweep is performed across a user-defined frequency range and angular grid, capturing S-parameters and calculating gain, return loss, and path loss. Data is saved to the disk and loaded into the app for plotting. Additionally the user is able to manually stop the test run from within the application. If an error occurs:

- The errors are caught, reported via the app interface, and saved to the error log.
- Positioners are safely stopped in case of interruption or failure.

```{admonition} Input Parameters
:class: tip
- app - Application object that holds hardware interfaces, user settings, UI elements, and measurement parameters.
```

```{admonition} Output Parameters
:class: tip
- None  (Results are saved to the user's machine and updated in the application UI).
```

---

## setLinearSlider.m
`Path: src\support\AntennaFunctions\setLinearSlider.m`

**Description:**

This function controls the movement of the EMCenter linear slider by setting its speed preset and moving it to a user-specified target position. Once the speed is set, the slider will move smoothly to the specified target position, ensuring precise control over the motion.

```{admonition} Input Parameters
:class: tip
- speedPreset    - An integer between 1 (slowest) and 8 (fastest) that sets the speed of the linear slider.
- targetPosition - Target position in cm (0 - 200 cm) for the slider to move to.
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## validateAntennaMeasurement.m
`Path: src\support\AntennaFunctions\validateAntennaMeasurement.m`

**Description:**

This function performs the following validation checks on the antenna test setup. If any condition is not met, the function displays an appropriate message and prompts the user to correct the configuration.

- Whether the VNA, EMCenter, and EMSlider are connected.
- Whether the start and end frequencies are specified and not equal.
- Whether the number of sweep points is defined.
- Whether the antenna's physical size is specified.
- Whether the turntable scan settings (mode, start angle, step angle, end angle) are configured.
- Whether the tower scan settings (mode, start angle, step angle, end angle) are configured.

```{admonition} Input Parameters
:class: tip
- app     - Application object containing the antenna setup configuration.
```

```{admonition} Output Parameters
:class: tip
- isValid - Logical value. `true` if the configuration is valid; otherwise, `false`.
```

