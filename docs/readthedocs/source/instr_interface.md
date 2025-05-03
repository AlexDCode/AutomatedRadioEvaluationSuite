# Instrument Interfacing

This guide explains how the Automated Radio Evaluation Suite (ARES) communicates with lab instruments using standard APIs and SCPI commands. Whether you're measuring power amplifier (PA) performance or characterizing antennas, this section helps you interface with your instruments through MATLAB using VISA libraries.

---

## VISA Library Overview

**Virtual Instrument Standard Architecture (VISA)** is a test & measurement industry standard communication API (Application Programming Interface) for use with test and measurement devices regardless of their communication protocol (i.e., LAN, USB, GPIB, etc.). The VISA libraries are the communication drivers that allow ARES to control the instruments using Standard Commands for Programmable Instruments (SCPI). ARES uses the **VISAdev** interface, introduced in MATLAB R2021a. VISAdev replaces the older VISA interface and provides better integration with modern instrument drivers. 
Read more about the necessary software in [MATLAB: Get Started with VISA](https://www.mathworks.com/help//releases/R2021a/instrument/visa-overview.html).

## SCPI Command Basics

**Standard Commands for Programmable Instruments (SCPI)** are text-based commands used to configure and query instruments. These commands are device-independent and can be used over any supported communication interface.

[Keysight Command Expert](https://www.keysight.com/find/commandexpert) allows searching the necessary SCPI strings interactively and provides seamless integrations with different VISA libraries.

Command Types
 There are two types of SCPI strings:

* **Command String:** `:KEY <parameter>`
* **Query String:** `:KEY?`

Command strings are reserved for writing only, while query strings are reserved for reading data back from the instrument. The `KEY` represents the name of the instrument feature to adjust, while '<parameter>' is the value to be sent to the instrument. Complex SCPI strings can be made by combining several KEYs and parameters into one string. You can chain multiple levels of control using colons, i.e., `:KEY1:KEY2:KEY3 <parameter 1> <parameter 2>`.

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

|**Instrument**    |**Command / Query** |**SCPI String**                     |
|------------------|--------------------|------------------------------------|
| Power Supply     | Set voltage & limit| `:APPLY <mode> <voltage> <current>`|
| Power Supply     | Measure voltage    | `:MEAS:VOLT:DC? <mode>`            |
| Power Supply     | Set voltage & limit| `:APPLY <mode> <voltage> <current>`|
| Power Supply     | Measure voltage    | `:MEAS:VOLT:DC? <mode>`            |
| Signal Generator | Set frequency      | `:SOUR:FREQ:CW <frequency>`        |
| Signal Generator | Set frequency      | `:SOUR:FREQ:CW <frequency>`        |
| Signal Generator | Set frequency      | `:SOUR:FREQ:CW <frequency>`        |
| Signal Generator | Set frequency      | `:SOUR:FREQ:CW <frequency>`        |
| Signal Generator | Set frequency      | `:SOUR:FREQ:CW <frequency>`        |
| Signal Analyzer  | Set span           | `:SENS:FREQ:SPAN <span>`           |
| Signal Analyzer  | Set span           | `:SENS:FREQ:SPAN <span>`           |
| Signal Analyzer  | Set span           | `:SENS:FREQ:SPAN <span>`           |
| Signal Analyzer  | Set span           | `:SENS:FREQ:SPAN <span>`           |

### Sample SCPI Commands for Antenna Measurement Instruments

|**Instrument** |**Command / Query**   |**SCPI String**                 | **Input Parameter**                                        |
|---------------|----------------------|--------------------------------|------------------------------------------------------------|
| VNA           | Start frequency      | `:SENS<cnum>:FREQ:START <num>` | Number between the MIN and MAX frequency limits.           |
| VNA           | Stop frequency       | `:SENS<cnum>:FREQ:STOP <num>`  | Number between 70 (VNA specific) and MAX frequency limits. |
| VNA           | Sweep points         | `:SENS<cnum>:SWE:POIN <num>`   | Number between 1 and maximum number of supported points.   |
| VNA           | Sweep mode           | `:SENS<cnum>:SWE:MODE <char>`  | HOLD, CONTinuos, SINGle                                    |
| VNA           | Data smoothing       | `:CALC<cnum>:SMO:STAT <state>` | ON or OFF (Alternatively 1 or 0)                           |
| VNA           | Smoothing percentage | `:CALC<cnum>:SMO:APER <num>`   | Number between 1 and 25                                    |
| EM Center     | Set speed            | `1<slot-letter>:SPEED <speed>` |                                                            |
| EM Center     | Seek angle           | `1<slot-letter>:SK <angle>`    |                                                            |

For the Vector Network Analyzer (VNA):
 - `cnum` is the channel number, which defaults to one if not specified.
 - `mnum` is the measurement number, and `mname` is the name of the measurement.

For the EM Center, which controls the anechoic chamber, the tower and table are in slot one; however, the table is in letter A, and the tower is in letter B.
