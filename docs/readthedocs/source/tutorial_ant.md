# Antenna Tutorial

The Antenna Module enables parametric measurements by varying the position of the Device Under Test (DUT) and acquiring its frequency response. The application captures the data, calculates antenna gain, saves the results, and visualizes the plots. Measurements can be reloaded from saved data, so tests do not need to be repeated unnecessarily.

Sample datasets are available in the [data/Antenna](https://github.com/AlexDCode/AutomatedRadioEvaluationSuite/tree/main/data/Antenna) folder.

```{admonition} Average Measurement Time
:class: important
* Scan $\theta$ ($1^{\circ}$ step) with fixed $\phi$: ~16 minutes
* Scan $\theta$ ($3^{\circ}$ step) with fixed $\phi$: ~8 minutes
* Scan $\theta$ ($5^{\circ}$ step) with fixed $\phi$: ~6 minutes
* 3D scan ($3^{\circ}$ step for both $\theta$ and $\phi$): ~20 hours, (~380 MB for 201 frequency points)
    * Note only half $\theta$ scan may be needed for full 3D pattern, cutting the total time in half.
```

## Theory

### Foundational Equations

Friis Transmission Equation:

$$
\frac{P_r}{P_t} = G_t G_r \left( \frac{\lambda}{4 \pi d} \right)^2
$$

Where:
* $P_r$: Received power
* $P_t$: Transmitted power
* $G_t$: Transmitter Antenna Gain
* $G_r$: Receiver Antenna Gain
* $\lambda$ Wavelength
* $d$: Distance between transmitter and receiver

Which can be expressed in dB scale as:

$$
P_r^{[dB]} = P_t^{[dB]} + G_t^{[dBi]} + G_r^{[dBi]} + 20 \log \left( \frac{\lambda}{4 \pi d} \right)
$$

The Free Space Path Loss (FSPL) factor is given by:

$$
FSPL = 20 \log\bigg( \frac{\lambda}{4 \pi d} \bigg)
$$

The ratio of received to transmitted power will be the measured magnitude:

$$
S_{21} = \frac{P_r}{P_t} 
$$

### Gain Comparison Method

In the gain comparison method (i.e., two antenna method), the reference antenna gain is known. Hence, we can solve Friis transmission equation with this assumption and express it in terms of the measured S-parameters $S_{21}^{[dB]}$, calculated $FSPL$, and reference antenna gain $G_{REF}^{[dBi]}$.

$$
G_{DUT}^{[dBi]} = S_{21}^{[dB]} - FSPL - G_{REF}^{[dBi]}
$$


### Gain Transfer Method

In the gain transfer method (i.e., one antenna method), the DUT and reference antenna are identical ($G_t^{[dBi]} = G_r^{[dBi]}$). Hence, we can solve Friis transmission equation with this assumption and express it in terms of the measured S-parameters $S_{21}^{[dB]}$ and calculated $FSPL$.

$$
G_{DUT}^{[dBi]} = \frac{S_{21}^{[dB]} - FSPL}{2}
$$


## Performing the Measurement

### Calibration
* To get started, calibrate the Vector Network Analyzer (VNA) at the measurement plane, where the reference antenna and DUT will be connected. Set your frequency range and number of points (or step size) as desired **before calibration**.

* Using an eCal is highly recommended, as shown in the following [demonstration](https://youtu.be/OefvtshJiC0?si=ZZNQlMm1ttoYM5Pf).

### Connect to the instruments

* Select the relevant instrument VISA addresses in each dropdown of the *Instruments* tab.
* Select *None: NA* for the instruments that will not be used. 
* Follow the [Instrument Database Tutorial](https://aresapp.readthedocs.io/latest/tutorial_instr.html) for detailed information on how to edit the user-defined instrument database. 
* Once all the addresses have been populated, click on *Connect* at the bottom to establish connection to each instrument and *Disconnect* to clear all connections. 

The *Measurement Delay* can be modified at any time before the measurement starts. This value is the time to wait between setting all the instruments and capturing the data.

```{admonition} Average Measurement Time
:class: note
The *Measurement Delay* can be modified at any time before the measurement starts. This value is the time to wait between setting all the instruments and capturing the data.
```

```{image} ./assets/Ant/instr_conf.png
:alt: Instrument Configuration
:class: bg-primary
:width: 100%
:align: center
```

### Load Reference Antenna Data (for Gain Comparison Method)

For the [Gain Comparison Method](#gain-comparison-method), the reference antenna gain needs to be loaded using the same data format as measured antennas. In the *Reference Antenna* window, click on *Browse Reference File* and select the data for the reference antenna. Only the boresight gain ($\theta = 0$, $\phi = 0$) is required from the reference antenna. The boresight gain and return loss magnitude over frequency will be plotted in the results view window. To remove the file, click on *Clear Reference*.

```{image} ./assets/Ant/demo_refAnt.png
:alt: Reference Antenna
:class: bg-primary
:width: 100%
:align: center
```

### Configure the VNA

Configure the Vector Network Analyzer (VNA) in the *VNA* tab. When connecting to the instruments, the app will load the current settings to the app. If you change any of the *Start Frequency*, *Step Frequency*, and *Stop Frequency*, the calibration might not be valid anymore. To prevent this, calibrate before connecting and leave the loaded values. These settings are limited to the capabilities of the instruments (i.e., frequency and power range). In addition, the app can load the smoothed data from the VNA, which utilizes a moving average filter with the given number of samples. If the *Smoothing Percentage* is set to zero, the smoothing will be turned off.

```{image} ./assets/Ant/vna_conf.png
:alt: VNA Configuration
:class: bg-primary
:width: 100%
:align: center
```


### Configure the table (theta axis)

Configure the theta axis in the *Table* tab. Select between a static or parametric sweep. Select the *Table Speed* using the slider. Then enter the appropriate *Start Angle*, *Angle Step Size*, and *Stop Angle*. Note that the software inputs are between $-180^\circ$ and $180^\circ$. Since the table is configured to take angles between $0^\circ$ and $360^\circ$, the software will translate to the appropriate values. If the user desires to control the table from the software, enter the target position and click on *Move to Angle*. To stop the movement at any time, click on *Stop Table*.

```{image} ./assets/Ant/table_conf.png
:alt: Table Configuration
:class: bg-primary
:width: 100%
:align: center
```


### Configure the tower (phi axis)

Configure the tower axis in the *Tower* tab. Select between a static or parametric sweep. Select the *Tower Speed* using the slider. Then enter the appropriate *Start Angle*, *Angle Step Size*, and *Stop Angle*. Note the software inputs are between $-180^\circ$ and $180^\circ$. If the user desires to control the table from the software, enter the target position and click on *Move to Angle*. To stop the movement at any time, click on *Stop Tower*.

```{image} ./assets/Ant/tower_conf.png
:alt: Tower Configuration
:class: bg-primary
:width: 100%
:align: center
```

### Configure the linear slider

In the *Linear Slider* tab, set the *Antenna Offset*, which adds the lengths of the DUT and reference antenna with respect to the mounting fixtures. The linear slider *Speed Preset* and *Slider Position* can be controlled from this tab. To move the slider, enter the target position and click on *Move to Position*. The *Slider Position* will display the current position of the slider, while the *Current Spacing* will display the current antenna separation, which takes into account the slider position and antenna offset. Options to *Home*, *Scan*, and *Stop* the slider are available.

```{image} ./assets/Ant/slider_conf.png
:alt: Linear Slider Configuration
:class: bg-primary
:width: 100%
:align: center
```

### Run the test and plot the results

After validating all the settings, click on *Start Test* to begin the measurement. The progress window will display the time taken and the estimated time to complete. Once the test is completed, a prompt will open up to save the data. Once you enter the name and save the data, ARES will automatically load the data and plot it. A previous measurement can be plotted by loading the data in the *Load Test* button. 

The *2D Radiation Pattern* results view window will display the realized gain vs. frequency, return loss, and 2D radiation pattern for the selected value of the *Frequency*, *$\theta$* cut, and *$\phi$* cut dropdowns.

```{image} ./assets/Ant/demo_2Dpattern.png
:alt: Antenna 2D Radiation Pattern
:class: bg-primary
:width: 100%
:align: center
```

The *3D Radiation Pattern* results view window will display the realized gain vs. frequency, return loss, and 2D radiation pattern for the selected value of the *Frequency* dropdown.

```{image} ./assets/Ant/demo_3Dpattern.png
:alt: Antenna 3D Radiation Pattern
:class: bg-primary
:width: 100%
:align: center
```
