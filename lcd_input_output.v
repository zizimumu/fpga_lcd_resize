
`include "sdram\sdram_timing.v"
`include "lcd\lcd_timing.v"

module lcd_input_output
	(

    input             				clk_50m,          //时钟
    input             				rst_n,            //复位,低有效
    
    output 	        				wr_en,            //SDRAM 写使能
    output        					rd_en,            //SDRAM 读使能	
    output     [`FIFO_WIDTH-1:0] 	wr_data,          //SDRAM 写入的数据
    input      [`FIFO_WIDTH-1:0] 	rd_data,          //SDRAM 读出的数据
    input             				sdram_init_done,  //SDRAM 初始化完成标志

    //RGB LCD接口
    output               			lcd_de,      //LCD 数据使能信号
    output               			lcd_hs,      //LCD 行同步信号
    output               			lcd_vs,      //LCD 场同步信号
    output               			lcd_clk,     //LCD 像素时钟
    output        [23:0]  			lcd_rgb,     //LCD RGB565颜色数据
    output               			lcd_rst,
    output               			lcd_bl,


	// lcd input
	output					fifo_clr,
	output					fifo_wr_clk,

    input               	lcd_de_i,      //LCD 数据使能信号
    input               	lcd_hs_i,      //LCD 行同步信号
    input               	lcd_vs_i,      //LCD 场同步信号

    input               	lcd_pclk_i,     //LCD 像素时钟
    input       [23:0]  	lcd_rgb_i     //LCD RGB565颜色数据	
    );

//parameter define  
parameter WHITE = 16'b11111_111111_11111;  //白色
parameter BLACK = 16'b00000_000000_00000;  //黑色
parameter RED   = 16'b11111_000000_00000;  //红色
parameter GREEN = 16'b00000_111111_00000;  //绿色
parameter BLUE  = 16'b00000_000000_11111;  //蓝色












wire 	lcd_init_done;
wire		[10:0]	v_disp;
wire		[10:0]	h_disp;

lcd_input u_lcd_input(
	.rst_n			(rst_n),       //复位，低电平有效

	.write_data		(wr_data),  //像素数据
	.write_req		(wr_en),
	.fifo_clr		(fifo_clr),
	.write_clk		(fifo_wr_clk),
	.v_disp			(v_disp),
	.h_disp			(h_disp),
	.init_done		(lcd_init_done),

	.lcd_de_i		(lcd_de_i),      //LCD 数据使能信号
	.lcd_hs_i		(lcd_hs_i),      //LCD 行同步信号
	.lcd_vs_i		(lcd_vs_i),      //LCD 场同步信号
	.lcd_pclk_i		(lcd_pclk_i),     //LCD 像素时钟
	.lcd_rgb_i		(lcd_rgb_i)     //LCD RGB565颜色数据
);



//  `define IN_FRAME_LEN ( (`LCD_IN_H_DISP*`LCD_IN_V_DISP*2/8 + 255) / 256 * 256)
// `define LCD_FRAME_LEN ( (`LCD_IN_H_DISP*`LCD_IN_V_DISP*2/8 + 255) / 256 * 256 * 8 / 2)
// `define LCD_FRAME_LEN ( (`LCD_IN_H_DISP*`LCD_IN_V_DISP*2/`SDRAM_WIDTH_BYTE + `SDRAM_FULL_PAGE_BURST_LEN-1) / `SDRAM_FULL_PAGE_BURST_LEN * `SDRAM_FULL_PAGE_BURST_LEN * `SDRAM_WIDTH_BYTE / 2)





  

wire          lcd_pclk  ;    //LCD像素时钟              
wire  [10:0]  pixel_xpos;    //当前像素点横坐标
wire  [10:0]  pixel_ypos;    //当前像素点纵坐标
// wire  [10:0]  h_disp    ;    //LCD屏水平分辨率
// wire  [10:0]  v_disp    ;    //LCD屏垂直分辨率
wire  [15:0]  pixel_data;    //像素数据
wire  [15:0]  lcd_rgb_o ;    //输出的像素数据


`define LCD_ID 16'h7084

//像素数据方向切换
assign lcd_rgb = lcd_de ?  {lcd_rgb_o[15:11],3'b000,lcd_rgb_o[10:5],2'b00, lcd_rgb_o[4:0],3'b000} :  {24{1'b0}};

//时钟分频模块    
clk_div u_clk_div(
    .clk           (clk_50m  ),
    .rst_n         (rst_n),
    .lcd_id        (`LCD_ID   ),
    .lcd_pclk      (lcd_pclk )
    );    


//LCD驱动模块
lcd_driver u_lcd_driver(
    .lcd_pclk      (lcd_pclk  ),
    .rst_n         (rst_n ),
    .lcd_id        (`LCD_ID    ),
    .pixel_data    (rd_data),
    .pixel_xpos    (pixel_xpos),
    .pixel_ypos    (pixel_ypos),
	.data_req		(rd_en),

    .lcd_de        (lcd_de    ),
    .lcd_hs        (lcd_hs    ),
    .lcd_vs        (lcd_vs    ),   
    .lcd_clk       (lcd_clk   ),
    .lcd_rgb       (lcd_rgb_o ),
    .lcd_rst       (lcd_rst   ),
    .lcd_bl        (lcd_bl)
    );
	
endmodule