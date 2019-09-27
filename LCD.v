module LCD(input clk,
			input reset,
			input lcd_pclk,
			output[4:0] lcd_r,
			output[5:0] lcd_g,
			output[4:0] lcd_b,
			output lcd_hsync,
			output lcd_vsync,
			output lcd_den
			 );
parameter SCREEN_WIDTH = 10'd800;
parameter SCREEN_HEIGTH = 10'd480;
parameter VBP	= 8'd1;	// vertical back porch timing
parameter VFP	= 8'd5;	// vertical front porch timing
parameter HBP	= 8'd10;	// horizontal back porch timing
parameter HFP	= 8'd20;	// horizontal front porch timing
localparam LCD_LINES = SCREEN_HEIGTH + VBP + VFP;
localparam LCD_LINE_SIZE = SCREEN_WIDTH + HBP + HFP;
wire[13:0] fb_line_addr[0:LCD_LINES-1];

genvar j;
generate
for (j=0;j<LCD_LINES; j=j+1)
begin: insLineAddr
	assign fb_line_addr[j] = j * LCD_LINE_SIZE;
end
endgenerate
reg[9:0] old_line;
reg[9:0] cur_line;//synthesis keep
reg[9:0] cur_pos;//synthesis keep
wire[9:0] next_pos = cur_pos + 1'b1;
wire[9:0] next_line = cur_line + 1'b1;
wire cur_hsync = cur_pos == 0 ? 1'b1 : 1'b0;//synthesis keep
wire cur_vsync = (old_line == LCD_LINES - 4'd1) && (cur_line == 0) ? 1'b1 : 1'b0;//synthesis keep
wire cur_den/* synthesis keep="1" */;
assign cur_den = ((cur_line >= VBP) 
						&& (cur_line <= LCD_LINES - VFP) 
						&& (cur_pos >= HBP) 
						&& (cur_pos <= LCD_LINE_SIZE - HFP)) ? 1'b1 : 1'b0;
wire[21:0] cur_addr = fb_line_addr[cur_line] + cur_pos/* synthesis keep=1 */;
wire[23:0] psram_addr = {1'b0, cur_addr, 1'b0};//synthesis keep

always @(posedge clk or posedge reset)
begin
	if (reset)
	begin
		old_line <= LCD_LINES - 4'd1;
		cur_line <= 10'd0;
		cur_pos <= 10'd0;
	end
	else
	begin		
		if (lcd_fifo_wrreq)
		begin
			old_line <= cur_line;
			if (next_pos < LCD_LINE_SIZE) cur_pos <= next_pos;
			else
			begin
				cur_pos <= 10'd0;
				if (next_line < LCD_LINES) cur_line <= next_line;
				else cur_line <= 10'd0;
			end			
		end
	end
end


reg[19:0] lcd_fifo_data;//synthesis keep
wire[19:0] lcd_fifo_q;//synthesis keep
wire lcd_fifo_aempty_flag;//synthesis keep
wire lcd_fifo_afull_flag;//synthesis keep
reg lcd_fifo_wrreq;//synthesis keep
wire lcd_fifo_empty_flag;//synthesis keep
wire lcd_fifo_full_flag;//synthesis keep
assign lcd_b = lcd_fifo_q[4:0];
assign lcd_g = lcd_fifo_q[10:5];
assign lcd_r = lcd_fifo_q[15:11];
assign lcd_hsync = lcd_fifo_q[16];
assign lcd_vsync = lcd_fifo_q[17];
assign lcd_den = lcd_fifo_q[18];

LCD_FIFO lcd_fifo(.rst(reset),
					.di(lcd_fifo_data),
					.clkw(clk),
					.we(lcd_fifo_wrreq),
					.do(lcd_fifo_q),
					.clkr(lcd_pclk),
					.aempty_flag(lcd_fifo_aempty_flag),
					.re(~lcd_fifo_aempty_flag),
					.afull_flag(lcd_fifo_afull_flag),
					.empty_flag(lcd_fifo_empty_flag),
					.full_flag(lcd_fifo_full_flag));
		
always @(posedge clk or posedge reset)
begin
	if (reset)
	begin
		lcd_fifo_wrreq <= 1'b0;
		lcd_fifo_data <= 20'hffffff;
	end
	else
	begin
		if (~lcd_fifo_afull_flag)
		begin
			lcd_fifo_data[15:0] <= {5'b11111, 6'b000000, 5'b00000};
			lcd_fifo_data[16] <= cur_hsync;
			lcd_fifo_data[17] <= cur_vsync;
			lcd_fifo_data[18] <= cur_den;
			lcd_fifo_wrreq <= 1'b1;
		end
		else
		begin
			lcd_fifo_wrreq <= 1'b0;
		end
	end
end
endmodule
