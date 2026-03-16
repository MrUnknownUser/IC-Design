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
    );

// State definitions        work on names!!!
localparam S0 = 3'b000; // IDLE 
localparam S1 = 3'b001; // REC_CHALLENGE -> start SPI transfer 
localparam S2 = 3'b010; // GEN_CHALLENGE 
localparam S3 = 3'b011; // STORE_EPH_KEY 
localparam S4 = 3'b100; // REQUEST_AUTH
localparam S5 = 3'b101; // KEYCARD_AUTHENTICATED
localparam S6 = 3'b110; // VALID_ID
localparam S7 = 3'b111; // UNLOCKED

// State definitions 
localparam CLA_PROPRIETARY = 8'h80;
localparam INS_AUTH_INIT   = 8'h10;
localparam INS_AUTH        = 8'h11;
localparam INS_GET_ID      = 8'h12;


// stupid shit
logic send_flag_1;
logic send_flag_2;
logic send_flag_3;
logic w_RX_DV_last_clk = 1'b0;
logic state2_flag0;
logic state2_flag1;
logic state2_flag2;
logic state2_flag3;
logic io_done_last_clk = 1'b0;
logic state3_flag1;
logic sampled_done_last_clk = 1'b0;
logic state3_flag2;
logic state3_flag3;
logic S4_done = 1'b0;
logic state4_flag1;
logic state4_flag2;
logic state4_flag3;
logic mAuthRes_valid = 1'b0;
logic state5_flag1;
logic state5_flag2;
logic state5_flag3;
logic is_decrypting;
logic is_buffering;
logic wait_for_mAuthRes_valid;
logic state6_flag1;
logic state6_flag2;
logic state6_flag3;
logic wait_for_valid_ID_valid;
reg [15:0] unlocked_timer;
logic state7_flag1;



reg [2:0] state, next_state;
reg       next_lock_state;

reg valid_ID;
reg [127:0] rec_ID;
reg [63:0] rec_Challenge = 64'b00;
reg [127:0] cAuthCmd_dec;
reg [127:0] cAuthCmd_enc;
reg [127:0] ephKey;
reg [127:0] mAuthRes;
//                           "{  A U T H _ S U C C E S S 0 0 0 0 }"
reg [127:0] auth_success = 128'h415554485F5355434345535300000000; 
reg [127:0] KeycardAvalidID = 128'Hbbe8278a67f960605adafd6f63cf7ba7;

reg preSharedKey = 128'H39558d1f193656ab8b4b65e25ac48474; // KEYCARD KEY


// --- SPI-signals ---
localparam MAX_BYTES_PER_CS = 2; 
wire w_TX_Ready; 
wire w_RX_DV; 
wire [7:0] w_RX_Byte; 
wire [$clog2(MAX_BYTES_PER_CS+1)-1:0] w_RX_Count = 2'b10;

reg [$clog2(MAX_BYTES_PER_CS+1)-1:0] i_TX_Count_reg = 2'b10;
reg [7:0] i_TX_Byte_reg;
reg i_TX_DV_reg;


reg [7:0] tx_buf [0:15];
reg [4:0] tx_len;     // 0..15 
reg [4:0] tx_idx;     // Index for sending
reg [7:0] rx_buf [0:15];
integer i;

logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] received_byte_count = 2'b00;
logic [4:0] RX_large_received_byte_count = 1'b0;

// --- instantiate SPI Master ---
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
    .i_SPI_MISO(i_SPI_MISO),
    //.i_SPI_MISO(o_SPI_MOSI),
    .o_SPI_MOSI(o_SPI_MOSI),
    //.o_SPI_MOSI(o_SPI_MOSI),
    .o_SPI_CS_n(o_SPI_CS_n)
);



// AES STUFF HERE
logic          io_start = 1'b0;
logic          io_decrypt = 1'b0;
logic [127:0]  io_key;
logic [127:0]  io_dataIn;
logic [127:0]  io_dataOut;
wire           io_busy;
logic          io_done;


//wire [127:0]  test_key = 128'H2b7e151628aed2a6abf7158809cf4f3c; // key for AES test
//                            2b7e151628aed2a6abf7158809cf4f3c
//logic [127:0] test_cipher = 128'H3925841d02dc09fbdc118597196a0b32; // ciphertext for AES test
//                               3925841d02dc09fbdc118597196a0b32
//logic [127:0] test_plain = 128'H3243f6a8885a308d313198a2e0370734; // plaintext for AES test
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


