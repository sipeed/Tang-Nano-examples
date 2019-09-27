`include "config.v"
module LCD_PSRAM(input clk,
					input reset,
					output reg psram_ctrl,
					output reg psram_ce_n,
					output psram_sclk,
					output reg[3:0] psram_sio_out,
					input[3:0] psram_sio_in,
					output reg[3:0] psram_sio_dir,
					input mcu_req,
					output mcu_ack,
					
					input lcd_pclk,
					output[4:0] lcd_r,
					output[5:0] lcd_g,
					output[4:0] lcd_b,
					output lcd_hsync,
					output lcd_vsync,
					output lcd_den,
                    output led_r
					);

parameter SCREEN_WIDTH = 10'd800;
parameter SCREEN_HEIGTH = 10'd480;
parameter VBP	= 8'd5;	// vertical back porch timing
parameter VFP	= 8'd5;	// vertical front porch timing
parameter HBP	= 8'd10;	// horizontal back porch timing
parameter HFP	= 8'd10;	// horizontal front porch timing
localparam LCD_LINES = SCREEN_HEIGTH + VBP + VFP;
localparam LCD_LINE_SIZE = SCREEN_WIDTH + HBP + HFP;
localparam SCREEN_SIZE = LCD_LINES * LCD_LINE_SIZE;
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


always @(negedge clk or posedge reset)
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

reg[15:0] lcd_fifo_data;//synthesis keep
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

LCD_RAM lcd_fifo(.aclr(reset),
                .data({1'b0, cur_den, cur_vsync, cur_hsync, lcd_fifo_data}),
                .rdclk(lcd_pclk),
                .rdreq(1'b1),
                .wrclk(~clk),
                .wrreq(lcd_fifo_wrreq),
                .q(lcd_fifo_q),
                .rdempty(lcd_fifo_empty_flag),
                .wrfull(lcd_fifo_full_flag),
                .almost_empty(lcd_fifo_aempty_flag),
                .almost_full(lcd_fifo_afull_flag));
reg psram_clk_out;	//synthesis keep
GATED_CLK sclk_gated(.clkin(clk),
						.clkout(psram_sclk),
						.clken(psram_clk_out));
reg[7:0] state;//synthesis keep
reg[7:0] task_state;//synthesis keep
reg[7:0] task_x;//synthesis keep
reg[15:0] tick_cnt;
reg[15:0] psram_eid;//synthesis keep
reg[1:0] spi_mode;//synthesis keep
reg[7:0] spi_buf_in;//synthesis keep
reg[7:0] spi_buf_in_high;
`define SPI_MODE_1	2'b00
`define SPI_MODE_4I	2'b01
`define SPI_MODE_4O	2'b10
`define SPI_MODE_WAIT	2'b11
always @(spi_mode)
begin
	case (spi_mode)
	`SPI_MODE_1: psram_sio_dir = 4'b0001;
	`SPI_MODE_4I: psram_sio_dir = 4'b0000;
	`SPI_MODE_4O: psram_sio_dir = 4'b1111;
	`SPI_MODE_WAIT: psram_sio_dir = 4'b0000;
	endcase
end

always @(posedge psram_sclk or posedge reset)
begin : spi_in_block
	if (reset)
	begin
		spi_buf_in <= 8'hff;
        spi_buf_in_high <= 8'hff;
	end
	else
	begin
		case (spi_mode)
		`SPI_MODE_1: 
        begin
            spi_buf_in <= {spi_buf_in[6:0], psram_sio_in[1]};
            spi_buf_in_high <= {spi_buf_in_high[6:0], spi_buf_in[7]};
        end
		`SPI_MODE_4I:
        begin
            spi_buf_in <= {spi_buf_in[3:0], psram_sio_in};
            spi_buf_in_high <= {spi_buf_in_high[3:0], spi_buf_in[7:4]};
        end
		default:
		begin
		end
		endcase
	end
end

`define WAIT_CYCLE	8'd6
`define PSRAM_CE_ON	1'b0
`define PSRAM_CE_OFF 1'b1
`define STATE_INIT	8'd0


task _SHIFT_INOUT_1;
input[7:0] next_state;
input[7:0] odata;
begin
	spi_mode <= `SPI_MODE_1;
