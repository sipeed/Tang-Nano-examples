/*
 * analysis.cpp
 *
 *  Created on: 2019年9月7日
 *      Author: athieka@hotmail.com
 */
module PSRAM64(input clk, 
					input reset,
					output PSRAM_CEn,
					output PSRAM_CLK,
					output [3:0] PSRAM_SIO_OUT,
					input[3:0] PSRAM_SIO_IN,
					output reg PSRAM_CMD_DIR,
					output reg PSRAM_SIO_DIR,
					
					input MCU_SCLK,
					input MCU_CS,
					input MCU_MOSI,
					input MCU_REQ,
					output reg MCU_ACK,
					
					input rdfifo_rdclk,
					input rdfifo_rdreq,
					output[18:0] rdfifo_q,
					output rdfifo_rdempty
					);
reg psram_ctrl;
reg psram_ctrl_buf;
always @(negedge clk)
begin
	psram_ctrl_buf <= psram_ctrl;
end
reg[3:0] psram_sio_out;
reg psram_cs_n;
reg en_clk_out;
wire gated_clk;
GATED_CLK psram_gated(.clkin(clk),
							.clkout(gated_clk),
							.clken(en_clk_out));

assign PSRAM_CEn = psram_ctrl ? psram_cs_n : MCU_CS;
assign PSRAM_CLK = psram_ctrl_buf ? gated_clk : MCU_SCLK;
assign PSRAM_SIO_OUT = psram_ctrl ? psram_sio_out : {3'b111, MCU_MOSI};

reg[15:0] rdfifo_data;
reg rdfifo_wrreq;
wire rdfifo_wrfull;
wire[9:0] rdfifo_wrusedw;
`define RDFIFO_LEN	16'd512
PSRAM_RDFIFO rdfifo(.WrReset(reset),
                    .RdReset(reset),
							.Data({3'b00, rdfifo_data}),
							.RdClk(rdfifo_rdclk),
							.RdEn(rdfifo_rdreq),
							.WrClk(clk),
							.WrEn(rdfifo_wrreq),
							.Q(rdfifo_q),
							.Empty(rdfifo_rdempty),
							.Full(rdfifo_wrfull),
							.Wnum(rdfifo_wrusedw));
reg[7:0] task_state;
reg[7:0] task_x;
`define WAIT_CYCLE	8'd6
task TASK_RESET;
begin
	task_state <= 8'd0;
	task_x <= 16'd0;
	en_clk_out <= 1'b0;
	rdfifo_wrreq <= 1'b0;
	rdfifo_data <= {16{1'b1}};
end
endtask

task _SHIFT_OUT_1;
input[7:0] next_state;
input[7:0] shift_data;
begin
	PSRAM_SIO_DIR <= 1'b0;
	PSRAM_CMD_DIR <= 1'b1;
	en_clk_out <= 1'b1;
	if (task_x < 8'd8)
	begin
		task_x <= task_x + 1'b1;
		psram_sio_out[0] <= shift_data[8'd7-task_x];
	end
	else
	begin
		task_x <= 16'd0;
		en_clk_out <= 1'b0;
		task_state <= next_state;
	end
end
endtask

task _SHIFT_OUT_4;
input[7:0] next_state;
input[3:0] shift_data;
begin
	en_clk_out <= 1'b1;
	PSRAM_CMD_DIR <= 1'b1;
	PSRAM_SIO_DIR <= 1'b1;
	psram_sio_out <= shift_data;
	task_state <= next_state;
	task_x <= 16'd0;
end
endtask

task _SHIFT_IN_4;
input fifo_wr;
begin
	PSRAM_CMD_DIR <= 1'b0;
	PSRAM_SIO_DIR <= 1'b0;
	rdfifo_data <= {rdfifo_data[15:4], PSRAM_SIO_IN};
	rdfifo_wrreq <= fifo_wr;
end
endtask

task _PSRAM_CS_DELAY;
input[7:0] next_state;
input[7:0] delay;
begin
	if (task_x < delay)
	begin
		if (~psram_cs_n) en_clk_out <= 1'b0;
		task_x <= task_x + 1'b1;
	end
	else
	begin
		task_x <= 16'd0;
		task_state <= next_state;
		psram_cs_n <= ~psram_cs_n;
	end
end
endtask
reg[15:0] cnt;
task PSRAM_RESET;
begin
	case (task_state)
	8'd0:
	begin
		psram_cs_n <= 1'b1;
		en_clk_out <= 1'b0;
		PSRAM_SIO_DIR <= 1'b0;
		PSRAM_CMD_DIR <= 1'b0;	
		if (cnt < 16'd20000) cnt <= cnt + 1'b1;
		else
		begin 
			cnt <= 16'd0;
			psram_cs_n <= 1'b0;
			task_state <= 8'd1;
			task_x <= 16'd0;			
		end
	end
	8'd1: _SHIFT_OUT_4(8'd2, 4'h6);
	8'd2: _SHIFT_OUT_4(8'd3, 4'h6);
	8'd3: _PSRAM_CS_DELAY(8'd4, 8'd3); // cs off
	8'd4: _PSRAM_CS_DELAY(8'd5, 8'd5);	// cs on
	8'd5: _SHIFT_OUT_4(8'd6, 4'h9);
	8'd6: _SHIFT_OUT_4(8'd7, 4'h9);
	8'd7: _PSRAM_CS_DELAY(8'd8, 8'd3);	// cs off
	8'd8: _PSRAM_CS_DELAY(8'd9, 8'd6);	// cs on
	8'd9: _SHIFT_OUT_1(8'd10, 8'h66);
	8'd10: _SHIFT_OUT_1(8'd11, 8'h99);	// enable reset
	8'd11: _PSRAM_CS_DELAY(8'd12, 8'd3);
	8'd12: _PSRAM_CS_DELAY(8'd13, 8'd5);
	8'd13: _SHIFT_OUT_1(8'd14, 8'h35);	// 4bit
	8'd14: _PSRAM_CS_DELAY(8'd15, 8'd3); // cs off
	8'd15: _PSRAM_CS_DELAY(8'd16, 8'd5); // cs on
	8'd16: _SHIFT_OUT_4(8'd17, 4'hC);// wrap mode
	8'd17: _SHIFT_OUT_4(8'd18, 4'h0);
	8'd18: _PSRAM_CS_DELAY(8'hff, 8'd3); // cs off
	8'hff:
	begin
		PSRAM_CMD_DIR <= 1'b0;
		PSRAM_SIO_DIR <= 1'b0;
	end
	endcase
end
endtask

task PSRAM_DELAY;
input[7:0] next_state;
input[7:0] delay;
begin
	PSRAM_CMD_DIR <= 1'b0;
	PSRAM_SIO_DIR <= 1'b0;
	psram_sio_out <= 4'hf;
	if (task_x < delay) task_x <= task_x + 1'b1;
	else
	begin
		task_x <= 16'd0;
		task_state <= next_state;
	end
end
endtask

integer i;

task PSRAM_RDFIFO_FILL;
input[23:0] addr;
begin
	case (task_state)
	8'd0:
	begin
		psram_cs_n <= 1'b0;
		rdfifo_wrreq <= 1'b0;
		rdfifo_data <= {{1'b1}};
		task_x <= 16'd0;
		task_state <= 8'd1;
	end
	8'd1: _SHIFT_OUT_4(8'd2, 4'hE);
	8'd2: _SHIFT_OUT_4(8'd3, 8'hB);
	8'd3: _SHIFT_OUT_4(8'd4, addr[6*4-1-:4]);
	8'd4: _SHIFT_OUT_4(8'd5, addr[5*4-1-:4]);
	8'd5: _SHIFT_OUT_4(8'd6, addr[4*4-1-:4]);
	8'd6: _SHIFT_OUT_4(8'd7, addr[3*4-1-:4]);
	8'd7: _SHIFT_OUT_4(8'd8, addr[2*4-1-:4]);
	8'd8: _SHIFT_OUT_4(8'd9, addr[1*4-1-:4]);
	8'd9: PSRAM_DELAY(8'd10, `WAIT_CYCLE);
	8'd10:
	begin
		if (task_x < 8'd64)
		begin
			task_x <= task_x + 1'b1;
			for (i=0; i<64; i=i+1)
			begin
				if (task_x == i)
				begin
					if (i == 0) _SHIFT_IN_4(1'b0);
					else _SHIFT_IN_4(i % 4 == 0 ? 1'b1 : 1'b0);
				end
			end
		end
		else
		begin
			task_x <= 16'd0;
			en_clk_out <= 1'b0;			
			rdfifo_wrreq <= 1'b1;
			task_state <= 8'd11;
		end
	end
	8'd11: 
	begin
		rdfifo_wrreq <= 1'b0;
		_PSRAM_CS_DELAY(8'hff, 8'd3); // cs off
	end
	8'hff:
	begin
	end
	endcase
end
endtask

task PSRAM_DIS_4BIT;
begin
	case (task_state)
	8'd0:
	begin
		psram_cs_n <= 1'b0;
		task_x <= 16'd0;
		task_state <= 8'd1;
	end
	8'd1: _SHIFT_OUT_4(8'd2, 4'hF);
	8'd2: _SHIFT_OUT_4(8'd3, 4'h5);
	8'd3: _PSRAM_CS_DELAY(8'hff, 8'd3);	// cs off
	8'hff:
	begin
	end
	endcase
end
endtask

task PSRAM_EN_4BIT;
begin
	case (task_state)
	8'd0:
	begin
		psram_cs_n <= 1'b0;
		task_x <= 16'd0;
		task_state <= 8'd1;
	end
	8'd1: _SHIFT_OUT_1(8'd1, 8'h35);
	8'd2: _PSRAM_CS_DELAY(8'hff, 8'd3);	// cs off
	8'hff:
	begin
	end
	endcase
end
endtask

`define STATE_INIT	8'd0
`define STATE_TSK_SELECT	8'd1
`define STATE_TSK_RDFIFO	8'd2
`define STATE_TSK_BEGIN_MCU 8'd3
`define STATE_TSK_WAIT_MCU	8'd4
`define STATE_TSK_END_MCU 8'd5
reg[7:0] state;
reg [21:0] psram_addr;
wire syn_mcu_req;
SYNC_SIGNAL syn_mcu(.clk(clk),
							.reset(reset),
							.signal(MCU_REQ),
							.syn_signal(syn_mcu_req));

always @(posedge clk or posedge reset)
begin
	if (reset)
	begin
		state <= `STATE_INIT;
		cnt <= 16'd0;
		psram_ctrl <= 1'b1;	
		psram_cs_n <= 1'b1;
		psram_sio_out <= 4'hf;		
		PSRAM_SIO_DIR <= 1'b0;
		PSRAM_CMD_DIR <= 1'b0;
		rdfifo_wrreq <= 1'b0;
		rdfifo_data <= {16{1'b1}};
		psram_addr <= 21'd0;
		MCU_ACK <= 1'b1;
		TASK_RESET();
	end
	else
	begin
		case(state)
		`STATE_INIT:
		begin
			PSRAM_RESET();
			if (task_state == 8'hff)
			begin
				TASK_RESET();
				state <= `STATE_TSK_SELECT;
			end
		end
		`STATE_TSK_SELECT:
		begin
			psram_ctrl <= 1'b1;
			PSRAM_SIO_DIR <= 1'b0;
			PSRAM_CMD_DIR <= 1'b0;
			psram_cs_n <= 1'b1;
			MCU_ACK <= 1'b1;
			TASK_RESET();
			if (syn_mcu_req)
			begin
				if ((`RDFIFO_LEN - rdfifo_wrusedw >= 8'd32) && (~rdfifo_wrfull)) state <= `STATE_TSK_RDFIFO;
			end
			else
			begin
				 if ((`RDFIFO_LEN - rdfifo_wrusedw >= 8'd32) && (~rdfifo_wrfull)) state <= `STATE_TSK_RDFIFO;
				 else
				 begin
					MCU_ACK <= 1'b0;
					state <= `STATE_TSK_BEGIN_MCU;
				 end
			end
		end
		`STATE_TSK_RDFIFO:
		begin
			PSRAM_RDFIFO_FILL({2'b00, psram_addr});
			if (task_state == 8'hff)
			begin
				TASK_RESET();
				psram_addr <= psram_addr + 8'd32;
				state <= `STATE_TSK_SELECT;
			end
		end
		`STATE_TSK_BEGIN_MCU:
		begin
			PSRAM_DIS_4BIT();
			if (task_state == 8'hff)
			begin
				TASK_RESET();
				PSRAM_SIO_DIR <= 1'b0;
				PSRAM_CMD_DIR <= 1'b1;
				state <= `STATE_TSK_WAIT_MCU;
			end
		end
		`STATE_TSK_WAIT_MCU:
		begin
			if (syn_mcu_req)
			begin
				psram_cs_n <= 1'b1;
				MCU_ACK <= 1'b1;
				state <= `STATE_TSK_END_MCU;
			end
		end
		`STATE_TSK_END_MCU:
		begin
			PSRAM_EN_4BIT();
			if (task_state == 8'hff)
			begin
				TASK_RESET();
				PSRAM_SIO_DIR <= 1'b0;
				PSRAM_CMD_DIR <= 1'b0;
				state <= `STATE_TSK_SELECT;
			end
		end
		endcase
	end
end
endmodule
