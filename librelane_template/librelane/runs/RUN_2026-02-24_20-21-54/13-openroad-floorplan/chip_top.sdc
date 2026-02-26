###############################################################################
# Created by write_sdc
###############################################################################
current_design chip_top
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk_core -period 20.0000 
set_clock_uncertainty 0.1500 clk_core
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {clk_PAD}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {input_PAD[0]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {input_PAD[1]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {input_PAD[2]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {input_PAD[3]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {input_PAD[4]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {input_PAD[5]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {input_PAD[6]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {input_PAD[7]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[0]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[1]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[2]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[3]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[4]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[5]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[6]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[7]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[8]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {output_PAD[9]}]
set_input_delay 8.0000 -clock [get_clocks {clk_core}] -add_delay [get_ports {rst_n_PAD}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 5.0000 [get_ports {clk_PAD}]
set_load -pin_load 5.0000 [get_ports {rst_n_PAD}]
set_load -pin_load 5.0000 [get_ports {input_PAD[7]}]
set_load -pin_load 5.0000 [get_ports {input_PAD[6]}]
set_load -pin_load 5.0000 [get_ports {input_PAD[5]}]
set_load -pin_load 5.0000 [get_ports {input_PAD[4]}]
set_load -pin_load 5.0000 [get_ports {input_PAD[3]}]
set_load -pin_load 5.0000 [get_ports {input_PAD[2]}]
set_load -pin_load 5.0000 [get_ports {input_PAD[1]}]
set_load -pin_load 5.0000 [get_ports {input_PAD[0]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[9]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[8]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[7]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[6]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[5]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[4]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[3]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[2]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[1]}]
set_load -pin_load 5.0000 [get_ports {output_PAD[0]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {clk_PAD}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {rst_n_PAD}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {input_PAD[7]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {input_PAD[6]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {input_PAD[5]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {input_PAD[4]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {input_PAD[3]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {input_PAD[2]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {input_PAD[1]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {input_PAD[0]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[9]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[8]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[7]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[6]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[5]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[4]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[3]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[2]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[1]}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin {pad} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {output_PAD[0]}]
###############################################################################
# Design Rules
###############################################################################
set_max_transition 3.0000 [current_design]
set_max_capacitance 0.5000 [current_design]
set_max_fanout 8.0000 [current_design]
