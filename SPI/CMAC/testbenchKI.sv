`timescale 1ns/1ps
//`include "SPI_Master_With_Single_CS.v"
//`include "AesIterative.v"
`include "CMAC_DEA.v"

module tb_cmac_handshake;

  // Clock / reset
  reg clk = 0;
  reg rst = 0;

  // DUT inputs
  reg in = 0;

  // SPI signals
  wire o_SPI_Clk;
  reg i_SPI_MISO = 1'b1;
  wire o_SPI_MOSI;
  wire o_SPI_CS_n;

  // DUT outputs
  wire lock_state;

  // Instantiate DUT
  cmac_handshake dut (
    .clk(clk),
    .rst(rst),
    .in(in),
    .lock_state(lock_state),
    .o_SPI_Clk(o_SPI_Clk),
    .i_SPI_MISO(i_SPI_MISO),
    .o_SPI_MOSI(o_SPI_MOSI),
    .o_SPI_CS_n(o_SPI_CS_n)
  );

  // Clock generator: 10 ns period -> 100 MHz
  always #5 clk = ~clk;

  // Task: shift out a byte on MISO synchronized to SPI clock (mode 0)
  // Note: This is a simplified model: SPI_Master_With_Single_CS generiert o_SPI_Clk,
  // we sample bits on falling/rising edge depending on module implementation.
  task automatic spi_slave_send_byte(input [7:0] data);
    integer i;
    begin
      // Provide 8 bits on MISO, MSB first
      for (i = 7; i >= 0; i = i - 1) begin
        // Wait for SPI clock edges - adjust depending on master implementation.
        // Here we align bit changes to falling edge of o_SPI_Clk to model standard mode 0 timing.
        @(negedge o_SPI_Clk);
        i_SPI_MISO <= data[i];
        // leave stable for whole half-bit
        @(posedge o_SPI_Clk);
      end
      // small delay after byte
      #20;
    end
  endtask

  initial begin
    // initialize
    $display("[%0t] Starting testbench", $time);

    // release reset after some cycles
    #20;
    rst = 1;
    #20;
    rst = 0; // your SPI master expects active low reset? You pass rst as i_Rst_L — in your DUT you connected rst directly.
            // If i_Rst_L is active-low, you should pass rst as 1'b1 for not reset. Adjust if needed.
    #20;

    // Stimulate input to start authentication
    @(posedge clk);
    in <= 1'b1;
    //@(posedge clk);
    //in <= 1'b0;

    // Wait for SPI CS to go low (transaction starts)
    @(posedge clk);
    o_SPI_CS_n = 1'b0;

    @(posedge clk);
    wait (o_SPI_CS_n == 1'b0);
    $display("[%0t] SPI CS asserted", $time);

    // For this simple test: respond with a 1-byte response for the auth_init exchange
    // send a single byte (e.g. 8'hAA) as challenge MSB first
    spi_slave_send_byte(8'hAA);

    // Wait for CS inactive
    wait (o_SPI_CS_n == 1'b1);
    $display("[%0t] SPI CS deasserted", $time);

    // add more stimulus cycles: e.g. simulate additional SPI exchanges
    #100;

    // Check lock state transitions
    $display("[%0t] lock_state = %b", $time, lock_state);

    // End simulation
    #200;
    $display("[%0t] End simulation", $time);
    $finish;
  end

  // Monitor some signals
  initial begin
    $dumpfile("tb_cmac_handshake.vcd");
    $dumpvars(0, tb_cmac_handshake);
  end

endmodule