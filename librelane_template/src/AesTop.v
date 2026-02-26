// Generator : SpinalHDL v1.12.3    git head : 591e64062329e5e2e2b81f4d52422948053edb97
// Component : AesTop_WithAesIterative
// Git hash  : 1e0751b11cc7afb9e3f4716735fb6f9d1183579e

//`timescale 1ns/1ps

module AesTop (
  input  wire          io_start,
  input  wire          io_decrypt,
  input  wire          io_key_bit,
  input  wire          io_dataIn_bit,
  output reg           io_dataOut_bit,
  output reg           io_busy,
  output reg           io_done,
  input  wire          io_clk,
  input  wire          io_reset
  //output wire [7:0]    bidir_out
);

  reg                 area_aes_io_start;
  wire       [127:0]  area_aes_io_dataOut;
  wire                area_aes_io_busy;
  wire                area_aes_io_done;
  wire       [0:0]    _zz_area_keyExpanded;
  wire       [116:0]  _zz_area_keyExpanded_1;
  wire       [0:0]    _zz_area_keyExpanded_2;
  wire       [100:0]  _zz_area_keyExpanded_3;
  wire       [0:0]    _zz_area_keyExpanded_4;
  wire       [84:0]   _zz_area_keyExpanded_5;
  wire       [0:0]    _zz_area_keyExpanded_6;
  wire       [68:0]   _zz_area_keyExpanded_7;
  wire       [0:0]    _zz_area_keyExpanded_8;
  wire       [52:0]   _zz_area_keyExpanded_9;
  wire       [0:0]    _zz_area_keyExpanded_10;
  wire       [36:0]   _zz_area_keyExpanded_11;
  wire       [0:0]    _zz_area_keyExpanded_12;
  wire       [20:0]   _zz_area_keyExpanded_13;
  wire       [0:0]    _zz_area_keyExpanded_14;
  wire       [4:0]    _zz_area_keyExpanded_15;
  wire       [0:0]    _zz_area_dataExpanded;
  wire       [116:0]  _zz_area_dataExpanded_1;
  wire       [0:0]    _zz_area_dataExpanded_2;
  wire       [100:0]  _zz_area_dataExpanded_3;
  wire       [0:0]    _zz_area_dataExpanded_4;
  wire       [84:0]   _zz_area_dataExpanded_5;
  wire       [0:0]    _zz_area_dataExpanded_6;
  wire       [68:0]   _zz_area_dataExpanded_7;
  wire       [0:0]    _zz_area_dataExpanded_8;
  wire       [52:0]   _zz_area_dataExpanded_9;
  wire       [0:0]    _zz_area_dataExpanded_10;
  wire       [36:0]   _zz_area_dataExpanded_11;
  wire       [0:0]    _zz_area_dataExpanded_12;
  wire       [20:0]   _zz_area_dataExpanded_13;
  wire       [0:0]    _zz_area_dataExpanded_14;
  wire       [4:0]    _zz_area_dataExpanded_15;
  reg                 area_sampledKeyBit;
  reg                 area_sampledDataBit;
  wire       [127:0]  area_keyExpanded;
  wire       [127:0]  area_dataExpanded;
  reg        [1:0]    area_state;
  wire       [1:0]    area_IDLE;
  wire       [1:0]    area_START;
  wire       [1:0]    area_WAIT;
  wire       [1:0]    area_DONE;