`ifdef NANO
    case (task_x)
    8'd0:
    begin
        psram_clk_out <= 1'b1;
        task_x <= 8'd1;
    end
    8'd1:
    begin
        psram_sio_out[0] <= odata[7];
        task_x <= 8'd2;
    end
    8'd2:
    begin
        psram_sio_out[0] <= odata[6];
        task_x <= 8'd3;
    end
    8'd3:
    begin
        psram_sio_out[0] <= odata[5];
        task_x <= 8'd4;
    end
    8'd4:
    begin
        psram_sio_out[0] <= odata[4];
        task_x <= 8'd5;
    end
    8'd5:
    begin
        psram_sio_out[0] <= odata[3];
        task_x <= 8'd6;
    end
    8'd6:
    begin
        psram_sio_out[0] <= odata[2];
        task_x <= 8'd7;
    end
    8'd7:
    begin
        psram_sio_out[0] <= odata[1];
        task_x <= 8'd8;        
    end
    8'd8:
    begin
        psram_sio_out[0] <= odata[0];
        task_x <= 8'd9;
        psram_clk_out <= 1'b0;
    end
    8'd9:
    begin
        task_state <= next_state;
		task_x <= 16'd0;
    end
    endcase
`else
	if (task_x < 8'd8)
	begin
		task_x <= task_x + 1'b1;
		psram_clk_out <= 1'b1;
		psram_sio_out[0] <= odata[7 - task_x];
	end
	else
	begin				
		psram_clk_out <= 1'b0;
		//if (~psram_clk_out)
		//begin
			task_state <= next_state;
			task_x <= 16'd0;
		//end
	end
`endif
end
endtask
task _SHIFT_OUT_4_24;
input[7:0] next_state;
input[23:0] out_data;
begin
`ifdef NANO
    case (task_x)
    8'd0:
    begin
        spi_mode <= `SPI_MODE_4O;
        psram_clk_out <= 1'b1;
        task_x <= 8'd1;
    end
    8'd1:
    begin
        task_x <= 8'd2;
        psram_sio_out <= out_data[6*4-1 -: 4];
    end
    8'd2:
    begin
        task_x <= 8'd3;
        psram_sio_out <= out_data[5*4-1 -: 4];
    end
    8'd3:
    begin
        task_x <= 8'd4;
        psram_sio_out <= out_data[4*4-1 -: 4];
    end
    8'd4:
    begin
        task_x <= 8'd5;
        psram_sio_out <= out_data[3*4-1 -: 4];
    end
    8'd5:
    begin
        task_x <= 8'd6;
        psram_sio_out <= out_data[2*4-1 -: 4];
    end
    8'd6:
    begin
        task_x <= 8'd7;
        psram_sio_out <= out_data[1*4-1 -: 4];
        psram_clk_out <= 1'b0;
    end
    8'd7:task_x <= 8'd8;
    8'd8:
    begin
        task_x <= 8'd0;
		task_state <= next_state;
    end
    endcase
`else
    case (task_x)
    8'd0:
    begin
        spi_mode <= `SPI_MODE_4O;
        psram_clk_out <= 1'b1;
        task_x <= 8'd1;
        psram_sio_out <= out_data[6*4-1 -: 4];
    end
    8'd1:
    begin
        task_x <= 8'd2;
        psram_sio_out <= out_data[5*4-1 -: 4];
    end
    8'd2:
    begin
        task_x <= 8'd3;
        psram_sio_out <= out_data[4*4-1 -: 4];
    end
    8'd3:
    begin
        task_x <= 8'd4;
        psram_sio_out <= out_data[3*4-1 -: 4];
    end
    8'd4:
    begin
        task_x <= 8'd5;
        psram_sio_out <= out_data[2*4-1 -: 4];
    end
    8'd5:
    begin
        task_x <= 8'd6;
        psram_sio_out <= out_data[1*4-1 -: 4];
        
    end
    8'd6:
    begin
    	task_x <= 8'd7;
    	psram_clk_out <= 1'b0;
   	end
    8'd7:
    begin
        task_x <= 8'd0;
		task_state <= next_state;
    end
    endcase
`endif
end
endtask
task _SHIFT_OUT_4_16;
input[7:0] next_state;
input[15:0] out_data;
begin
	spi_mode <= `SPI_MODE_4O;
`ifdef NANO
	case (task_x)
	8'd0:
	begin
		task_x <= 8'd1;
		psram_clk_out <= 1'b1;			
	end
	8'd1:
	begin
		task_x <= 8'd2;
		psram_sio_out <= out_data[4*4-1 -:4];
	end
	8'd2:
	begin
		task_x <= 8'd3;
		psram_sio_out <= out_data[3*4-1 -:4];
	end
	8'd3:
	begin
		task_x <= 8'd4;
		psram_sio_out <= out_data[2*4-1 -:4];
	end
	8'd4:
	begin
		task_x <= 8'd5;
		psram_sio_out <= out_data[1*4-1 -:4];
		psram_clk_out <= 1'b0;
	end
	8'd5: task_x <= 8'd6;
	8'd6:
	begin
		task_x <= 8'd0;
		task_state <= next_state;
	end
	endcase
`else
	case (task_x)
	8'd0:
	begin
		task_x <= 8'd1;
		psram_clk_out <= 1'b1;	
		psram_sio_out <= out_data[4*4-1 -:4];		
	end
	8'd1:
	begin
		task_x <= 8'd2;
		psram_sio_out <= out_data[3*4-1 -:4];
	end
	8'd2:
	begin
		task_x <= 8'd3;
		psram_sio_out <= out_data[2*4-1 -:4];
	end
	8'd3:
	begin
		task_x <= 8'd4;
		psram_sio_out <= out_data[1*4-1 -:4];
	end
	8'd4:
	begin
		task_x <= 8'd5;
		psram_clk_out <= 1'b0;
	end
	8'd5: 
	begin
		task_x <= 8'd0;
		task_state <= next_state;
	end
	endcase
`endif
end
endtask
task _SHIFT_OUT_4;
input[7:0] next_state;
input[7:0] out_data;
begin
`ifdef NANO
	case (task_x)
	8'd0:
	begin
		spi_mode <= `SPI_MODE_4O;
		task_x <= 8'd1;
		psram_clk_out <= 1'b1;		
	end
	8'd1:
	begin
		task_x <= 8'd2;
        psram_sio_out <= out_data[7:4];
		
	end
    8'd2:
    begin
        psram_clk_out <= 1'b0;
        psram_sio_out <= out_data[3:0];
        task_x <= 8'd3;
    end
	8'd3: task_x <= 8'd4;
    8'd4:
    begin
        task_x <= 8'd0;
		task_state <= next_state;
    end
	endcase
`else
	/*spi_mode <= `SPI_MODE_4O;
	if (task_x < 8'd2)
	begin		
		psram_clk_out <= 1'b1;
		task_x <= task_x + 1'b1;
		psram_sio_out <= out_data[(8'd2 - task_x) * 4 - 1 -: 4];		
	end
	else
	begin
		psram_clk_out <= 1'b0;
		task_x <= 8'd0;
		task_state <= next_state;
	end*/
	case (task_x)
	8'd0:
	begin
		spi_mode <= `SPI_MODE_4O;
		task_x <= 8'd1;
		psram_clk_out <= 1'b1;	
		psram_sio_out <= out_data[7:4];	
	end
	8'd1:
	begin
		task_x <= 8'd2;        
        psram_sio_out <= out_data[3:0];
		
	end
    8'd2:
    begin
    	psram_clk_out <= 1'b0;
        task_x <= 8'd0;
		task_state <= next_state;
    end
	endcase
`endif
end
endtask
task _SHIFT_IN_4_16_2;
input[7:0] next_state;
begin
    case (task_x)
    8'd0:
    begin
        lcd_fifo_wrreq <= 1'b0;
        psram_clk_out <= 1'b1;
		spi_mode <= `SPI_MODE_4I;
        task_x <= 8'd1;	
    end
    8'd1: task_x <= 8'd2;
    8'd2: task_x <= 8'd3;
    8'd3: task_x <= 8'd4;
    8'd4: 
    begin
        psram_clk_out <= 1'b0;
        task_x <= 8'd5;
    end
    8'd5: task_x <= 8'd6;
    8'd6: task_x <= 8'd7;
    8'd7:
    begin
        //if ({spi_buf_in_high, spi_buf_in} == 16'hf800)
        //lcd_fifo_data <= 16'hf800;
        lcd_fifo_data <= {spi_buf_in_high, spi_buf_in};
        lcd_fifo_wrreq <= 1'b1;
        task_x <= 8'd0;
		task_state <= next_state;
    end
    endcase
end
endtask
task _SHIFT_IN_4_16;
input[7:0] next_state;
begin
`ifdef NANO
	case (task_x)
	8'd0: 
	begin
		lcd_fifo_wrreq <= 1'b0;
		psram_clk_out <= 1'b1;
		spi_mode <= `SPI_MODE_4I;
		task_x <= 8'd1;	
	end
	8'd1: task_x <= 8'd2;
	8'd2:
	begin
		psram_clk_out <= 1'b0;
		task_x <= 8'd3;
	end
	8'd3:
	begin	
		psram_clk_out <= 1'b1;		
		task_x <= 8'd4;
	end
	8'd4:
    begin
        lcd_fifo_data <= {lcd_fifo_data[7:0], spi_buf_in};
        task_x <= 8'd5;
    end
	8'd5:
	begin
		psram_clk_out <= 1'b0;
		task_x <= 8'd6;		
	end
	8'd6:task_x <= 8'd7;
    8'd7:
    begin
        lcd_fifo_data <= {lcd_fifo_data[7:0], spi_buf_in};
		lcd_fifo_wrreq <= 1'b1;
		task_x <= 8'd0;
		task_state <= next_state;
    end
	endcase	
`else
    case (task_x)
	8'd0: 
	begin
		lcd_fifo_wrreq <= 1'b0;
		psram_clk_out <= 1'b1;
		spi_mode <= `SPI_MODE_4I;
		task_x <= 8'd1;	
	end
	8'd1: task_x <= 8'd2;
	8'd2:
	begin
		psram_clk_out <= 1'b0;
		task_x <= 8'd3;
	end
	8'd3:
	begin	
		psram_clk_out <= 1'b1;
		lcd_fifo_data <= {lcd_fifo_data[7:0], spi_buf_in};
		task_x <= 8'd4;
	end
	8'd4: task_x <= 8'd5;
	8'd5:
	begin
		psram_clk_out <= 1'b0;
		task_x <= 8'd6;		
	end
	8'd6:
	begin
		lcd_fifo_data <= {lcd_fifo_data[7:0], spi_buf_in};
		lcd_fifo_wrreq <= 1'b1;
		task_x <= 8'd0;
		task_state <= next_state;
	end
	endcase	
`endif
end
endtask


task _PSRAM_CS;
input[7:0] next_state;
input[7:0] delay;
input cs_n;
begin
	psram_ce_n <= cs_n;	
	if (task_x < delay) task_x <= task_x + 1'b1;
	else 
	begin
		task_state <= next_state;
		task_x <= 8'd0;
	end
end
endtask
task PSRAM_RESET;
begin
	case (task_state)
	8'd0:
	begin		
		psram_clk_out <= 1'b0;	
		if (tick_cnt < 16'd20000)
		begin
			psram_ce_n <= 1'b1;
			tick_cnt <= tick_cnt + 1'b1;
		end
		else
		begin
			tick_cnt <= 16'd0;
			task_x <= 8'd0;
			task_state <= 8'd1;
			psram_ce_n <= 1'b0;
		end
	end
	8'd1: _SHIFT_INOUT_1(8'd2, 8'h66);
	8'd2: _PSRAM_CS(8'd3, 8'd0, `PSRAM_CE_OFF);
	8'd3: _PSRAM_CS(8'd4, 8'd0, `PSRAM_CE_ON);
	8'd4: _SHIFT_INOUT_1(8'd5, 8'h99);
	8'd5: _PSRAM_CS(8'd6, 8'd10, `PSRAM_CE_OFF);
	8'd6: _PSRAM_CS(8'd7, 8'd0, `PSRAM_CE_ON);
	8'd7: _SHIFT_INOUT_1(8'd8, 8'h9f);
	8'd8: _SHIFT_INOUT_1(8'd9, 8'hff);
	8'd9: _SHIFT_INOUT_1(8'd10, 8'hff);
	8'd10: _SHIFT_INOUT_1(8'd11, 8'hff);
	8'd11: _SHIFT_INOUT_1(8'd12, 8'hff);
	8'd12: 
	begin
		psram_eid[15:8] <= spi_buf_in;
		task_state <= 8'd13;
	end
	8'd13:_SHIFT_INOUT_1(8'd14, 8'hff);
	8'd14:
	begin
		psram_eid[7:0] <= spi_buf_in;
		task_state <= 8'd15;
	end
	8'd15:_PSRAM_CS(8'hff, 8'd0, `PSRAM_CE_OFF);
	8'hff:
	begin
	end
	endcase
end
endtask

task _PSRAM_WAIT;
input[7:0] next_state;
input[7:0] cycle;
begin
	spi_mode <= `SPI_MODE_WAIT;
	if (task_x < cycle)
	begin
		psram_clk_out <= 1'b1;
		task_x <= task_x + 1'b1;
	end
	else
	begin
		psram_clk_out <= 1'b0;
        if (~psram_clk_out)
        begin
            task_x <= 8'd0;
            task_state <= next_state;
        end
	end
end
endtask
task PSRAM_WRITE;
input[23:0] addr;
input[15:0] data;
begin
	case (task_state)
	8'd0: _PSRAM_CS(8'd1, 8'd0, `PSRAM_CE_ON);
	8'd1: _SHIFT_INOUT_1(8'd2, 8'h38);
    8'd2: _SHIFT_OUT_4_24(8'd5, addr);
	/*8'd2: _SHIFT_OUT_4(8'd3, addr[3*8-1 -:8]);
	8'd3: _SHIFT_OUT_4(8'd4, addr[2*8-1 -:8]);
	8'd4: _SHIFT_OUT_4(8'd5, addr[8-1 -:8]);*/
	8'd5: _SHIFT_OUT_4_16(8'd6, data);
	8'd6: _SHIFT_OUT_4_16(8'd7, data);
	8'd7: _SHIFT_OUT_4_16(8'd8, data);
	8'd8: _SHIFT_OUT_4_16(8'd9, data);
	8'd9: _SHIFT_OUT_4_16(8'd10, data);
	8'd10: _SHIFT_OUT_4_16(8'd11, data);
	8'd11: _SHIFT_OUT_4_16(8'd12, data);
	8'd12: _SHIFT_OUT_4_16(8'd13, data);
	8'd13: _SHIFT_OUT_4_16(8'd14, data);
	8'd14: _SHIFT_OUT_4_16(8'd15, data);
	8'd15: _SHIFT_OUT_4_16(8'd16, data);
	8'd16: _SHIFT_OUT_4_16(8'd17, data);
	8'd17: _SHIFT_OUT_4_16(8'd18, data);
	8'd18: _SHIFT_OUT_4_16(8'd19, data);
	8'd19: _SHIFT_OUT_4_16(8'd20, data);
	8'd20: _SHIFT_OUT_4_16(8'd37, data);
	/*8'd21: _SHIFT_OUT_4(8'd22, data[15:8]);
	8'd22: _SHIFT_OUT_4(8'd23, data[7:0]);
	8'd23: _SHIFT_OUT_4(8'd24, data[15:8]);
	8'd24: _SHIFT_OUT_4(8'd25, data[7:0]);
	8'd25: _SHIFT_OUT_4(8'd26, data[15:8]);
	8'd26: _SHIFT_OUT_4(8'd27, data[7:0]);
	8'd27: _SHIFT_OUT_4(8'd28, data[15:8]);
	8'd28: _SHIFT_OUT_4(8'd29, data[7:0]);
	8'd29: _SHIFT_OUT_4(8'd30, data[15:8]);
	8'd30: _SHIFT_OUT_4(8'd31, data[7:0]);
	8'd31: _SHIFT_OUT_4(8'd32, data[15:8]);
	8'd32: _SHIFT_OUT_4(8'd33, data[7:0]);
	8'd33: _SHIFT_OUT_4(8'd34, data[15:8]);
	8'd34: _SHIFT_OUT_4(8'd35, data[7:0]);
	8'd35: _SHIFT_OUT_4(8'd36, data[15:8]);
	8'd36: _SHIFT_OUT_4(8'd37, data[7:0]);*/
	8'd37: _PSRAM_CS(8'hff, 8'd16, `PSRAM_CE_OFF);
	8'hff:
	begin
	end
	endcase
