# App Overview

---

##  Internal Architecture – PA Measurement Flow

```{image} ./assets/PA/PAInternalArch.png
:alt: PA Code Internal Architecture 
:class: bg-primary
:width: 100%
:align: center
```

This diagram was generated using MATLAB's Dependency Analyzer and shows the internal function call structure for the Power Amplifier (PA) module in ARES.

At the top level, `ARES.mlapp` connects to the main controller functions, like:

* `runPAmeasurement.m`: The central function for a PA test.
* `validatePSUChannels.m` and `populatePSUChannels.m`: Used to configure the power supplies.
* `loadData.m`: Handles importing previously saved measurements.

From there, the process branches into:

* **DC supply handling**: `enablePSUChannels.m`, `setPSUChannels.m`
* **Data preparation**: `createPAParametersTable.m`, `createPAResultsTable.m`
* **Data capture and analysis**: `measureRFParameters.m`, `measureRFParametersPeaks`,`measureRFOutputandDCPower.m`, and `deembedPA.m` 
* **Plotting and visualization**: `plotPASingleMeasurement.m`, `plotPASweepMeasurement.m`, and `plotPADCMeasurement.m`
* **Plot enhancements**: `improveAxesAppearance.m`

All results are ultimately passed to `saveData.m`.

##  Internal Architecture – Antenna Measurement Flow

```{image} ./assets/Ant/AntennaInternalArch.png
:alt: Antenna Code Internal Architecture 
:class: bg-primary
:width: 100%
:align: center
```

This diagram was generated using MATLAB's Dependency Analyzer and shows the internal function call structure for the Antenna module in ARES.

At the top level, `ARES.mlapp` connects to the main controller functions, like:

* `runAntennaMeasurement.m`: The central function for an antenna test.
* `validateAntennaMeasurement`: Used to validate the measurement parameters before running the test.
* `loadData.m`: Handles importing previously saved measurements.

From there, the process branches into:

* **Data preparation**: `createAntennaParametersTable.m`, `createAntennaResultsTable.m`
* **Data capture and analysis**: `measureAntennaGain.m`, `measureSParameters`
* **Plotting and visualization**: `plotReferenceAntenna.m`, `plotAntenna2DRadiationPattern.m`, `createAntenna3DRadiationPattern`, and `plotAntenna3DRadiationPattern.m`
* **Plot enhancements**: `improveAxesAppearance.m`, `setupContextMenuFor3DPlot.m`

All results are ultimately passed to `saveData.m`.




