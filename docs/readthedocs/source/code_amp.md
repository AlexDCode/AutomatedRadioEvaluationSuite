# Power Amplifier Functions

---

## createPAParametersTable.m
`Path: src\support\PAFunctions\createPAParametersTable.m`

**Description:**

This function generates a complete parameter sweep table for Power Amplifier (PA) testing. It creates all possible combinations of frequency, RF input power, voltage, and current based on the sweep settings defined in the application for each active PSU channel. The resulting table is used to drive automated PA characterization across various operating conditions, it contains the following columns:

- Frequency (Hz)
- RF Input Power (dBm)
- Voltage (V) and Current (A) per active PSU channel

```{admonition} Input Parameters
:class: tip
- app - App object containing configuration parameters for frequency, RF input power, and power supply settings.
```

```{admonition} Output Parameters
:class: tip
- ParametersTable - The resulting parameters table containing all combinations of PA test settings.
```

---

## createPAResultsTable.m
`Path: src\support\PAFunctions\createPAResultsTable.m`

**Description:**

This function initializes an empty results table for Power Amplifier (PA) measurements, with columns dynamically generated based on the number of active PSU channels configured in the application. The table is pre-allocated to the specified number of measurements and channels. For n channels:

- Frequency (MHz)
- Channel 1 Voltage (V) (if n = 1)
- ...
- Channel n Voltages (V)
- RF Input Power (dBm)
- RF Output Power (dBm)
- Gain
- Channel 1 DC Power (W) (if n = 1)
- ...
- Channel n DC Power (W)
- Total DC Drain Power (W)
- Total DC Gate Power (W)
- DE (%)
- PAE (%)

```{admonition} Input Parameters
:class: tip
- app               - The app object containing configuration details, including active PSU channels.
- totalMeasurements - Total number of rows to preallocate in the results table.
```

```{admonition} Output Parameters
:class: tip
- ResultsTable      - An empty table with predefined variable names and types for storing PA test results.
```

---

## deembedPA.m
`Path: src\support\PAFunctions\deembedPA.m`

**Description:**

This function de-embeds Power Amplifier (PA) measurements by removing the effects of passive and active devices. It generates calibration factors for both the input and output of the PA, which are applied to the measured RF power values in order to obtain the corrected PA input and output RF power. The calibration factors are computed based on the selected calibration mode and available data on the app. The function supports the following calibration modes:

- **None**: No calibration is applied, and both input and output calibration factors are set to 0.
- **Fixed Attenuation**: The function directly applies the attenuation values set in the application for both input and output.
- **Small Signal**: Uses fixed attenuation values combined with interpolated Sparameters from the provided Sparameter file for both input and output.
- **Small + Large Signal**: Same behavior as **Small Signal** but also integrates driver gain data. The driver gain is interpolated based on both the test frequency and RF input power, which is then subtracted from the input calibration factor.

```{admonition} Input Parameters
:class: tip
- app            - The application object containing configuration settings and attenuation values for the PA setup.
- testFrequency  - The measurement frequency (Hz) at which the calibration and de-embedding should be performed.
- RFInputPower   - The measured RF input power (dBm) at the specified frequency.
```

```{admonition} Output Parameters
:class: tip
- inCal          - The input attenuation calibration factor (dB). Subtracts this from the input RF power to obtain the corrected PA input power.
- outCal         - The output attenuation calibration factor (dB). Adds this to the measured output power to get the corrected PA output power.
```

---

## enablePSUChannels.m
`Path: src\support\PAFunctions\enablePSUChannels.m`

**Description:**

This function enables or disables the specified channels on two power supply units (PSU A and PSU B) based on the provided state (1 for enabling, 0 for disabling). Channels are grouped by PSU (PSU A or PSU B) and then enabled or disabled accordingly. The order in which the channels are processed depends on the state: gate biases are controlled before drain supplies when enabling, and drain supplies are turned off before gate biases when disabling.

