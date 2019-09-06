module PSRAM64(input clk, 
					input reset,
					output reg PSRAM_CEn,
					output PSRAM_CLK,
					output reg[3:0] PSRAM_SIO_OUT,
					input[3:0] PSRAM_SIO_IN,
					output reg PSRAM_CMD_DIR,
					output reg PSRAM_SIO_DIR,
					
					input rdfifo_rdclk,
					input rdfifo_rdreq,
					output[16:0] rdfifo_q,
					output rdfifo_rdempty
					);
assign PSRAM_CLK = clk;
reg[15:0] rdfifo_data;
reg rdfifo_wrreq;
wire rdfifo_wrfull;
wire[9:0] rdfifo_wrusedw;
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
		PSRAM_CEn <= 1'b0;
		PSRAM_SIO_OUT[0] <= task_data[7];
		task_data <= {task_data[6:0], 1'b1};
	end
	else
	begin
		task_x <= 16'd0;
		PSRAM_CEn <= 1'b1;
		task_state <= next_state;
		task_data <= next_data;
	end
end
endtask


task PSRAM_RESET;
begin
	case (task_state)
	8'd0:
	begin
		PSRAM_CEn <= 1'b1;
		PSRAM_SIO_DIR <= 1'b0;
		PSRAM_CMD_DIR <= 1'b0;			
		if (task_x < 16'd20000) task_x <= task_x + 1'b1;
		else
		begin 
			task_state <= 8'd1;
			task_x <= 16'd0;
			task_data <= 8'h66;	
		end
	end
	8'd1: task_state <= 8'd2;
	8'd2: task_state <= 8'd3;
	8'd3:	task_state <= 8'd4;
	8'd4:	_SHIFT_OUT_1(8'd5, 8'h99);	// enable reset
	8'd5:	_SHIFT_OUT_1(8'd6, 8'h35);	// reset
	8'd6:	_SHIFT_OUT_1(8'd7, 8'hff);	// 4bit
	8'd7:	_SHIFT_OUT_4(8'd8, 4'hC);// wrap mode
	8'd8: _SHIFT_OUT_4(8'd9, 4'h0);
	8'd9:
	begin
		PSRAM_CEn <= 1'b1;
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

task _SHIFT_OUT_4;
input[7:0] next_state;
input[3:0] shift_data;
begin
	PSRAM_CEn <= 1'b0;
	PSRAM_CMD_DIR <= 1'b1;
	PSRAM_SIO_DIR <= 1'b1;
	PSRAM_SIO_OUT <= shift_data;
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
integer i;
`define WAIT_CYCLE	8'd6
task PSRAM_RDFIFO_FILL;
input[23:0] addr;
begin
	case (task_state)
	8'd0:
	begin
		rdfifo_wrreq <= 1'b0;
		rdfifo_data <= {{1'b1}};
		task_data <= 8'hEB;
		task_x <= 16'd0;
		task_state <= 8'd1;
	end
	8'd1:
	begin		
		if (task_x < 8'd8)
		begin
			PSRAM_CMD_DIR <= 1'b1;
			PSRAM_SIO_DIR <= 1'b0;
			task_x <= task_x + 1'b1;
			PSRAM_SIO_OUT[0] <= task_data[7];
			task_data <= {task_data[6:0], 1'b1};
		end
		else _SHIFT_OUT_4(8'd2, addr[6*4-1-:4]);
	end
	8'd2: _SHIFT_OUT_4(8'd3, addr[5*4-1-:4]);
	8'd3: _SHIFT_OUT_4(8'd4, addr[4*4-1-:4]);
	8'd4: _SHIFT_OUT_4(8'd5, addr[3*4-1-:4]);
	8'd5: _SHIFT_OUT_4(8'd6, addr[2*4-1-:4]);
	8'd6:
	begin
		_SHIFT_OUT_4(8'd7, addr[1*4-1-:4]);
		task_x <= 16'd0;
	end
	8'd7:
	begin
		PSRAM_CMD_DIR <= 1'b0;
		PSRAM_SIO_DIR <= 1'b0;
		if (task_x < `WAIT_CYCLE) task_x <= task_x+1'b1;
		else
		begin
			task_x <= 16'd0;
			task_state <= 8'd8;
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
			PSRAM_CEn <= 1'b1;
			rdfifo_wrreq <= 1'b1;
			state <= 8'hff;
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

`define STATE_INIT	8'd0
`define STATE_TSK_SELECT	8'd1
`define STATE_TSK_RDFIFO	8'd2
reg[7:0] state;
reg [21:0] psram_addr;
always @(posedge clk or posedge reset)
begin
	if (reset)
	begin
		state <= `STATE_INIT;
		PSRAM_CEn <= 1'b1;
		PSRAM_SIO_OUT <= 4'hf;
		PSRAM_SIO_DIR <= 1'b0;
		PSRAM_CMD_DIR <= 1'b0;
		rdfifo_wrreq <= 1'b0;
		rdfifo_data <= {16{1'b1}};
		psram_addr <= 21'd0;
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
			TASK_RESET();
			if (~rdfifo_wrfull) state <= `STATE_TSK_RDFIFO;
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
		endcase
	end
end
endmodule
