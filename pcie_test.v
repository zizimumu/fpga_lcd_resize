`include "sdram\sdram_timing.v"

module pcie_test
(
    input              i_sys_rst_n        ,
    input              i_fpga_clk_50m     ,
	 output [3:0]   		  o_fpga_led,
	 output wire [11:0]	sd_a,
	 output wire [1:0]	sd_ba,
	 output wire 			sd_cas,
	 output wire			sd_cs,
	 inout wire [`SDRAM_DATA_WIDTH-1:0]	sd_dq,
	 output wire [`SDRAM_DATA_WIDTH/8 - 1:0]	sd_dqm,
	 output wire			sd_ras,
	 output wire			sd_we,
	 output wire 			sd_clk
);




wire clk_100m_out;
wire clk_50m_out;
wire clk_100m_ctl;
wire        locked;

wire        wr_en;                          //SDRAM 写端口:写使能
wire [`SDRAM_DATA_WIDTH-1:0] wr_data;                        //SDRAM 写端口:写入的数据
wire        rd_en;                          //SDRAM 读端口:读使能
wire [`SDRAM_DATA_WIDTH-1:0] rd_data;                        //SDRAM 读端口:读出的数据
wire        sdram_init_done;                //SDRAM 初始化完成信号

wire        sys_rst_n;                      //系统复位信号
wire        error_flag;                     //读写测试错误标志
wire [3:0]		cycle_countor;				// 测试周期计数

`define		SDRAM_TEST_LEN		    24'h400000 
`define		SDRAM_FULL_PAGE_BURST_LEN 10'd256

assign sys_rst_n = i_sys_rst_n & locked;

clk_pll	clk_pll_inst (
	.areset ( ~i_sys_rst_n ),
	.inclk0 ( i_fpga_clk_50m ),
	.c0 ( clk_100m_out ),
	.c1 ( clk_100m_ctl ),
	.locked (locked)
	);


//SDRAM测试模块，对SDRAM进行读写测试
sdram_test #(.TEST_LEN(`SDRAM_TEST_LEN))
u_sdram_test(
    .clk_50m            (i_fpga_clk_50m),
    .rst_n              (sys_rst_n),
    
    .wr_en              (wr_en),
    .wr_data            (wr_data),
    .rd_en              (rd_en),
    .rd_data            (rd_data),   
    
    .sdram_init_done    (sdram_init_done),    
    .error_flag         (error_flag),
	.cycle_countor		(cycle_countor)
    );

//利用LED灯指示SDRAM读写测试的结果
led_disp u_led_disp(
    .clk_50m            (i_fpga_clk_50m),
    .rst_n              (sys_rst_n),
   
    .error_flag         (error_flag),
    .led                (o_fpga_led),
	.cycle_countor		(cycle_countor)
    );

//SDRAM 控制器顶层模块,封装成FIFO接口
//SDRAM 控制器地址组成: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top u_sdram_top(
	.ref_clk			(clk_100m_ctl),			//sdram	控制器参考时钟
	.out_clk			(clk_100m_out),	//用于输出的相位偏移时钟
	.rst_n				(sys_rst_n),		//系统复位
    
    //用户写端口
	.wr_clk 			(i_fpga_clk_50m),		    //写端口FIFO: 写时钟
	.wr_en				(wr_en),			//写端口FIFO: 写使能
	.wr_data		    (wr_data),		    //写端口FIFO: 写数据
	.wr_min_addr		(24'd0),			//写SDRAM的起始地址
	.wr_max_addr		(`SDRAM_TEST_LEN),		    //写SDRAM的结束地址
	.wr_len			    (`SDRAM_FULL_PAGE_BURST_LEN),			//写SDRAM时的数据突发长度
	.wr_load			(~sys_rst_n),		//写端口复位: 复位写地址,清空写FIFO
   
    //用户读端口
	.rd_clk 			(i_fpga_clk_50m),			//读端口FIFO: 读时钟
    .rd_en				(rd_en),			//读端口FIFO: 读使能
	.rd_data	    	(rd_data),		    //读端口FIFO: 读数据
	.rd_min_addr		(24'd0),			//读SDRAM的起始地址
	.rd_max_addr		(`SDRAM_TEST_LEN),	    	//读SDRAM的结束地址
	.rd_len 			(`SDRAM_FULL_PAGE_BURST_LEN),			//从SDRAM中读数据时的突发长度
	.rd_load			(~sys_rst_n),		//读端口复位: 复位读地址,清空读FIFO
	   
     //用户控制端口  
	.sdram_read_valid	(1'b1),             //SDRAM 读使能
	.sdram_init_done	(sdram_init_done),	//SDRAM 初始化完成标志
   
	//SDRAM 芯片接口
	.sdram_clk			(sd_clk),        //SDRAM 芯片时钟
	.sdram_cke			(),        //SDRAM 时钟有效
	.sdram_cs_n			(sd_cs),       //SDRAM 片选
	.sdram_ras_n		(sd_ras),      //SDRAM 行有效
	.sdram_cas_n		(sd_cas),      //SDRAM 列有效
	.sdram_we_n			(sd_we),       //SDRAM 写有效
	.sdram_ba			(sd_ba),         //SDRAM Bank地址
	.sdram_addr			(sd_a),       //SDRAM 行/列地址
	.sdram_data			(sd_dq),       //SDRAM 数据
	.sdram_dqm			(sd_dqm)         //SDRAM 数据掩码
    );

	 

endmodule
