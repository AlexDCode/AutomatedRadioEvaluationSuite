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

This function sets up a context menu for the 3D radiation pattern plot created using Antenna Toolbox's internal renderer. INPUT PARAMETERS: app: Application object containing plot handles and export logic. This function: plots

- Creates a right-click context menu on the 3D radiation plot
- Adds export options (PNG, JPG) to the context menu
- Assigns the menu to the axes and all child graphics objects
- Ensures export functionality works even with toolbox-rendered

## waitForInstrument.m
`File path: src\support\SupportFunctions\waitForInstrument.m`

**DESCRIPTION:**

This function waits for an instrument to complete its operation before proceeding. It continuously queries the instrument's operation status and checks if it is ready, or if a specified timeout duration has passed. If the instrument is not ready within the timeout period, the function will exit. INPUT PARAMETERS app:         The application object, which contains settings like the measurement delay value. Instrument:  The instrument object to query for its operation status. OUTPUT PARAMETERS None

