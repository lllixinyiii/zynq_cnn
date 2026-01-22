module ov5640_top #(
    parameter CONV_IN_BIT_WIDTH_F = 8
    )(
    input            clk_100M,
    // input            clk_24M,
    input            rst,
    
    output           i2c_sclk,
    inout            i2c_sdat,
    // output      wire ov5640_xclk,
    output      wire ov5640_pwdn,
    output      wire ov5640_rst_n,
    input       wire ov5640_pclk,
    input       wire ov5640_href,
    input       wire ov5640_vsync,
    input wire [7:0] ov5640_data,
    
    output wire [11:0] data_pixel_o,
    output wire wr_pixel_en,
    
    //input wire[7:0] binar_threshold,
    //output wire [7:0] ov5640_data_o         // 主要用来看二值化处理效果
    output wire wr_fm_en,                   // 写特征图存储器使能信号
    output wire [CONV_IN_BIT_WIDTH_F-1:0] wr_fm_data, 
    output wire lenet5_go
    );
    
    
    wire init_done;
    camera_init ci_0 (
        .clk_100M(clk_100M),
        // .clk_24M(clk_24M),
        .rst(rst),
        .init_done(init_done),
        // .ov5640_xclk(ov5640_xclk),
        .ov5640_rst_n(ov5640_rst_n),
        .ov5640_pwdn(ov5640_pwdn),
        .i2c_sclk(i2c_sclk),
        .i2c_sdat(i2c_sdat)
    );
    
    
    ov5640_data od_0(
    .rst(rst),
    .ov5640_pclk(ov5640_pclk),
    .ov5640_href(ov5640_href),
    .ov5640_vsync(ov5640_vsync),
    .ov5640_data(ov5640_data),
    .data_pixel_o(data_pixel_o),
    .wr_pixel_en(wr_pixel_en),
    .wr_fm_en(wr_fm_en),
    .wr_fm_data(wr_fm_data),
    .lenet5_go(lenet5_go)
    );
    
    
endmodule
