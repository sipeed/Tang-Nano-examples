module GATED_CLK(input clkin,
					 output clkout,
					 input clken);
reg clken_buf;
always @(negedge clkin)
begin
	clken_buf <= clken;
end
assign clkout = clken_buf & clkin;
endmodule