// ASG synthesizable
localparam int R1_LEN = 20;
localparam logic [R1_LEN-1:0] R1_SEED =
    20'b11101111011110111101;

localparam int R2_LEN = 127;
localparam logic [R2_LEN-1:0] R2_SEED =
    127'b0110011001100110110101101011010110101101011010110101101011010001001001001001001001001;

localparam int R3_LEN = 60;
localparam logic [R3_LEN-1:0] R3_SEED =
    {60{1'b1}};


typedef enum logic [2:0] {
    S_R1_CLEAR,
    S_R1_LOAD,
    S_R2_CLEAR,
    S_R2_LOAD,
    S_R3_CLEAR,
    S_R3_LOAD,
    S_DONE
} state_t;

state_t ASG_state;
logic [7:0] idx;
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        ASG_state     <= S_R1_CLEAR;
        idx       <= 0;
        loadIt    <= 0;
        load      <= 0;
        enable    <= 1;
        init_done <= 0;
    end else begin
        case (ASG_state)

        // ---------------- R1 leeren ----------------
        S_R1_CLEAR: begin
            loadIt <= 2'b01;
            load   <= 1'b0;
            if (idx == 31) begin
                idx   <= 0;
                ASG_state <= S_R1_LOAD;
            end else idx <= idx + 1;
        end

        // ---------------- R1 seed laden ----------------
        S_R1_LOAD: begin
            loadIt <= 2'b01;
            load   <= R1_SEED[R1_LEN-1-idx];
            if (idx == R1_LEN-1) begin
                idx   <= 0;
                ASG_state <= S_R2_CLEAR;
            end else idx <= idx + 1;
        end

        // ---------------- R2 leeren ----------------
        S_R2_CLEAR: begin
            loadIt <= 2'b10;
            load   <= 1'b0;
            if (idx == 127) begin
                idx   <= 0;
                ASG_state <= S_R2_LOAD;
            end else idx <= idx + 1;
        end

        // ---------------- R2 seed laden ----------------
        S_R2_LOAD: begin
            loadIt <= 2'b10;
            load   <= R2_SEED[R2_LEN-1-idx];
            if (idx == R2_LEN-1) begin
                idx   <= 0;
                ASG_state <= S_R3_CLEAR;
            end else idx <= idx + 1;
        end

        // ---------------- R3 leeren ----------------
        S_R3_CLEAR: begin
            loadIt <= 2'b11;
            load   <= 1'b0;
            if (idx == 89) begin
                idx   <= 0;
                ASG_state <= S_R3_LOAD;
            end else idx <= idx + 1;
        end

        // ---------------- R3 seed laden ----------------
        S_R3_LOAD: begin
            loadIt <= 2'b11;
            load   <= R3_SEED[R3_LEN-1-idx];
            if (idx == R3_LEN-1) begin
                ASG_state <= S_DONE;
            end else idx <= idx + 1;
        end

        // ---------------- fertig ----------------
        S_DONE: begin
            loadIt    <= 2'b00;
            load      <= 1'b0;
            init_done <= 1'b1;
        end
        endcase
    end
end
// _ASG




// State storage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S0;
            lock_state <= 1'b0;
            received_byte_count <= 1'b0;
            unlocked_timer <= 16'b0;


        end else begin
            state <= next_state;
            lock_state <= next_lock_state;
        end
    end

// Next-State-Logik 
    always @(*) begin 
        // Default SPI control signals 
        i_TX_DV_reg = 1'b0; 
        i_TX_Count_reg = 0;

    case (state)
        S0: begin
            if (in) next_state = S1;
            next_lock_state <= 1'b0;
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
                $display("rx_buf: %X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X", rx_buf[15], rx_buf[14], rx_buf[13], rx_buf[12], rx_buf[11], rx_buf[10], rx_buf[9], rx_buf[8], rx_buf[7], rx_buf[6], rx_buf[5], rx_buf[4], rx_buf[3], rx_buf[2], rx_buf[1], rx_buf[0]);
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
            if ((~sampled_done) && (sampled_done_last_clk == 1'b1)) begin
                if (~state3_flag1) begin
                    $display("S3 termination??");
                    state3_flag1 <= 1'b1;
                end else begin
                    $display("S3 termination!!");
                    sampled_done_last_clk <= 1'b0;
                    next_state <= S4;
                    state3_flag1 <= 1'b0;
                    $display("cAuthCmd_enc? %X", cAuthCmd_enc);
                end
            end
        end

        S4: begin
            if (o_SPI_CS_n && (S4_done == 1'b1)) begin 
                if (~state4_flag3) begin
                    $display("S4 termination??");
                    state4_flag3 <= 1'b1;
                end else begin
                    $display("S4 termination!!");
                    S4_done <= 1'b0;
                    next_state <= S5;
                    state4_flag3 <= 1'b0;
                    state4_flag2 <= 1'b0;
                    RX_large_received_byte_count <= 1'b0;
                    $display("received cAuthRes: %X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X", rx_buf[15], rx_buf[14], rx_buf[13], rx_buf[12], rx_buf[11], rx_buf[10], rx_buf[9], rx_buf[8], rx_buf[7], rx_buf[6], rx_buf[5], rx_buf[4], rx_buf[3], rx_buf[2], rx_buf[1], rx_buf[0]);
                end
            end
        end
        S5: begin
            if ((~io_done) && (io_done_last_clk == 1'b1)) begin 
               if (~state5_flag3) begin
                    $display("S5 termination??");
                    state5_flag3 <= 1'b1;
                end else begin
                    $display("S5 termination!!");
                    io_done_last_clk <= 1'b0;
                    if (~wait_for_mAuthRes_valid) begin
                        wait_for_mAuthRes_valid <= 1'b1;
                    end else begin
                        if (mAuthRes_valid == 1'b1) begin
                            $display("VALIDATION SUCCESS");
                            next_state <= S6;
                        end else begin
                            $display("VALIDATION FAILED");
                            next_state <= S0;
                        end
                        wait_for_mAuthRes_valid <= 1'b0;
                        state5_flag3 <= 1'b0;
                        io_decrypt <= 1'b0;
                        //$display("decrypted mAuthRes: %X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X", rx_buf[15], rx_buf[14], rx_buf[13], rx_buf[12], rx_buf[11], rx_buf[10], rx_buf[9], rx_buf[8], rx_buf[7], rx_buf[6], rx_buf[5], rx_buf[4], rx_buf[3], rx_buf[2], rx_buf[1], rx_buf[0]);
                    end
                end
            end
        end
        S6: begin
            if ((~io_done) && (io_done_last_clk == 1'b1)) begin
                if (~state6_flag1) begin
                    $display("S6 termination??");
                    state6_flag1 <= 1'b1;
                end else begin
                    $display("S6 termination!!");
                    io_done_last_clk <= 1'b0;
                    if (~wait_for_valid_ID_valid) begin
                        wait_for_valid_ID_valid <= 1'b1;
                    end else begin
                        if (valid_ID == 1'b1) begin
                            $display("ID CORRECT; UNLOCKING");
                            next_state <= S7;
                        end else begin
                            $display("ID INVALID");
                            next_state <= S0;
                        end
                        wait_for_valid_ID_valid <= 1'b0;
                        state6_flag1 <= 1'b0;
                    end
                end
            end
        end
        S7: begin
            @(posedge clk)
            if (~state7_flag1) begin 
                state7_flag1 <= 1'b1;
            end else if (unlocked_timer == 16'b1111111111111111) begin 
                next_state <= S0;
                state7_flag1 <= 1'b0;
                next_lock_state <= 1'b0;
            end else begin
                unlocked_timer <= unlocked_timer + 1;
            end
        end
        default: next_state = S0;
    endcase
end


// --- synchronous thingy layout ---
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // clear tx_buf
        for (i = 0; i < 16; i = i + 1) tx_buf[i] <= 8'h00;
        // clear rx_buf
        for (i = 0; i < 16; i = i + 1) rx_buf[i] <= 8'h00;

        tx_idx <= 0;
        tx_len <= 0;
        i_TX_DV_reg <= 1'b0;
        i_TX_Byte_reg <= 8'h00;
        i_TX_Count_reg <= 0;
        send_flag_1 <= 1'b0;
        send_flag_2 <= 1'b0;
        send_flag_3 <= 1'b0;
        w_RX_DV_last_clk <= 1'b0;  
        state2_flag0 <= 1'b0;
        state2_flag1 <= 1'b0;
        state2_flag2 <= 1'b0;
        state2_flag3 <= 1'b0;

        state3_flag1 <= 1'b0;
        state3_flag2 <= 1'b0;
        state3_flag3 <= 1'b0;

        state4_flag1 <= 1'b0;
        state4_flag2 <= 1'b0;
        state4_flag3 <= 1'b0;

        state5_flag1 <= 1'b0;
        state5_flag2 <= 1'b0;
        state5_flag3 <= 1'b0;

        is_decrypting <= 1'b0;
        is_buffering <= 1'b0;
        wait_for_mAuthRes_valid <= 1'b0;

        state6_flag1 <= 1'b0;
        state6_flag2 <= 1'b0;
        state6_flag3 <= 1'b0;
        wait_for_valid_ID_valid <= 1'b0;

        state7_flag1 <= 1'b0;

        //received_byte_count <= 1'b0;
        enable_sample <= 1'b0;

        valid_ID <= 1'b0;

    end else begin
        // S1.0 - init INS_AUTH_INIT Header into buffer
        if (state == S0 && next_state == S1) begin
            tx_buf[0] <= CLA_PROPRIETARY; 
            tx_buf[1] <= INS_AUTH_INIT;
            tx_buf[2] <= 8'h00; 
            tx_buf[3] <= 8'h00; 
            //$display("tx_buf[0]: %X", tx_buf[0]);
            //$display("tx_buf[1]: %X", tx_buf[1]);
            //$display("tx_buf[2]: %X", tx_buf[2]);
            //$display("tx_buf[3]: %X", tx_buf[3]);
            tx_len <= 4;         //byte count to send
            tx_idx <= 0;
            i_TX_Count_reg <= 4;
        end

        // S1 - save byte on o_RX_DV pulse
        if ((state == S1) && w_RX_DV) begin
            w_RX_DV_last_clk <= 1'b1;  // terminates S1
            $display(" [][][][][%0t]  found RX pulse, saving byte", $time);
            rx_buf[received_byte_count] <= w_RX_Byte;
            received_byte_count <= received_byte_count + 1'b1;
            $display("w_RX_Byte: %X", w_RX_Byte);
            $display("received_byte_count: %X", received_byte_count);
        end

        // S1 - Send INS_AUTH_INIT and receive bytes
        if (state == S1 && w_TX_Ready && (tx_idx < tx_len)) begin
            $display(" [][][][][%0t]  state 1 logic", $time);
            // drive i_TX_Byte_reg and pulse i_TX_DV_reg for next byte
            if (send_flag_1) begin
                if (~send_flag_2) begin
                    send_flag_2 <= 1'b1;
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
                send_flag_1 <= 1'b1;
            end
        end else if (send_flag_1 && send_flag_2) begin
            if (~send_flag_3) begin
                send_flag_3 <= 1'b1;
            end else begin
                i_TX_DV_reg <= 1'b0;
                send_flag_1 <= 1'b0;
                send_flag_2 <= 1'b0;
                send_flag_3 <= 1'b0;
            end
        end
        // S2 - decrypt 16 byte challenge here
        if (state == S2 && next_state == S2) begin
            if (~state2_flag2) begin
                // 
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

                //io_dataIn <= test_cipher;
                
                //io_key <= test_key
                io_key <= preSharedKey;


                io_decrypt <= 1'b1;
                io_start <= 1'b1;
                state2_flag2 <= 1'b1;
                //$display("[%0t] vor clockedge", $time);
            end else begin

                //$display("[%0t] nach clockedge", $time);
                io_start <= 1'b0;

                if (~state2_flag3) begin 
                    state2_flag3 <= 1'b1;
                end else begin 
                    if (io_done) begin
                        io_done_last_clk <= 1'b1;
                        $display("io_done :)");
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

                        // assert io_dataOut[63:0] to be all zeroes?
                        state2_flag2 <= 1'b0; 
                        state2_flag3 <= 1'b0; 
                    end
                end
            end
        end

        // S3.1 - generate own 8 byte challenge
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
                    if (count == 6'd63) begin
                        sampling     <= 1'b0;
                        sampled_done <= 1'b1;
                        count        <= 6'd0;
                        init_done <= 1'b0;
                    end
                    else begin
                        count <= count + 6'd1;
                    end
                end
            end
        end
        // S3.2 - build cAuthCmd_dec 
        if (state == S3 && next_state == S3 && sampled_done) begin
            // concat first 8 bytes of challenge with own challenge
            // store as 16 bytes cAuthCmd_dec 
            enable_sample = 1'b0;
            cAuthCmd_dec [127:64] <= rec_Challenge;  // [15:8]
            // check if lower 8 bytes are 0? --
            cAuthCmd_dec [63:0] <= own_Challenge;  // [7:0]
            $display("rec_Challenge? %X", rec_Challenge);
            $display("own_Challenge? %X", own_Challenge);
            $display("cAuthCmd_dec? %X", cAuthCmd_dec);
            state3_flag2 <= 1'b1;
            sampled_done <= 1'b0;
        end
        // S3.3 - encrypt cAuthCmd_dec
        if (state == S3 && next_state == S3 && state3_flag2) begin
            io_dataIn <= cAuthCmd_dec;
                //io_dataIn <= test_plain;
                //io_key <= test_key;
            io_key <= preSharedKey;
                //io_dataIn <= auth_success;
                //io_key <= 128'H7f27c5cf01fdf40127eb880970804c24;
                //io_dataIn <= KeycardAvalidID;
            io_decrypt <= 1'b0;
            io_start <= 1'b1;
            state3_flag2 <= 1'b0;
            state3_flag3 <= 1'b1;
        end
        // S3.4 - pulse io_start for one clk cycle
        if (state == S3 && next_state == S3 && state3_flag3) begin
            io_start <= 1'b0;
            state3_flag3 <= 1'b0;
        end
        // S3.5 - store encrypted cAuthCmd_enc
        if (state == S3 && next_state == S3 && io_done) begin
            cAuthCmd_enc <= io_dataOut;
            sampled_done_last_clk <= 1'b1;
        end

        // S4.1 - build INS_AUTH Header
        if (state == S3 && next_state == S4) begin
            for (i = 0; i < 16; i = i + 1) begin
                rx_buf[i] = 8'h00;
            end
            $display("initialising INS_AUTH");
            tx_buf[0] <= CLA_PROPRIETARY; 
            tx_buf[1] <= INS_AUTH;
            tx_buf[2] <= 8'h00; 
            tx_buf[3] <= 8'h00;
            tx_len <= 4;         //byte count to send
            tx_idx <= 0;
            i_TX_Count_reg <= 4;
            state4_flag2 <= 1'b0;
        end



        // S4.2 - Send logic HEADER + cAuthCmd
        if ((state == S4) && (next_state == S4) && w_TX_Ready && (tx_idx < tx_len)) begin
            $display(" [][][][][%0t]  state 4 logic", $time);
            // drive i_TX_Byte_reg and pulse i_TX_DV_reg for next byte
            if (send_flag_1) begin
                if (~send_flag_2) begin
                    send_flag_2 <= 1'b1;
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
                send_flag_1 <= 1'b1;
            end
        end else if (send_flag_1 && send_flag_2) begin
            if (~send_flag_3) begin
                send_flag_3 <= 1'b1;
            end else begin
                i_TX_DV_reg <= 1'b0;
                send_flag_1 <= 1'b0;
                send_flag_2 <= 1'b0;
                send_flag_3 <= 1'b0;
                if (tx_idx == tx_len) begin
                    $display("[%0t] tx_idx Header done %x", $time, tx_idx);
                    if (~state4_flag2 && state == S4) begin
                        $display("set this flag");
                        state4_flag1 <= 1'b1;
                    end
                end
            end
        end
        // S4 - save cAuthRes
        if ((state == S4) && (next_state == S4) && w_RX_DV && state4_flag2) begin
            $display("[0%t] saving w_RX_Byte: %X at %XXX", $time, w_RX_Byte, RX_large_received_byte_count);
            if (tx_idx == 16) begin
                S4_done <= 1'b1;  // terminates S4
                state4_flag2 <= 1'b0;
            end
            rx_buf[RX_large_received_byte_count - 1] <= w_RX_Byte;
            RX_large_received_byte_count <= RX_large_received_byte_count + 1'b1;
        end
        // S4.3 - build cAuthCmd
        if ((state == S4) && (next_state == S4) && state4_flag1) begin
            $display("initialising cAuthCmd send");
            tx_buf[0] <= cAuthCmd_enc [7:0];
            tx_buf[1] <= cAuthCmd_enc [15:8];
            tx_buf[2] <= cAuthCmd_enc [23:16];
            tx_buf[3] <= cAuthCmd_enc [31:24];
            tx_buf[4] <= cAuthCmd_enc [39:32];
            tx_buf[5] <= cAuthCmd_enc [47:40];
            tx_buf[6] <= cAuthCmd_enc [55:48];
            tx_buf[7] <= cAuthCmd_enc [63:56];
            tx_buf[8] <= cAuthCmd_enc [71:64];
            tx_buf[9] <= cAuthCmd_enc [79:72];
            tx_buf[10] <= cAuthCmd_enc [87:80];
            tx_buf[11] <= cAuthCmd_enc [95:88];
            tx_buf[12] <= cAuthCmd_enc [103:96];
            tx_buf[13] <= cAuthCmd_enc [111:104];
            tx_buf[14] <= cAuthCmd_enc [119:112];
            tx_buf[15] <= cAuthCmd_enc [127:120];
            tx_len <= 16;         //byte count to send
            tx_idx <= 0;
            i_TX_Count_reg <= 16;
            state4_flag1 <= 1'b0;
            state4_flag2 <= 1'b1;
        end
        // S5.1 - Build ephKey, yes this is correct 
        if (state == S5 && next_state == S5) begin
            ephKey [127:64] <= own_Challenge[63:0];  // [15:8]
            // check if lower 8 bytes are 0? --
            ephKey [63:0] <= rec_Challenge[63:0];  // [7:0]
            state5_flag1 <= 1'b1;
        end
        // S5.2 - Decrypt cAuthRes using ephKey
        if (state == S5 && next_state == S5 && state5_flag1) begin
            $display("ephKey: %X", ephKey);
            // decrypt
            if (~is_decrypting) begin
                //
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

                    //io_dataIn <= 128'H495e1ed17cb3ff77c38bf654b8cea01a;

                io_key <= ephKey;
                    //io_key <= 128'H7f27c5cf01fdf40127eb880970804c24;
                    
                    //io_key <= test_key;

                io_decrypt <= 1'b1;
                io_start <= 1'b1;
                is_decrypting <= 1'b1;
            end else begin
                io_start <= 1'b0;

                if (~is_buffering) begin 
                    is_buffering <= 1'b1;
                end else begin 
                    if (io_done) begin
                        io_done_last_clk <= 1'b1;
                        $display("io_done, saving decrypted cAuthRes");
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
                        mAuthRes[127:0] <= io_dataOut[127:0];
                        is_decrypting <= 1'b0; 
                        is_buffering <= 1'b0; 
                        state5_flag1 <= 1'b0;
                        state5_flag2 <= 1'b1;   
                    end
                end
            end
        end
        // S5.3 - Validate Plaintext of mAuthRes
        if (state == S5 && next_state == S5 && state5_flag2) begin
            // VALIDATION_PLAINTEXT == {'A','U','T','H','_','S','U','C','C','E','S','S', 0, 0, 0, 0}
            $display("decrypted mAuthResBuffer: %X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X", rx_buf[15], rx_buf[14], rx_buf[13], rx_buf[12], rx_buf[11], rx_buf[10], rx_buf[9], rx_buf[8], rx_buf[7], rx_buf[6], rx_buf[5], rx_buf[4], rx_buf[3], rx_buf[2], rx_buf[1], rx_buf[0]);
            $display("decrypted mAuthResStored: %X", mAuthRes);
            $display("AUTH_SUCCESS ~-~-~-~      %X", auth_success);
            if (mAuthRes == auth_success) begin 
                mAuthRes_valid <= 1'b1;
                $display("Authenticated Keycard, asking ID next...");
            end else begin
                mAuthRes_valid <= 1'b0;
                $display("Failed to Authenticate Keycard, restoring program at S0");
            end
            state5_flag2 <= 1'b0;
        end
        // S6.1 - Initialize INS_GET_ID command into TX Buffer
        if (state == S5 && next_state == S6) begin 
            for (i = 0; i < 16; i = i + 1) begin
                rx_buf[i] = 8'h00;
            end
            for (i = 0; i < 16; i = i + 1) begin
                tx_buf[i] = 8'h00;
            end
            $display("initialising INS_GET_ID");
            tx_buf[0] <= CLA_PROPRIETARY; 
            tx_buf[1] <= INS_GET_ID;
            tx_buf[2] <= 8'h00; 
            tx_buf[3] <= 8'h00;
            tx_len <= 4;         //byte count to send
            tx_idx <= 0;
            i_TX_Count_reg <= 4;
            //state4_flag1 <= 1'b0;
            //state4_flag2 <= 1'b0;
        end

        // receive 16 byte rec_IC_enc through on RX
        if ((state == S6) && w_RX_DV) begin
            w_RX_DV_last_clk <= 1'b1;
            $display(" [][][][][%0t]  found RX pulse, saving byte", $time);
            //rx_buf[RX_large_received_byte_count] <= w_RX_Byte;
            rx_buf[RX_large_received_byte_count-1] <= w_RX_Byte;
            //HIER IRGENDWO FEHLER IN DER DATEIÜBERTRAGUNG
            RX_large_received_byte_count <= RX_large_received_byte_count + 1'b1;
            $display("w_RX_Byte: %X", w_RX_Byte);
            $display("RX_large_received_byte_count: %X", RX_large_received_byte_count);
        end

        // S6.1 transmit command INS_GET_ID
        if (state == S6 && next_state == S6 && w_TX_Ready && (tx_idx < tx_len)) begin
            $display(" [][][][][%0t]  state 6 logic", $time);
            // drive i_TX_Byte_reg and pulse i_TX_DV_reg for next byte
            if (send_flag_1) begin
                if (~send_flag_2) begin
                    send_flag_2 <= 1'b1;
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
                send_flag_1 <= 1'b1;
            end
        end else if (send_flag_1 && send_flag_2) begin
            if (~send_flag_3) begin
                send_flag_3 <= 1'b1;
            end else begin
                i_TX_DV_reg <= 1'b0;
                send_flag_1 <= 1'b0;
                send_flag_2 <= 1'b0;
                send_flag_3 <= 1'b0;
                state6_flag2 <= 1'b1;
            end
        end
        // S6.2 decrypt rec_ID_dec using ephKey
        if (state == S6 && next_state == S6 && state6_flag2) begin
            $display("index testing: %X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X", rx_buf[15], rx_buf[14], rx_buf[13], rx_buf[12], rx_buf[11], rx_buf[10], rx_buf[9], rx_buf[8], rx_buf[7], rx_buf[6], rx_buf[5], rx_buf[4], rx_buf[3], rx_buf[2], rx_buf[1], rx_buf[0]);
            if (~is_decrypting) begin
                // 
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


                //io_dataIn <= 128'H828b132c596d1906d9090456e5671b56;
                //io_dataIn <= 128'Hb20e8632aab045bac5f15a4d85471c02;
                
                io_key <= ephKey;

                io_decrypt <= 1'b1;
                io_start <= 1'b1;
                is_decrypting <= 1'b1;
            end else begin
                io_start <= 1'b0;

                if (~is_buffering) begin 
                    is_buffering <= 1'b1;
                end else begin 
                    if (io_done) begin
                        io_done_last_clk <= 1'b1;
                        $display("io_done :)");
                        rec_ID[127:0] <= io_dataOut [127:0];

                        //store decrypted rec_ID from KEYCARD
                        is_decrypting <= 1'b0; 
                        is_buffering <= 1'b0; 
                        state6_flag2 <= 1'b0;
                        state6_flag3 <= 1'b1;
                    end
                end
            end
        end
        // S6.3 - check for validity of ID
        if (state == S6 && next_state == S6 && state6_flag3) begin
            $display("decrypted mAuthResBuffer: %X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X", rx_buf[15], rx_buf[14], rx_buf[13], rx_buf[12], rx_buf[11], rx_buf[10], rx_buf[9], rx_buf[8], rx_buf[7], rx_buf[6], rx_buf[5], rx_buf[4], rx_buf[3], rx_buf[2], rx_buf[1], rx_buf[0]);
            $display("decrypted mAuthResStored: %X", rec_ID);
            $display("AUTH_SUCCESS ~-~-~-~      %X", KeycardAvalidID);
            
            if (rec_ID == KeycardAvalidID) begin
                valid_ID <= 1'b1;
                $display("ID matched, proceed to unlock...");
            end else begin
                valid_ID <= 1'b0;
                $display("unknown ID, restoring program at S0");
            end
            state6_flag3 <= 1'b0;
        end

        if (state == S7) next_lock_state = 1'b1;

    end
end
endmodule