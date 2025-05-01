## A2dB.m
`File path: src\support\SupportFunctions\A2dB.m`

**DESCRIPTION:**

The function A2dB converts magnitudes (voltage or current) to dB.

```{admonition} Input
:class: note

- A    - Magnitude (voltage or current) in linear scale
```

```{admonition} Output
:class: note

- AdB  - Magnitude in decibels (dB)
```

## dBm2W.m
`File path: src\support\SupportFunctions\dBm2W.m`

**DESCRIPTION:**

The function dBm2mag converts dBm to Watts (W).

```{admonition} Input
:class: note

- PdBm - Power in (dBm)
```

```{admonition} Output
:class: note

- P    -   Power in (W)
```

## extract_docs.m
`File path: src\support\SupportFunctions\extract_docs.m`

**DESCRIPTION:**

EXTRACT_DOCS Extracts help comments from all .m files in a folder. extract_docs('path/to/your/folder', 'path/to/your/outputfile', 'Header String')

## improveAxesAppearance.m
`File path: src\support\SupportFunctions\improveAxesAppearance.m`

**DESCRIPTION:**

This function improves the appearance of axes in MATLAB App Designer, handles plots containing two graphs one on the left y axis and the other on the right y axis, sharing the same x axis. INPUT PARAMETERS axesObj:       Handle to the UIAxes object. varargin:      Optional name-value pairs for 'YYAxis', 'LineWidth'. YYAxis:        Boolean flag, to handle plots with graphs on the left and right y axis, sharing the same x axis. LineThickness: Positive numeric scalar, to handle the thickness.

## loadData.m
`File path: src\support\SupportFunctions\loadData.m`

**DESCRIPTION:**

This function loads data in from a CSV or Excel file containing a single or sweep PA test measurement, or an Antenna test measurement. PARAMETERS RFcomponenet: Either 'PA' or 'Antenna' depending on which type of measurement is being loaded. FileName:     The name of the file that will be loaded into the application. RETURNS combinedData: A struct containing all the data from each column of the loaded file. User can acces specific data by accesing the array's fields.

## saveData.m
`File path: src\support\SupportFunctions\saveData.m`

**DESCRIPTION:**

This function saves data from the application into either a CSV or Excel file. The user passes in the combined test data and combined test variable names, the function saves and organizes the data. PARAMETERS combinedData:  Cell array containing the data for all measurement variables. Example: {testFrequency, testGain, ...} combinedNames: Cell array containing the titles of the measurement variables. Example: {'Frequency Hz', 'Gain dB', ...}

## setupContextMenuFor3DPlot.m
`File path: src\support\SupportFunctions\setupContextMenuFor3DPlot.m`

**DESCRIPTION:**

This function sets up a right-click context menu for the 3D radiation pattern plot, allowing the user to export the visualization to image formats (PNG and JPG). This is particularly useful because plots rendered using the Antenna Toolbox may have limited export options or reduced visual quality by default.

```{admonition} Input
:class: note

- app - Application object containing the 3D plot handle and export logic.
```

```{admonition} Output
:class: note

- None
```

## waitForInstrument.m
`File path: src\support\SupportFunctions\waitForInstrument.m`

**DESCRIPTION:**

The function waits for a connected instrument to complete its current operation by polling its status using the `*OPC?` SCPI query. This ensures that subsequent operations only proceed once the instrument is ready. The function enforces a timeout (default 15 seconds). The function:

- Starts a timer.
- Continuously queries instrument status via '*OPC?'.
- Waits between queries using app-defined delay.
- Exits if instrument reports ready (status == 1) or timeout is exceeded.

```{admonition} Input
:class: note

- app        - Application object that provides the delay setting between polls.
- Instrument - VISA-compatible instrument object supporting '*OPC?' queries.
```

```{admonition} Output
:class: note

- None
```

