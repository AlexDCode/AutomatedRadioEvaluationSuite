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

* `runPAmeasurement.m`: The central orchestrator for a full PA test
* `validatePSUChannels.m` and `populatePSUChannels.m`: Used for configuring the power supplies
* `loadData.m`: Handles importing previously saved sessions

From there, the process branches into:

* **DC supply handling**: `enablePSUChannels.m`, `setPSUChannels.m`
* **Data preparation**: `createPAParametersTable.m`, `createPAResultsTable.m`
* **Data capture and analysis**: `measureRFParameters.m`, `measureRFParametersPeaks`,`measureRFOutputandDCPower.m`, and `deembedPA.m`, 
* **Plotting and visualization**: `plotPASingleMeasurement.m`, `plotPASweepMeasurement.m`, and `plotPADCMeasurement.m`

All results are ultimately passed to `saveData.m`.

##  Internal Architecture – Antenna Measurement Flow

```{image} ./assets/Ant/AntennaInternalArch.png
:alt: Antenna Code Internal Architecture 
:class: bg-primary
:width: 100%
:align: center
```

This diagram was generated using MATLAB's Dependency Analyzer and shows the internal function call structure for the Antenna module in ARES.




