/*
 * analysis.cpp
 *
 *  Created on: 2019年9月7日
 *      Author: athieka@hotmail.com
 */
module SYNC_SIGNAL(input clk,
							input reset,
							input signal,
							output reg syn_signal);
parameter SYNC_STAGE = 2;
parameter INIT_SIGNAL = 1'b1;
reg[SYNC_STAGE-1:0] cur_signal;
integer i;
always @(posedge clk or posedge reset)
begin
	if (reset)
	begin
		syn_signal <= INIT_SIGNAL;
		for (i = 0; i < SYNC_STAGE; i=i+1)
		begin
			cur_signal[i] <= INIT_SIGNAL;
		end
	end
	else
	begin
		for (i=1; i<SYNC_STAGE; i=i+1)
		begin
			cur_signal[i] <= cur_signal[i-1];
		end
		if (signal == 1'b0)
		begin
			cur_signal[0] <= 1'b0;
		end
		else if (signal == 1'b1)
		begin
			cur_signal[0] <= 1'b1;
		end		
		if (cur_signal == {SYNC_STAGE{1'b0}}) syn_signal <= 1'b0;
		else if(cur_signal == {SYNC_STAGE{1'b1}}) syn_signal <= 1'b1;		
	end
end
endmodule
