
#Begin clock constraint
define_clock -name {PSRAM_RDFIFO|WrClk} {p:PSRAM_RDFIFO|WrClk} -period 13.556 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 6.778 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {PSRAM_RDFIFO|RdClk} {p:PSRAM_RDFIFO|RdClk} -period 15.236 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 7.618 -route 0.000 
#End clock constraint
