`include "defines.v"
// 卷积层
module conv_layer(
    input wire clk,
    input wire rst_n,
    input wire get_fm_in_go,
    input wire get_c2_fm_go,
    input wire[4:0] feature_in_width,
    input wire[4:0] feature_out_width,
    /*input wire[7:0] conv_in_channel,
    input wire[7:0] conv_out_channel,*/
    
    output wire signed [`CONV_OUT_BIT_WIDTH+6:0] add_tree_result_4_channel,
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_0,
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_1,
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_2,
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_3,
    output wire add_tree_result_valid,
    input wire[1:0] conv_compute_mode,
    output wire[`BIAS_MEM_ADDR_WIDTH-1:0] bias_addr,
    output wire bias_valid,
    
    output wire[4:0] feature_buffer_addr_b0,
    output wire[4:0] feature_buffer_addr_b1,
    
    output wire b0_low_flag,
    output wire [2:0] internal_row,
    output wire newline_flag,
    output wire direction_flag,
    
    input wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_0,
    input wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_1,
    input wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_2,
    input wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_3,
    
    input wire fc_compute_en,
    input wire[799:0] fc_mem_o_weight,
    input wire[799:0] fc_data_in,
    input wire load_fc_flag,
    
    input wire final_result_valid
    );
    
    
    
    /*conv_mode_ctl cmc_0(
    .conv_in_channel(conv_in_channel),
    .conv_out_channel(conv_out_channel),
    .get_fm_in_go(get_fm_in_go),
    .conv_compute_mode(conv_compute_mode)
    );*/
    
    
    wire conv_compute_en;
    wire load_fm_flag;
    wire[1:0] receptive_field_change_mode;
    wire[`FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_b0;
    wire[`FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_b1;
    wire[`WEIGHT_MEM_ADDR_WIDTH-1:0] weight_addr;
    
    /*wire b0_low_flag;
    wire[2:0] internal_row;
    wire newline_flag;
    wire direction_flag;*/
    
    
    
    conv_5_5_in_control c55_ic_0(
    .clk(clk),
    .rst_n(rst_n),
    .get_fm_in_go(get_fm_in_go),
    .feature_in_width(feature_in_width),
    .feature_out_width(feature_out_width),
    .conv_compute_mode(conv_compute_mode),
    .get_c2_fm_go(get_c2_fm_go),
    
    .conv_compute_en(conv_compute_en),
    .load_fm_flag(load_fm_flag),
    .receptive_field_change_mode(receptive_field_change_mode),
    .newline_flag(newline_flag),
    .direction_flag(direction_flag), 
    .b0_low_flag(b0_low_flag),
    .internal_row(internal_row),
    
    .feature_addr_b0(feature_addr_b0),
    .feature_addr_b1(feature_addr_b1),
    .weight_addr(weight_addr),
    .bias_addr(bias_addr),
    .bias_valid(bias_valid),
    
    .feature_buffer_addr_b0(feature_buffer_addr_b0),
    .feature_buffer_addr_b1(feature_buffer_addr_b1),
    .load_fc_flag(load_fc_flag),
    
    .final_result_valid(final_result_valid)
    );
    
    // 访问获取输入特征图和权重
    // wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_0, feature_in_1, feature_in_2, feature_in_3;
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_0;
    
    feature_in_access fia_0(
    .clk(clk),
    .rst_n(rst_n),
    .b0_low_flag(b0_low_flag),
    .internal_row(internal_row),
    .newline_flag(newline_flag),
    .direction_flag(direction_flag), 
    .feature_addr_b0(feature_addr_b0),
    .feature_addr_b1(feature_addr_b1),
    .feature_in_0(feature_in_0)/*,
    .feature_in_1(feature_in_1),
    .feature_in_2(feature_in_2),
    .feature_in_3(feature_in_3)*/
    );
    
    wire[`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in_0, weight_in_1, weight_in_2, weight_in_3;
    
    weight_mem_access wma_0(
    .clk(clk),
    .weight_addr(weight_addr),
    .weight_in_0(weight_in_0),
    .weight_in_1(weight_in_1),
    .weight_in_2(weight_in_2),
    .weight_in_3(weight_in_3)
    );
    
    // 4 通道卷积
    /*wire[`CONV_OUT_BIT_WIDTH+6:0] add_tree_result_4_channel;
    wire add_tree_result_valid;*/
    reg[`CONV_IN_BIT_WIDTH_F*5-1:0] conv_feature_in_0, conv_feature_in_1, conv_feature_in_2, conv_feature_in_3;
    always @ (*) begin
        case (conv_compute_mode)
            `CONV_COMPUTE_MODE_C1: begin                
                conv_feature_in_0 = feature_in_0;
                conv_feature_in_1 = feature_in_0;
                conv_feature_in_2 = feature_in_0;
                conv_feature_in_3 = feature_in_0;
            end
            `CONV_COMPUTE_MODE_C2: begin
                conv_feature_in_0 = feature_buffer_in_0;
                conv_feature_in_1 = feature_buffer_in_1;
                conv_feature_in_2 = feature_buffer_in_2;
                conv_feature_in_3 = feature_buffer_in_3;
            end
            default: begin
                conv_feature_in_0 = feature_in_0;
                conv_feature_in_1 = feature_in_0;
                conv_feature_in_2 = feature_in_0;
                conv_feature_in_3 = feature_in_0;
            end
        endcase
    end
    
    //wire[`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_0, add_tree_result_1, add_tree_result_2, add_tree_result_3;
    reg c4c_compute_en;
    always @ (*) begin
        case (conv_compute_mode)
            `CONV_COMPUTE_MODE_C1: begin                
                c4c_compute_en = conv_compute_en;
            end
            `CONV_COMPUTE_MODE_C2: begin
                c4c_compute_en = conv_compute_en;
            end
            `CONV_COMPUTE_MODE_FC1: begin
                c4c_compute_en = fc_compute_en;
            end
            `CONV_COMPUTE_MODE_FC2: begin
                c4c_compute_en = fc_compute_en;
            end
            default: begin
                c4c_compute_en = conv_compute_en;
            end
        endcase
    end
    
    conv_4_channel c4c_0(
    .clk(clk),
    .rst_n(rst_n),
    .c4c_compute_en(c4c_compute_en),
    .load_fm_flag(load_fm_flag),
    .receptive_field_change_mode(receptive_field_change_mode),
    .feature_in_0(conv_feature_in_0),
    .weight_in_0(weight_in_0),
    .feature_in_1(conv_feature_in_1),
    .weight_in_1(weight_in_1),
    .feature_in_2(conv_feature_in_2),
    .weight_in_2(weight_in_2),
    .feature_in_3(conv_feature_in_3),
    .weight_in_3(weight_in_3),
    .add_tree_result_4_channel(add_tree_result_4_channel),
    .add_tree_result_valid(add_tree_result_valid),
    .add_tree_result_0(add_tree_result_0),
    .add_tree_result_1(add_tree_result_1),
    .add_tree_result_2(add_tree_result_2),
    .add_tree_result_3(add_tree_result_3),
    
    .fc_mem_o_weight(fc_mem_o_weight),
    .fc_data_in(fc_data_in),
    .load_fc_flag(load_fc_flag)
    );
    
    // 需要有一个信号判定当前处于什么阶段，主要计数是否是这一层最后一次使用卷积硬件
    // 若是，则输出需要加 bias（可以放在conv_4_channel内完成），并且此时需要写入
    // 需要根据当前的计算循环次数、计算模式、counter_row、counter_col等等确定输出写入地址   
    // 考虑如何将输出模块和输入模块之间动态转换，是否也用状态机实现？
    // 另外，中间结果暂存模块是否需要参与这个转换过程也需要考虑
    // 还有，量化放在什么地方，怎么处理也需要考虑
    
    
    
    
    
    
    
    
    
    
    
    
    
    
endmodule
