`timescale 1ns/1ps
// INCLUDES 
`include "SPI_Master_With_Single_CS.v" 
`include "AesIterative.v"
`include "ASG.v"

module cmac_handshake ( 
    input clk, 
    input rst, 
    input in, 
    output reg lock_state, // 0 = locked, 1 = unlocked
    // SPI Interface 
    output o_SPI_Clk, 
    input i_SPI_MISO, 
    output o_SPI_MOSI, 
    output o_SPI_CS_n 
    // ASG Interface 
    //... 
    // AES Interface 
    //... 
    );

// State definitions 
localparam S0 = 3'b000; // IDLE 
localparam S1 = 3'b001; // REC_CHALLENGE -> start SPI transfer 
localparam S2 = 3'b010; // GEN_CHALLENGE 
localparam S3 = 3'b011; // STORE_EPH_KEY 
localparam S4 = 3'b100; // REC_ID 
localparam S5 = 3'b101; // UNLOCKED

// State definitions 
localparam CLA_PROPRIETARY = 8'h80;
localparam INS_AUTH_INIT   = 8'h10;
localparam INS_AUTH        = 8'h11;
localparam INS_GET_ID      = 8'h12;


// stupid shit
logic state1_flag1;
logic state1_flag2;
logic state1_flag3;
logic w_RX_DV_last_clk = 1'b0;
logic state2_flag0;
logic state2_flag1;
logic state2_flag2;
logic state2_flag3;
logic io_done_last_clk = 1'b0;




reg [2:0] state, next_state;
reg       next_lock_state;

reg valid_ID;
reg [127:0] rec_ID;
reg [63:0] rec_Challenge = 64'b00;
reg [127:0] eph_key_dec;
reg [127:0] eph_key_enc;


// --- SPI-signals ---
localparam MAX_BYTES_PER_CS = 2; 
wire w_TX_Ready; 
wire w_RX_DV; 
wire [7:0] w_RX_Byte; 
wire [$clog2(MAX_BYTES_PER_CS+1)-1:0] w_RX_Count = 2'b10;
//wire [1:0] w_RX_Count = 2'b10;

reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] i_TX_Count_reg = 2'b10;
reg [7:0] i_TX_Byte_reg;
reg i_TX_DV_reg;


reg [7:0] tx_buf [0:15];
reg [3:0] tx_len;     // 0..15 
reg [3:0] tx_idx;     // Index for sending
reg [7:0] rx_buf [0:15];
integer i;
initial begin
    for (i = 0; i < 16; i = i + 1) begin
        rx_buf[i] = 8'h00;
    end
end
logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] received_byte_count = 2'b00;

// --- instantiatae SPI Master ---
SPI_Master_With_Single_CS
  #(.SPI_MODE(3),
    .CLKS_PER_HALF_BIT(5),
    .MAX_BYTES_PER_CS(MAX_BYTES_PER_CS),
    .CS_INACTIVE_CLKS(10))
spi_inst (
    .i_Rst_L(~rst),
    .i_Clk(clk),

    .i_TX_Count(i_TX_Count_reg),
    .i_TX_Byte(i_TX_Byte_reg),
    .i_TX_DV(i_TX_DV_reg),
    .o_TX_Ready(w_TX_Ready),

    .o_RX_Count(w_RX_Count),
    .o_RX_DV(w_RX_DV),
    .o_RX_Byte(w_RX_Byte),

    .o_SPI_Clk(o_SPI_Clk),
    //.i_SPI_MISO(i_SPI_MISO),
    .i_SPI_MISO(o_SPI_MOSI),
    //.o_SPI_MOSI(o_SPI_MOSI),
    .o_SPI_MOSI(o_SPI_MOSI),
    .o_SPI_CS_n(o_SPI_CS_n)
);
logic tx_dv_pending;



// AES STUFF HERE
logic          io_start = 1'b0;
logic          io_decrypt = 1'b0;
logic [127:0]  io_key = 128'H39558d1f193656ab8b4b65e25ac48474; // KEYCARD KEY
logic [127:0]  io_dataIn;
logic  [127:0]  io_dataOut;
wire          io_busy;
logic           io_done;

wire [127:0]  test_key = 128'H2b7e151628aed2a6abf7158809cf4f3c; // key for AES test
//                            2b7e151628aed2a6abf7158809cf4f3c
logic [127:0] test_cipher = 128'H3925841d02dc09fbdc118597196a0b32; // ciphertext for AES test
//                               3925841d02dc09fbdc118597196a0b32
logic [127:0] test_plain = 128'H3243f6a8885a308d313198a2e0370734; // plaintext for AES test
//                              3243f6a8885a308d313198a2e0370734