/*
    logic [31:0] sram_0_out;

    RM_IHPSG13_1P_1024x32_c2_bm_bist sram_0 (
        .A_CLK  (io_clk),
        .A_MEN  (1'b1),
        .A_WEN  (1'b0),
        .A_REN  (1'b1),
        .A_ADDR ('0),
        .A_DIN  ('0),
        .A_DLY  (1'b1), // tie high!
        .A_DOUT (sram_0_out),
        .A_BM   ('0),
        
        // Built-in self test port
        .A_BIST_CLK   ('0),
        .A_BIST_EN    ('0),
        .A_BIST_MEN   ('0),
        .A_BIST_WEN   ('0),
        .A_BIST_REN   ('0),
        .A_BIST_ADDR  ('0),
        .A_BIST_DIN   ('0),
        .A_BIST_BM    ('0)
    );

    logic [31:0] sram_1_out;

    RM_IHPSG13_1P_1024x32_c2_bm_bist sram_1 (
        .A_CLK  (io_clk),
        .A_MEN  (1'b1),
        .A_WEN  (1'b0),
        .A_REN  (1'b1),
        .A_ADDR ('0),
        .A_DIN  ('0),
        .A_DLY  (1'b1), // tie high!
        .A_DOUT (sram_1_out),
        .A_BM   ('0),
        
        // Built-in self test port
        .A_BIST_CLK   ('0),
        .A_BIST_EN    ('0),
        .A_BIST_MEN   ('0),
        .A_BIST_WEN   ('0),
        .A_BIST_REN   ('0),
        .A_BIST_ADDR  ('0),
        .A_BIST_DIN   ('0),
        .A_BIST_BM    ('0)
    );

    assign bidir_out = {7'b0, (^sram_0_out) ^ (^sram_1_out)};
*/

  assign _zz_area_keyExpanded = area_sampledKeyBit;
  assign _zz_area_keyExpanded_1 = {area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{_zz_area_keyExpanded_2,_zz_area_keyExpanded_3}}}}}}}}}}}}}}}};
  assign _zz_area_keyExpanded_2 = area_sampledKeyBit;
  assign _zz_area_keyExpanded_3 = {area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{_zz_area_keyExpanded_4,_zz_area_keyExpanded_5}}}}}}}}}}}}}}}};
  assign _zz_area_keyExpanded_4 = area_sampledKeyBit;
  assign _zz_area_keyExpanded_5 = {area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{_zz_area_keyExpanded_6,_zz_area_keyExpanded_7}}}}}}}}}}}}}}}};
  assign _zz_area_keyExpanded_6 = area_sampledKeyBit;
  assign _zz_area_keyExpanded_7 = {area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{_zz_area_keyExpanded_8,_zz_area_keyExpanded_9}}}}}}}}}}}}}}}};
  assign _zz_area_keyExpanded_8 = area_sampledKeyBit;
  assign _zz_area_keyExpanded_9 = {area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{_zz_area_keyExpanded_10,_zz_area_keyExpanded_11}}}}}}}}}}}}}}}};
  assign _zz_area_keyExpanded_10 = area_sampledKeyBit;
  assign _zz_area_keyExpanded_11 = {area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{_zz_area_keyExpanded_12,_zz_area_keyExpanded_13}}}}}}}}}}}}}}}};
  assign _zz_area_keyExpanded_12 = area_sampledKeyBit;
  assign _zz_area_keyExpanded_13 = {area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{_zz_area_keyExpanded_14,_zz_area_keyExpanded_15}}}}}}}}}}}}}}}};
  assign _zz_area_keyExpanded_14 = area_sampledKeyBit;
  assign _zz_area_keyExpanded_15 = {area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,area_sampledKeyBit}}}};
  assign _zz_area_dataExpanded = area_sampledDataBit;
  assign _zz_area_dataExpanded_1 = {area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{_zz_area_dataExpanded_2,_zz_area_dataExpanded_3}}}}}}}}}}}}}}}};
  assign _zz_area_dataExpanded_2 = area_sampledDataBit;
  assign _zz_area_dataExpanded_3 = {area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{_zz_area_dataExpanded_4,_zz_area_dataExpanded_5}}}}}}}}}}}}}}}};
  assign _zz_area_dataExpanded_4 = area_sampledDataBit;
  assign _zz_area_dataExpanded_5 = {area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{_zz_area_dataExpanded_6,_zz_area_dataExpanded_7}}}}}}}}}}}}}}}};
  assign _zz_area_dataExpanded_6 = area_sampledDataBit;
  assign _zz_area_dataExpanded_7 = {area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{_zz_area_dataExpanded_8,_zz_area_dataExpanded_9}}}}}}}}}}}}}}}};
  assign _zz_area_dataExpanded_8 = area_sampledDataBit;
  assign _zz_area_dataExpanded_9 = {area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{_zz_area_dataExpanded_10,_zz_area_dataExpanded_11}}}}}}}}}}}}}}}};
  assign _zz_area_dataExpanded_10 = area_sampledDataBit;
  assign _zz_area_dataExpanded_11 = {area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{_zz_area_dataExpanded_12,_zz_area_dataExpanded_13}}}}}}}}}}}}}}}};
  assign _zz_area_dataExpanded_12 = area_sampledDataBit;
  assign _zz_area_dataExpanded_13 = {area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{_zz_area_dataExpanded_14,_zz_area_dataExpanded_15}}}}}}}}}}}}}}}};
  assign _zz_area_dataExpanded_14 = area_sampledDataBit;
  assign _zz_area_dataExpanded_15 = {area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,area_sampledDataBit}}}};
  AesIterative area_aes (
    .io_start   (area_aes_io_start         ), //i
    .io_decrypt (io_decrypt                ), //i
    .io_key     (area_keyExpanded[127:0]   ), //i
    .io_dataIn  (area_dataExpanded[127:0]  ), //i
    .io_dataOut (area_aes_io_dataOut[127:0]), //o
    .io_busy    (area_aes_io_busy          ), //o
    .io_done    (area_aes_io_done          ), //o
    .clk     (io_clk                    ), //i
    .reset   (io_reset                  )  //i
  );
  assign area_keyExpanded = {area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{area_sampledKeyBit,{_zz_area_keyExpanded,_zz_area_keyExpanded_1}}}}}}}}}}};
  assign area_dataExpanded = {area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{area_sampledDataBit,{_zz_area_dataExpanded,_zz_area_dataExpanded_1}}}}}}}}}}};
  assign area_IDLE = 2'b00;
  assign area_START = 2'b01;
  assign area_WAIT = 2'b10;
  assign area_DONE = 2'b11;
  always @(*) begin
    area_aes_io_start = 1'b0;
    if((area_state == area_IDLE)) begin
        if(io_start) begin
          area_aes_io_start = 1'b1;
        end
    end else if((area_state == area_START)) begin
    end else if((area_state == area_WAIT)) begin
    end else if((area_state == area_DONE)) begin
    end
  end

  always @(*) begin
    io_busy = 1'b0;
    if((area_state == area_IDLE)) begin
        if(io_start) begin
          io_busy = 1'b1;
        end
    end else if((area_state == area_START)) begin
        io_busy = 1'b1;
    end else if((area_state == area_WAIT)) begin
       io_busy = area_aes_io_busy;
    end else if((area_state == area_DONE)) begin
        io_busy = 1'b0;
    end
  end

  always @(*) begin
    io_done = 1'b0;
    if((area_state == area_IDLE)) begin
    end else if((area_state == area_START)) begin
    end else if((area_state == area_WAIT)) begin
    end else if((area_state == area_DONE)) begin
        io_done = 1'b1;
    end
  end

  always @(*) begin
    io_dataOut_bit = 1'b0;
    if((area_state == area_IDLE)) begin
    end else if((area_state == area_START)) begin
    end else if((area_state == area_WAIT)) begin
    end else if((area_state == area_DONE)) begin
        io_dataOut_bit = (^area_aes_io_dataOut);
    end
  end

  always @(posedge io_clk or posedge io_reset) begin
    if(io_reset) begin
      area_sampledKeyBit <= 1'b0;
      area_sampledDataBit <= 1'b0;
      area_state <= 2'b00;
    end else begin
      area_sampledKeyBit <= io_key_bit;
      area_sampledDataBit <= io_dataIn_bit;
      if((area_state == area_IDLE)) begin
          if(io_start) begin
            area_state <= area_START;
          end
      end else if((area_state == area_START)) begin
          area_state <= area_WAIT;
      end else if((area_state == area_WAIT)) begin
          if(area_aes_io_done) begin
            area_state <= area_DONE;
          end
      end else if((area_state == area_DONE)) begin
          area_state <= area_IDLE;
      end
    end
  end


endmodule

