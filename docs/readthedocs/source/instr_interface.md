# Instrument Interfacing

This guide explains how the Automated Radio Evaluation Suite (ARES) communicates with lab instruments using standard APIs and SCPI commands. Whether you're measuring power amplifier (PA) performance or characterizing antennas, this section helps you interface with your instruments through MATLAB using VISA libraries.

---

## VISA Library Overview

**Virtual Instrument Standard Architecture (VISA)** is a test and measurement industry-standard communication API (Application Programming Interface) for use with test and measurement devices regardless of their communication protocol (e.g., LAN, USB, GPIB, etc.). The VISA libraries are the communication drivers that allow ARES to control the instruments using Standard Commands for Programmable Instruments (SCPI). 

ARES uses the VISAdev interface, introduced in MATLAB R2021a. VISAdev replaces the older VISA interface and integrates better with modern instrument drivers. 
Read more about the necessary software in [MATLAB: Get Started with VISA](https://www.mathworks.com/help//releases/R2021a/instrument/visa-overview.html).

## SCPI Command Basics

**Standard Commands for Programmable Instruments (SCPI)** are text-based commands used to configure and query instruments. These commands are device-independent and can be used over any supported communication interface.

[Keysight Command Expert](https://www.keysight.com/find/commandexpert) allows searching the necessary SCPI strings interactively and provides seamless integrations with different VISA libraries.

There are two types of SCPI strings:

* **Command String:** `:KEY <parameter>`
* **Query String:** `:KEY?`

Command strings are reserved for writing to the instrument, while query strings are reserved for reading back from the instrument. The `KEY` represents the name of the instrument feature to adjust, while '<parameter>' is the value to be sent to the instrument. Complex SCPI strings can be made by combining several KEYs and parameters into one string. You can chain multiple levels of control using colons, i.e., `:KEY1:KEY2:KEY3 <parameter 1> <parameter 2>`.

### Transitioning from VISA to VISAdev

ARES uses the `visadev` interface instead of the older `visa` interface. Here's a summary of equivalent MATLAB commands:

|**VISA Interface**|**VISAdev Interface**  |**Purpose**                          |
|----------------- |-----------------------|-------------------------------------|
| `visa()`         | `visadev()`           | Connect to an instrument.           |
| `fprintf()`      | `writeline()`         | Send a command.                     |
| `fscanf()`       | `readline()`          | Read a response.                    |
| `query()`        | `writeread()`         | Send a query and read the response. |
| `binblockread()` | `readbinblock()`      | Read binary data blocks.            |
| `clrdevice()`    | `flush()`             | Flush I/O data buffers.             |
| `fclose()`       | `clear()`             | Disconnect the instrument object.   |


### Common SCPI Strings Across Instruments

Many instruments share a basic set of SCPI commands, regardless of vendor or type. These are especially helpful for setup, synchronization, and debugging. 

|**Type**                   |**SCPI Command/Query**  |**Purpose**                                 |**When to Use**                                                                          |
|---------------------------|------------------------|--------------------------------------------|-----------------------------------------------------------------------------------------|
| Identification Instrument | `*IDN?`                | Returns instrument model and info.         | Verify the instrument after connecting.                                                 |
| Reset to Default State    | `*RST`                 | Resets instrument to factory defaults.     | Use at the start of the session unless your instrument uses a preconfigured environment.|
| Clear Status Register     | `*CLS`                 | Clears error and communication flags.      | Prevent corrupted data in sweeps.                                                       |
| Operation Complete        | `*OPC?`                | Queries if previous commands finished      | For command debugging.                                                                  |
| Wait for Completion       | `*WAI`                 | Waits until prior operations are complete. | Improve speed/accuracy.                                                                 |

### SCPI Data Format Commands

The following commands control how numerical data is formatted and transmitted between the instrument and controller, impacting compatibility, speed, and precision during data transfer.

|**Type**           |**SCPI Command/Query** |**Purpose**                              |**When to Use**                               |
|-------------------|-----------------------|-----------------------------------------|----------------------------------------------|
| Set Byte Order    | `:FORM:BORD: SWAP`    | Configures Little-endian binary format. | Required by MATLAB for binary reads.         |
| Set Byte Order    | `:FORM:BORD: NORM`    | Configures Big-endian binary format.    | Used in other environments (non-MATLAB).     |
| Query Byte Order  | `:FORM:BORD?`         | Queries current byte order.             | Verifying before reading binary data.        |
| Set Data Format   | `:FORM:DATA ASCii,0`  | Sets ASCII data format.                 | Useful for debugging, not efficient.         |
| Set Data Format   | `:FORM:DATA REAL,32`  | Sets 32-bit real binary format.         | Faster transfer, sufficient for most tasks.  |
| Set Data Format   | `:FORM:DATA REAL,64`  | Sets 64-bit real binary format.         | Highest precision, use for double-precision. |
| Query Data Format | `:FORM:DATA?`         | Queries current data format.            | Verifying before reading trace/sample data.  |

### Sample SCPI Commands for PA Measurement Instruments

The following table lists frequently used SCPI commands for configuring and controlling instruments in the power amplifier (PA) measurement setup. These commands help automate voltage/current sourcing, RF signal generation, and signal analysis tasks.

|**Instrument**    |**Command / Query**            |**SCPI String**                         | **Input Parameter**                                                         |
|------------------|-------------------------------|----------------------------------------|-----------------------------------------------------------------------------|
| Power Supply     | Set voltage and current       | `:APPLy <channel>,<voltage>,<current>` | Voltage and current within instrument limits.                               |
| Power Supply     | Measure DC voltage            | `:MEAS:SCAL:VOLT:DC? <channel>`        | Use `@1`, `@2`, or `@1,2` to specify channel(s).                            |
| Power Supply     | Measure DC current            | `:MEAS:SCAL:CURR:DC? <channel`         | Use `@1`, `@2`, or `@1,2` to specify channel(s).                            |
| Power Supply     | Enable or disable output      | `:OUTP:STAT <state>, (<channel>)`      | `ON`/`OFF` or `1`/`0`. Channel in parentheses: `(@1)`, `(@2)`, or `(@1,2)`. |
| Signal Generator | Set RF power                  | `:SOUR1:POW:LEV:IMM:AMPL <power>`      | Power in dBm, within allowed range.                                         |
| Signal Generator | Set frequency                 | `:SOUR1:FREQ:CW <frequency>`           | Frequency in Hz, within allowed range.                                      |
| Signal Generator | Enable or disable output      | `:OUTP1:STAT <state>`                  | `ON`/`OFF` or `1`/`0`.                                                      |
| Signal Analyzer  | Set number of sweep points    | `:SENS:SWE:POIN <points>`              | Integer between 1 and the maximum supported value..                         |
| Signal Analyzer  | Set frequency span            | `:SENS:FREQ:SPAN <span>`               | Span in Hz, within valid range.                                             |
| Signal Analyzer  | Set center frequency          | `:SENS:FREQ:CENT <frequency>`          | Center frequency in Hz, within valid range.                                 |
| Signal Analyzer  | Enable continuous measurement | `:INIT:CONT <state>`                   | `ON`/`OFF` or `1`/`0`.                                                      |
| Signal Analyzer  | Restart current sweep         | `:INIT:IMM`                            | No input. Immediately starts or restarts a sweep.                           |
| Signal Analyzer  | Query sweep data              | `:TRAC:DATA? <trace>`                  | Trace name, e.g., `TRAC1`, `TRAC2`, ..., `TRAC6`.                           |

For the Power Supply Unit (PSU):
 - `channel`: Use `@1` for channel 1, `@2` for channel 2, and `@1,2` to address both simultaneously. 

### Sample SCPI Commands for Antenna Measurement Instruments

The following table lists frequently used SCPI commands for configuring and controlling instruments in the antenna measurement setup. These commands allow automation of RF sweeps, mechanical motion, and data acquisition during the antenna measurements.

|**Instrument** |**Command / Query**     |**SCPI String**                 | **Input Parameter**                                          |
|---------------|------------------------|--------------------------------|--------------------------------------------------------------|
| VNA           | Set start frequency    | `:SENS<cnum>:FREQ:START <num>` | Frequency in Hz; within VNA's allowed range.                 |
| VNA           | Set stop frequency     | `:SENS<cnum>:FREQ:STOP <num>`  | Frequency in Hz; minimum is often 70 Hz, depending on model. |
| VNA           | Set sweep points       | `:SENS<cnum>:SWE:POIN <num>`   | Integer between 1 and max supported points.                  |
| VNA           | Set sweep mode         | `:SENS<cnum>:SWE:MODE <mode>`  | Mode can be `HOLD`, `CONT` (continuous), or `SING` (single). |
| VNA           | Enable smoothing       | `:CALC<cnum>:SMO:STAT <state>` | `ON`/`OFF` or `1`/`0`.                                       |
| VNA           | Set smoothing aperture | `:CALC<cnum>:SMO:APER <num>`   | Percentage between 1 and 25.                                 |
| EM Center     | Set rotation speed     | `1<slot-letter>:SPEED <speed>` | Speed between 1 and 100.                                     |
| EM Center     | Seek to angle          | `1<slot-letter>:SK <angle>`    | Angle in degrees.                                            |
| EM Center     | Stop movement          | `1<slot-letter>:ST`            | No parameters. Immediately halts motion.                     |
| Linear Slider | Set speed              | `AXIS1:S <speed`               | Speed preset from 1 (slowest) to 8 (fastest).                |                               
| Linear Slider | Seek to position       | `AXIS1:SK <position`           | Position in cm (within travel limits).                       |
| Linear Slider | Query current position | `AXIS1:CP?`                    | Returns current position in cm.                              |
| Linear Slider | Enable scan mode       | `AXIS1:SCAN`                   | No parameters. Starts programmed scan routine.               |
| Linear Slider | Enable homing mode     | `AXIS1:HOME`                   | No parameters. Returns the axis to mechanical zero.          |

For the Vector Network Analyzer (VNA):
 - `cnum` is the channel number, which defaults to one if not specified.
 - `mnum` is the measurement number, and `mname` is the name of the measurement.

For the EM Center, which controls the anechoic chamber:
 - Slot 1 contains both tower and table actuators.
 - Use `A` for the table and `B` for the tower as slot-letter designations (e.g., `1A`, `1B`).
