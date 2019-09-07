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
					output[16:0] rdfifo_q,
					output rdfifo_rdempty
					);
reg psram_ctrl;
reg[3:0] psram_sio_out;
reg psram_cs_n;
wire gated_clk;
GATED_CLK psram_gated(.clkin(clk),
							.clkout(gated_clk),
							.clken(~psram_cs_n));
assign PSRAM_CEn = psram_ctrl ? psram_cs_n : MCU_CS;
assign PSRAM_CLK = psram_ctrl ? gated_clk : MCU_SCLK;
assign PSRAM_SIO_OUT = psram_ctrl ? psram_sio_out : {3'b111, MCU_MOSI};

reg[15:0] rdfifo_data;
reg rdfifo_wrreq;
wire rdfifo_wrfull;
wire[9:0] rdfifo_wrusedw;
`define RDFIFO_LEN	16'd512
PSRAM_RDFIFO rdfifo(.aclr(reset),
							.data({2'b00, rdfifo_data}),
							.rdclk(rdfifo_rdclk),
							.rdreq(rdfifo_rdreq),
							.wrclk(clk),
							.wrreq(rdfifo_wrreq),
							.q(rdfifo_q),
							.rdempty(rdfifo_rdempty),
							.wrfull(rdfifo_wrfull),
							.wrusedw(rdfifo_wrusedw));
reg[7:0] task_state;
reg[15:0] task_x;
reg[7:0] task_data;
`define WAIT_CYCLE	8'd6
task TASK_RESET;
begin
	task_state <= 8'd0;
	task_x <= 16'd0;
	rdfifo_wrreq <= 1'b0;
	rdfifo_data <= {16{1'b1}};
end
endtask

task _SHIFT_OUT_1;
input[7:0] next_state;
input[7:0] next_data;
begin
	PSRAM_SIO_DIR <= 1'b0;
	PSRAM_CMD_DIR <= 1'b1;
	if (task_x < 8'd8)
	begin
		task_x <= task_x + 1'b1;
		psram_cs_n <= 1'b0;
		psram_sio_out[0] <= task_data[7];
		task_data <= {task_data[6:0], 1'b1};
	end
	else
	begin
		task_x <= 16'd0;
		psram_cs_n <= 1'b1;
		task_state <= next_state;
		task_data <= next_data;
	end
end
endtask

task _SHIFT_OUT_4;
input[7:0] next_state;
input[3:0] shift_data;
begin
	psram_cs_n <= 1'b0;
	PSRAM_CMD_DIR <= 1'b1;
	PSRAM_SIO_DIR <= 1'b1;
	psram_sio_out <= shift_data;
	task_state <= next_state;	
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

task PSRAM_RESET;
begin
	case (task_state)
	8'd0:
	begin
		psram_cs_n <= 1'b1;
		PSRAM_SIO_DIR <= 1'b0;
		PSRAM_CMD_DIR <= 1'b0;	
		task_data <= 8'hff;
		if (task_x < 16'd20000) task_x <= task_x + 1'b1;
		else
		begin 
			task_state <= 8'd1;
			task_x <= 16'd0;
			task_data <= 8'h66;	
		end
	end
	8'd1: _SHIFT_OUT_4(8'd2, 4'h6);
	8'd2: _SHIFT_OUT_4(8'd3, 4'h6);
	8'd3: _SHIFT_OUT_4(8'd4, 4'h9);
	8'd4: _SHIFT_OUT_4(8'd5, 4'h9);
	8'd5:
	begin
		psram_cs_n <= 1'b1;
		PSRAM_SIO_DIR <= 1'b0;
		PSRAM_CMD_DIR <= 1'b1;	
		if (task_x <= `WAIT_CYCLE) task_x <= task_x + 1'b1;
		else
		begin
			task_x <= 16'd0;
			task_data <= 8'h66;	
			task_state <= 8'd6;
		end
	end
	8'd6:	_SHIFT_OUT_1(8'd7, 8'h99);	// enable reset
	8'd7:	_SHIFT_OUT_1(8'd8, 8'h35);	// reset
	8'd8:	_SHIFT_OUT_1(8'd9, 8'hff);	// 4bit
	8'd9:
	begin
		psram_cs_n <= 1'b1;
		PSRAM_SIO_DIR <= 1'b0;
		PSRAM_CMD_DIR <= 1'b0;	
		if (task_x <= `WAIT_CYCLE) task_x <= task_x + 1'b1;
		else
		begin
			task_x <= 16'd0;
			task_state <= 8'd10;
		end
	end
	8'd10: _SHIFT_OUT_4(8'd11, 4'hC);// wrap mode
	8'd11: _SHIFT_OUT_4(8'd12, 4'h0);
	8'd12:
	begin
		psram_cs_n <= 1'b1;
		PSRAM_CMD_DIR <= 1'b0;
		PSRAM_SIO_DIR <= 1'b0;
		task_state <= 8'hff;
	end
	8'hff:
	begin
	end
	endcase
end
endtask


integer i;

task PSRAM_RDFIFO_FILL;
input[23:0] addr;
begin
	case (task_state)
	8'd0:
	begin
		rdfifo_wrreq <= 1'b0;
		rdfifo_data <= {{1'b1}};
		task_x <= 16'd0;
		_SHIFT_OUT_4(8'd1, 4'hE);
	end
	8'd1: _SHIFT_OUT_4(8'd2, 8'hB);
	8'd2: _SHIFT_OUT_4(8'd3, addr[6*4-1-:4]);
	8'd3: _SHIFT_OUT_4(8'd4, addr[5*4-1-:4]);
	8'd4: _SHIFT_OUT_4(8'd5, addr[4*4-1-:4]);
	8'd5: _SHIFT_OUT_4(8'd6, addr[3*4-1-:4]);
	8'd6: _SHIFT_OUT_4(8'd7, addr[2*4-1-:4]);
	8'd7: _SHIFT_OUT_4(8'd8, addr[1*4-1-:4]);
	8'd8:
	begin
		PSRAM_CMD_DIR <= 1'b0;
		PSRAM_SIO_DIR <= 1'b0;
		if (task_x < `WAIT_CYCLE) task_x <= task_x+1'b1;
		else
		begin
			task_x <= 16'd0;
			task_state <= 8'd9;
		end
	end
	8'd9:
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
			psram_cs_n <= 1'b1;
			rdfifo_wrreq <= 1'b1;
			task_state <= 8'hff;
		end
	end
	/*8'd7: _SHIFT_IN_4(8'd8, 1'b0);
	8'd8: _SHIFT_IN_4(8'd9, 1'b0);
	8'd9: _SHIFT_IN_4(8'd10, 1'b0);
	8'd10: _SHIFT_IN_4(8'd11, 1'b1);
	8'd11: _SHIFT_IN_4(8'd12, 1'b0);
	8'd12: _SHIFT_IN_4(8'd13, 1'b0);
	8'd13: _SHIFT_IN_4(8'd14, 1'b0);
	8'd15: _SHIFT_IN_4(8'd15, 1'b1);*/
	8'hff:
	begin
		rdfifo_wrreq <= 1'b0;
	end
	endcase
end
endtask

task PSRAM_EN_4BIT;
begin
	case (task_state)
	8'd0:
	begin
		task_x <= 16'd0;
	end
	endcase
end
endtask

`define STATE_INIT	8'd0
`define STATE_TSK_SELECT	8'd1
`define STATE_TSK_RDFIFO	8'd2
`define STATE_TSK_WAIT_MCU	8'd3
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
					psram_cs_n <= 1'b0;
					MCU_ACK <= 1'b0;
					state <= `STATE_TSK_WAIT_MCU;
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
		`STATE_TSK_WAIT_MCU:
		begin
			if (syn_mcu_req)
			begin
				psram_cs_n <= 1'b1;
				MCU_ACK <= 1'b1;
				state <= `STATE_TSK_SELECT;
			end
		end
		endcase
	end
end
endmodule
