# Components
## Functionality
- SPI communication in general
- communication with external Key Storage via SPI (i guess)


### necessary Pins
| Name  | Function | IO | Description |
|:----  | :----     | :----  | :----  |
| Pin1  | rst       | Input  | Reset |   
| Pin2  | sys_clk   | Input  | System clock |
| Pin11 | Vdd       | Input  | Vdd |
| Pin12 | Vss       | Input  | Vss |
| Pin13 | cs_1      | Output | spi cable select 1 |
| Pin15 | spi_miso  | Input  | SPI Master In Slave Out |
| Pin16 | spi_mosi  | Output | SPI Master Out Slave In |
| Pin17 | spi_sclk  | Output | SPI Clock  |
| Pin18 | Vss       | Input  | Vss |
| Pin19 | Vdd       | Input  | Vdd |
| Pin21 | status_unlock | Output  | Signaling a state or status 1 |
| Pin22 | status_fault  | Output  | Signaling a state or status 2 |
| Pin23 | status_busy   | Output  | Signaling a state or status 3 |
| Pin24 | IO_Vss    | Input  | IO_Vss |
| Pin25 | IO_Vdd    | Input  | IO_Vdd |


### presumably unnecessary Pins
| Name  | Function | IO | Description |
| Pin3  | uart_clk  | Input  | UART_clock |
| Pin4  | user_io_0 | Output | I/O user defined |
| Pin5  | uart_rx   | Input  | UART receive |
| Pin6  | uart_tx   | Output | UART send |
| Pin7  | user_io_1 | Output | I/O user defined |
| Pin8  | user_io_2 | Output | I/O user defined |
| Pin9  | user_io_3 | Output | I/O user defined |
| Pin10 | user_io_4 | Output | I/O user defined |
| Pin14 | cs_2      | Output | spi cable select 2 |



## Security
- Session Key handshake thingy
    - "easy" to implement Hash Algorithm (MD5)
    - neglect more secure options for easily implementable alternatives

### Masking (LVL 2)
- robustness against SCA (power traces)

### Threat protection (LVL 3)
- collect information about realistic hardware threats (and model accordingly)
    - build countermeasures?
- discard unrealistic hardware threats (i.e. Laser fault injection) and explain why