`include "config.v"
module LCD_RAM(input aclr,
                input[19:0] data,
                input rdclk,
                input rdreq,
                input wrclk,
                input wrreq,
                output[19:0] q,
                output rdempty,
                output wrfull,
                output almost_empty,
                output almost_full);
`ifdef NANO
LCD_FIFO lcd_fifo(.Reset(aclr),
					.Data(data),
					.WrClk(wrclk),
					.WrEn(wrreq),
					.Q(q),
					.RdClk(rdclk),
					.Almost_Empty(almost_empty),
					.RdEn(rdreq),
					.Almost_Full(almost_full),
					.Empty(rdempty),
					.Full(wrfull));
`else
LCD_FIFO lcd_fifo(.rst(aclr),
					.di(data),
					.clkw(wrclk),
					.we(wrreq),
					.do(q),
					.clkr(rdclk),
					.aempty_flag(almost_empty),
					.re(rdreq),
					.afull_flag(almost_full),
					.empty_flag(rdempty),
					.full_flag(wrfull));
`endif


endmodule
