//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           lcd_driver
// Last modified Date:  2020/05/28 20:28:08
// Last Version:        V1.0
// Descriptions:        驱动LCD
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
`include "sdram\sdram_timing.v"

module lcd_driver(
    input                lcd_pclk,    //时钟
    input                rst_n,       //复位，低电平有效
    input        [15:0]  lcd_id,      //LCD屏ID
    input        [15:0]  pixel_data,  //像素数据
    output       [10:0]  pixel_xpos,  //当前像素点横坐标
    output       [10:0]  pixel_ypos,  //当前像素点纵坐标   
    output    [10:0]  o_h_disp,      //LCD屏水平分辨率
    output    [10:0]  o_v_disp,      //LCD屏垂直分辨率  
	output 				data_req,
    //RGB LCD接口
    output               lcd_de,      //LCD 数据使能信号
    output               lcd_hs,      //LCD 行同步信号
    output               lcd_vs,      //LCD 场同步信号
    output     reg       lcd_bl,      //LCD 背光控制信号
    output               lcd_clk,     //LCD 像素时钟
    output       [15:0]  lcd_rgb,     //LCD RGB565颜色数据
    output     reg       lcd_rst,
	
    input    [10:0]  i_h_disp,      //LCD屏水平分辨率
    input    [10:0]  i_v_disp,      //LCD屏垂直分辨率  
    input      input_done,     //LCD屏垂直分辨率   
	input	    [19:0]		fifo_left_s	
    );


//reg define
// reg  [10:0] h_sync ;
// reg  [10:0] h_back ;
// reg  [10:0] h_total;
// reg  [10:0] v_sync ;
// reg  [10:0] v_back ;
// reg  [10:0] v_total;
reg  [10:0] h_cnt  ;
reg  [10:0] v_cnt  ;

//wire define    
wire        lcd_en;
wire             data_valide            ;           //数据有效信号
// wire [19:0]fifo_left_s;
//*****************************************************
//**                    main code
//*****************************************************

//RGB LCD 采用DE模式时，行场同步信号需要拉高





parameter  h_sync   =  `LCD_H_SYNC;     //行同步
parameter  h_back   =  `LCD_H_BACK;    //行显示后沿
parameter  h_disp   =  `LCD_H_DISP;   //行有效数据
parameter  H_FRONT  =  `LCD_H_FRONT;     //行显示前沿
parameter  h_total  =  `LCD_H_TOTAL;  //行扫描周期

