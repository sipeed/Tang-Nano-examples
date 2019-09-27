module TOP(input SYS_CLK,
			input RSTn,
			output reg[7:0] LCD_R,
			output reg[7:0] LCD_G,
			output reg[7:0] LCD_B,
			output reg LCD_HSYNC,
			output reg LCD_VSYNC,
			output reg LCD_DEN,
			output LCD_PWM,
			output LCD_PCLK,
			
			inout PSRAM_CEn,
			inout PSRAM_CLK,
			inout[3:0] PSRAM_SIO,
			input MCU_REQ,
			output MCU_ACK,
			
			input SPI_CEn,
			input SPI_SCLK,
			input[3:0] SPI_SIO
			);
wire spi_ce_n = SPI_CEn;//synthesis keep
wire spi_sclk = SPI_SCLK;//synthesis keep
wire[3:0] spi_sio = SPI_SIO;//synthesis keep
assign LCD_PWM = 1'b1;
wire pll0_lock;
wire GLOBAL_RESET = (~RSTn) | (~pll0_lock);//synthesis keep
wire SYS_CLK_100M;//synthesis keep
wire SYS_CLK_60M;//synthesis keep
wire SYS_CLK_33M;//synthesis keep
wire SYS_CLK_15M;//synthesis keep
wire SYS_CLK_5M;
PLL0 pll0(.refclk(SYS_CLK),
			.extlock(pll0_lock),
			.clk0_out(SYS_CLK_100M),
			.clk1_out(SYS_CLK_60M),
			.clk2_out(SYS_CLK_33M),
			.clk3_out(SYS_CLK_15M),
			.clk4_out(SYS_CLK_5M));
assign LCD_PCLK = SYS_CLK_15M;
wire[4:0] lcd_r;//synthesis keep
wire[5:0] lcd_g;//synthesis keep
wire[4:0] lcd_b;//synthesis keep
wire lcd_hsync;//synthesis keep
wire lcd_vsync;//synthesis keep
wire lcd_den;//synthesis keep

//assign PSRAM_CLK = psram_ctrl ? psram_clk : 1'bz;//synthesis keep


//assign PSRAM_CEn = psram_ctrl ? psram_ce_n : 1'bz;//synthesis keep
/*assign PSRAM_CEn = psram_ce_n;
assign PSRAM_SIO[0] = psram_cmd_dir ? psram_sio_out[0] : 1'bz;//synthesis keep
assign PSRAM_SIO[3:1] = psram_sio_dir ? psram_sio_out[3:1] : 3'bzzz;//synthesis keep
wire[3:0] psram_sio;//synthesis keep
assign psram_sio = PSRAM_SIO;
PSRAM64 lcd0(.clk(SYS_CLK_33M),
			.reset(GLOBAL_RESET),
			.pclk(SYS_CLK_15M),
			.red(lcd_r),
			.green(lcd_g),
			.blue(lcd_b),
			.hsync(lcd_hsync),
			.vsync(lcd_vsync),
			.den(lcd_den),
			.PSRAM_CTRL(psram_ctrl),
			.PSRAM_CLK(psram_clk),
			.PSRAM_CEn(psram_ce_n),
			.PSRAM_CMD_DIR(psram_cmd_dir),
			.PSRAM_SIO_DIR(psram_sio_dir),
			.PSRAM_SIO_OUT(psram_sio_out),
			.PSRAM_SIO_IN(PSRAM_SIO),
			.MCU_REQ(MCU_REQ),
			.MCU_ACK(MCU_ACK)
			);*/
			
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

LCD_PSRAM lcd0(.clk(SYS_CLK_33M),
			.reset(GLOBAL_RESET),
			.psram_ctrl(psram_ctrl),
			.psram_ce_n(psram_ce_n),
			.psram_sclk(psram_sclk),
			.psram_sio_out(psram_sio_out),
			.psram_sio_in(psram_sio_in),
			.psram_sio_dir(psram_sio_dir),
			.lcd_pclk(SYS_CLK_5M),
			.lcd_r(lcd_r),
			.lcd_g(lcd_g),
			.lcd_b(lcd_b),
			.lcd_hsync(lcd_hsync),
			.lcd_vsync(lcd_vsync),
			.lcd_den(lcd_den));
endmodule
