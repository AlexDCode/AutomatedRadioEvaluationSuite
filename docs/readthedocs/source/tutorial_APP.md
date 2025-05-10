# App Tutorial

-------------------

### Plot Exporting

ARES includes a built-in **right-click export system** for all major plots across the application, making it easy to save results directly from the GUI.

How It Works:
* Right-click on any plot.
* A context menu with export options appears next to the plot.
* Choose a format:
  * **PNG, JPG** – High resolution images
  * **PDF** – Vector graphics for papers and presentations
  * **TikZ** – For LaTeX users

```{admonition} Note
:class: important
* **TikZ export** requires the `matlab2tikz` package and is only supported for **Cartesian 2D plots**.
* **PDF export** is **not supported** for the **3D Radiation Plot** due to MATLAB’s `exportgraphics` limitations on 3D content.
```

### Measurement Time Logging

ARES automatically logs performance metrics for every measurement session to help users monitor and optimize testing efficiency.

Each log entry includes:

- **Measurement Type**: `PA` or `Antenna`
- **Start Time** and **End Time**
- **Total Duration** of the measurement
- **Number of Measured** points or positions
- **Average Time** per point/position

This log is stored in:

```none
<userpath>/ARES/ARES_Measurement_Log.txt
```

This log enables users to:

- Benchmark performance across different configurations
- Optimize sweep parameters and delays
- Maintain a record of test durations for reproducibility or documentation

**Measurement Log Example**:

```none
[27-Apr-2025 15:57:38]
Antenna Measurement Summary:
Start Time: 27-Apr-2025 15:56:11
End Time: 27-Apr-2025 15:57:38
Duration: 00:01:26
Total Positions Measured: 19
Average Time Per Position: 00:00:04
---------------------------------------------------------------------------
```

### Error Logging

ARES includes a built-in error handling system to capture unexpected issues during execution.
When an error occurs:

1) A **pop-up alert** with the error message is shown to the user.
2) A detailed error report is automatically logged to:

```none
<userpath>/ARES/ARES_Error_Log.txt
```

Each error entry includes:

- **Timestamp**
- **Error Message**
- **Error Identifier**
- **Stack Trace** (file, function name, and line number)

```{admonition} Note
:class: tip
*  If the log file or folder doesn’t exist, ARES will create it automatically.
```

This feature is particularly useful when debugging or reporting issues. The user can easily share the log file with our team to diagnose problems quickly.

**Error Log Example**:

```none
[08-May-2025 19:57:30]
Error: Unrecognized function or variable 'units'.
Identifier: MATLAB:UndefinedFunction

Stack Trace:
In file: C:\Users\USERNAME\Documents\GitHub\AutomatedRadioEvaluationSuite\src\support\AntennaFunctions\RADIATIONPATTERN3D.m
Function: RADIATIONPATTERN3D
Line: 70

In file: C:\Users\USERNAME\Documents\GitHub\AutomatedRadioEvaluationSuite\src\support\AntennaFunctions\plotAntenna3DRadiationPattern.m
Function: plotAntenna3DRadiationPattern
Line: 83

In file: C:\Users\USERNAME\Documents\GitHub\AutomatedRadioEvaluationSuite\src\ARES.mlapp
Function: ARES.AntennaSelectedFrequencyValue
Line: 1793

In file: C:\Program Files\MATLAB\R2025a\toolbox\matlab\appdesigner\appdesigner\runtime\+matlab\+apps\AppBase.m
Function: @(source,event)executeCallback(ams,app,callback,requiresEventData,event)
Line: 54

---------------------------------------------------------------------------
```

