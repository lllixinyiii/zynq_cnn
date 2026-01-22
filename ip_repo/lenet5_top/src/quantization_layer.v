`include "defines.v"

module quantization_layer(
    input wire clk,
    input wire rst_n,
    input wire signed [31:0] conv_result_channel_0,
    input wire signed [31:0] conv_result_channel_1,
    input wire signed [31:0] conv_result_channel_2,
    input wire signed [31:0] conv_result_channel_3,
    input wire [3:0] quant_en,                                         // 量化使能信号，4bit 代表 4 块量化硬件
    
    output wire [3:0] quant_valid,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c0,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c1,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c2,
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c3,
    
    input wire[1:0] conv_compute_mode
    );
    
    quantization_single_channel qsc_0(
    .clk(clk),
    .rst_n(rst_n),
    .conv_o_data(conv_result_channel_0),
    .quant_en(quant_en[0]),
    .quant_o_data(quant_o_data_c0),
    .quant_valid(quant_valid[0]),
    .conv_compute_mode(conv_compute_mode)
    );
    
    
    quantization_single_channel qsc_1(
    .clk(clk),
    .rst_n(rst_n),
    .conv_o_data(conv_result_channel_1),
    .quant_en(quant_en[1]),
    .quant_o_data(quant_o_data_c1),
    .quant_valid(quant_valid[1]),
    .conv_compute_mode(conv_compute_mode)
    );
    
    
    quantization_single_channel qsc_2(
    .clk(clk),
    .rst_n(rst_n),
    .conv_o_data(conv_result_channel_2),
    .quant_en(quant_en[2]),
    .quant_o_data(quant_o_data_c2),
    .quant_valid(quant_valid[2]),
    .conv_compute_mode(conv_compute_mode)
    );
    
    
    quantization_single_channel qsc_3(
    .clk(clk),
    .rst_n(rst_n),
    .conv_o_data(conv_result_channel_3),
    .quant_en(quant_en[3]),
    .quant_o_data(quant_o_data_c3),
    .quant_valid(quant_valid[3]),
    .conv_compute_mode(conv_compute_mode)
    );
endmodule
