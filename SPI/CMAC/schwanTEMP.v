// INCLUDES
`include "SPI_Master_With_Single_CS.v"
`include "AesIterative.v"



module cmac_handshake (
    input clk,
    input rst,
    input  in,
    output reg lock_state  // 0 = locked, 1 = unlocked
    // SPI Interface
    output o_SPI_Clk,
    input  i_SPI_MISO,
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
    reg       next_aes_start;

// --- SPI-Steuersignale (Interne Register/Signale) ---
    localparam MAX_BYTES_PER_CS = 16;
    localparam TX_CNT_WIDTH = $clog2(MAX_BYTES_PER_CS+1);

    wire w_TX_Ready;
    wire w_RX_DV;
    wire [7:0] w_RX_Byte;
    wire [TX_CNT_WIDTH-1:0] w_RX_Count;

    reg [TX_CNT_WIDTH-1:0] i_TX_Count_reg, next_i_TX_Count;
    reg [7:0] i_TX_Byte_reg, next_i_TX_Byte;
    reg i_TX_DV_reg, next_i_TX_DV;


    reg [3:0] tx_len;   // 0..15 -> Länge-1, oder alternativ use tx_total
    reg [3:0] tx_idx;
    reg [7:0] tx_buf [0:15];
    reg [7:0] rx_buf [0:15];

    // --- Instanziere SPI Master mit Single CS ---
    SPI_Master_With_Single_CS
      #(.SPI_MODE(0),
        .CLKS_PER_HALF_BIT(5),
        .MAX_BYTES_PER_CS(MAX_BYTES_PER_CS),
        .CS_INACTIVE_CLKS(10))
    spi_inst (
        .i_Rst_L(rst), //.i_Rst_L(~rst)?
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
        .o_SPI_MOSI(o_SPI_MOSI),
        .o_SPI_CS_n(o_SPI_CS_n)
    );



// State storage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S0;
            lock_state <= 1'b0;
        end else begin
            state <= next_state;
            lock_state <= next_lock_state;
        end
    end

// Next-State-Logik
    always @(*) begin
        // Default
        next_state = state;
        next_lock_state = 1'b0;
        // Default SPI control signals
        next_i_TX_DV = 1'b0;
        next_i_TX_Byte = i_TX_Byte_reg;
        next_i_TX_Count = i_TX_Count_reg;
        next_state = state;
        next_lock_state = 1'b0;


        case (state)
            S0: if (in) next_state = S1;
            
            S1: begin
                // when entering S1, ensure i_TX_Count is set to total bytes (16)
                // start send when master ready and tx_idx < tx_total
                next_i_TX_Count = MAX_BYTES_PER_CS;
                if (w_TX_Ready && (tx_idx <= tx_len)) begin
                    next_i_TX_Byte = tx_buf[tx_idx];
                    next_i_TX_DV = 1'b1;
                    if (w_RX_DV && (w_RX_Count == tx_len)) begin
                        next_state = S2;
                    end else begin
                        next_state = S1;
                    end
                end
            end
            S2: next_state = S3;
            S3: next_state = S4;
            S4: next_state = S5;
            S5: next_state = S0;
            default: next_state = S0;
        endcase
    end

    // synchronous registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Default values
            state <= S0;
            next_lock_state = 1'b0;

            i_TX_Count_reg <= 0;
            i_TX_Byte_reg <= 0;
            i_TX_DV_reg <= 0;
            tx_idx <= 0;
            tx_len <= 15; // expect 16 bytes
            // initialize tx_buf: first byte 0x10, others 0x00 or as needed
            tx_buf[0] <= 8'h10;
            // clear buffer on reset
            //tx_buf[0] <= 8'h00;
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

        end else begin
            state <= next_state;
            // SPI controls
            i_TX_Count_reg <= next_i_TX_Count;
            i_TX_Byte_reg <= next_i_TX_Byte;
            // pulse behavior: i_TX_DV_reg shall be 1 only for one clk if next_i_TX_DV asserted
            i_TX_DV_reg <= next_i_TX_DV;
            // increment tx_idx when we pulsed a byte (and master accepted it)
            if (next_i_TX_DV && w_TX_Ready) tx_idx <= tx_idx + 1;
            // store incoming bytes
            if (w_RX_DV) rx_buf[w_RX_Count] <= w_RX_Byte;

            // Wenn wir gerade in S0 waren und in S1 wechseln, initialisiere das Senden
            if (state == S0 && next_state == S1) begin
                tx_buf[0] <= 8'h10;  //send auth_init
                tx_len <= 0;         // z. B. 3 Bytes (indices 0..2)
                tx_idx <= 0;
                i_TX_Count_reg <= MAX_BYTES_PER_CS; // Anzahl Bytes pro CS
                // Option: setze i_TX_Byte_reg/i_TX_DV_reg hier für ersten Byte,
                // oder überlasse es dem generellen Sender unten.
            end

            // Sende-Controller: falls SPI ready und noch Bytes, pulse i_TX_DV für 1 Takt
            // Wir müssen w_TX_Ready abfragen und i_TX_DV nur dann kurz hochziehen.
            if (w_TX_Ready && (tx_idx <= tx_len)) begin
                i_TX_Byte_reg <= tx_buf[tx_idx];
                i_TX_DV_reg <= 1'b1;          // 1-cycle pulse
                i_TX_Count_reg <= tx_len + 1; // informiere Master über Gesamtanzahl
                // inkrementiere Index beim nächsten Takt (nachdem Master das Byte übernommen hat)
                // Da Master o_TX_Ready bleibt low bis der Byte-Transfer durch ist, sichere Inkrement:
                tx_idx <= tx_idx + 1'b1;
            end else begin
                i_TX_DV_reg <= 1'b0;
            end

            // Empfang: wenn o_RX_DV pulst, speichere das Byte
            if (w_RX_DV) begin
                rx_buf[w_RX_Count] <= w_RX_Byte;
            end

            if (state == S1 && next_state == S2) begin
                // decrypt challenge
            end

            // unlocked only in S5
            if (state == S5) next_lock_state = 1'b1;

        end
    end

// Instantiate SPI
// ...
// Instantiate AES
// ...
// Instantiate ASG
// ...


endmodule