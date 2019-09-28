`include "config.v"
module GATED_CLK(input clkin,
					 output clkout,
					 input clken);
/*reg clken_buf;
always @(posedge clkin)
begin
	clken_buf <= clken;
end
assign clkout = clken_buf & clkin;*/
`ifdef NANO
/*DQCE dqce_inst (
.CLKIN(clkin), 
.CE(clken), 
.CLKOUT(clkout)
);*/
DCS dcs_inst (
.CLK0(clkin), 
.CLK1(1'b0),
.CLK2(1'b0),
.CLK3(1'b0),
.CLKSEL({3'b0, clken}),
.SELFORCE(selforce),
.CLKOUT(clkout)
);
defparam dcs_inst.DCS_MODE="RISING";
`else
EG_LOGIC_BUFGMUX ins(.o(clkout),
						.i0(clkin),
						.i1(1'b0),
						.s(~clken));
`endif
endmodule
