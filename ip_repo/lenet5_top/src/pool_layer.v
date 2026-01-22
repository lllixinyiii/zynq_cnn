`include "defines.v"
// 这个模块需要完成池化的功能
module pool_layer(
    input wire clk,
    input wire rst_n,
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c0,
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c1,
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c2,
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c3,
    input wire [3:0] pool_en,                                         // 池化使能信号，4bit 代表 4 块池化硬件
    
    /*output wire[3:0] pool_result_valid,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c0,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c1,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c2,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c3*/
    
    output wire[3:0] pool_result_valid,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c0,              // 直接输出 relu 激活后的结果
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c1,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c2,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c3,
    input wire[3:0] pool_o_width
    );
    
    
    
    pool_single_channel psc_0(
    .clk(clk),
    .rst_n(rst_n),
    .quant_o_data(quant_o_data_c0),
    .pool_single_channel_en(pool_en[0]),
    .pool_result_valid(pool_result_valid[0]),
    .pool_result_level1(pool_result_level1_c0),
    .pool_o_width(pool_o_width)
    );
    
    
    pool_single_channel psc_1(
    .clk(clk),
    .rst_n(rst_n),
    .quant_o_data(quant_o_data_c1),
    .pool_single_channel_en(pool_en[1]),
    .pool_result_valid(pool_result_valid[1]),
    .pool_result_level1(pool_result_level1_c1),
    .pool_o_width(pool_o_width)
    );
    
    
    pool_single_channel psc_2(
    .clk(clk),
    .rst_n(rst_n),
    .quant_o_data(quant_o_data_c2),
    .pool_single_channel_en(pool_en[2]),
    .pool_result_valid(pool_result_valid[2]),
    .pool_result_level1(pool_result_level1_c2),
    .pool_o_width(pool_o_width)
    );
    
    
    pool_single_channel psc_3(
    .clk(clk),
    .rst_n(rst_n),
    .quant_o_data(quant_o_data_c3),
    .pool_single_channel_en(pool_en[3]),
    .pool_result_valid(pool_result_valid[3]),
    .pool_result_level1(pool_result_level1_c3),
    .pool_o_width(pool_o_width)
    );
    
    
    
endmodule
