`define	  LCD_H_SYNC  11'd128     //行同步
`define	  LCD_H_BACK     11'd64    //行显示后沿
`define	  LCD_H_DISP     11'd800   //行有效数据
`define	  LCD_H_FRONT    11'd64     //行显示前沿
`define	  LCD_H_TOTAL    11'd1056  //行扫描周期

`define	  LCD_V_SYNC     11'd2     //场同步
`define	  LCD_V_BACK     11'd21    //场显示后沿
`define	  LCD_V_DISP     11'd480   //场有效数据
`define	  LCD_V_FRONT    11'd22  //场显示前沿
`define	  LCD_V_TOTAL    11'd525  //场扫描周期

`define		LCD_IN_H_DISP 11'd800  // 至少少于最大显示分辨率 -4
`define		LCD_IN_V_DISP 11'd480   //