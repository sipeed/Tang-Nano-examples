//Copyright (C)2014-2019 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: v1.9.2Beta
//Part Number: GW1N-LV1QN48C5/I4
//Created Time: Sun Sep 29 00:40:23 2019

module PLL0 (clkout, lock, clkoutp, clkoutd, clkin);

output clkout;
output lock;
output clkoutp;
output clkoutd;
input clkin;

wire clkoutd3_o;
wire gw_vcc;
wire gw_gnd;

assign gw_vcc = 1'b1;
assign gw_gnd = 1'b0;

PLL pll_inst (
    .CLKOUT(clkout),
    .LOCK(lock),
    .CLKOUTP(clkoutp),
    .CLKOUTD(clkoutd),
    .CLKOUTD3(clkoutd3_o),
    .RESET(gw_gnd),
    .RESET_P(gw_gnd),
    .RESET_I(gw_gnd),
    .RESET_S(gw_gnd),
    .CLKIN(clkin),
    .CLKFB(gw_gnd),
    .FBDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .IDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PSDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTYDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDLY({gw_vcc,gw_vcc,gw_vcc,gw_vcc})
);

defparam pll_inst.FCLKIN = "24";
defparam pll_inst.DYN_IDIV_SEL = "false";
defparam pll_inst.IDIV_SEL = 7;
defparam pll_inst.DYN_FBDIV_SEL = "false";
defparam pll_inst.FBDIV_SEL = 10;
defparam pll_inst.DYN_ODIV_SEL = "false";
defparam pll_inst.ODIV_SEL = 16;
defparam pll_inst.PSDA_SEL = "0000";
defparam pll_inst.DYN_DA_EN = "false";
defparam pll_inst.DUTYDA_SEL = "1000";
defparam pll_inst.CLKOUT_FT_DIR = 1'b1;
defparam pll_inst.CLKOUTP_FT_DIR = 1'b1;
defparam pll_inst.CLKOUT_DLY_STEP = 0;
defparam pll_inst.CLKOUTP_DLY_STEP = 0;
defparam pll_inst.CLKFB_SEL = "internal";
defparam pll_inst.CLKOUT_BYPASS = "false";
defparam pll_inst.CLKOUTP_BYPASS = "false";
defparam pll_inst.CLKOUTD_BYPASS = "false";
defparam pll_inst.DYN_SDIV_SEL = 10;
defparam pll_inst.CLKOUTD_SRC = "CLKOUTP";
defparam pll_inst.CLKOUTD3_SRC = "CLKOUT";
defparam pll_inst.DEVICE = "GW1N-1";

endmodule //PLL0
