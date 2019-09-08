/*
 * analysis.cpp
 *
 *  Created on: 2019年9月7日
 *      Author: athieka@hotmail.com
 */
module MAIN(input SYS_CLK,
            input SYS_RSTn,
				inout SYS_WDI,
				// psram interface
				output PSRAM_CEn,
				output PSRAM_CLK,
				inout[3:0] PSRAM_SIO,
				// mcu interface
				input MCU_SPI_SCLK,
				input MCU_SPI_CS,
				input MCU_SPI_MOSI,
				input MCU_REQ,
				output MCU_ACK
				//output MCU_SPI_MISO
				);
wire SYS_CLK_100M;
wire SYS_CLK_33M;
wire pll0_locked;
wire GLOBAL_RESET = (~SYS_RSTn) | (~pll0_locked);
Gowin_PLL pll0(.clkin(SYS_CLK),
				.clkout(SYS_CLK_100M),
				.lock(pll0_locked));
wire[3:0] PSRAM_SIO_OUT;
wire PSRAM_CMD_DIR;
wire PSRAM_SIO_DIR;
assign PSRAM_SIO[0] = PSRAM_CMD_DIR ? PSRAM_SIO_OUT[0] : 1'bz;
assign PSRAM_SIO[3:1] = PSRAM_SIO_DIR ? PSRAM_SIO_OUT[3:1] : 3'bzzz;
PSRAM64 psram64(.clk(SYS_CLK_100M),
						.reset(GLOBAL_RESET),
						.PSRAM_CEn(PSRAM_CEn),
						.PSRAM_CLK(PSRAM_CLK),
						.PSRAM_SIO_OUT(PSRAM_SIO_OUT),
						.PSRAM_SIO_IN(PSRAM_SIO),
						.PSRAM_CMD_DIR(PSRAM_CMD_DIR),
						.PSRAM_SIO_DIR(PSRAM_SIO_DIR),
						.rdfifo_rdclk(SYS_CLK_100M),
						.rdfifo_rdreq(1'b1),
						.MCU_SCLK(MCU_SPI_SCLK),
						.MCU_CS(MCU_SPI_CS),
						.MCU_MOSI(MCU_SPI_MOSI),
						.MCU_REQ(MCU_REQ),
						.MCU_ACK(MCU_ACK));
endmodule
