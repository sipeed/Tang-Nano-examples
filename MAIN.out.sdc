## Generated SDC file "MAIN.out.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.1.0 Build 162 10/23/2013 SJ Full Version"

## DATE    "Mon Sep 09 21:46:20 2019"

##
## DEVICE  "EP4CE115F23I7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {SYS_CLK} -period 100.000 -waveform { 0.000 50.000 } [get_ports {SYS_CLK}]
create_clock -name {PSRAM_CLK} -period 10.000 -waveform { 0.000 5.000 } [get_ports {PSRAM_CLK}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {pll0|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {pll0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 10 -master_clock {SYS_CLK} [get_pins {pll0|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {pll0|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {pll0|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 2 -master_clock {SYS_CLK} [get_pins {pll0|altpll_component|auto_generated|pll1|clk[1]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay -max -clock [get_clocks {PSRAM_CLK}]  7.500 [get_ports {PSRAM_SIO[0]}]
set_input_delay -add_delay -min -clock [get_clocks {PSRAM_CLK}]  2.500 [get_ports {PSRAM_SIO[0]}]
set_input_delay -add_delay -max -clock [get_clocks {PSRAM_CLK}]  7.500 [get_ports {PSRAM_SIO[1]}]
set_input_delay -add_delay -min -clock [get_clocks {PSRAM_CLK}]  2.500 [get_ports {PSRAM_SIO[1]}]
set_input_delay -add_delay -max -clock [get_clocks {PSRAM_CLK}]  7.500 [get_ports {PSRAM_SIO[2]}]
set_input_delay -add_delay -min -clock [get_clocks {PSRAM_CLK}]  2.500 [get_ports {PSRAM_SIO[2]}]
set_input_delay -add_delay -max -clock [get_clocks {PSRAM_CLK}]  7.500 [get_ports {PSRAM_SIO[3]}]
set_input_delay -add_delay -min -clock [get_clocks {PSRAM_CLK}]  2.500 [get_ports {PSRAM_SIO[3]}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay -max -clock [get_clocks {PSRAM_CLK}]  4.000 [get_ports {PSRAM_CEn}]
set_output_delay -add_delay -min -clock [get_clocks {PSRAM_CLK}]  -1.500 [get_ports {PSRAM_CEn}]
set_output_delay -add_delay -max -clock [get_clocks {PSRAM_CLK}]  4.000 [get_ports {PSRAM_SIO[0]}]
set_output_delay -add_delay -min -clock [get_clocks {PSRAM_CLK}]  -1.500 [get_ports {PSRAM_SIO[0]}]
set_output_delay -add_delay -max -clock [get_clocks {PSRAM_CLK}]  4.000 [get_ports {PSRAM_SIO[1]}]
set_output_delay -add_delay -min -clock [get_clocks {PSRAM_CLK}]  -1.500 [get_ports {PSRAM_SIO[1]}]
set_output_delay -add_delay -max -clock [get_clocks {PSRAM_CLK}]  4.000 [get_ports {PSRAM_SIO[2]}]
set_output_delay -add_delay -min -clock [get_clocks {PSRAM_CLK}]  -1.500 [get_ports {PSRAM_SIO[2]}]
set_output_delay -add_delay -max -clock [get_clocks {PSRAM_CLK}]  4.000 [get_ports {PSRAM_SIO[3]}]
set_output_delay -add_delay -min -clock [get_clocks {PSRAM_CLK}]  -1.500 [get_ports {PSRAM_SIO[3]}]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from [get_keepers {*rdptr_g*}] -to [get_keepers {*ws_dgrp|dffpipe_se9:dffpipe9|dffe10a*}]
set_false_path -from [get_keepers {*delayed_wrptr_g*}] -to [get_keepers {*rs_dgwp|dffpipe_re9:dffpipe6|dffe7a*}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