end
endtask
task PSRAM_READ;
input[23:0] addr;
begin
	case (task_state)
	8'd0: _PSRAM_CS(8'd1, 8'd0, `PSRAM_CE_ON);
	8'd1: _SHIFT_INOUT_1(8'd2, 8'hEB);
    8'd2: _SHIFT_OUT_4_24(8'd5, addr);
	/*8'd2: _SHIFT_OUT_4(8'd3, addr[3*8-1 -:8]);
	8'd3: _SHIFT_OUT_4(8'd4, addr[2*8-1 -:8]);
	8'd4: _SHIFT_OUT_4(8'd5, addr[8-1 -:8]);*/
	8'd5: _PSRAM_WAIT(8'd6, `WAIT_CYCLE);
	8'd6: _SHIFT_IN_4_16_2(8'd7);
	8'd7: _SHIFT_IN_4_16_2(8'd8);
	8'd8: _SHIFT_IN_4_16_2(8'd9);
	8'd9: _SHIFT_IN_4_16_2(8'd10);
	8'd10: _SHIFT_IN_4_16_2(8'd11);
	8'd11: _SHIFT_IN_4_16_2(8'd12);
	8'd12: _SHIFT_IN_4_16_2(8'd13);
	8'd13: _SHIFT_IN_4_16_2(8'd14);
	8'd14: _SHIFT_IN_4_16_2(8'd15);
	8'd15: _SHIFT_IN_4_16_2(8'd16);
	8'd16: _SHIFT_IN_4_16_2(8'd17);
	8'd17: _SHIFT_IN_4_16_2(8'd18);
	8'd18: _SHIFT_IN_4_16_2(8'd19);
	8'd19: _SHIFT_IN_4_16_2(8'd20);
	8'd20: _SHIFT_IN_4_16_2(8'd21);
	8'd21: _SHIFT_IN_4_16_2(8'd22);	
	8'd22: 
	begin
		lcd_fifo_wrreq <= 1'b0;
		_PSRAM_CS(8'hff, 8'd6, `PSRAM_CE_OFF);
	end
	8'hff:
	begin		
	end
	endcase
