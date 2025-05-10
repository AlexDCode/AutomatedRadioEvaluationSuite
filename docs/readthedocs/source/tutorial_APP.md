# App Tutorial

-------------------

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

```{admonition} 
:class: tip
*  If the log file or folder doesn’t exist, ARES will create it automatically.
```

This feature is particularly useful when debugging or reporting issues. The user can easily share the log file with our team to diagnose problems quickly.

