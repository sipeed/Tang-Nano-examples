module MAIN(input SYS_CLK,
            input SYS_RSTn,
				// psram interface
				output PSRAM_CEn,
				output PSRAM_CLK,
				inout[3:0] PSRAM_SIO,
				// mcu interface
				input MCU_SPI_SCLK,
				input MCU_SPI_CS,
				input MCU_SPI_MOSI,
				output MCU_SPI_MISO
				);
wire SYS_CLK_100M;
wire pll0_locked;
wire GLOBAL_RESET = (~SYS_RSTn) & (~pll0_locked);
PLL0 pll0(.inclk0(SYS_CLK),
				.c0(SYS_CLK_100M),
				.locked(pll0_locked));
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
						.PSRAM_SIO_DIR(PSRAM_SIO_DIR),
						.rdfifo_rdclk(SYS_CLK_100M),
						.rdfifo_rdreq(1'b1));
endmodule
