# List of Components and their Usecase
- according to the [Hardware Kit](https://github.com/OCDCpro/LAYR/tree/main/hardware_kit)

## NFC Reader with RC522 Chip and SPI
- [Datasheet](https://www.nxp.com/docs/en/data-sheet/MFRC522.pdf)
- RFID Chip – Communicates with our Keycard

### Pinout
| Pin Nr | Pin Name | Description |
|:-      |:-        |:-           |
| 1      | SDA	    | I²C-bus serial data line input/output|
| 2      | SPI_CLK  | Serial Clock for synchronisation |
| 3      | SPI_MOSI | SPI master out, slave in |
| 4      | SPI_MISO | SPI master in, slave out |
| 5      | IRQ      | interrupt request output: indicates an interrupt event |
| 6      | GND      | Ground |
| 7      | RST      | Reset |
| 8      | 3.3V     | Power in|



## EEPROM Memory AT25010B on Pinheader board, SPI
- [Datasheet](https://ww1.microchip.com/downloads/en/devicedoc/atmel-8707-seeprom-at25010b-020b-040b-datasheet.pdf)
- External Memory Chip for Key Storage

### Pinout
| Pin Nr | Pin Name | Description |
|:-      |:-        |:-           |
|1 |CS|Chip Select
|2|SPI_MISO|Serial Data Input
|3|WP|Write Protect & Write Disable Instructions for Both Hardware and Software Data Protection
|4|GND|Ground
|5|SPI_MOSI|Serial Data Output
|6|SPI_CLK|Serial Data Clock
|7|HOLD|Suspends Serial Input
|8|VCC|Power Supply 1.8V to 5.5V
- confirm Pinout using multimeter!!


## Keycard (Javacard), pre-programmed
- [Datasheet](https://github.com/OCDCpro/javacard-applet/tree/master)
- Card ID A: 
- AES Key;                          ID
- 39558d1f193656ab8b4b65e25ac48474; bbe8278a67f960605adafd6f63cf7ba7


## DC-DC Step-down Converter
- down conversion of high direct current to low direct current

### Pinout
| Pin Nr | Pin Name | Description |
|:-      |:-        |:-           |
|1|OUT-|lower current out|
|2|OUT+|lower current in|
|3|IN-|higher current out|
|4|IN+|higher current in|


## Relais 12V
- electrically activated switch
- on/off toggling of circuit with higher current

### Pinout
| Pin Nr | Pin Name | Description |
|:-      |:-        |:-           |
|1|NO|Open circuit when the relay is inactive; closed when the relay is activated|
|2|COM|Common terminal for the relay's switching contacts|
|3|NC|Closed circuit when  the relay is inactive; open when the relay is activated|
|4|DC+| Connect DC positive|
|5|DC-| Connect DC negative|
|6|IN|Signal Trigger Terminal|

![img](https://i.ebayimg.com/images/g/R44AAOSw5wRf9CJD/s-l1600.jpg)


## USB-C Powersupply board with step-up converter
- power supply through USB-C connection
- power gets stepped up to higher Voltage

### Pinout
| Pin Nr | Pin Name | Description |
|:-      |:-        |:-           |
|1|OUT-|higher voltage out|
|2|OUT+|higher voltage in|
|3|IN-|lower voltage out|
|4|IN+|lower voltage in|


## Doorlock 12V

### Pinout 
| Pin Nr | Pin Name | Description |
|:-      |:-        |:-           |
|1|IN|Power in|
|2|GND|Ground|



## LEDs, Buttons and Resistors



# Schematic
- [Schematic](https://github.com/OCDCpro/LAYR/tree/main/demonstrator)

![img](https://raw.githubusercontent.com/OCDCpro/LAYR/refs/heads/main/demonstrator/schematic/schematic_symbols_v1.0.png)