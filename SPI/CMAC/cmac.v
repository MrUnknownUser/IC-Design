// INCLUDES
`include "SPI_Master.v"



// key and ID of chip card A
var CARD_A_KEY = 128'H39558d1f193656ab8b4b65e25ac48474;
var CARD_A_ID  = 128'Hbbe8278a67f960605adafd6f63cf7ba7;


// Instantiate SPI Connection
module CMAC_HANDSHAKE ();
    //KEY_CARD Instructions
    var AUTH_INIT = 8'H10;
    var AUTH      = 8'H11;
    var GET_ID    = 8'H12;

    parameter SPI_MODE = 0;           // CPOL = 0; CPHA = 0
    parameter CLKS_PER_HALF_BIT = 5;  // 6.25 MHz
    parameter MAIN_CLK_DELAY = 2;     // 25 MHz
    parameter MAX_BYTES_PER_CS = 2;   // 2 bytes per chip select
    parameter CS_INACTIVE_CLKS = 10;  // Adds delay between bytes

    logic r_Rst_L     = 1'b0;  
    logic w_SPI_Clk;
    logic r_SPI_En    = 1'b0;
    logic r_Clk       = 1'b0;
    logic w_SPI_CS_n;
    logic w_SPI_MOSI;

    // Master Specific
    logic [7:0] r_Master_TX_Byte = 0;
    logic r_Master_TX_DV = 1'b0;
    logic w_Master_TX_Ready;
    logic w_Master_RX_DV;
    logic [7:0] w_Master_RX_Byte;
    logic [$clog2(MAX_BYTES_PER_CS+1)-1:0] w_Master_RX_Count, r_Master_TX_Count = 2'b10;

    // Clock Generators:
    always #(MAIN_CLK_DELAY) r_Clk = ~r_Clk;

    // Instantiate UUT
    SPI_Master_With_Single_CS
    #(.SPI_MODE(SPI_MODE),
        .CLKS_PER_HALF_BIT(CLKS_PER_HALF_BIT),
        .MAX_BYTES_PER_CS(MAX_BYTES_PER_CS),
        .CS_INACTIVE_CLKS(CS_INACTIVE_CLKS)
    ) UUT

    // Control/Data Signals,
   .i_Rst_L(r_Rst_L),     // FPGA Reset
   .i_Clk(r_Clk),         // FPGA Clock

   // TX (MOSI) Signals
   .i_TX_Count(r_Master_TX_Count),   // Number of bytes per CS
   .i_TX_Byte(r_Master_TX_Byte),     // Byte to transmit on MOSI
   .i_TX_DV(r_Master_TX_DV),         // Data Valid Pulse with i_TX_Byte
   .o_TX_Ready(w_Master_TX_Ready),   // Transmit Ready for Byte
   
   // RX (MISO) Signals
   .o_RX_Count(w_Master_RX_Count), // Index of RX'd byte
   .o_RX_DV(w_Master_RX_DV),       // Data Valid pulse (1 clock cycle)
   .o_RX_Byte(w_Master_RX_Byte),   // Byte received on MISO

   // SPI Interface
   .o_SPI_Clk(w_SPI_Clk),
   .i_SPI_MISO(w_SPI_MOSI),
   .o_SPI_MOSI(w_SPI_MOSI),
   .o_SPI_CS_n(w_SPI_CS_n)
   );

   // Sends a single byte from master.  Will drive CS on its own.
    task SendSingleByte(input [7:0] data);
        @(posedge r_Clk);
        r_Master_TX_Byte <= data;
        r_Master_TX_DV   <= 1'b1;
        @(posedge r_Clk);
        r_Master_TX_DV <= 1'b0;
        @(posedge r_Clk);
        @(posedge w_Master_TX_Ready);
    endtask // SendSingleByte

    initial
        begin
            repeat(10) @(posedge r_Clk);
            r_Rst_L  = 1'b0;
            repeat(10) @(posedge r_Clk);
            r_Rst_L  = 1'b1;

            /*
             * Card generates random 8-byte challenge rc, 
             * computes AES_psk(rc || 00..00) 
             * using the pre-shared key and returns the ciphertext.
             */
            // send AUTH_INIT to KEY_CARD
            SendSingleByte(AUTH_INIT);
            var challenge = w_Master_RX_Byte;  // receive 16 Byte encrypted Challenge 

            // decrypt challenge -> only first 8 bytes are relevant, rest is padding

            // encrypt received challenge, send back to KEY_CARD

            //var plain_challenge = AES_DEC(challenge)
            //send_plain_challenge()

            //Fragen
            /*
            - wie weiß ich dass SPI gestartet werden soll? keycard reader docu
            - wie funktioniert der Handshake?
            - javacard erwartet challenge die gleich der eigenen ist aber wo ist da die encryption von Bob aus?
            siehe repofile sesh_key_symm.png für erdachtes protokoll?
            siehe
            https://github.com/OCDCpro/javacard-applet/blob/master/applet/src/main/java/applet/AuthenticatedIdentificationApplet.java
            zeile 164
            */





/*
 * Terminal decrypts the ciphertext to recover rc, 
 * generates its own 8-byte challenge rt, 
 * and proves possesion of the key to the card 
 * by returning AES_psk(rt || rc) using the pre-shared key.
 */



/*
 * Derive an ephemeral AES session key as 
 * k_eph = AES_psk(rc || rt) 
 * and returns the 16-byte card ID encrypted using that key 
 * if authentication was successful.
 */






// something happens

// SPI connection to keycard (hopefully)

// AES Mode: AES-128 ECB, no padding
// no padding: input must be devisible into 16Byte Blocks
// ECB: electronic code block - no chaining, every 16 byte block gets encrypted with the same key seperately
