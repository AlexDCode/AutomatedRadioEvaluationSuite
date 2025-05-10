# App Tutorial

-------------------

### Error Logging

ARES automatically tracks internal software errors using a built-in logging system. When an unexpected issue occurs, the app:

1) Displays an error message to the user via a pop-up alert.
2) Records detailed diagnostic info (message, identifier, stack trace, timestamp) to an error log file:

```none
<userpath>/ARES/ARES_Error_Log.txt
```

This log is useful for debugging or reporting issues. Each entry includes:

- Timestamp
- Error message
- Identifier
- Stack trace (file, function, line)

```{admonition} 
:class: tip
*  If the log file or folder doesn’t exist, ARES will create it automatically.
```

### Measurement Time Logging

To help track testing efficiency, ARES logs timing information for each measurement session.

Each entry includes:

- Measurement type (PA or Antenna)
- Start and end times
- Total duration
- Number of measured points or positions
- Average time per point or position

These logs are stored in:

```none
<userpath>/ARES/ARES_Measurement_Log.txt
```

This helps users:

- Compare test durations across sessions
- Optimize sweep parameters
- Keep performance records


