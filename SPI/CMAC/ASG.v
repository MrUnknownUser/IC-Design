// Generator : SpinalHDL v1.10.2a    git head : a348a60b7e8b6a455c72e1536ec3d74a2ea16935
// Component : ASG
// Git hash  : 2e584748354e3f600c452babd6955da3da9b0735

`timescale 1ns/1ps

module ASG (
  input  wire [1:0]    loadIt,
  input  wire          load,
  input  wire          enable,
  output wire          newBit,
  input  wire          clk,
  input  wire          reset
);

  wire                R1_enable;
  wire                R2_enable;
  wire                R3_enable;
  wire                R1_newBit;
  wire                R2_newBit;
  wire                R3_newBit;
  wire                loadR1;
  wire                loadR2;
  wire                loadR3;

  LSFR R1 (
    .load   (load     ), //i
    .loadIt (loadR1   ), //i
    .enable (R1_enable), //i
    .newBit (R1_newBit), //o
    .clk    (clk      ), //i
    .reset  (reset    )  //i
  );
  LSFR_1 R2 (
    .load   (load     ), //i
    .loadIt (loadR2   ), //i
    .enable (R2_enable), //i
    .newBit (R2_newBit), //o
    .clk    (clk      ), //i
    .reset  (reset    )  //i
  );
  LSFR_2 R3 (
    .load   (load     ), //i
    .loadIt (loadR3   ), //i
    .enable (R3_enable), //i
    .newBit (R3_newBit), //o
    .clk    (clk      ), //i
    .reset  (reset    )  //i
  );
  assign loadR1 = (loadIt == 2'b01);
  assign loadR2 = (loadIt == 2'b10);
  assign loadR3 = (loadIt == 2'b11);
  assign R1_enable = (enable || loadR1);
  assign R2_enable = ((enable && R1_newBit) || loadR2);
  assign R3_enable = ((enable && (! R1_newBit)) || loadR3);
  assign newBit = (R2_newBit ^ R3_newBit);

endmodule

module LSFR_2 (
  input  wire          load,
  input  wire          loadIt,
  input  wire          enable,
  output wire          newBit,
  input  wire          clk,
  input  wire          reset
);

  wire       [88:0]   fsRegN;
  reg        [88:0]   fsReg;
  wire                taps_0;
  wire                taps_1;
  reg                 genBit;

  assign taps_0 = fsReg[0];
  assign taps_1 = fsReg[51];
  always @(*) begin
    genBit = (taps_0 ^ taps_1);
    if(loadIt) begin
      genBit = load;
    end
  end

  assign newBit = fsReg[0];
  assign fsRegN = {genBit,fsReg[88 : 1]};
  always @(posedge clk) begin
    if(reset) begin
      fsReg <= 89'h0;
    end else begin
      if(enable) begin
        fsReg <= fsRegN;
      end
    end
  end


endmodule

module LSFR_1 (
  input  wire          load,
  input  wire          loadIt,
  input  wire          enable,
  output wire          newBit,
  input  wire          clk,
  input  wire          reset
);

  wire       [126:0]  fsRegN;
  reg        [126:0]  fsReg;
  wire                taps_0;
  wire                taps_1;
  reg                 genBit;

  assign taps_0 = fsReg[0];
  assign taps_1 = fsReg[126];
  always @(*) begin
    genBit = (taps_0 ^ taps_1);
    if(loadIt) begin
      genBit = load;
    end
  end

  assign newBit = fsReg[0];
  assign fsRegN = {genBit,fsReg[126 : 1]};
  always @(posedge clk) begin
    if(reset) begin
      fsReg <= 127'h0;
    end else begin
      if(enable) begin
        fsReg <= fsRegN;
      end
    end
  end


endmodule

module LSFR (
  input  wire          load,
  input  wire          loadIt,
  input  wire          enable,
  output wire          newBit,
  input  wire          clk,
  input  wire          reset
);

  wire       [30:0]   fsRegN;
  reg        [30:0]   fsReg;
  wire                taps_0;
  wire                taps_1;
  reg                 genBit;

  assign taps_0 = fsReg[0];
  assign taps_1 = fsReg[28];
  always @(*) begin
    genBit = (taps_0 ^ taps_1);
    if(loadIt) begin
      genBit = load;
    end
  end

  assign newBit = fsReg[0];
  assign fsRegN = {genBit,fsReg[30 : 1]};
  always @(posedge clk) begin
    if(reset) begin
      fsReg <= 31'h0;
    end else begin
      if(enable) begin
        fsReg <= fsRegN;
      end
    end
  end


endmodule
