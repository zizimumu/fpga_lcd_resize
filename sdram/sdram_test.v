//****************************************Copyright (c)***********************************//
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com 
//关注微信公众平台微信号："正点原子"，免费获取FPGA & STM32资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           sdram_test
// Last modified Date:  2018/3/18 8:41:06
// Last Version:        V1.0
// Descriptions:        SDRAM读写测试: 向SDRAM中写入数据,然后将数据读出,并判断读出的数据是否正确
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2018/3/18 8:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`include "sdram_timing.v"

module sdram_test#(
	parameter TEST_LEN = 32'd1024,  // 测试数据长度
	parameter TEST_CYCLE = 32'd50_000000 // 测试周期, 50000000为1s
) 
(
    input             clk_50m,          //时钟
    input             rst_n,            //复位,低有效
    
    output reg        wr_en,            //SDRAM 写使能
    output reg [`SDRAM_DATA_WIDTH-1:0] wr_data,          //SDRAM 写入的数据
    output reg        rd_en,            //SDRAM 读使能
    input      [`SDRAM_DATA_WIDTH-1:0] rd_data,          //SDRAM 读出的数据
    
    input             sdram_init_done,  //SDRAM 初始化完成标志
    output reg        error_flag,        //SDRAM 读写测试错误标志
	output reg [3:0] cycle_countor
    );

	
//reg define
reg        init_done_d0;                //寄存SDRAM初始化完成信号
reg        init_done_d1;                //寄存SDRAM初始化完成信号
reg [10:0] wr_cnt;                      //写操作计数器
reg [10:0] rd_cnt;                      //读操作计数器
reg        rd_valid;                    //读数据有效标志
   
//*****************************************************
//**                    main code
//***************************************************** 

//同步SDRAM初始化完成信号
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        init_done_d0 <= 1'b0;
        init_done_d1 <= 1'b0;
    end
    else begin
        init_done_d0 <= sdram_init_done;
        init_done_d1 <= init_done_d0;
    end
end            



reg [31:0] counter;

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 32'd0;  
		
	end
    else if(init_done_d1 && (counter < TEST_CYCLE) ) begin
	
        counter <= counter + 1'b1;
	end
    else begin
        counter <= 32'd0;
	end
end  
  



// fifo 写数据时，wr_en使能的同时要准备好数据
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin      
        wr_en   <= 1'b0;
        wr_data <= 0; //64'd0;
		cycle_countor <= 4'd0;
    end
    else if(counter >= 11'd1 && (counter <= TEST_LEN)) begin
            wr_en   <= 1'b1;            //写使能拉高
			rd_en   <= 1'b0;
            wr_data <=  counter;          //写入数据1~1024 64'h55aa55aa_00000000 +
    end    
    else if(counter > TEST_LEN && (counter <= TEST_LEN*2)) begin
            wr_en   <= 1'b0;            //写使能拉高
			rd_en   <= 1'b1;

    end
	else if(counter == TEST_CYCLE) 
		cycle_countor <= cycle_countor + 1'b1;
	else begin
            wr_en   <= 1'b0;            //写使能拉高
			rd_en   <= 1'b0;	
	end
end  


// fifo读数据时，在rd_en有效后下一个周期读取
reg [31:0] rd_counter;
//读数据有效时,若读取数据错误,给出标志信号

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
		rd_counter <= 32'd0;
	end
    else if(rd_en) begin
		rd_counter <= rd_counter + 1'b1;
	end
	else begin
		rd_counter <= 32'd0;
	end
		
end


//读出FIFO的第一个值是上次读出的值，所以要延迟一个clock再做判断
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        error_flag <= 1'b0; 
	end
    else if(rd_en && rd_counter >= 32'd1) begin
		if (rd_data != (  rd_counter) && cycle_countor >= 1)  // 因为FIFO有预读，导致第一次读到的数据不正确，这里避开第一个写读周期
			error_flag <= 1'b1;             // 若读取的数据错误,将错误标志位拉高 
		else
			error_flag <= error_flag;
		
	end
end


endmodule 