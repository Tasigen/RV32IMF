set_max_area 0
create_clock -period 5 [get_ports clk]
set_clock_transition 0.5 [get_clocks clk]
set_input_delay 1 -clock clk [get_ports rst]
set_load 0.1 [get_nets internal_signal]
set_input_transition 0.8 [get_ports rst]