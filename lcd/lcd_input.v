`include "lcd_timing.v"
// `include "sdram\sdram_timing.v"

module lcd_input(
    input                	rst_n,       //复位，低电平有效

    output        [15:0]  	write_data,  //像素数据
	output 					write_req,
	output					fifo_clr,
	output					write_clk,
	output	reg		[10:0]	v_disp,
	output	reg		[10:0]	h_disp,
	output	reg				init_done,
	output [19:0]			fifo_left_s,

    //RGB LCD接口
    input               	lcd_de_i,      //LCD 数据使能信号
    input               	lcd_hs_i,      //LCD 行同步信号
    input               	lcd_vs_i,      //LCD 场同步信号

    input               	lcd_pclk_i,     //LCD 像素时钟
    input       [23:0]  	lcd_rgb_i     //LCD RGB565颜色数据

  
    );
	
wire [15:0] rgb_data;
wire pos_vsync;
wire neg_vsync;
wire pos_hsync;
wire neg_hsync;
wire pos_desync;
wire neg_desync;
// wire [19:0]fifo_left_s;


	
	

reg		[10:0]		vcnt;
reg		[10:0]		hcnt;
reg		[10:0]		vs_cnt;

reg [31:0] cnt_fifo;
reg wr_fifo_left;

reg             vsync_d0   ;
reg             vsync_d1   ;

reg             desync_d0   ;
reg             desync_d1   ;

reg             hsync_d0   ;
reg             hsync_d1   ;

reg				frame_start;
reg				h_start;


assign pos_vsync = (~vsync_d1) & vsync_d0;  
assign neg_vsync = vsync_d1   & ~vsync_d0;
assign pos_hsync = (~hsync_d1) & hsync_d0;  
assign neg_hsync = hsync_d1   & ~hsync_d0;
assign pos_desync = (~desync_d1) & desync_d0; 
assign neg_desync = desync_d1 & ~desync_d0; 
// clear fifo
assign fifo_clr = neg_vsync;
assign write_clk = lcd_pclk_i;
assign rgb_data = {lcd_rgb_i[23:19],lcd_rgb_i[15:10],lcd_rgb_i[7:3]};
assign write_req = ( (init_done &&  frame_start && h_start && lcd_de_i) || wr_fifo_left) ? 1'b1: 1'b0;
assign write_data = rgb_data;


always @(posedge lcd_pclk_i or negedge rst_n) begin
    if(!rst_n) begin
        vsync_d0 <= 1'b0;
        vsync_d1 <= 1'b0;
		hsync_d0 <= 0;
		hsync_d1 <= 0;
		desync_d0 <= 0;
		desync_d1 <= 0;
    end
    else begin
        vsync_d0 <= lcd_vs_i;
        vsync_d1 <= vsync_d0;

        hsync_d0 <= lcd_hs_i;
        hsync_d1 <= hsync_d0;
		
        desync_d0 <= lcd_de_i;
        desync_d1 <= desync_d0;		
    end
end


always @(posedge lcd_pclk_i or negedge rst_n) begin
    if(!rst_n) begin
		frame_start <= 1'b0;
		
		init_done <= 1'b0;
    end
    else if(neg_vsync) begin 
		frame_start <= 1'b1;

		if(v_disp !=0 && h_disp!=0)
			init_done <= 1'b1;
			
    end
	else if(pos_vsync) begin
		frame_start <= 1'b0;
		
		//if(!v_disp)
		//	v_disp <= vcnt;
		
		
	end
	// 防止fifo_left_s 计算占时过长的情况，h_disp,v_disp在vs上升沿置位，init_done在 vs下降沿置位
	// 注意， init_done必须在 一帧数据开始写之前置位，以保证后续数据同步
	//else if(v_disp !=0 && h_disp!=0  )
	//else if(v_disp !=0 && h_disp!=0 && neg_vsync )
	//	init_done <= 1'b1;
		
	
end

always @(posedge lcd_pclk_i or negedge rst_n) begin
    if(!rst_n) begin
		h_start <= 1'b0;
		
    end
    else if(neg_hsync) begin 
		h_start <= 1'b1;
    end
	else if(pos_hsync) begin
		h_start <= 1'b0;
		// h_disp <= hcnt;
	end
end

always @(posedge lcd_pclk_i or negedge rst_n) begin
    if(!rst_n) begin
		vcnt <= 0;
		v_disp <= 0;

    end
    else if(frame_start) begin 
		if(pos_desync) begin
			vcnt <= vcnt + 1'b1;
			
		end
		else
			vcnt <= vcnt;
				
			
    end
	else if(!frame_start) begin
		vcnt <= 0;
		
		if(!v_disp)
			v_disp <= vcnt;	
	end
	else
		vcnt <= 0;

end

always @(posedge lcd_pclk_i or negedge rst_n) begin
    if(!rst_n) begin
		hcnt <= 0;
		h_disp <= 0;
    end
    else if(h_start && lcd_de_i) begin 
			hcnt <= hcnt + 1'b1;
    end
	else if(!h_start) begin
		hcnt <= 0;
		
		if(!h_disp)
			h_disp <= hcnt;
	end
	else
		hcnt <= hcnt;

end





// 处理帧数据不是burst len对齐的问题


reg write_fifo_req;
always @(posedge lcd_pclk_i or negedge rst_n) begin
    if(!rst_n) begin
		write_fifo_req <= 1'b0;
    end
    else if(init_done && neg_desync && (vcnt ==  v_disp) ) begin 
		write_fifo_req <= 1'b1;
    end
	else if(neg_vsync)
		write_fifo_req <= 1'b0;
	else 
		write_fifo_req <= write_fifo_req;


end


// `define LCD_FRAME_LEN_MAX ( (`LCD_IN_H_DISP*`LCD_IN_V_DISP*2/`SDRAM_WIDTH_BYTE + `SDRAM_FULL_PAGE_BURST_LEN-1) / `SDRAM_FULL_PAGE_BURST_LEN * `SDRAM_FULL_PAGE_BURST_LEN * `SDRAM_WIDTH_BYTE / 2)
// `define FIFO_LEFT  (( `LCD_FRAME_LEN_MAX - `LCD_IN_H_DISP*`LCD_IN_V_DISP ))

`define LCD_FRAME_LEN_MAX_SS ( (h_disp*v_disp*2/`SDRAM_WIDTH_BYTE + `SDRAM_FULL_PAGE_BURST_LEN-1) / `SDRAM_FULL_PAGE_BURST_LEN * `SDRAM_FULL_PAGE_BURST_LEN * `SDRAM_WIDTH_BYTE / 2)
assign fifo_left_s =  (( `LCD_FRAME_LEN_MAX_SS - h_disp*v_disp ));


always @(posedge lcd_pclk_i or negedge rst_n) begin
    if(!rst_n) begin
		wr_fifo_left <= 1'b0;
		cnt_fifo <= 0;
	end
    else if( `FIFO_LEFT  != 0   &&   write_fifo_req ) begin
		if (cnt_fifo >= 1 && cnt_fifo <= `FIFO_LEFT) begin
			wr_fifo_left <= 1'b1;
		end
		else
			wr_fifo_left <= 1'b0;
			
		cnt_fifo <= cnt_fifo + 1'b1;
	end
	else begin
		wr_fifo_left <= 1'b0;
		cnt_fifo = 0;
		
	end
 
end  



	
endmodule