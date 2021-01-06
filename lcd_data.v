
`include "sdram\sdram_timing.v"
`include "lcd\lcd_timing.v"

module lcd_data
	(

    input             clk_50m,          //时钟
    input             rst_n,            //复位,低有效
    
    output reg        wr_en,            //SDRAM 写使能
    output        rd_en,            //SDRAM 读使能	
    output reg [`FIFO_WIDTH-1:0] wr_data,          //SDRAM 写入的数据
    input      [`FIFO_WIDTH-1:0] rd_data,          //SDRAM 读出的数据
    input             sdram_init_done,  //SDRAM 初始化完成标志

    //RGB LCD接口
    output               lcd_de,      //LCD 数据使能信号
    output               lcd_hs,      //LCD 行同步信号
    output               lcd_vs,      //LCD 场同步信号
    output               lcd_clk,     //LCD 像素时钟
    output        [23:0]  lcd_rgb,     //LCD RGB565颜色数据
    output               lcd_rst,
    output               lcd_bl
	
    );

//parameter define  
parameter WHITE = 16'b11111_111111_11111;  //白色
parameter BLACK = 16'b00000_000000_00000;  //黑色
parameter RED   = 16'b11111_000000_00000;  //红色
parameter GREEN = 16'b00000_111111_00000;  //绿色
parameter BLUE  = 16'b00000_000000_11111;  //蓝色

`define LCD_FRAME_LEN (`LCD_IN_H_DISP*`LCD_IN_V_DISP)




reg [31:0] counter;
reg [`FIFO_WIDTH-1:0] write_color;
reg [31:0] wr_counter;




/*
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 32'd0;  
		
	end
    else if(sdram_init_done && (counter <= 32'd150_000_000) ) begin
        counter <= counter + 1'b1;
	end
    else begin
        counter <= 32'd0;
	end
end  


reg        start_write; 
reg			write_req;

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
		write_color <= BLACK;
		start_write <= 1'b0;
	end
    else if(counter == 32'd50_000_000 ) begin
        write_color <= RED;
		start_write <= 1'b1;
	end
    else if(counter == 32'd100_000_000 ) begin
        write_color <= GREEN;
		start_write <= 1'b1;
	end
    else if(counter == 32'd150_000_000 ) begin
        write_color <= BLUE;
		start_write <= 1'b1;
	end
    else begin
		start_write <= 1'b0;
		// write_color <= BLACK;
	end
end  

always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
		write_req <= 1'b0;
	end
	else if(start_write == 1'b1)
		write_req <= 1'b1;
    else if(wr_counter >  `LCD_FRAME_LEN)
		write_req <= 1'b0;

	else
		write_req <= write_req;
end  

reg [1:0]color_cnt;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        wr_counter <= 32'd0;  
		color_cnt <= 0;
	end
    else if(sdram_init_done && (wr_counter <= `LCD_FRAME_LEN) ) begin
        wr_counter <= wr_counter + 1'b1;
	end
    else begin
        wr_counter <= 32'd0;
		color_cnt <= color_cnt + 1'b1;
	end
end  
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        wr_counter <= 32'd0;  
		color_cnt <= 0;
	end
    else if(color_cnt == 2'b00) begin
		write_color <= RED;
	end
    else if(color_cnt == 2'b01) begin
		write_color <= BLUE;
	end
    else if(color_cnt == 2'b10) begin
		write_color <= GREEN;
	end
    else if(color_cnt == 2'b11) begin
		write_color <= BLACK;
	end
    else begin
		write_color <= BLACK;
	end
end  



// fifo 写数据时，wr_en使能的同时要准备好数据
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin      
        wr_en   <= 1'b0;
        wr_data <= 0; //64'd0;
    end
    else if(write_req == 1'b1 && wr_counter >= 1 && (wr_counter <= `LCD_FRAME_LEN)) begin
		wr_en   <= 1'b1;            //写使能拉高
		wr_data <=   write_color;  
    end    
	else begin
		wr_en   <= 1'b0;            //写使能拉高
		wr_data <= 0;
	end
end  
*/



reg [9:0]color_cnt;
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        wr_counter <= 32'd0;  
		color_cnt <= 0;
	end
    else if(sdram_init_done && (wr_counter <= `LCD_FRAME_LEN) ) begin
        wr_counter <= wr_counter + 1'b1;
	end
    else if(sdram_init_done) begin
        wr_counter <= 32'd0;
		color_cnt <= color_cnt + 1'b1;
		if(color_cnt >= 10'd800)
			color_cnt <= 0;
	end
	else
		wr_counter <= 32'd0;
end  
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
		write_color <= BLACK;
	end
    else if(color_cnt == 10'd200) begin
		write_color <= RED;
	end
    else if(color_cnt == 10'd400) begin
		write_color <= BLUE;
	end
    else if(color_cnt == 10'd600) begin
		write_color <= GREEN;
	end
    else if(color_cnt == 10'd800) begin
		write_color <= BLACK;
	end
    else begin
		write_color <= write_color;
	end
end  

// fifo 写数据时，wr_en使能的同时要准备好数据
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin      
        wr_en   <= 1'b0;
        wr_data <= 0; //64'd0;
    end
    else if(wr_counter >= 1 && (wr_counter <= `LCD_FRAME_LEN)) begin
		wr_en   <= 1'b1;            //写使能拉高
		wr_data <=   write_color;  
    end    
	else begin
		wr_en   <= 1'b0;            //写使能拉高
		wr_data <= 0;
	end
end  





  

wire          lcd_pclk  ;    //LCD像素时钟              
wire  [10:0]  pixel_xpos;    //当前像素点横坐标
wire  [10:0]  pixel_ypos;    //当前像素点纵坐标
wire  [10:0]  h_disp    ;    //LCD屏水平分辨率
wire  [10:0]  v_disp    ;    //LCD屏垂直分辨率
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