parameter  v_sync   =  `LCD_V_SYNC;     //场同步
parameter  v_back   =  `LCD_V_BACK;    //场显示后沿
parameter  v_disp   =  `LCD_V_DISP;   //场有效数据
parameter  V_FRONT  =  `LCD_V_FRONT;    //场显示前沿
parameter  v_total  =  `LCD_V_TOTAL;   //场扫描周期


assign lcd_hs  = (h_cnt <= h_sync - 1'b1) ? 1'b1 : 1'b0;
assign lcd_vs  = (v_cnt <= v_sync - 1'b1) ? 1'b1 : 1'b0;

//assign  lcd_bl = 1'b1;        //LCD背光控制信号  
assign  lcd_clk = lcd_pclk;   //LCD像素时钟
assign  lcd_de = lcd_en;      //LCD数据有效信号

//使能RGB565数据输出
assign  lcd_en = ((h_cnt >= h_sync + h_back) && (h_cnt < h_sync + h_back + h_disp)
                  && (v_cnt >= v_sync + v_back) && (v_cnt < v_sync + v_back + v_disp)) 
                  ? 1'b1 : 1'b0;

//请求像素点颜色数据输入  
assign data_valide = ((h_cnt >= h_sync + h_back - 1'b1) && (h_cnt < h_sync + h_back + h_disp - 1'b1)
                  && (v_cnt >= v_sync + v_back) && (v_cnt < v_sync + v_back + v_disp)) 
                  ? 1'b1 : 1'b0;

//像素点坐标  
assign pixel_xpos = data_valide ? (h_cnt - (h_sync + h_back - 1'b1) + 1) : 11'd0;
// 注意： y坐标从1开始计数
assign pixel_ypos = data_valide ? (v_cnt - (v_sync + v_back - 1'b1) ) : 11'd0;







reg read_fifo_left;
reg             data_val            ;           //数据有效信号
localparam BLACK  = 16'b00000_000000_00000;     //RGB565 黑色
//wire define
wire    [10:0]  display_border_pos_l;           //左侧边界的横坐标
wire    [10:0]  display_border_pos_r;           //右侧边界的横坐标
wire    [10:0]  display_border_pos_t;           //上侧边界的横坐标
wire    [10:0]  display_border_pos_b;           //下侧边界的横坐标


assign display_border_pos_l  =  ( 1 + (h_disp - i_h_disp)/2  );
assign display_border_pos_r = i_h_disp + display_border_pos_l;
assign display_border_pos_t  = ( 1+ (v_disp - i_v_disp)/2 );
assign display_border_pos_b = i_v_disp + display_border_pos_t;


//有效数据滞后于请求信号一个时钟周期,所以数据有效信号在此延时一拍

always @(posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n)
        data_val <= 1'b0;
    else
        data_val <= data_req;    
end   



// `define LCD_FRAME_LEN_MAX ( (`LCD_IN_H_DISP*`LCD_IN_V_DISP*2/`SDRAM_WIDTH_BYTE + `SDRAM_FULL_PAGE_BURST_LEN-1) / `SDRAM_FULL_PAGE_BURST_LEN * `SDRAM_FULL_PAGE_BURST_LEN * `SDRAM_WIDTH_BYTE / 2)
// `define FIFO_LEFT  (( `LCD_FRAME_LEN_MAX - `LCD_IN_H_DISP*`LCD_IN_V_DISP ))

// 处理帧数据不是burst len对齐的问题
reg [31:0] cnt_fifo;
always @(posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n) begin
		read_fifo_left <= 1'b0;
		cnt_fifo <= 0;
	end
    else if( input_done && `FIFO_LEFT  != 0   && v_cnt > (v_sync + v_back - 1'b1)  &&  (v_cnt - (v_sync + v_back - 1'b1)  ) >=  (display_border_pos_b) ) begin
		if (cnt_fifo >= 1 && cnt_fifo <= `FIFO_LEFT) begin
			read_fifo_left <= 1'b1;
		end
		else
			read_fifo_left <= 1'b0;
			
		cnt_fifo <= cnt_fifo + 1'b1;
	end
	else begin
		read_fifo_left <= 1'b0;
		cnt_fifo = 0;
		
	end
 
end   



//请求像素点颜色数据输入 范围:79~718，共640个时钟周期
  assign data_req = ( ( ((pixel_xpos >= display_border_pos_l) &&
                    (pixel_xpos < display_border_pos_r) &&
  				  (pixel_ypos >= display_border_pos_t) &&
  				  (pixel_ypos < display_border_pos_b) ) || read_fifo_left )  && input_done
 				  ) ? 1'b1 : 1'b0;

				  
//在数据有效范围内，将摄像头采集的数据赋值给LCD像素点数据
assign lcd_rgb = ( data_val && (!read_fifo_left) && input_done)? pixel_data : BLACK;
//assign lcd_rgb = ( data_val && (!read_fifo_left) )? pixel_data : BLACK;






//RGB565数据输出
//assign lcd_rgb = lcd_en ? pixel_data : 16'd0;
//assign data_req = data_valide;



//行计数器对像素时钟计数
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n) 
        h_cnt <= 11'd0;
    else begin
        if(h_cnt == h_total - 1'b1)
            h_cnt <= 11'd0;
        else
            h_cnt <= h_cnt + 1'b1;           
    end
end

//场计数器对行计数
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n) 
        v_cnt <= 11'd0;
    else begin
        if(h_cnt == h_total - 1'b1) begin
            if(v_cnt == v_total - 1'b1)
                v_cnt <= 11'd0;
            else
                v_cnt <= v_cnt + 1'b1;    
        end
    end    
end
always@ (posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n)begin 
    lcd_rst<=0;
    lcd_bl<=0;
    end
    else begin
     lcd_rst<=1;
    lcd_bl<=1;
    end
    end
endmodule
