
#Begin clock constraint
define_clock -name {LCD_FIFO|WrClk} {p:LCD_FIFO|WrClk} -period 13.504 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 6.752 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {LCD_FIFO|RdClk} {p:LCD_FIFO|RdClk} -period 14.945 -clockgroup Autoconstr_clkgroup_1 -rise 0.000 -fall 7.473 -route 0.000 
#End clock constraint
