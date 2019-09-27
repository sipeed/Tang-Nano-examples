module PSRAM(input clk,
			input reset,
			output reg PSRAM_CEn,
			output PSRAM_SCLK,//synthesis keep
			output reg PSRAM_SI,
			input PSRAM_SO //synthesis keep
			);

reg en_clk_out;//synthesis keep
GATED_CLK psram_gated(.clkin(clk),
							.clkout(PSRAM_SCLK),
							.clken(en_clk_out));
reg[7:0] sbuf;//synthesis keep
reg[15:0] eid;//synthesis keep
reg[7:0] state;//synthesis keep
reg[15:0] task_x;//synthesis keep
wire psram_si = PSRAM_SI;//synthesis keep
integer i;
always @(negedge clk or posedge reset)
begin
	if (reset)
	begin
		state <= 8'd0;
		eid <= 16'hffff;
		PSRAM_CEn <= 1'b1;
		PSRAM_SI <= 1'b0;
		en_clk_out <= 1'b0;
		task_x <= 16'd0;
		sbuf <= 8'hff;
	end
	else
	begin
		case (state)
		8'd0:
		begin
			if (task_x < 16'd20000) task_x <= task_x + 1'b1;
			else
			begin
				task_x <= 16'd0;
				state <= 8'd1;
				PSRAM_CEn <= 1'b0;
				sbuf <= 8'h66;
			end
		end
		8'd1:
		begin
			if (task_x < 8'd8)
			begin				
				en_clk_out <= 1'b1;
				task_x <= task_x + 1'b1;
				PSRAM_SI <= sbuf[7];
				sbuf <= {sbuf[6:0], PSRAM_SO};
			end
			else
			begin
				sbuf <= {sbuf[6:0], PSRAM_SO};				
				state <= 8'd2;
				task_x <= 16'd0;
				en_clk_out <= 1'b0;
			end
		end
		8'd2:
		begin
			PSRAM_CEn <= 1'b1;
			state <= 8'd3;
		end
		8'd3:
		begin
			PSRAM_CEn <= 1'b0;
			state <= 8'd4;
			sbuf <= 8'h99;
		end
		8'd4:
		begin
			if (task_x < 8'd8)
			begin
				en_clk_out <= 1'b1;
				task_x <= task_x + 1'b1;
				PSRAM_SI <= sbuf[7];
				sbuf <= {sbuf[6:0], PSRAM_SO};
			end
			else
			begin
				en_clk_out <= 1'b0;
				sbuf <= {sbuf[6:0], PSRAM_SO};
				state <= 8'd5;
				task_x <= 16'd0;
			end
		end
		8'd5:
		begin
			PSRAM_CEn <= 1'b1;
			state <= 8'd6;
		end
		8'd6:
		begin
			if (task_x < 8'd10) task_x <= task_x + 1'b1;
			else
			begin
				PSRAM_CEn <= 1'b0;
				state <= 8'd7;
				sbuf <= 8'h9f;
				task_x <= 16'd0;
			end			
		end
		8'd7:
		begin
			if (task_x < 8'd8)
			begin
				en_clk_out <= 1'b1;
				task_x <= task_x + 1'b1;
				PSRAM_SI <= sbuf[7];
				sbuf <= {sbuf[6:0], PSRAM_SO};
			end
			else
			begin
				en_clk_out <= 1'b0;
				sbuf <= {sbuf[6:0], PSRAM_SO};
				state <= 8'd8;
				task_x <= 16'd0;
			end
		end
		8'd8:
		begin
			if (task_x < 8'd24)
			begin
				en_clk_out <= 1'b1;
				task_x <= task_x + 1'b1;
				sbuf <= {sbuf[6:0], PSRAM_SO};
			end
			else
			begin
				state <= 8'd9;
				en_clk_out <= 1'b0;
				task_x <= 16'd0;
				sbuf <= {sbuf[6:0], PSRAM_SO};
			end
		end
		8'd9:
		begin
			if (task_x < 8'd16)
			begin
				en_clk_out <= 1'b1;
				task_x <= task_x + 1'b1;
				eid <= {eid[14:0], PSRAM_SO};
			end
			else
			begin
				en_clk_out <= 1'b0;
				task_x <= 16'd0;
				state <= 8'hff;
				eid <= {eid[14:0], PSRAM_SO};
			end
		end
		8'hff:
		begin
			PSRAM_CEn <= 1'b1;
		end
		endcase
	end
end


endmodule
