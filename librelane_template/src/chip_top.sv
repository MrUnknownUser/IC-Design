// SPDX-FileCopyrightText: © 2025 LibreLane Template Contributors
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module chip_top #(
    // Power/ground pads for core
    parameter NUM_VDD_PADS = 1,
    parameter NUM_VSS_PADS = 1,
    
    // Power/ground pads for I/O
    parameter NUM_IOVDD_PADS = 1,
    parameter NUM_IOVSS_PADS = 1,
    
    // Signal pads
    parameter NUM_INPUT_PADS  = 8,
    parameter NUM_OUTPUT_PADS = 10
    //parameter NUM_BIDIR_PADS  = 0,
    //parameter NUM_ANALOG_PADS = 0
    )(
    `ifdef USE_POWER_PINS
    inout wire IOVDD,
    inout wire IOVSS,
    inout wire VDD,
    inout wire VSS,
    `endif
    inout  wire clk_PAD,
    inout  wire rst_n_PAD,
    inout  wire [NUM_INPUT_PADS-1 :0] input_PAD,
    inout  wire [NUM_OUTPUT_PADS-1:0] output_PAD
    //inout  wire [NUM_BIDIR_PADS-1 :0] bidir_PAD,
    //inout  wire [NUM_ANALOG_PADS-1:0] analog_PAD
);

    wire clk_PAD2CORE;
    wire rst_n_PAD2CORE;
    wire [NUM_INPUT_PADS-1 :0] input_PAD2CORE;
    wire [NUM_OUTPUT_PADS-1:0] output_CORE2PAD;
    //wire [NUM_BIDIR_PADS-1 :0] bidir_PAD2CORE;
    //wire [NUM_BIDIR_PADS-1 :0] bidir_CORE2PAD;
    //wire [NUM_BIDIR_PADS-1 :0] bidir_CORE2PAD_OE;
    //wire [NUM_ANALOG_PADS-1:0] analog_PADRES;

    // Power/ground pad instances
    generate
    for (genvar i=0; i<NUM_IOVDD_PADS; i++) begin : iovdd_pads
        (* keep *)
        sg13g2_IOPadIOVdd iovdd_pad  (
            `ifdef USE_POWER_PINS
            .iovdd  (IOVDD),
            .iovss  (IOVSS),
            .vdd    (VDD),
            .vss    (VSS)
            `endif
        );
    end
    for (genvar i=0; i<NUM_IOVSS_PADS; i++) begin : iovss_pads
        (* keep *)
        sg13g2_IOPadIOVss iovss_pad  (
            `ifdef USE_POWER_PINS
            .iovdd  (IOVDD),
            .iovss  (IOVSS),
            .vdd    (VDD),
            .vss    (VSS)
            `endif
        );
    end
    for (genvar i=0; i<NUM_VDD_PADS; i++) begin : vdd_pads
        (* keep *)
        sg13g2_IOPadVdd vdd_pad  (
            `ifdef USE_POWER_PINS
            .iovdd  (IOVDD),
            .iovss  (IOVSS),
            .vdd    (VDD),
            .vss    (VSS)
            `endif
        );
    end
    for (genvar i=0; i<NUM_VSS_PADS; i++) begin : vss_pads
        (* keep *)
        sg13g2_IOPadVss vss_pad  (
            `ifdef USE_POWER_PINS
            .iovdd  (IOVDD),
            .iovss  (IOVSS),
            .vdd    (VDD),
            .vss    (VSS)
            `endif
        );
    end
    endgenerate

    // Signal IO pad instances

    // Schmitt trigger
    sg13g2_IOPadIn clk_pad (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS),
        `endif
        .p2c    (clk_PAD2CORE),
        .pad    (clk_PAD)
    );
    
    // Normal input
    sg13g2_IOPadIn rst_n_pad (
        `ifdef USE_POWER_PINS
        .iovdd  (IOVDD),
        .iovss  (IOVSS),
        .vdd    (VDD),
        .vss    (VSS),
        `endif
        .p2c    (rst_n_PAD2CORE),
        .pad    (rst_n_PAD)
    );

    generate
    for (genvar i=0; i<NUM_INPUT_PADS; i++) begin : inputs
        sg13g2_IOPadIn input_pad (
            `ifdef USE_POWER_PINS
            .iovdd  (IOVDD),
            .iovss  (IOVSS),
            .vdd    (VDD),
            .vss    (VSS),
            `endif
            .p2c    (input_PAD2CORE[i]),
            .pad    (input_PAD[i])
        );
    end
    endgenerate

    generate
    for (genvar i=0; i<NUM_OUTPUT_PADS; i++) begin : outputs
        sg13g2_IOPadOut30mA output_pad (
            `ifdef USE_POWER_PINS
            .iovdd  (IOVDD),
            .iovss  (IOVSS),
            .vdd    (VDD),
            .vss    (VSS),
            `endif
            .c2p    (output_CORE2PAD[i]),
            .pad    (output_PAD[i])
        );
    end
    endgenerate
    
    generate
    if (NUM_INPUT_PADS > 4) 
    	begin : g_consume_unused_inputs
		wire _unused_inputs_hi;
		assign _unused_inputs_hi = |input_PAD2CORE[NUM_INPUT_PADS-1:4];
	end
    endgenerate

	// Unused output bits [NUM_OUTPUT_PADS-1:3] treiben
	generate
	if (NUM_OUTPUT_PADS > 3) begin : g_tieoff_unused_outputs
	    assign output_CORE2PAD[NUM_OUTPUT_PADS-1:3] = '0;
	end
	endgenerate


    // Core design

    (* keep *) //AesTop (
        //.NUM_INPUT_PADS  (NUM_INPUT_PADS),
        //.NUM_OUTPUT_PADS (NUM_OUTPUT_PADS)
        //.NUM_BIDIR_PADS  (NUM_BIDIR_PADS),
        //.NUM_ANALOG_PADS (NUM_ANALOG_PADS)
    //); i_AesTop (
    AesTop AesTop(
        .io_clk          (clk_PAD2CORE),
        .io_reset        (rst_n_PAD2CORE),
        .io_dataIn_bit   (input_PAD2CORE[0]),
        .io_start        (input_PAD2CORE[1]),
        .io_decrypt      (input_PAD2CORE[2]),
        .io_key_bit      (input_PAD2CORE[3]),
        .io_dataOut_bit  (output_CORE2PAD[0]),
        .io_busy         (output_CORE2PAD[1]),
        .io_done         (output_CORE2PAD[2])
    );

endmodule

`default_nettype wire
