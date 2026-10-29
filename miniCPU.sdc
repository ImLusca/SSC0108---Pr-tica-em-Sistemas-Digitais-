# Stable manual pulses; no mechanical debouncing is implemented.
# Falling edge: fetch. Rising edge: execute. Validate up to 1 MHz.
create_clock -name CLK -period 1000.000 [get_ports {CLK}]
derive_clock_uncertainty
set_input_delay -clock CLK -max 10.000 [get_ports {BRST}]
set_input_delay -clock CLK -min 0.000 [get_ports {BRST}]
set_output_delay -clock CLK -max 10.000 [get_ports {Disp* LD*}]
set_output_delay -clock CLK -min 0.000 [get_ports {Disp* LD*}]
