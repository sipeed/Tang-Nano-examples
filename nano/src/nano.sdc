//Copyright (C)2014-2019 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.2 Beta
//Created Time: 2019-09-22 22:06:18
create_clock -name SYS_CLK -period 41.666 -waveform {0 20.833} [get_ports {SYS_CLK}]
create_clock -name PSRAM_CLK -period 13.888 -waveform {0 6.944} [get_ports {PSRAM_CLK}]
//create_clock -name SYS_CLK_100M -period 13.888 -waveform {0 6.944} [get_nets {SYS_CLK_100M}]
set_input_delay -clock PSRAM_CLK 7.5 -max -add_delay [get_ports {PSRAM_SIO[0]}]
set_input_delay -clock PSRAM_CLK 2.5 -min -add_delay [get_ports {PSRAM_SIO[0]}]
set_input_delay -clock PSRAM_CLK 7.5 -max -add_delay [get_ports {PSRAM_SIO[1]}]
set_input_delay -clock PSRAM_CLK 2.5 -min -add_delay [get_ports {PSRAM_SIO[1]}]
set_input_delay -clock PSRAM_CLK 7.5 -max -add_delay [get_ports {PSRAM_SIO[2]}]
set_input_delay -clock PSRAM_CLK 2.5 -min -add_delay [get_ports {PSRAM_SIO[2]}]
set_input_delay -clock PSRAM_CLK 7.5 -max -add_delay [get_ports {PSRAM_SIO[3]}]
set_input_delay -clock PSRAM_CLK 2.5 -min -add_delay [get_ports {PSRAM_SIO[3]}]
set_output_delay -clock PSRAM_CLK 4 -max -add_delay [get_ports {PSRAM_CEn}]
set_output_delay -clock PSRAM_CLK -1.5 -min -add_delay [get_ports {PSRAM_CEn}]
set_output_delay -clock PSRAM_CLK 4 -max -add_delay [get_ports {PSRAM_SIO[0]}]
set_output_delay -clock PSRAM_CLK -1.5 -min -add_delay [get_ports {PSRAM_SIO[0]}]
set_output_delay -clock PSRAM_CLK 4 -max -add_delay [get_ports {PSRAM_SIO[1]}]
set_output_delay -clock PSRAM_CLK -1.5 -min -add_delay [get_ports {PSRAM_SIO[1]}]
set_output_delay -clock PSRAM_CLK 4 -max -add_delay [get_ports {PSRAM_SIO[2]}]
set_output_delay -clock PSRAM_CLK -1.5 -min -add_delay [get_ports {PSRAM_SIO[2]}]
set_output_delay -clock PSRAM_CLK 4 -max -add_delay [get_ports {PSRAM_SIO[3]}]
set_output_delay -clock PSRAM_CLK -1.5 -min -add_delay [get_ports {PSRAM_SIO[3]}]
