SIMULATOR = iverilog -g2012
GTKWAVE = gtkwave

sim:
	${SIMULATOR} -o testbench testbench.sv
	vvp testbench

wave:
	${GTKWAVE} dump.vcd sim.gtkw

clean:
	rm -f dump.vcd
	rm -f testbench	

.PHONY: sim wave clean 

