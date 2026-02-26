## link
- https://www.edaplayground.com/x/db6u

## output
> [2026-02-25 15:55:22 UTC] iverilog '-Wall' '-g2012' design.sv testbench.sv  && unbuffer vvp a.out  
warning: Some design elements have no explicit time unit and/or
       : time precision. This may cause confusing timing results.
       : Affected design elements are:
       :   -- module ASG declared here: ./ASG.v:7
       :   -- module LSFR declared here: ./LSFR.v:1
       :   -- module LSFR_1 declared here: ./LSFR_1.v:1
       :   -- module LSFR_2 declared here: ./LSFR_2.v:1
Forced start patterns into R1/R2/R3 at time 25000
45000 ns: cycle 0 newBit=0
55000 ns: cycle 1 newBit=0
65000 ns: cycle 2 newBit=0
75000 ns: cycle 3 newBit=0
85000 ns: cycle 4 newBit=0
95000 ns: cycle 5 newBit=0
105000 ns: cycle 6 newBit=0
115000 ns: cycle 7 newBit=0
125000 ns: cycle 8 newBit=0
135000 ns: cycle 9 newBit=0
145000 ns: cycle 10 newBit=0
155000 ns: cycle 11 newBit=0
165000 ns: cycle 12 newBit=0
175000 ns: cycle 13 newBit=0
185000 ns: cycle 14 newBit=0
195000 ns: cycle 15 newBit=0
205000 ns: cycle 16 newBit=0
215000 ns: cycle 17 newBit=0
225000 ns: cycle 18 newBit=0
235000 ns: cycle 19 newBit=0
245000 ns: cycle 20 newBit=0
255000 ns: cycle 21 newBit=0
265000 ns: cycle 22 newBit=0
275000 ns: cycle 23 newBit=0
285000 ns: cycle 24 newBit=0
295000 ns: cycle 25 newBit=0
305000 ns: cycle 26 newBit=0
315000 ns: cycle 27 newBit=0
325000 ns: cycle 28 newBit=0
335000 ns: cycle 29 newBit=0
345000 ns: cycle 30 newBit=0
355000 ns: cycle 31 newBit=0
365000 ns: cycle 32 newBit=0
375000 ns: cycle 33 newBit=0
385000 ns: cycle 34 newBit=0
395000 ns: cycle 35 newBit=0
405000 ns: cycle 36 newBit=0
415000 ns: cycle 37 newBit=0
425000 ns: cycle 38 newBit=0
435000 ns: cycle 39 newBit=0
445000 ns: cycle 40 newBit=0
455000 ns: cycle 41 newBit=0
465000 ns: cycle 42 newBit=0
475000 ns: cycle 43 newBit=0
485000 ns: cycle 44 newBit=0
495000 ns: cycle 45 newBit=0
505000 ns: cycle 46 newBit=0
515000 ns: cycle 47 newBit=0
525000 ns: cycle 48 newBit=0
535000 ns: cycle 49 newBit=0
545000 ns: cycle 50 newBit=0
555000 ns: cycle 51 newBit=0
565000 ns: cycle 52 newBit=0
575000 ns: cycle 53 newBit=0
585000 ns: cycle 54 newBit=0
595000 ns: cycle 55 newBit=0
605000 ns: cycle 56 newBit=0
615000 ns: cycle 57 newBit=0
625000 ns: cycle 58 newBit=0
635000 ns: cycle 59 newBit=0
645000 ns: cycle 60 newBit=0
655000 ns: cycle 61 newBit=0
665000 ns: cycle 62 newBit=0
675000 ns: cycle 63 newBit=0
Observed 64 bits (LSB = cycle 0): 0000000000000000000000000000000000000000000000000000000000000000
testbench.sv:109: $finish called at 675000 (1ps)
Finding VCD file...
No *.vcd file found. EPWave will not open. Did you use '$dumpfile("dump.vcd"); $dumpvars;'?
Done
