// INCLUDES
`include "ASG.v"



// ASG generates one Bit per clock cycle -> wrapper returns random number after 8*8 clock cycles
//                                                                             /   \
//                                                                      Byte_size  Challenge_length
module asg_64_bit ( 
                    input logic clk, 
                    input logic reset,
                    input logic enable_sample, // start, when this goes high
                    logic [63:0] own_challenge, 
                    output logic sampled_done  // high when 64 bits have been sampled
                    );

    // Intialize ASG variables
    wire [1:0] loadIt = 2'b0;
    wire       load;
    wire       enable = 1'b1;
    wire       newBit;  // ASG output
    wire       clk;
    wire       reset;

    ASG asg1 (
        loadIt,
        load,
        enable,
        newBit,
        clk,
        reset
    );

    logic [5:0] count; // 6 Bit counter: 0..63 
    logic sampling;

    // logic: rng begins once enable_sample gets asserted AND NOT sampling
    always_ff @(posedge clk) 
        begin 
            if (reset) 
                begin 
                    sampling <= 1'b0; 
                    count <= 6'd0; 
                    own_challenge <= 64'h0; 
                    sampled_done <= 1'b0; 
                end 
            else 
                begin 
                    if (!sampling) 
                        begin 
                            sampled_done <= 1'b0; 
                                if (enable_sample) 
                                    begin 
                                        sampling <= 1'b1; 
                                        count <= 6'd0; 
                                        own_challenge <= 64'h0; // initialize on zeros
                                    end 
                        end 
                    else // sampling == 1 
                        begin
                            // shift and collect
                            own_challenge <= {own_challenge[62:0], newBit};
                            // Alternative MSB-first: own_challenge <= {newBit, own_challenge[63:1]};
                            if (count == 6'd63) 
                                begin
                                    sampling     <= 1'b0;
                                    sampled_done <= 1'b1;
                                    count        <= 6'd0;
                                end
                            else
                                begin
                                    count <= count + 6'd1;
                                end
                        end
                end
        end
endmodule
