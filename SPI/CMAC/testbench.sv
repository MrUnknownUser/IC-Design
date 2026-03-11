`timescale 1ns/1ps
`include "CMAC_DEA.v"

module CMAC_TESTING();
  logic      clk = 1'b0;
  logic       rst = 1'b0;
  logic in = 1'b0;
  reg lock_state;
  logic o_SPI_Clk;
  logic i_SPI_MISO;
  logic o_SPI_MOSI;
  logic o_SPI_CS_n;
  logic rec_ID = 128'b0;
    
    // Clock Generators:
  always #(2) clk = ~clk;
  
  cmac_handshake cmac1 (
    clk,
    rst,
    in,
    lock_state,
    o_SPI_Clk, 
    i_SPI_MISO, 
    o_SPI_MOSI, 
    o_SPI_CS_n 
  );


  initial begin
        $display("[%0t] Starting testbench", $time);
        // Assert reset
        rst = 1'b1;
        @(posedge clk);

        // Deassert reset
        rst = 1'b0;
        @(posedge clk);

        in <= 1'b1;
        @(posedge clk);

        in <= 1'b0;
        @(posedge clk);
  end


  initial
    begin
      // Required for EDA Playground
      $dumpfile("dump.vcd"); 
      $dumpvars;
      in <= 1'b1;
      repeat(100000) @(posedge clk);
      in <= 1'b0;
      $display("[%0t] Finished testbench", $time);
      $finish();    
    end

endmodule