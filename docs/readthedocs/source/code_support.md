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

## P2dB.m
`Path: src\support\SupportFunctions\P2dB.m`

**Description:**

The function P2dB converts magnitudes (power) to dB.

```{admonition} Input Parameters
:class: tip
- P    - Magnitude (power) in linear scale
```

```{admonition} Output Parameters
:class: tip
- PdB  - Magnitude in decibels (dB)
```

---

## addLineAndLegendContextMenu.m
`Path: src\support\SupportFunctions\addLineAndLegendContextMenu.m`

**Description:**

Add context menu to both lines and corresponding legend items hLine: array of line handles hLegend: handle to legend

---

## addLineContextMenu.m
`Path: src\support\SupportFunctions\addLineContextMenu.m`

**Description:**

addLineContextMenu Adds a right-click context menu to a line object. hLine: handle to the line or array of line objects.

---

## dB2A.m
`Path: src\support\SupportFunctions\dB2A.m`

**Description:**

The function dB2A converts dB to magnitudes (voltage or current)

```{admonition} Input Parameters
:class: tip
- dB    - A scalar of vector of magnitudes in dB
```

```{admonition} Output Parameters
:class: tip
- dBA   - A scalar or vector of magnitudes (voltage or current) in linear scale
```

---

## dB2P.m
`Path: src\support\SupportFunctions\dB2P.m`

**Description:**

The function dB2P converts dB to magnitudes (power)

```{admonition} Input Parameters
:class: tip
- dB  - A scalar of vector of magnitudes in dB
```

```{admonition} Output Parameters
:class: tip
- P   - A scalar or vector of magnitudes (power) in linear scale
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

## detectPAMeasurementType.m
`Path: src\support\SupportFunctions\detectPAMeasurementType.m`

**Description:**

Define keyword groups

---

## enableLegendToggle.m
`Path: src\support\SupportFunctions\enableLegendToggle.m`

**Description:**

This function enables interactive toggling of plot visibility through the figure legend. When enabled, clicking on any legend entry will hide or show the corresponding plot object (line, patch, or other graphics). This feature improves the user experience by allowing selective visualization of traces without removing them from the plot. The function sets the `ItemHitFcn` callback for the legend to toggle the `Visible` property of the plot object.

```{admonition} Input Parameters
:class: tip
- lgd  - Legend handle created for the target plot. Must be a valid legend object returned by the `legend()` function.
```

```{admonition} Output Parameters
:class: tip
- None
- USAGE:
- figure;
- plot(x, y1, 'LineWidth', 2); hold on;
- plot(x, y2, 'LineWidth', 2);
- lgd = legend('Trace 1', 'Trace 2');
- enableLegendToggle(lgd);
- NOTES:
- Requires MATLAB R2016a or newer (support for `ItemHitFcn`).
- Works with lines, patches, and most common plot objects.
```

---

## extractDocs.m
`Path: src\support\SupportFunctions\extractDocs.m`

**Description:**

Extracts documentation from .m files within a given folder and writes it to a Markdown file. Designed to support ReadTheDocs/Sphinx workflows. Example usage:

- extractDocs('./src/support/AntennaFunctions/', './docs/readthedocs/source/code_antenna.md', 'Antenna Functions')
- extractDocs('./src/support/PAFunctions/', './docs/readthedocs/source/code_amp.md', 'Power Amplifier Functions')
- extractDocs('./src/support/SupportFunctions/', './docs/readthedocs/source/code_support.md', 'Supporting Functions', {'matlab2tikz'})

```{admonition} Input Parameters
:class: tip
- folderPath      - Path to folder containing .m files (recursively searched)
- outFilename     - Path to output .md file
- headerStr       - (Optional) Header/title for the generated Markdown file
- excludedFolders - (Optional) Cell array of subfolders to exclude (by name)
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## extractTODOs.m
`Path: src\support\SupportFunctions\extractTODOs.m`

**Description:**

Extracts TODO comments from .m files within a given folder and writes it to a Markdown file. Designed to support ReadTheDocs/Sphinx workflows. Example usage:

- extractTODOs(pwd+"\src", "./docs/readthedocs/source/TODOs.md")

