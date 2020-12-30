//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           lcd_rgb_colorbar
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        LCD屏幕显示彩条
//                      
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2020/05/28 20:28:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`include "lcd_timing.v"

module lcd_rgb_colorbar(
    input                sys_clk,     //系统时钟
    input                sys_rst_n,   //系统复位

    //RGB LCD接口
    output               lcd_de,      //LCD 数据使能信号
    output               lcd_hs,      //LCD 行同步信号
    output               lcd_vs,      //LCD 场同步信号
    output               lcd_clk,     //LCD 像素时钟
    output        [23:0]  lcd_rgb,     //LCD RGB565颜色数据
    output               lcd_rst,
    output               lcd_bl
    
    );                                                      

// wire  [15:0]  lcd_id    ;    //LCD屏ID
wire          lcd_pclk  ;    //LCD像素时钟              
wire  [10:0]  pixel_xpos;    //当前像素点横坐标
wire  [10:0]  pixel_ypos;    //当前像素点纵坐标
wire  [10:0]  h_disp    ;    //LCD屏水平分辨率
wire  [10:0]  v_disp    ;    //LCD屏垂直分辨率
wire  [15:0]  pixel_data;    //像素数据
wire  [15:0]  lcd_rgb_o ;    //输出的像素数据


`define LCD_ID 16'h7084
//*****************************************************
//**                    main code
//*****************************************************

//像素数据方向切换
assign lcd_rgb = lcd_de ?  {lcd_rgb_o[15:11],3'b000,lcd_rgb_o[10:5],2'b00, lcd_rgb_o[4:0],3'b000} :  {24{1'b0}};

//时钟分频模块    
clk_div u_clk_div(
    .clk           (sys_clk  ),
    .rst_n         (sys_rst_n),
    .lcd_id        (`LCD_ID   ),
    .lcd_pclk      (lcd_pclk )
    );    

//LCD显示模块    
lcd_display u_lcd_display(
    .lcd_pclk       (lcd_pclk  ),
    .rst_n          (sys_rst_n ),
    .pixel_xpos     (pixel_xpos),
    .pixel_ypos     (pixel_ypos),
    .pixel_data     (pixel_data)
    );    

//LCD驱动模块
lcd_driver u_lcd_driver(
    .lcd_pclk      (lcd_pclk  ),
    .rst_n         (sys_rst_n ),
    .lcd_id        (`LCD_ID    ),
    .pixel_data    (pixel_data),
    .pixel_xpos    (pixel_xpos),
    .pixel_ypos    (pixel_ypos),
	.data_req		(),

    .lcd_de        (lcd_de    ),
    .lcd_hs        (lcd_hs    ),
    .lcd_vs        (lcd_vs    ),   
    .lcd_clk       (lcd_clk   ),
    .lcd_rgb       (lcd_rgb_o ),
    .lcd_rst       (lcd_rst   ),
    .lcd_bl        (lcd_bl)
    );

endmodule
