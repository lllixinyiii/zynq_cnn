`include "defines.v"
// 这个模块包含了 4 个 5×5 卷积，用以同时处理 4 个通道

module conv_4_channel(
    input clk,
    input rst_n,
    //input [4:0] feature_out_width,
    input c4c_compute_en,
    input load_fm_flag,
    input [1:0] receptive_field_change_mode,
    input wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_0,      // 一次输入 一行（即5个）特征图像素
    input wire signed [`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in_0,       // 卷积核也一起一行一行读进来
    input wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_1,
    input wire signed [`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in_1,
    input wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_2,
    input wire signed [`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in_2,
    input wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_3,
    input wire signed [`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in_3,
    
    output wire signed [`CONV_OUT_BIT_WIDTH+6:0] add_tree_result_4_channel,
    output wire add_tree_result_valid,
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_0,
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_1,
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_2,
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_3,
    
    input wire[799:0] fc_mem_o_weight,
    input wire[799:0] fc_data_in,
    input wire load_fc_flag
    );
    
    // wire[`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_0;
    wire add_tree_result_valid_0;
    conv_5_5 c55_0(
        .clk(clk),
        .rst_n(rst_n),
        .feature_in(feature_in_0),
        .weight_in(weight_in_0),
        .c4c_compute_en(c4c_compute_en),
        .load_fm_flag(load_fm_flag),
        .receptive_field_change_mode(receptive_field_change_mode),
        .add_tree_result(add_tree_result_0),
        .add_tree_result_valid(add_tree_result_valid_0),
        
        .fc_mem_o_weight(fc_mem_o_weight[199:0]),
        .fc_data_in(fc_data_in[199:0]),
        .load_fc_flag(load_fc_flag)
    );
    
    // wire[`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_1;
    wire add_tree_result_valid_1;
    conv_5_5 c55_1(
        .clk(clk),
        .rst_n(rst_n),
        .feature_in(feature_in_1),
        .weight_in(weight_in_1),
        .c4c_compute_en(c4c_compute_en),
        .load_fm_flag(load_fm_flag),
        .receptive_field_change_mode(receptive_field_change_mode),
        .add_tree_result(add_tree_result_1),
        .add_tree_result_valid(add_tree_result_valid_1),
        
        .fc_mem_o_weight(fc_mem_o_weight[399:200]),
        .fc_data_in(fc_data_in[399:200]),
        .load_fc_flag(load_fc_flag)
    );
    
    // wire[`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_2;
    wire add_tree_result_valid_2;
    conv_5_5 c55_2(
        .clk(clk),
        .rst_n(rst_n),
        .feature_in(feature_in_2),
        .weight_in(weight_in_2),
        .c4c_compute_en(c4c_compute_en),
        .load_fm_flag(load_fm_flag),
        .receptive_field_change_mode(receptive_field_change_mode),
        .add_tree_result(add_tree_result_2),
        .add_tree_result_valid(add_tree_result_valid_2),
        
        .fc_mem_o_weight(fc_mem_o_weight[599:400]),
        .fc_data_in(fc_data_in[599:400]),
        .load_fc_flag(load_fc_flag)
    );
    
    
    wire add_tree_result_valid_3;
    conv_5_5 c55_3(
        .clk(clk),
        .rst_n(rst_n),
        .feature_in(feature_in_3),
        .weight_in(weight_in_3),
        .c4c_compute_en(c4c_compute_en),
        .load_fm_flag(load_fm_flag),
        .receptive_field_change_mode(receptive_field_change_mode),
        .add_tree_result(add_tree_result_3),
        .add_tree_result_valid(add_tree_result_valid_3),
        
        .fc_mem_o_weight(fc_mem_o_weight[799:600]),
        .fc_data_in(fc_data_in[799:600]),
        .load_fc_flag(load_fc_flag)
    );
    
    wire signed [`CONV_OUT_BIT_WIDTH+5:0] add_tree_result_2_channel_0;
    wire signed [`CONV_OUT_BIT_WIDTH+5:0] add_tree_result_2_channel_1;        
    assign add_tree_result_2_channel_0 = add_tree_result_0 + add_tree_result_1;
    assign add_tree_result_2_channel_1 = add_tree_result_2 + add_tree_result_3;

    
    assign add_tree_result_4_channel = add_tree_result_2_channel_0 + add_tree_result_2_channel_1;
    assign add_tree_result_valid = add_tree_result_valid_0 & add_tree_result_valid_1 & add_tree_result_valid_2 & add_tree_result_valid_3;
    
    
endmodule
