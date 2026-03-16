// INCLUDES
`include "ASG.v"
`timescale 1ns/1ps


// see testbench https://www.edaplayground.com/x/SKWH
// ASG generates one Bit per clock cycle -> wrapper returns random number after 8*8 clock cycles
//                                                                             /   \
//                                                                      Byte_size  Challenge_length
module asg_64_bit ( 
                    input logic clk, 
                    input logic rst,
                    input logic enable_sample, // start, when this goes high
                    logic [63:0] own_Challenge, 
                    output logic sampled_done  // high when 64 bits have been sampled
                    );

    // Intialize ASG variables (careful! signals (hence wires and registers!)
    logic [1:0] loadIt = 2'b0;
    logic       load = 1'b0;
    logic       enable = 1'b1;
    wire        newBit;  // ASG output
    logic       clk = 1'b0;
    logic       rst = 1'b0;

    //always #(2) clk = ~clk;

    ASG asg1 (
        loadIt,
        load,
        enable,
        newBit,
        clk,
        rst
    );

    logic [5:0] count; // 6 Bit counter: 0..63 
    own_Challenge <= 6'b0;
    logic sampling = 1'b0;
    sampled_done <= 1'b0;
    enable_sample <= 1'b1;


// Initialize ASG (and LSFRs) with non zero seeds
initial begin
        // Assert rst
		rst <= 1'b1;
        @(posedge clk);
        
        // Deassert rst
        rst <= 1'b0;
        @(posedge clk);

    	//
        // fill R1 with zeroes
    	repeat (31) begin
            loadIt <= 2'b01;
    	    enable <= 1'b1;
    	    load <= 1'b0;
            @(posedge clk);
        end
    	//
        // seed R1 with b'11101
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
    
    	// seed R2 with b'11010
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
        enable <= 1'b1;
    end




    // logic: rng begins once enable_sample gets asserted AND NOT sampling
    always_ff @(posedge clk) 
        begin 
            if (rst) 
                begin 
                    sampling <= 1'b0; 
                    count <= 6'd0; 
                    own_Challenge <= 64'h0; 
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
                                        own_Challenge <= 64'h0; // initialize on zeros
                                    end 
                        end 
                    else // sampling == 1 
                        begin
                            // shift and collect
                            own_Challenge <= {own_Challenge[62:0], newBit};
                            // Alternative MSB-first: own_Challenge <= {newBit, own_Challenge[63:1]};
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
