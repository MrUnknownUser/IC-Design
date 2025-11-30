/*
 * modeled after
 * https://gist.github.com/tzechienchu/bf698f51e406cfcc59238a9ceebe2827
 */
`timescale 1ns/1ps

module fibonacci_pseudo_random_128(input  clk, ce, rst, output reg [127:0] q);
// according to https://poincare.matf.bg.ac.rs/%7Eezivkovm/publications/primpol1.pdf
// use this primitive polynomial: x^128 + x^95 + x^57 + x^45 + x^38 + x^36 + 1
// about the longest we found for degree 128
logic feedback = q[127]^q[94]^q[56]^q[44]^q[37]^q[35]^q[0];

always @(posedge clk or posedge rst)
  if (rst) 
    q <= 128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; // initialize with non-zero value -> avoidance of all-zero-lockup issue
  else if (ce)
    q <= {q[127:0], feedback};  // shift all bytes by one bit
endmodule


/* come back once we've understood this
module galois_pseudo_random_128(input  clk, ce, rst, output reg [127:0] q);
// according to https://poincare.matf.bg.ac.rs/%7Eezivkovm/publications/primpol1.pdf
// use this primitive polynomial: x^128 + x^95 + x^57 + x^45 + x^38 + x^36 + 1
// about the longest we found for degree 128
logic feedback = q[127]^q[126]


always @(posedge clk or posedge rst)
  if (rst) 
    q <= 128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; // initialize with non-zero value -> avoidance of all-zero-lockup issue
  else if (ce)
    q <= {q[127:0], feedback};  // shift all bytes by one bit
endmodule
*/