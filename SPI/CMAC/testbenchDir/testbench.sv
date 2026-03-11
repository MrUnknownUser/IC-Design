// Code your testbench here
// or browse Examples

`include "ASG.v"
`timescale 1ns/1ps

module ASG_TESTING ();
  
    // Intialize ASG variables (careful! signals (hence wires and registers!)
    logic [1:0] loadIt = 2'b0;
    logic       load = 1'b0;
    logic       enable = 1'b1;
    wire        newBit;  // ASG output
    logic       clk = 1'b0;
    logic       reset = 1'b0;
  
    // Clock Generators:
  always #(2) clk = ~clk;
  
    ASG asg1 (
        loadIt,
        load,
        enable,
        newBit,
        clk,
        reset
    );

  logic [5:0] count; // 6 Bit counter: 0..63 
  logic [63:0] own_challenge = 6'b0;
  logic sampling = 1'b0;
  logic sampled_done = 1'b0;
  logic enable_sample = 1'b1;
    
  initial begin
        // Assert reset
		reset <= 1'b1;
        @(posedge clk);
        
        // Deassert reset
        reset <= 1'b0;
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
  
    initial
    begin
      // Required for EDA Playground
      $dumpfile("dump.vcd"); 
      $dumpvars;
      
      repeat(10000) @(posedge clk);
      
      // Test generating pseudo random bits
      //gen_bit();
      //$display("first bit, Received 0x%X", own_challenge); 
      //repeat(10) @(posedge clk);
      //gen_bit();
      $display("?, Received 0x%X", own_challenge); 
      $finish();      
    end

endmodule

