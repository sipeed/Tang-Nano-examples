/*
 * TOP.v
 *
 *  Created on: 2019年9月7日
 *      Author: athieka@hotmail.com
 */
module TOP(input SYS_CLK,
            input SYS_RSTn,
            output LED_R,
            output LED_G,
            output LED_B,
            // psram interface
            output PSRAM_CEn,
            output PSRAM_CLK,
            inout[3:0] PSRAM_SIO,
            // mcu interface
            //input MCU_SPI_SCLK,
            //input MCU_SPI_CS,
            //input MCU_SPI_MOSI,
            input MCU_REQ,
            output MCU_ACK,
            // LCD
            output reg[4:0] LCD_R,
            output reg[5:0] LCD_G,
            output reg[4:0] LCD_B,
            output reg LCD_VSYNC,
            output reg LCD_HSYNC,
            output reg LCD_DEN,
            output LCD_PCLK,
            input LCD_BKL
            );
wire SYS_CLK_100M;
wire SYS_CLK_25M;
wire pll0_lock;
PLL0 pll0(
        .clkout(SYS_CLK_100M), //output clkout
        .lock(pll0_lock), //output lock
        .clkoutd(SYS_CLK_25M), //output clkoutd
        .clkin(SYS_CLK) //input clkin
    );

wire GLOBAL_RESET = (~SYS_RSTn) | (~pll0_lock);
wire PSRAM_CTRL;
wire psram_ce_n;
wire psram_clk;
wire[3:0] PSRAM_SIO_OUT;
wire PSRAM_CMD_DIR;
wire PSRAM_SIO_DIR;
assign PSRAM_SIO[0] = PSRAM_CTRL & PSRAM_CMD_DIR ? PSRAM_SIO_OUT[0] : 1'bz;
assign PSRAM_SIO[3:1] = PSRAM_CTRL & PSRAM_SIO_DIR ? PSRAM_SIO_OUT[3:1] : 3'bzzz;
assign PSRAM_CEn = PSRAM_CTRL ? psram_ce_n : 1'bz;
assign PSRAM_CLK = PSRAM_CTRL ? psram_clk : 1'bz;

wire[4:0] lcd_r;
wire[5:0] lcd_g;
wire[4:0] lcd_b;
wire lcd_hsync;
wire lcd_vsync;
wire lcd_den;
wire lcd_pclk = SYS_CLK_25M;

PSRAM64 psram64(.clk(SYS_CLK_100M),
						.reset(GLOBAL_RESET),
						.PSRAM_CEn(psram_ce_n),
						.PSRAM_CLK(psram_clk),
						.PSRAM_SIO_OUT(PSRAM_SIO_OUT),
						.PSRAM_SIO_IN(PSRAM_SIO),
						.PSRAM_CMD_DIR(PSRAM_CMD_DIR),
						.PSRAM_SIO_DIR(PSRAM_SIO_DIR),
                        .PSRAM_CTRL(PSRAM_CTRL),
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
