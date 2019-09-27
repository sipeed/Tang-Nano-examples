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
assign LED_B = 1'b0;
wire SYS_CLK_80M;
wire SYS_CLK_10M;
wire pll0_lock;
PLL0 pll0(
        .clkout(SYS_CLK_80M), //output clkout
        .lock(pll0_lock), //output lock
        .clkoutd(SYS_CLK_10M), //output clkoutd
        .clkin(SYS_CLK) //input clkin
    );

wire GLOBAL_RESET = (~SYS_RSTn) | (~pll0_lock);


wire[4:0] lcd_r;
wire[5:0] lcd_g;
wire[4:0] lcd_b;
wire lcd_hsync;
wire lcd_vsync;
wire lcd_den;
wire lcd_pclk = SYS_CLK_10M;
assign LCD_PCLK = SYS_CLK_10M;
always @(posedge LCD_PCLK or posedge GLOBAL_RESET)
begin
	if (GLOBAL_RESET)
	begin
		LCD_R <= {8{1'b1}};
		LCD_G <= {8{1'b1}};
		LCD_B <= {8{1'b1}};
		LCD_VSYNC <= 1'b1;
		LCD_HSYNC <= 1'b1;
		LCD_DEN <= 1'b0;
	end
	else
	begin
		LCD_R <= {lcd_r, 3'b000};
		LCD_G <= {lcd_g, 2'b00};
		LCD_B <= {lcd_b, 3'b000};
		LCD_HSYNC <= ~lcd_hsync;
		LCD_VSYNC <= ~lcd_vsync;
		LCD_DEN <= lcd_den;
	end
end

wire psram_ctrl;//synthesis keep
wire psram_ce_n;//synthesis keep
wire psram_sclk;//synthesis keep
wire[3:0] psram_sio_out;//synthesis keep
wire[3:0] psram_sio_in;//synthesis keep
wire[3:0] psram_sio_dir;//synthesis keep
assign PSRAM_CLK = psram_ctrl ? psram_sclk : 1'bz;
assign PSRAM_CEn = psram_ctrl ? psram_ce_n : 1'bz;
assign psram_sio_in = PSRAM_SIO;
genvar i;
generate
for (i=0; i<4; i=i+1)
begin : insSIO
	assign PSRAM_SIO[i] = psram_ctrl & psram_sio_dir[i] ? psram_sio_out[i] : 1'bz;
end
endgenerate

LCD_PSRAM lcd0(.clk(SYS_CLK_80M),
			.reset(GLOBAL_RESET),
			.psram_ctrl(psram_ctrl),
			.psram_ce_n(psram_ce_n),
			.psram_sclk(psram_sclk),
			.psram_sio_out(psram_sio_out),
			.psram_sio_in(psram_sio_in),
			.psram_sio_dir(psram_sio_dir),
			.lcd_pclk(SYS_CLK_10M),
			.lcd_r(lcd_r),
			.lcd_g(lcd_g),
			.lcd_b(lcd_b),
			.lcd_hsync(lcd_hsync),
			.lcd_vsync(lcd_vsync),
			.lcd_den(lcd_den));
endmodule
