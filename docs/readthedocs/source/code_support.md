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

This function improves the appearance of UIAxes in MATLAB App Designer. It supports enhancing single or dual Y-axis (yyaxis) plots.

```{admonition} Input
:class: note

- axesObj        - Handle to the UIAxes object.
- 'YYAxis'       - Logical (true/false), if the plot uses yyaxis.
- 'LineThickness'- Scalar > 0, sets line thickness for plotted lines.
```

```{admonition} Output
:class: note

- None
```

## loadData.m
`File path: src\support\SupportFunctions\loadData.m`

**DESCRIPTION:**

This function loads data from a CSV or Excel file containing a single or sweep PA test measurement, or an Antenna test measurement.

```{admonition} Input
:class: note

- RFcomponent  - Either 'PA', 'Antenna', or 'AntennaReference' depending on which type of measurement is being loaded.
- FileName     - The name of the file that will be loaded into the application.
```

```{admonition} Output
:class: note

- combinedData - A struct containing all the data from each column of the loaded file.
```

## saveData.m
`File path: src\support\SupportFunctions\saveData.m`

**DESCRIPTION:**

This function saves test data to either a CSV or Excel (.xlsx) file, depending on size and user selection. If the data exceeds Excel's row/column limits, only the CSV option is offered.

```{admonition} Input
:class: note

- combinedData  - Either a table or a cell array of measurement vectors (e.g., {frequency, gain, ...}).
- combinedNames - Cell array of variable names corresponding to the data (e.g., {'Frequency (Hz)', 'Gain (dB)', ...}).
```

```{admonition} Output
:class: note

- fullFilename  - Full path to the saved file, or an empty string if the user cancels the save dialog.
```

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

