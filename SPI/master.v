module SPI_master(clk, SCK, MOSI, MISO, SSEL);
input clk;  // internal clock

output SCK, SSEL, MOSI;  // instructions for slave
input MISO;  // receiver line from slave to master