```{admonition} Input Parameters
:class: tip
- app       - The application object containing the power supplies and the channel-to-device mapping.
- channels  - A cell array of channel names (e.g., {'CH1', 'CH2'}).
- state     - Channel state (1 for enable, 0 for disable).
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## measureRFOutputandDCPower.m
`Path: src\support\PAFunctions\measureRFOutputandDCPower.m`

**Description:**

This function measures the output RF power, DC drain power, and DC gate power based on the specified input RF power and test frequency.

```{admonition} Input Parameters
:class: tip
- app            - The application object containing instrument configurations.
- frequency      - The test frequency for measurement.
```

```{admonition} Output Parameters
:class: tip
- DCDrainPower   - The DC power delivered to the drain (W).
- DCGatePower    - The DC power delivered to the gate (W).
```

---

## measureRFParameters.m
`Path: src\support\PAFunctions\measureRFParameters.m`

**Description:**

This function calculates the RF Gain, Drain Efficiency (DE), and Power Added Efficiency (PAE) based on the specified input and output RF power and the DC power supplied to the drain.

```{admonition} Output Parameters
:class: tip
- DCDrainPower    - DC power supplied to the drain (in W).
- Gain            - RF Gain (dB).
- DE              - Drain Efficiency (%).
- PAE             - Power Added Efficiency (%).
```

---

## measureRFParametersPeaks.m
`Path: src\support\PAFunctions\measureRFParametersPeaks.m`

**Description:**

This function calculates peak RF performance metrics from power amplifier (PA) measurement data, including saturation power, peak gain, peak drain efficiency (DE), peak power-added efficiency (PAE), and -1 dB and -3 dB compression points.

```{admonition} Input Parameters
:class: tip
- app     - The application object containing the PA measurement data table.
- idx     - Logical or numeric index used to filter the rows of the PA data table for analysis.
```

```{admonition} Output Parameters
:class: tip
- Psat            - Table containing the maximum RF output power (Psat) per frequency and corresponding gain.
- peakGain        - Table of peak small-signal gain values per frequency.
- peakDE          - Table of maximum drain efficiency per frequency.
- peakPAE         - Table of maximum power-added efficiency per frequency.
- compression1dB  - Table containing the -1 dB gain compression points per frequency.
- compression3dB  - Table containing the -3 dB gain compression points per frequency.
```

---

## plotPASingleMeasurement.m
`Path: src\support\PAFunctions\plotPASingleMeasurement.m`

**Description:**

This function plots gain, drain efficiency (DE), and power-added efficiency (PAE) versus RF output power for a single frequency measurement. Also overlays peak values such as Psat, -1 dB and -3 dB compression points. This function generates a dual y-axis plot:

- Left Y axis: Gain (dB)
  - Green X: Psat (saturation output power)
  - Red X: -1 dB gain compression point
  - Blue X: -3 dB gain compression point
- Right Y axis: DE and PAE (%)

```{admonition} Input Parameters
:class: tip
- app  - Application object containing PA measurement data, user-selected frequency, supply voltages, and plotting handles.
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## plotPASweepMeasurement.m
`Path: src\support\PAFunctions\plotPASweepMeasurement.m`

**Description:**

This function plots performance metrics from a frequency sweep Power Amplifier (PA) measurement, including gain, saturation power (Psat), efficiency (DE and PAE), and gain compression points (-1 dB, -3 dB). It filters the PA dataset using user-selected supply voltages and generates four annotated plots with styled axes and markers for clarity:

- Gain vs. Output Power for each frequency
- Peak Gain vs. Frequency
- Peak Drain Efficiency (DE) and PowerAdded Efficiency (PAE) vs. Frequency
- Psat, 1 dB, and 3 dB compression points vs. Frequency

```{admonition} Input Parameters
:class: tip
- app  - Application object containing PA measurement data and plotting components.
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## populatePSUChannels.m
`Path: src\support\PAFunctions\populatePSUChannels.m`

**Description:**

This function evaluates the configuration of power supply channels and identifies which channels are "filled," meaning they have complete user-defined parameters (voltage, current, etc.) and are ready for use. These filled channels are stored in the app object for future processing or interaction with the PSU units.

```{admonition} Input Parameters
:class: tip
- app   - The application object containing the channel configurations and channel-to-device mapping.
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## resetPSUChannels.m
`Path: src\support\PAFunctions\resetPSUChannels.m`

**Description:**

This function resets all power supply unit (PSU) channels to their default settings, including setting voltage and current values to 0 and configuring each channel to 'Single' mode. It also refreshes the GUI to reflect these changes and ensures the PA side of the application returns to its initial state.

```{admonition} Input Parameters
:class: tip
- app   - The application object containing the channel configurations.
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## runPAMeasurement.m
`Path: src\support\PAFunctions\runPAMeasurement.m`

**Description:**

This function performs a full RF Power Amplifier (PA) measurement sweep. On error, the instruments are safely turned off, and the error message is displayed in the app and logged to the user path. The function process includes:

- Generating test parameter combinations and initializing the output results table.
- Configuring the signal analyzer and initializing the measurement loop.
- For each test point:
  - Sets frequency and signal levels
  - Configures PSU voltages and currents
  - Measures RF output power and DC power
  - Applies calibration factors (de-embedding)
  - Calculates Gain, DE (Drain Efficiency), and PAE (Power Added Efficiency)
  - Stores results in a structured table
- Providing a progress UI with estimated time updates.
- Saving the results and loading them back into the application.

```{admonition} Input Parameters
:class: tip
- app  - Application object containing hardware interfaces, user settings, and UI components.
```

```{admonition} Output Parameters
:class: tip
- None   (Results are saved in a file and updated in the application UI).
```

---

## setPSUChannels.m
`Path: src\support\PAFunctions\setPSUChannels.m`

**Description:**

This function sets the voltage and current for a specific power supply channel based on the application's channel-to-device mapping. It determines the correct physical channel and PSU (A or B), and applies the specified settings via SCPI commands. The function handles numeric or string inputs for voltage and current values, ensuring compatibility with SCPI command formatting.

```{admonition} Input Parameters
:class: tip
- app           - App object containing power supply configurations and the channel-to-device mapping.
- deviceChannel - Logical channel name (e.g., 'CH1') as defined in the mapping structure.
- voltage       - Desired voltage for the channel (numeric or string).
- current       - Desired current limit for the channel (numeric or string).
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## validatePSUChannels.m
`Path: src\support\PAFunctions\validatePSUChannels.m`

**Description:**

This function validates PSU channel configuration based on the selected mode. It checks:

- That devices are connected.
- That the mode matches available devices.
- That enough channels are configured.
- That channel count does not exceed mode limits.

```{admonition} Input Parameters
:class: tip
- app     - App object with mode, device, and channel info
```

```{admonition} Output Parameters
:class: tip
- isValid - True if configuration is valid; otherwise false
```

