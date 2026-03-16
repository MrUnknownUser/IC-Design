// INCLUDES
`include "SPI_Master.v"
`include "asg_64_bit.v"




// key and ID of chip card A
var CARD_A_KEY = 128'H39558d1f193656ab8b4b65e25ac48474;
var CARD_A_ID  = 128'Hbbe8278a67f960605adafd6f63cf7ba7;


// Instantiate SPI Connection
module CMAC_HANDSHAKE (
            input logic clk, 
            input logic reset,
            );
    //KEY_CARD Instructions
    logic AUTH_INIT = 8'H10;
    logic AUTH      = 8'H11;
    logic GET_ID    = 8'H12;

    // Key Necessities
    logic [127:0] callback = 0;
    logic callback_valid = 1'b0;
    logic [63:0] challenge = 0;
    logic [127:0] eph_key = 0;
    logic [127:0] encrypted_eph_key = 0;
    logic [63:0] plain_challenge = 0;
    logic [63:0] own_challenge = 0;
    

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
            // somehow fill all 16 bytes of challenge with received callbacks


            logic callback_valid = 1'b0;

            // Capture incoming bytes and assemble into 16-bit word (MSB first)
            always @(posedge r_Clk) 
                begin
                    callback_valid <= 1'b0;
                    // default: no new full word this cycle
                    if (w_Master_RX_DV) 
                    begin 
                        // receive 16 Byte encrypted Challenge 
                        case (w_Master_RX_Count) 
                         0: callback[127:120] <= w_Master_RX_Byte;
                         1: callback[119:112] <= w_Master_RX_Byte;
                         2: callback[111:104] <= w_Master_RX_Byte;
                         3: callback[103:96] <= w_Master_RX_Byte;
                         4: callback[95:88] <= w_Master_RX_Byte;
                         5: callback[87:80] <= w_Master_RX_Byte;
                         6: callback[79:72] <= w_Master_RX_Byte;
                         7: callback[71:64] <= w_Master_RX_Byte;
                         8: callback[63:56] <= w_Master_RX_Byte;
                         9: callback[55:48] <= w_Master_RX_Byte;
                        10: callback[47:40] <= w_Master_RX_Byte;
                        11: callback[39:32] <= w_Master_RX_Byte;
                        12: callback[31:24] <= w_Master_RX_Byte;
                        13: callback[23:16] <= w_Master_RX_Byte;
                        14: callback[15:8] <= w_Master_RX_Byte;
                        15: callback[7:0] <= w_Master_RX_Byte;
                        begin 
                            callback_valid <= 1'b1; // full 128-bit word ready 
                        end 
                        default: ; // ignore extra bytes 
                        endcase 
                    end
                end

            // decrypt challenge -> only first 8 bytes are relevant, rest is padding
            assign plain_callback = AES_DEC(callback);
            assign challenge = plain_callback[15:8];

     


            // generate own 8 byte challenge
            logic enable_sample = 1'b1;
            logic [63:0] own_challenge = 6'b0;
            logic sampled_done = 1'b0;

            asg_64_bit u_ASG (
                clk,
                reset,
                enable_sample,
                own_challenge,
                sampled_done;
            );

            // do we have to wait 64 clock cycles?
            //repeat(64) @(posedge r_Clk);

            
            
            // concatenate challenges -> store as eph_key (session key)
            assign eph_key <= {challenge, own_challenge};

            // encrypt eph_key and send back to KEY_CARD
            assign encrypted_eph_key = AES_ENC(eph_key);
            r_Master_TX_Count = 128;

            SendSingleByte(encrypted_eph_key[127:120]);
            SendSingleByte(encrypted_eph_key[119:112]);
            SendSingleByte(encrypted_eph_key[111:104]);
            SendSingleByte(encrypted_eph_key[103:96]);
            SendSingleByte(encrypted_eph_key[95:88]);
            SendSingleByte(encrypted_eph_key[87:80]);
            SendSingleByte(encrypted_eph_key[79:72]);
            SendSingleByte(encrypted_eph_key[71:64]);
            SendSingleByte(encrypted_eph_key[63:56]);
            SendSingleByte(encrypted_eph_key[55:48]);
            SendSingleByte(encrypted_eph_key[47:40]);
            SendSingleByte(encrypted_eph_key[39:32]);
            SendSingleByte(encrypted_eph_key[31:24]);
            SendSingleByte(encrypted_eph_key[23:16]);
            SendSingleByte(encrypted_eph_key[15:8]);
            SendSingleByte(encrypted_eph_key[7:0]);




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
        end
endmodule