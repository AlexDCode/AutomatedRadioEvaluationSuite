# Instrument Interfacing


## VISA Library

Virtual Instrument Standard Architecture (VISA) is a test & measurement industry standard communication API (Application Programming Interface) for use with test and measurement devices regardless of their communication protocol (i.e., LAN, USB, GPIB, etc.). The VISA libraries are the communication drivers that allow ARES to control the instruments using Standard Commands for Programmable Instruments (SCPI). Read more about the neccesary software in [MATLAB: Get Started with VISA](https://www.mathworks.com/help//releases/R2021a/instrument/visa-overview.html).

## SCPI Strings

SCPI is a text-based command language used to control instruments and provides a common language to simplify the interface between devices and instruments mirrowing the intrument physical inputs and utilities. Since SCPI is hardware independent, SCPI strings can be sent over any interface that supports it. [Keysight Command Expert](https://www.keysight.com/find/commandexpert) allows to search the neccesary SCPI strings interactively and provides seamless integrations with different VISA libraries. There are two types of SCPI strings:

* **Command String:** `:KEY <parameter>`
* **Query String:** `:KEY?`

Command strings are reserved for writing only while Query strings are reserved for reading data back from the instrument. The `KEY` represents the name of the instrument feature to adjust while < parameter > is the value to be sent to the instrument. Complex SCPI strings can be made y combining several KEYs and parameters into one string, i.e. `:KEY1:KEY2:KEY3? <parameter 1> <parameter 2>`.

### Transitioning Code from VISA Interface to VISAdev Interface

Command Expert references the original library but ARES uses the newer version, VISAdev, compatible only with MATLAB R2021a and newer. The following table lists the equivalent commands for each implementation.

|**VISA Interface**|**VISAdev Interface**  |**Purpose**                     |
|----------------- |-----------------------|--------------------------------|
| `visa()`         | `visadev()`           | Connect the instrument         |
| `fprintf()`      | `writeline()`         | Write to the instrument        |
| `fscanf()`       | `readline()`          | Read from the instrument       |
| `query()`        | `writeread()`         | Write and read at the same time|
| `binblockread()` | `readbinblock()`      | Read binblock data             |
| `clrdevice()`    | `flush()`             | Flush data from memory         |
| `fclose()`       | `delete()` & `clear()`| Disconnect the instrument      |


### Common SCPI Strings Across Instruments

All instruments which adhere to the VISA standards share a small subset of SCPI strings. This subset can be found in all instruments and are employed in the application for distinct reasons discussed in the table below. In contrast to standard SCPI strings, they have a different form, `*KEY and *KEY?`.


|**Command / Query**       |**SCPI String**   |**Purpose**                                                     |**When To Use**                                        |
|--------------------------|------------------|----------------------------------------------------------------|-------------------------------------------------------|
| Identification Query     | `*IDN?`          | Returns a string that uniquely identifies the instrument.      | Verify instrument after connecting.                   |
| Reset Command            | `*RST`           | Resets most instrument functions to factory-defined conditions.| Use after connecting unless preconfigured environment.|
| Clear Status Command     | `*CLS`           | Clears the registers from the status byte.                     | Prevent compromised data in sweeps.                   |
| Operation Complete Query | `*OPC?`          | Confirms all pending operations are finished.                  | Useful in debugging QUERY errors.                     |
| Wait Command             | `*WAI`           | Blocks new commands until current ones complete.               | Less dynamic version of `*OPC?`.                      |
| Data Format Commands     | `:FORM:BORD:SWAP`| Sets type and format for returned trace measurement data.      | Adjust endianness and data type for efficiency.       |

For the *Data Format Commands*, there are three types of data to be chosen. `REAL,32` is best for transferring substantial amounts of data. `REAL,64` is slower but has more significant digits than `REAL,32`. For these types use `readbinblock()`, because they transfer data in block format. The last one is ASCii,0 easiest to implement, but slow, used when you have small amounts of data to transfer.

### Specific SCPI Strings Across PA Instruments

This set of SCPI strings are used to control the instrument relevant for the PA measurement module.

|**Instrument**    |**Command / Query** |**SCPI String**                     |
|------------------|--------------------|------------------------------------|
| Power Supply     | Set voltage & limit| `:APPLY <mode> <voltage> <current>`|
| Power Supply     | Measure voltage    | `:MEAS:VOLT:DC? <mode>`            |
| Signal Generator | Set frequency      | `:SOUR:FREQ:CW <frequency>`        |
| Spectrum Analyzer| Set span           | `:SENS:FREQ:SPAN <span>`           |

### Specific SCPI Strings Across Antenna Instruments

This set of SCPI strings are used to control the instrument relevant for the Antenna measurement module.

|**Instrument**          |**Command / Query** |**SCPI String**                     |
|------------------------|--------------------|------------------------------------|
| Vector Network Analyzer| Set start frequency| `:SENS<cnum>:FREQ:STAR <frequency>`|
| EM Center              | Set speed          | `1<slot-letter>:SPEED <speed>`     |
| EM Center              | Seek angle         | `1<slot-letter>:SK <angle>`        |

For the Vector Network Analyzer (VNA), `cnum` is the channel number which defaults to one if not specified, `mnum` is the measurement number, and `mname` is the name of the measurement. For the EM Center which controls the anechoic chamber, the tower and table are in slot one, however the table is in letter A, and the tower is in letter B.