```{admonition} Input Parameters
:class: tip
- folderPath      - Path to folder containing .m files (recursively searched)
- outFilename     - Path to output .md file
- excludedFolders - (Optional) Cell array of subfolders to exclude (by name)
```

```{admonition} Output Parameters
:class: tip
- None
- extractTODOs.m: IGNORE
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

## processAntennaData.m
`Path: src\support\SupportFunctions\processAntennaData.m`

**Description:**

Modular function to handle Antenna Data

---

## processAntennaReferenceData.m
`Path: src\support\SupportFunctions\processAntennaReferenceData.m`

**Description:**

Modular function to handle Antenna Reference Data

---

## processPAData.m
`Path: src\support\SupportFunctions\processPAData.m`

**Description:**

Modular function to handle PA Data

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

## string2table.m
`Path: src\support\SupportFunctions\string2table.m`

**Description:**

This function reconstructs a MATLAB table from a string formatted by the `tableToString` function. The input string contains rows enclosed in curly braces `{}` with elements separated by semicolons `;`. The function parses this string, splits it into rows and columns, and returns a MATLAB table. If all elements of the parsed data are numeric, they are converted to numeric values; otherwise, the output remains as text. Generic column names (`Col1`, `Col2`, ..., `ColM`) are assigned automatically since the original variable names are not stored in the string.

```{admonition} Input Parameters
:class: tip
- str - A character array or string scalar representing table data in the format:
- {col11;col12;...;col1M}{col21;col22;...;col2M}...{colN1;colN2;...;colNM}
- where N is the number of rows and M is the number of columns.
```

```{admonition} Output Parameters
:class: tip
- T   - A MATLAB table reconstructed from the input string. Column names are automatically assigned as
- 'Col1', 'Col2', ..., 'ColM'. Data types are automatically detected and converted to numeric if all
- values are numeric; otherwise, data is returned as text.
- EXAMPLE:
- s = '{1;3;A}{2;4;B}';
- T = string2table(s);
- T =
- Col1    Col2    Col3
- 1       3       'A'
- 2       4       'B'
- NOTES:
- The function does not preserve original variable names (can be extended if needed).
- Handles arbitrary table sizes.
- Optimized for performance using regular expressions and vectorized operations.
```

---

## table2string.m
`Path: src\support\SupportFunctions\table2string.m`

**Description:**

This function converts a MATLAB table of any size (N-by-M) into a single formatted string representation. Each row of the table is enclosed in curly braces `{}` and the elements within a row are separated by semicolons `;`. The rows are concatenated together without spaces. This format is useful for serializing table data into a compact, structured string that can be stored, transmitted, or embedded into text-based files or databases. The function works with both numeric and string data types. All elements are converted to string form internally. Mixed data types are preserved as text in the output string. The function uses vectorized operations for efficiency and scales well for large tables.

```{admonition} Input Parameters
:class: tip
- T  - MATLAB table of size N-by-M containing numeric, string, or mixed data types. There is no restriction
- on the number of rows (N) or columns (M).
```

```{admonition} Output Parameters
:class: tip
- str - A single string representing the entire table. Each row of the table is formatted as:
- {col1;col2;col3;...;colM}, and all rows are concatenated together as:
- {row1}{row2}{row3}...{rowN}
- EXAMPLE:
- T = table([1;2], [3;4], {'A';'B'}, 'VariableNames', {'X','Y','Z'});
- s = tableToString(T);
- s = '{1;3;A}{2;4;B}'
- NOTES:
- Handles arbitrary table sizes.
- Preserves original data as strings.
- Optimized for speed using columnwise and vectorized operations.
```

---

## updateColorOrder.m
`Path: src\support\SupportFunctions\updateColorOrder.m`

**Description:**

This function updates the colororder of UIAxes in MATLAB App Designer. Color order is primarily used on line plots (rectangular and polar axes)

```{admonition} Input Parameters
:class: tip
- app             - MATLAB app which contains the UIAxes
```

```{admonition} Output Parameters
:class: tip
- None
```

---

## updateColormap.m
`Path: src\support\SupportFunctions\updateColormap.m`

**Description:**

This function updates the colormaps of UIAxes in MATLAB App Designer. Colormaps are primarily used on 3D surfaces.

```{admonition} Input Parameters
:class: tip
- app             - MATLAB app which contains the UIAxes
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

