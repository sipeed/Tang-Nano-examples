module TOP
(
	input			nRST,
    input           XTAL_IN,

	output			LCD_CLK,
	output			LCD_HYNC,
	output			LCD_SYNC,
	output			LCD_DEN,
	output	[4:0]	LCD_R,
	output	[5:0]	LCD_G,
	output	[4:0]	LCD_B,

    output          LED_R,
    output          LED_G,
    output          LED_B,
    input           KEY

);

	wire		CLK_SYS;	
	wire		CLK_PIX;

    wire        oscout_o;
/* //使用内部时钟
    Gowin_OSC chip_osc(
        .oscout(oscout_o) //output oscout
    );
*/
    Gowin_PLL chip_pll(
        .clkout(CLK_SYS), //output clkout      //200M
        .clkoutd(CLK_PIX), //output clkoutd   //33.33M
        .clkin(XTAL_IN) //input clkin
    );	


	VGAMod	D1
	(
		.CLK		(	CLK_SYS     ),
		.nRST		(	nRST		),

		.PixelClk	(	CLK_PIX		),
		.LCD_DE		(	LCD_DEN	 	),
		.LCD_HSYNC	(	LCD_HYNC 	),
    	.LCD_VSYNC	(	LCD_SYNC 	),

		.LCD_B		(	LCD_B		),
		.LCD_G		(	LCD_G		),
		.LCD_R		(	LCD_R		)
	);

	assign		LCD_CLK		=	CLK_PIX;

    //RGB LED TEST
    reg 	[31:0] Count;
    reg     [1:0] rgb_data;
	always @(  posedge CLK_SYS or negedge nRST  )
	begin
		if(  !nRST  )
		begin
		Count		<= 32'd0;
        rgb_data    <= 2'b00;
		end
		else if ( Count == 100000000 )
		begin
			Count <= 4'b0;
            rgb_data <= rgb_data + 1'b1;
		end
		else
		Count <= Count + 1'b1;
	end
    assign  LED_R = ~(rgb_data == 2'b01);
    assign  LED_G = ~(rgb_data == 2'b10);
    assign  LED_B = ~(rgb_data == 2'b11);

endmodule