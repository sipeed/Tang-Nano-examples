module GATED_CLK(input clkin,
					 output clkout,
					 input clken);
/*reg clken_buf;
always @(posedge clkin)
begin
	clken_buf <= clken;
end
assign clkout = clken_buf & clkin;*/
DQCE dqce_inst (
.CLKIN(clkin), 
.CE(clken), 
.CLKOUT(clkout)
);
endmodule
