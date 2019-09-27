// Verilog netlist created by TD v4.5.12562
// Thu Sep 26 11:56:29 2019

`timescale 1ns / 1ps
module LCD_FIFO  // al_ip/lcd_fifo.v(14)
  (
  clkr,
  clkw,
  di,
  re,
  rst,
  we,
  aempty_flag,
  afull_flag,
  do,
  empty_flag,
  full_flag
  );

  input clkr;  // al_ip/lcd_fifo.v(25)
  input clkw;  // al_ip/lcd_fifo.v(24)
  input [19:0] di;  // al_ip/lcd_fifo.v(23)
  input re;  // al_ip/lcd_fifo.v(25)
  input rst;  // al_ip/lcd_fifo.v(22)
  input we;  // al_ip/lcd_fifo.v(24)
  output aempty_flag;  // al_ip/lcd_fifo.v(28)
  output afull_flag;  // al_ip/lcd_fifo.v(29)
  output [19:0] do;  // al_ip/lcd_fifo.v(27)
  output empty_flag;  // al_ip/lcd_fifo.v(28)
  output full_flag;  // al_ip/lcd_fifo.v(29)

  wire empty_flag_neg;
  wire full_flag_neg;

  EG_PHY_CONFIG #(
    .DONE_PERSISTN("ENABLE"),
    .INIT_PERSISTN("ENABLE"),
    .JTAG_PERSISTN("DISABLE"),
    .PROGRAMN_PERSISTN("DISABLE"))
    config_inst ();
  not empty_flag_inv (empty_flag_neg, empty_flag);
  not full_flag_inv (full_flag_neg, full_flag);
  EG_PHY_FIFO #(
    .AE(32'b00000000000000000000000100000000),
    .AEP1(32'b00000000000000000000000100001000),
    .AF(32'b00000000000000000001111100000000),
    .AFM1(32'b00000000000000000001111011111000),
    .ASYNC_RESET_RELEASE("SYNC"),
    .DATA_WIDTH_A("9"),
    .DATA_WIDTH_B("9"),
    .E(32'b00000000000000000000000000000000),
    .EP1(32'b00000000000000000000000000001000),
    .F(32'b00000000000000000010000000000000),
    .FM1(32'b00000000000000000001111111111000),
    .GSR("DISABLE"),
    .MODE("FIFO8K"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("ASYNC"))
    logic_fifo_0 (
    .clkr(clkr),
    .clkw(clkw),
    .csr({2'b11,empty_flag_neg}),
    .csw({2'b11,full_flag_neg}),
    .dia(di[8:0]),
    .orea(1'b0),
    .oreb(1'b0),
    .re(re),
    .rprst(rst),
    .rst(rst),
    .we(we),
    .aempty_flag(aempty_flag),
    .afull_flag(afull_flag),
    .dob(do[8:0]),
    .empty_flag(empty_flag),
    .full_flag(full_flag));
  EG_PHY_FIFO #(
    .AE(32'b00000000000000000000000100000000),
    .AEP1(32'b00000000000000000000000100001000),
    .AF(32'b00000000000000000001111100000000),
    .AFM1(32'b00000000000000000001111011111000),
    .ASYNC_RESET_RELEASE("SYNC"),
    .DATA_WIDTH_A("9"),
    .DATA_WIDTH_B("9"),
    .E(32'b00000000000000000000000000000000),
    .EP1(32'b00000000000000000000000000001000),
    .F(32'b00000000000000000010000000000000),
    .FM1(32'b00000000000000000001111111111000),
    .GSR("DISABLE"),
    .MODE("FIFO8K"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("ASYNC"))
    logic_fifo_1 (
    .clkr(clkr),
    .clkw(clkw),
    .csr({2'b11,empty_flag_neg}),
    .csw({2'b11,full_flag_neg}),
    .dia(di[17:9]),
    .orea(1'b0),
    .oreb(1'b0),
    .re(re),
    .rprst(rst),
    .rst(rst),
    .we(we),
    .dob(do[17:9]));
  EG_PHY_FIFO #(
    .AE(32'b00000000000000000000000100000000),
    .AEP1(32'b00000000000000000000000100001000),
    .AF(32'b00000000000000000001111100000000),
    .AFM1(32'b00000000000000000001111011111000),
    .ASYNC_RESET_RELEASE("SYNC"),
    .DATA_WIDTH_A("9"),
    .DATA_WIDTH_B("9"),
    .E(32'b00000000000000000000000000000000),
    .EP1(32'b00000000000000000000000000001000),
    .F(32'b00000000000000000010000000000000),
    .FM1(32'b00000000000000000001111111111000),
    .GSR("DISABLE"),
    .MODE("FIFO8K"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("ASYNC"))
    logic_fifo_2 (
    .clkr(clkr),
    .clkw(clkw),
    .csr({2'b11,empty_flag_neg}),
    .csw({2'b11,full_flag_neg}),
    .dia({open_n87,open_n88,open_n89,open_n90,open_n91,open_n92,open_n93,di[19:18]}),
    .orea(1'b0),
    .oreb(1'b0),
    .re(re),
    .rprst(rst),
    .rst(rst),
    .we(we),
    .dob({open_n114,open_n115,open_n116,open_n117,open_n118,open_n119,open_n120,do[19:18]}));

endmodule 