end
endtask
reg[23:0] px_cnt;
wire[23:0] waddr = ((px_cnt - 8'd1) << 1'b1);
always @(negedge clk or posedge reset)
begin
	if (reset)
	begin
		lcd_fifo_wrreq <= 1'b0;
		lcd_fifo_data <= 16'hffff;
		psram_clk_out <= 1'b0;
		psram_ctrl <= 1'b0;
		psram_ce_n <= 1'b1;
		psram_sio_out <= 4'h0;
		psram_eid <= 16'hffff;
		task_state <= 8'd0;
		task_x <= 8'd0;
		tick_cnt <= 16'd0;
		state <= `STATE_INIT;
		px_cnt <= 24'd0;
	end
	else
	begin
	
		case (state)
		`STATE_INIT:
		begin
			psram_ctrl <= 1'b1;
			PSRAM_RESET();
			if (task_state == 8'hff)
			begin
				task_state <= 8'd0;
				task_x <= 8'd0;
				state <= 8'd1;
			end
		end
		8'd1:
		begin
			if (px_cnt < SCREEN_SIZE)
			begin
				px_cnt <= px_cnt +8'd1;
				state <= 8'd2;
			end
			else 
			begin
				px_cnt <= 24'd0;
				state <= 8'd3;
			end
			
		end
		8'd2:
		begin
			PSRAM_WRITE(24'd0, 16'h5050);
			if (task_state == 8'hff)
			begin
				task_state <= 8'd0;
				task_x <= 8'd0;
				state <= 8'd3;
			end
		end
		8'd3:
		begin
			if (~lcd_fifo_afull_flag)
			begin
				task_state <= 8'd0;
				task_x <= 8'd0;
				state <= 8'd4;
			end
		end
		8'd4:
		begin
			PSRAM_READ(24'd0);
			if (task_state == 8'hff)
			begin
				task_state <= 8'd0;
				task_x <= 8'd0;
				state <= 8'd3;
			end
		end
		endcase
	end
end
endmodule
