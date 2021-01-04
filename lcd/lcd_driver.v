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
    output     reg       lcd_rst
  
    );

/* 
//parameter define  
// 4.3' 480*272
parameter  H_SYNC_4342   =  11'd41;     //行同步
parameter  H_BACK_4342   =  11'd2;      //行显示后沿
parameter  H_DISP_4342   =  11'd480;    //行有效数据
parameter  H_FRONT_4342  =  11'd2;      //行显示前沿
parameter  H_TOTAL_4342  =  11'd525;    //行扫描周期
   
parameter  V_SYNC_4342   =  11'd10;     //场同步
parameter  V_BACK_4342   =  11'd2;      //场显示后沿
parameter  V_DISP_4342   =  11'd272;    //场有效数据
parameter  V_FRONT_4342  =  11'd2;      //场显示前沿
parameter  V_TOTAL_4342  =  11'd286;    //场扫描周期
   
   
   
// 7' 800*480   
parameter  H_SYNC_   =  11'd128;    //行同步
parameter  H_BACK_   =  11'd88;     //行显示后沿
parameter  H_DISP_   =  11'd800;    //行有效数据
parameter  H_FRONT_  =  11'd40;     //行显示前沿
parameter  H_TOTAL_  =  11'd1056;   //行扫描周期
   
parameter  V_SYNC_   =  11'd2;      //场同步
parameter  V_BACK_   =  11'd33;     //场显示后沿
parameter  V_DISP_   =  11'd480;    //场有效数据
parameter  V_FRONT_  =  11'd10;     //场显示前沿
parameter  V_TOTAL_  =  11'd525;    //场扫描周期       
   
   
   
// 7' 1024*600   
parameter  H_SYNC_7016   =  11'd20;     //行同步
parameter  H_BACK_7016   =  11'd140;    //行显示后沿
parameter  H_DISP_7016   =  11'd1024;   //行有效数据
parameter  H_FRONT_7016  =  11'd160;    //行显示前沿
parameter  H_TOTAL_7016  =  11'd1344;   //行扫描周期
   
parameter  V_SYNC_7016   =  11'd3;      //场同步
parameter  V_BACK_7016   =  11'd20;     //场显示后沿
parameter  V_DISP_7016   =  11'd600;    //场有效数据
parameter  V_FRONT_7016  =  11'd12;     //场显示前沿
parameter  V_TOTAL_7016  =  11'd635;    //场扫描周期
   
// 10.1' 1280*800   
parameter  H_SYNC_1018   =  11'd10;     //行同步
parameter  H_BACK_1018   =  11'd80;     //行显示后沿
parameter  H_DISP_1018   =  11'd1280;   //行有效数据
parameter  H_FRONT_1018  =  11'd70;     //行显示前沿
parameter  H_TOTAL_1018  =  11'd1440;   //行扫描周期
   
parameter  V_SYNC_1018   =  11'd3;      //场同步
parameter  V_BACK_1018   =  11'd10;     //场显示后沿
parameter  V_DISP_1018   =  11'd800;    //场有效数据
parameter  V_FRONT_1018  =  11'd10;     //场显示前沿
parameter  V_TOTAL_1018  =  11'd823;    //场扫描周期

// 4.3' 800*480   
parameter  H_SYNC_4384   =  11'd128;    //行同步
parameter  H_BACK_4384   =  11'd88;     //行显示后沿
parameter  H_DISP_4384   =  11'd800;    //行有效数据
parameter  H_FRONT_4384  =  11'd40;     //行显示前沿
parameter  H_TOTAL_4384  =  11'd1056;   //行扫描周期
   
parameter  V_SYNC_4384   =  11'd2;      //场同步
parameter  V_BACK_4384   =  11'd33;     //场显示后沿
parameter  V_DISP_4384   =  11'd480;    //场有效数据
parameter  V_FRONT_4384  =  11'd10;     //场显示前沿
parameter  V_TOTAL_4384  =  11'd525;    //场扫描周期    


*/

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
assign pixel_xpos = data_valide ? (h_cnt - (h_sync + h_back - 1'b1)) : 11'd0;
assign pixel_ypos = data_valide ? (v_cnt - (v_sync + v_back - 1'b1)) : 11'd0;






/*


localparam BLACK  = 16'b00000_000000_00000;     //RGB565 黑色
//wire define
wire    [10:0]  display_border_pos_l;           //左侧边界的横坐标
wire    [10:0]  display_border_pos_r;           //右侧边界的横坐标
wire    [10:0]  display_border_pos_t;           //上侧边界的横坐标
wire    [10:0]  display_border_pos_b;           //下侧边界的横坐标

//左侧边界的横坐标计算 (800-640)/2-1 = 79
assign display_border_pos_l  = ((h_disp - `LCD_IN_H_DISP)==0 ? 0 : ( (h_disp - `LCD_IN_H_DISP)/2-1 ) );
//右侧边界的横坐标计算 640 + (800-640)/2-1 = 719
assign display_border_pos_r = `LCD_IN_H_DISP + display_border_pos_l;

// 上侧边界的横坐标计算 (800-640)/2-1 = 79
assign display_border_pos_t  = ((v_disp - `LCD_IN_V_DISP)==0 ? 0 : ( (v_disp - `LCD_IN_V_DISP)/2-1 ));
// 下侧边界的横坐标计算 640 + (800-640)/2-1 = 719
assign display_border_pos_b = `LCD_IN_V_DISP + display_border_pos_t;


//请求像素点颜色数据输入 范围:79~718，共640个时钟周期
assign data_req = ((pixel_xpos >= display_border_pos_l) &&
                  (pixel_xpos < display_border_pos_r) &&
				  (pixel_ypos >= display_border_pos_t) &&
				  (pixel_ypos < display_border_pos_b) &&
				  (data_valide)) ? 1'b1 : 1'b0;

//在数据有效范围内，将摄像头采集的数据赋值给LCD像素点数据
assign lcd_rgb = data_val ? pixel_data : BLACK;

//有效数据滞后于请求信号一个时钟周期,所以数据有效信号在此延时一拍
reg             data_val            ;           //数据有效信号
always @(posedge lcd_pclk or negedge rst_n) begin
    if(!rst_n)
        data_val <= 1'b0;
    else
        data_val <= data_req;    
end   


*/





//RGB565数据输出
assign lcd_rgb = lcd_en ? pixel_data : 16'd0;
assign data_req = data_valide;

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
