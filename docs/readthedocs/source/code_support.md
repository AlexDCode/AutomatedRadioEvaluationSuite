# Supporting Functions

---

## A2dB.m
`Path: src\support\SupportFunctions\A2dB.m`

**Description:**

The function A2dB converts magnitudes (voltage or current) to dB.

```{admonition} Input Parameters
:class: tip
- A    - Magnitude (voltage or current) in linear scale
```

```{admonition} Output Parameters
:class: tip
- AdB  - Magnitude in decibels (dB)
```

---

## dBm2W.m
`Path: src\support\SupportFunctions\dBm2W.m`

**Description:**

The function dBm2mag converts dBm to Watts (W).

```{admonition} Input Parameters
:class: tip
- PdBm - Power in (dBm)
```

```{admonition} Output Parameters
:class: tip
- P    -   Power in (W)
```

---

## extract_docs.m
`Path: src\support\SupportFunctions\extract_docs.m`

**Description:**

Extracts documentation from .m files within a given folder and writes it to a Markdown file. Designed to support ReadTheDocs/Sphinx workflows. Example usage:

- extract_docs('./src/support/AntennaFunctions/', './docs/readthedocs/source/code_antenna.md', 'Antenna Functions')
- extract_docs('./src/support/PAFunctions/', './docs/readthedocs/source/code_amp.md', 'Power Amplifier Functions')
- extract_docs('./src/support/SupportFunctions/', './docs/readthedocs/source/code_support.md', 'Supporting Functions', {'matlab2tikz'})

```{admonition} Input Parameters
:class: tip
- folder_path      - Path to folder containing .m files (recursively searched)
```

```{admonition} Output Parameters
:class: tip
- headerStr        - Header/title for the generated Markdown file
- excludedFolders  - (Optional) Cell array of subfolders to exclude (by name)
- None
```

---

## improveAxesAppearance.m
`Path: src\support\SupportFunctions\improveAxesAppearance.m`

**Description:**

This function improves the appearance of UIAxes in MATLAB App Designer. It supports enhancing single or dual Y-axis (yyaxis) plots.

```{admonition} Input Parameters
:class: tip
- axesObj        - Handle to the UIAxes object.
- 'YYAxis'       - Logical (true/false), if the plot uses yyaxis.
- 'LineThickness'- Scalar > 0, sets line thickness for plotted lines.
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## loadData.m
`Path: src\support\SupportFunctions\loadData.m`

**Description:**

This function loads data from a CSV or Excel file containing a single or sweep PA test measurement, or an Antenna test measurement.

```{admonition} Input Parameters
:class: tip
- RFcomponent  - Either 'PA', 'Antenna', or 'AntennaReference' depending on which type of measurement is being loaded.
- FileName     - The name of the file that will be loaded into the application.
```

```{admonition} Output Parameters
:class: tip
- combinedData - A struct containing all the data from each column of the loaded file.
```

---

## saveData.m
`Path: src\support\SupportFunctions\saveData.m`

**Description:**

This function saves test data to either a CSV or Excel (.xlsx) file, depending on size and user selection. If the data exceeds Excel's row/column limits, only the CSV option is offered.

```{admonition} Input Parameters
:class: tip
- combinedData  - Either a table or a cell array of measurement vectors (e.g., {frequency, gain, ...}).
- combinedNames - Cell array of variable names corresponding to the data (e.g., {'Frequency (Hz)', 'Gain (dB)', ...}).
```

```{admonition} Output Parameters
:class: tip
- fullFilename  - Full path to the saved file, or an empty string if the user cancels the save dialog.
```

---

## setupContextMenuFor3DPlot.m
`Path: src\support\SupportFunctions\setupContextMenuFor3DPlot.m`

**Description:**

This function sets up a right-click context menu for the 3D radiation pattern plot, allowing the user to export the visualization to image formats (PNG and JPG). This is particularly useful because plots rendered using the Antenna Toolbox may have limited export options or reduced visual quality by default.

```{admonition} Input Parameters
:class: tip
- app - Application object containing the 3D plot handle and export logic.
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## waitForInstrument.m
`Path: src\support\SupportFunctions\waitForInstrument.m`

**Description:**

The function waits for a connected instrument to complete its current operation by polling its status using the `*OPC?` SCPI query. This ensures that subsequent operations only proceed once the instrument is ready. The function enforces a timeout (default 15 seconds). The function:

- Starts a timer.
- Continuously queries instrument status via '*OPC?'.
- Waits between queries using appdefined delay.
- Exits if instrument reports ready (status == 1) or timeout is exceeded.

```{admonition} Input Parameters
:class: tip
- app        - Application object that provides the delay setting between polls.
- Instrument - VISA-compatible instrument object supporting '*OPC?' queries.
```

```{admonition} Output Parameters
:class: tip
- None
```

