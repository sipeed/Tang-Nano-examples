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
DQCE dqce_inst (
.CLKIN(clkin), 
.CE(clken), 
.CLKOUT(clkout)
);
`else
EG_LOGIC_BUFGMUX ins(.o(clkout),
						.i0(clkin),
						.i1(1'b0),
						.s(~clken));
`endif
endmodule
