//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           lcd_display
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        产生彩条数据
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

module lcd_display(
    input                lcd_pclk,    //时钟
    input                rst_n,       //复位，低电平有效
    input        [10:0]  pixel_xpos,  //当前像素点横坐标
    input        [10:0]  pixel_ypos,  //当前像素点纵坐标  
    // input        [10:0]  h_disp,      //LCD屏水平分辨率
    // input        [10:0]  v_disp,      //LCD屏垂直分辨率       
    output  reg  [15:0]  pixel_data   //像素数据
    );

//parameter define  
parameter WHITE = 16'b11111_111111_11111;  //白色
parameter BLACK = 16'b00000_000000_00000;  //黑色
parameter RED   = 16'b11111_000000_00000;  //红色
parameter GREEN = 16'b00000_111111_00000;  //绿色
parameter BLUE  = 16'b00000_000000_11111;  //蓝色

//根据当前像素点坐标指定当前像素点颜色数据，在屏幕上显示彩条
always @(posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n)
        pixel_data <= BLACK;
    else begin
        if((pixel_xpos >= 11'd0) && (pixel_xpos < 	`LCD_H_DISP/5*1))
            pixel_data <= WHITE;
        else if((pixel_xpos >= `LCD_H_DISP/5*1) && (pixel_xpos < `LCD_H_DISP/5*2))    
            pixel_data <= BLACK;
        else if((pixel_xpos >= `LCD_H_DISP/5*2) && (pixel_xpos < `LCD_H_DISP/5*3))    
            pixel_data <= RED;   
        else if((pixel_xpos >= `LCD_H_DISP/5*3) && (pixel_xpos < `LCD_H_DISP/5*4))    
            pixel_data <= GREEN;                
        else 
            pixel_data <= BLUE;      
    end    
end
  
endmodule
