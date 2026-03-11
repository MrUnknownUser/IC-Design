`timescale 1ns/1ps
// INCLUDES 
`include "SPI_Master_With_Single_CS.v" 
`include "AesIterative.v"

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

reg [2:0] state, next_state;
reg       next_lock_state;

reg valid_ID;
reg [127:0] rec_ID;
//reg [127:0] rec_Challenge = 128'b00;


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




// AES STUFF HERE
logic          io_start = 1'b0;
logic          io_decrypt = 1'b0;
wire [127:0]  io_key = 128'H39558d1f193656ab8b4b65e25ac48474;
logic [127:0]  io_dataIn;
reg  [127:0]  io_dataOut;
wire          io_busy;
reg           io_done;

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
        //$display("[%0t] fkass rx count: %X", $time, received_byte_count);
        // Default 
        next_state = state; 
        next_lock_state = 1'b0; 
        // Default SPI control signals 
        i_TX_DV_reg = 1'b0; 
        i_TX_Byte_reg = 8'h00; 
        i_TX_Count_reg = 0;
        valid_ID = 1'b0; 

    case (state)
        S0: begin
            if (in) next_state = S1;
            $display("[%0t] switched to S1", $time);
            received_byte_count <= 1'b0;
        end
        
        S1: begin
            if (w_TX_Ready && (tx_idx <= tx_len)) begin
                $display("[%0t] tx ready and still bytes to send", $time);
                
                // drive i_TX_Byte_reg and pulse i_TX_DV_reg for next byte
                @(posedge clk);
                i_TX_Byte_reg = tx_buf[tx_idx];
                i_TX_DV_reg = 1'b1;
                i_TX_Count_reg = tx_len + 1; // Anzahl Bytes insgesamt
                $display("i_TX_Byte_reg: %X", i_TX_Byte_reg);
                $display("i_TX_Count_reg: %X", i_TX_Count_reg);
                $display("tx_len: %X", tx_len);
                @(posedge clk);
                i_TX_DV_reg = 1'b0;
                @(posedge clk);
                @(posedge w_TX_Ready);

                //if ((w_RX_Count == (tx_len + 1)) && w_RX_DV) begin
                if (o_SPI_CS_n && (received_byte_count != 0)) begin
                    $display("RX DATA VALID: %X", w_RX_DV);
                    $display("CS INACTIVE AGAIN: %X", o_SPI_CS_n);
                    // proceed once byte received and count matches
                    $display("[%0t] something happened, lets go to the mall (S2)", $time);
                    //$display("w_RX_Byte: %X", w_RX_Byte);
                    next_state = S2;
                    //received_byte_count <= 1'b0;
                    i_TX_Byte_reg <= 8'h00;
                    @(posedge clk);
                end else begin
                    $display("[%0t] I am retarded and want to KMS", $time);
                    next_state = S1;
                end
            end
        end
        S2:  begin 
            // decrypt 16 byte challenge here
            // generate own 8 byte challenge
            // concat first 8 bytes of challenge with own challenge
            // store as 16 byte eph_key 
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

            io_decrypt <= 1'b1;
            io_start <= 1'b1;
            @(posedge clk);
            io_start <= 1'b0;

            @(posedge io_done);
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

            next_state = S3; 
            @(posedge clk);
        end
        S3: begin 
            // send own challenge as padded 8 bytes + 8 byte challenge?
            for (i = 0; i < 16; i = i + 1) begin
                $display("decrypted? %X", rx_buf[i]);
            end
            next_state = S4;
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
        tx_idx <= 0;
        tx_len <= 0;
        // clear buffer on reset
        tx_buf[0] <= 8'h00;
        tx_buf[1] <= 8'h00;
        tx_buf[2] <= 8'h00;
        tx_buf[3] <= 8'h00;
        tx_buf[4] <= 8'h00;
        tx_buf[5] <= 8'h00;
        tx_buf[6] <= 8'h00;
        tx_buf[7] <= 8'h00;
        tx_buf[8] <= 8'h00;
        tx_buf[9] <= 8'h00;
        tx_buf[10] <= 8'h00;
        tx_buf[11] <= 8'h00;
        tx_buf[12] <= 8'h00;
        tx_buf[13] <= 8'h00;
        tx_buf[14] <= 8'h00;
        tx_buf[15] <= 8'h00;
        //$display("tx_buf: %X", tx_buf[0]);
        i_TX_DV_reg <= 1'b0;
        i_TX_Byte_reg <= 8'h00;
        i_TX_Count_reg <= 0;
        received_byte_count <= 1'b0;


        valid_ID <= 1'b0;
    end else begin
        if (state == S1 && next_state == S1) begin
            //tx_buf[0] <= 8'h10;  //send auth_init
            tx_buf[0] <= 8'h10; 
            tx_buf[1] <= 8'hFF; 
            //$display("tx_buf[0]: %X", tx_buf[0]);
            //$display("tx_buf[1]: %X", tx_buf[1]);
            tx_len <= 1;         //byte count to send (i-1)
            tx_idx <= 0;
            i_TX_Count_reg <= 2;
        end

        // pulse i_TX_DV for 1 clockcycle if SPI ready and not done 
        if (w_TX_Ready && (tx_idx <= tx_len)) begin  // evtl index fehler
            $display("ich bin ein nerviger bastard und muss weitersenden");
            i_TX_Byte_reg <= tx_buf[tx_idx];
            i_TX_DV_reg <= 1'b1;          // 1-cycle pulse
            i_TX_Count_reg <= tx_len + 1; // informiere Master über Gesamtanzahl
            // increment index on next clock cycle 
            tx_idx <= tx_idx + 1'b1;
        end else begin
            i_TX_DV_reg <= 1'b0;
        end

        // save byte on o_RX_DV pulse
        if (w_RX_DV) begin
            //rx_buf[w_RX_Count] <= w_RX_Byte;
            rx_buf[received_byte_count] <= w_RX_Byte;
            received_byte_count <= received_byte_count + 1'b1;
            $display("w_RX_Byte: %X", w_RX_Byte);
            $display("received_byte_count: %X", received_byte_count);
            $display("captured rx_buf: %X", rx_buf[received_byte_count]);
        end

        if (state == S1 && next_state == S2) begin
            // decrypt challenge
        end

        if (state == S3 && next_state == S4) begin
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