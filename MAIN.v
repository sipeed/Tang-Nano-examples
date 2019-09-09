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
				output MCU_ACK,
				
				output reg[4:0] LCD_R,
				output reg[5:0] LCD_G,
				output reg[4:0] LCD_B,
				output reg LCD_VSYNC,
				output reg LCD_HSYNC,
				output reg LCD_DEN,
				output LCD_PCLK
				//output MCU_SPI_MISO
				);
wire SYS_CLK_100M;
wire SYS_CLK_20M;
wire pll0_locked;
wire GLOBAL_RESET = (~SYS_RSTn) | (~pll0_locked);
PLL0 pll0(.inclk0(SYS_CLK),
				.c0(SYS_CLK_100M),
				.c1(SYS_CLK_20M),
				.locked(pll0_locked));
wire[3:0] PSRAM_SIO_OUT;
wire PSRAM_CMD_DIR;
wire PSRAM_SIO_DIR;
assign PSRAM_SIO[0] = PSRAM_CMD_DIR ? PSRAM_SIO_OUT[0] : 1'bz;
assign PSRAM_SIO[3:1] = PSRAM_SIO_DIR ? PSRAM_SIO_OUT[3:1] : 3'bzzz;

wire[4:0] lcd_r;
wire[5:0] lcd_g;
wire[4:0] lcd_b;
wire lcd_hsync;
wire lcd_vsync;
wire lcd_den;
wire lcd_pclk = SYS_CLK_20M;
PSRAM64 psram64(.clk(SYS_CLK_100M),
						.reset(GLOBAL_RESET),
						.PSRAM_CEn(PSRAM_CEn),
						.PSRAM_CLK(PSRAM_CLK),
						.PSRAM_SIO_OUT(PSRAM_SIO_OUT),
						.PSRAM_SIO_IN(PSRAM_SIO),
						.PSRAM_CMD_DIR(PSRAM_CMD_DIR),
						.PSRAM_SIO_DIR(PSRAM_SIO_DIR),
						.MCU_SCLK(MCU_SPI_SCLK),
						.MCU_CS(MCU_SPI_CS),
						.MCU_MOSI(MCU_SPI_MOSI),
						.MCU_REQ(MCU_REQ),
						.MCU_ACK(MCU_ACK),
						
						.pclk(lcd_pclk),
						.red(lcd_r),
						.green(lcd_g),
						.blue(lcd_b),
						.hsync(lcd_hsync),
						.vsync(lcd_vsync),
						.den(lcd_den));
assign LCD_PCLK = ~lcd_pclk;
always @(posedge lcd_pclk or posedge GLOBAL_RESET)
begin
	if (GLOBAL_RESET)
	begin
		LCD_R <= {5{1'b1}};
		LCD_G <= {6{1'b1}};
		LCD_B <= {5{1'b1}};
		LCD_VSYNC <= 1'b1;
		LCD_HSYNC <= 1'b1;
		LCD_DEN <= 1'b0;
	end
	else
	begin
		LCD_R <= lcd_r;
		LCD_G <= lcd_g;
		LCD_B <= lcd_b;
		LCD_HSYNC <= ~lcd_hsync;
		LCD_VSYNC <= ~lcd_vsync;
		LCD_DEN <= lcd_den;
	end
end

endmodule
