//Copyright (C)2014-2019 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: v1.9.2Beta
//Part Number: GW1N-LV1QN48C6/I5
//Created Time: Fri Oct 25 19:30:39 2019

module Gowin_OSC (oscout);

output oscout;

OSCH osc_inst (
    .OSCOUT(oscout)
);

defparam osc_inst.FREQ_DIV = 10;

endmodule //Gowin_OSC