AesIterative AES1 (
io_start,
io_decrypt,
io_key,
io_dataIn,
io_dataOut,
io_busy,
io_done,
clk,
rst
);
// _AES





// ASG STUFF HERE
// Intialize ASG variables (careful! signals (hence wires and registers!)
logic [1:0] loadIt = 2'b0;
logic       load = 1'b0;
logic       enable = 1'b0;
wire        newBit;  // ASG output


ASG asg1 (
    loadIt,
    load,
    enable,
    newBit,
    clk,
    rst
);

logic init_done = 1'b0;
logic [5:0] count; // 6 Bit counter: 0..63 
logic [63:0] own_Challenge;
logic sampling = 1'b0;
logic enable_sample = 1'b0; // start, when this goes high
logic [63:0] own_challenge; 
logic sampled_done = 1'b0; // high when 64 bits have been sampled





// Initialize ASG (and LSFRs) with non zero seeds
initial begin
        // fill R1 with zeroes
    	repeat (31) begin
            loadIt <= 2'b01;
    	    enable <= 1'b1;
    	    load <= 1'b0;
            @(posedge clk);
        end
    	//
        // seed R1 with b'11101111011110111101
    	loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

    	loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

    	loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

    	loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

    	loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b01;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	// fill R2 with zeroes
        repeat (127) begin
        	loadIt <= 2'b10;
        	enable <= 1'b1;
    	    load <= 1'b0;
            @(posedge clk);
        end
    

        
    	// seed R2 with b'0110011001100110110101101011010110101101011010110101101011010001001001001001001001001
        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);
    	
    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);
    	
    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);
    	
    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);
    	
    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);
    	
    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);
    	
    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);
    	
    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);
    	
    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
        @(posedge clk);
    	
    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

    	loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b0;
    	@(posedge clk);

        loadIt <= 2'b10;
    	enable <= 1'b1;
    	load <= 1'b1;
    	@(posedge clk);
    	
    	// fill R3 with zeroes
        repeat (89) begin
        	loadIt <= 2'b11;
        	enable <= 1'b1;
    	    load <= 1'b1;
    	    @(posedge clk);
        end 
        
      	// seed R3 with many one's
    	repeat (60) begin
    		loadIt <= 2'b11;
    		enable <= 1'b1;
    		load <= 1'b1;
    		#1;
    	end
        
        // Stop loading
        loadIt <= 2'b00;
      	load <= 1'b0;
        #1;

        // Enable the ASG
        //#(1600); use if bad randomness at init_done clockedge
        enable <= 1'b1;
        init_done <= 1'b1;
    end
// _ASG





// State storage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S0;
            lock_state <= 1'b0;
            received_byte_count <= 1'b0;
        end else begin
            state <= next_state;
            lock_state <= next_lock_state;
        end
    end

// Next-State-Logik 
    always @(*) begin 
        // Default 
        valid_ID = 1'b0; 

        // Default SPI control signals 
        i_TX_DV_reg = 1'b0; 
        i_TX_Count_reg = 0;



    case (state)
        S0: begin
            if (in) next_state = S1;
            $display("[%0t] switched to S1", $time);
            received_byte_count <= 1'b0;
        end
        
        S1: begin
            if (o_SPI_CS_n && (w_RX_DV_last_clk == 1'b1)) begin
                if (~state2_flag0) begin
                    state2_flag0 <= 1'b1;
                end else begin
                    w_RX_DV_last_clk <= 1'b0;
                    next_state <= S2;
                    $display("[%0t] switched to S2", $time);
                    $display("rx_buf[0]: %X", rx_buf[0]);
                    $display("rx_buf[1]: %X", rx_buf[1]);
                    $display("rx_buf[2]: %X", rx_buf[2]);
                    $display("rx_buf[3]: %X", rx_buf[3]);
                    state2_flag0 <= 1'b0;
                end
            end
        end

        S2:  begin 
            if ((~io_done) && (io_done_last_clk == 1'b1)) begin
                if (~state2_flag1) begin
                    $display("S2 termination??");
                    state2_flag1 <= 1'b1;
                end else begin
                    $display("S2 termination!!");
                    io_done_last_clk <= 1'b0;
                    next_state <= S3;
                    enable_sample <= 1'b1;
                    state2_flag1 <= 1'b0;
                    io_decrypt <= 1'b0;
                end
            end
        end
        S3: begin 
            
            if (sampled_done) begin
                // send own challenge as padded 8 bytes + 8 byte challenge?
                enable_sample = 1'b0;
                next_state = S4;
                eph_key_dec [127:64] <= rec_Challenge;  // [15:8]
                // check if lower 8 bytes are 0? --
                eph_key_dec [63:0] <= own_Challenge;  // [7:0]
                $display("rec_Challenge? %X", rec_Challenge);
                $display("own_Challenge? %X", own_Challenge);
                $display("eph_key_dec? %X", eph_key_dec);

                @(posedge clk);
                //io_dataIn <= eph_key_dec;
                io_dataIn <= test_plain;
                io_key <= test_key;

                io_decrypt <= 1'b0;
                io_start <= 1'b1;
                @(posedge clk);
                io_start <= 1'b0;

                @(posedge io_done);
                eph_key_enc <= io_dataOut;
                $display("eph_key_enc? %X", eph_key_enc);
                
                @(posedge clk);
            end else begin
                next_state = S3;
            end
            
        end
        S4: begin
            //receive ID
            // check ID CARD_A_ID = 128'Hbbe8278a67f960605adafd6f63cf7ba7;
            // if valid, change state
            if (1) next_state = S5; 
        end
        S5: next_state = S0;
        default: next_state = S0;
    endcase
end


// --- synchronous thingy layout ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // clear tx_buf
        // does this synthesise?
        for (i = 0; i < 16; i = i + 1) tx_buf[i] <= 8'h00;

        //$display("tx_buf: %X", tx_buf[0]);
        tx_idx <= 0;
        tx_len <= 0;
        i_TX_DV_reg <= 1'b0;
        i_TX_Byte_reg <= 8'h00;
        i_TX_Count_reg <= 0;
        state1_flag1 <= 1'b0;
        state1_flag2 <= 1'b0;
        state1_flag3 <= 1'b0;
        w_RX_DV_last_clk <= 1'b0;  
        state2_flag0 <= 1'b0;
        state2_flag1 <= 1'b0;
        state2_flag2 <= 1'b0;
        state2_flag3 <= 1'b0;
        //io_done_last_clk <= 1'b0;

        //received_byte_count <= 1'b0;
        enable_sample <= 1'b0;

        valid_ID <= 1'b0;

    end else begin
        if (state == S0 && next_state == S1) begin
            tx_buf[0] <= CLA_PROPRIETARY; 
            tx_buf[1] <= INS_AUTH_INIT;
            tx_buf[2] <= 8'h00; 
            tx_buf[3] <= 8'h00; 
            $display("tx_buf[0]: %X", tx_buf[0]);
            $display("tx_buf[1]: %X", tx_buf[1]);
            $display("tx_buf[2]: %X", tx_buf[2]);
            $display("tx_buf[3]: %X", tx_buf[3]);
            tx_len <= 4;         //byte count to send
            tx_idx <= 0;
            i_TX_Count_reg <= 4;
        end

        // save byte on o_RX_DV pulse
        if (w_RX_DV) begin
            w_RX_DV_last_clk <= 1'b1;
            $display(" [][][][][%0t]  found RX pulse, saving byte", $time);
            rx_buf[received_byte_count] <= w_RX_Byte;
            received_byte_count <= received_byte_count + 1'b1;
            $display("w_RX_Byte: %X", w_RX_Byte);
            $display("received_byte_count: %X", received_byte_count);
        end

        if (state == S1 && w_TX_Ready && (tx_idx < tx_len)) begin
            $display(" [][][][][%0t]  state 1 logic", $time);
            // drive i_TX_Byte_reg and pulse i_TX_DV_reg for next byte
            if (state1_flag1) begin
                if (~state1_flag2) begin
                    state1_flag2 <= 1'b1;
                end else begin
                    i_TX_Byte_reg <= tx_buf[tx_idx];
                    i_TX_Count_reg <= tx_len; // Anzahl Bytes insgesamt
                    i_TX_DV_reg <= 1'b1;
                    tx_idx <= tx_idx + 1'b1;
                    $display("i_TX_Byte_reg: %X", i_TX_Byte_reg);
                    $display("i_TX_Count_reg: %X", i_TX_Count_reg);
                    $display("tx_len: %X", tx_len);
                end
            end else begin
                state1_flag1 <= 1'b1;
            end
        end else if (state1_flag1 && state1_flag2) begin
            if (~state1_flag3) begin
                state1_flag3 <= 1'b1;
            end else begin
                i_TX_DV_reg <= 1'b0;
                state1_flag1 <= 1'b0;
                state1_flag2 <= 1'b0;
                state1_flag3 <= 1'b0;
            end
        end

        if (state == S2 && next_state == S2) begin
            if (~state2_flag2) begin
                // decrypt 16 byte challenge here
                // generate own 8 byte challenge
                // concat first 8 bytes of challenge with own challenge
                // store as 16 byte eph_key_dec 
                $display("STATE 2 DEBUG \n rx_buf[0] %X", rx_buf[0]);
                $display("STATE 2 DEBUG \n rx_buf[1] %X", rx_buf[1]);
                $display("STATE 2 DEBUG \n counter %X bytes received", received_byte_count);
                io_dataIn [7:0]     <= rx_buf[0];
                io_dataIn [15:8]    <= rx_buf[1];
                io_dataIn [23:16]   <= rx_buf[2];
                io_dataIn [31:24]   <= rx_buf[3];
                io_dataIn [39:32]   <= rx_buf[4];
                io_dataIn [47:40]   <= rx_buf[5];
                io_dataIn [55:48]   <= rx_buf[6];
                io_dataIn [63:56]   <= rx_buf[7];
                io_dataIn [71:64]   <= rx_buf[8];
                io_dataIn [79:72]   <= rx_buf[9];
                io_dataIn [87:80]   <= rx_buf[10];
                io_dataIn [95:88]   <= rx_buf[11];
                io_dataIn [103:96]  <= rx_buf[12];
                io_dataIn [111:104] <= rx_buf[13];
                io_dataIn [119:112] <= rx_buf[14];
                io_dataIn [127:120] <= rx_buf[15];

                io_dataIn <= test_cipher;
                io_key <= test_key;

                io_decrypt <= 1'b1;
                io_start <= 1'b1;
                state2_flag2 <= 1'b1;
                $display("[%0t] vor clockedge", $time);
            end else begin
            //@(posedge clk);

                $display("[%0t] nach clockedge", $time);
                io_start <= 1'b0;

                if (~state2_flag3) begin 
                    state2_flag3 <= 1'b1;
                end else begin 
                //@(posedge io_done);
                    if (io_done) begin
                        io_done_last_clk <= 1'b1;
                        $display("io_done :)");
                        //POTENTIALLY USELESS :)
                        rx_buf[0] <= io_dataOut [7:0];
                        rx_buf[1] <= io_dataOut [15:8];
                        rx_buf[2] <= io_dataOut [23:16];
                        rx_buf[3] <= io_dataOut [31:24];
                        rx_buf[4] <= io_dataOut [39:32];
                        rx_buf[5] <= io_dataOut [47:40];
                        rx_buf[6] <= io_dataOut [55:48];
                        rx_buf[7] <= io_dataOut [63:56];
                        rx_buf[8] <= io_dataOut [71:64];
                        rx_buf[9] <= io_dataOut [79:72];
                        rx_buf[10] <= io_dataOut [87:80];
                        rx_buf[11] <= io_dataOut [95:88];
                        rx_buf[12] <= io_dataOut [103:96];
                        rx_buf[13] <= io_dataOut [111:104];
                        rx_buf[14] <= io_dataOut [119:112];
                        rx_buf[15] <= io_dataOut [127:120];

                        //store challenge from KEYCARD
                        rec_Challenge[63:0] <= io_dataOut[127:64];
                        state2_flag2 <= 1'b0; 
                        state2_flag3 <= 1'b0; 
                    end
                end
            end
        end

        if (state == S3 && next_state == S3 && init_done) begin
            if (rst) begin 
                sampling <= 1'b0; 
                count <= 6'd0; 
                own_Challenge <= 64'h0; 
                sampled_done <= 1'b0; 
            end 
            else begin 
                if (!sampling) begin 
                    sampled_done <= 1'b0; 
                    if (enable_sample) begin 
                        sampling <= 1'b1; 
                        count <= 6'd0; 
                        own_Challenge <= 64'h0; // initialize on zeros
                    end 
                end 
                else begin // sampling == 1 
                    // shift and collect
                    own_Challenge <= {own_Challenge[62:0], newBit};
                    // Alternative MSB-first_asg: own_Challenge <= {newBit, own_Challenge[63:1]};
                    if (count == 6'd63) begin
                        sampling     <= 1'b0;
                        sampled_done <= 1'b1;
                        count        <= 6'd0;
                    end
                    else begin
                        count <= count + 6'd1;
                    end
                end
            end
        end

        if (state == S4 && next_state == S4) begin
            // decrypt challenge
            if (rec_ID == 128'Hbbe8278a67f960605adafd6f63cf7ba7) valid_ID <= 1'b1;
        end
        

        // unlocked only in S5
        if (state == S5) next_lock_state = 1'b1;

    end
end

// Instantiate AES 
// ... 
// Instantiate ASG 
// ...

endmodule