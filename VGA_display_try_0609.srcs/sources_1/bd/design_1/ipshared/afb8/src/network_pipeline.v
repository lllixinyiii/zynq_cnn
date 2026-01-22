`include "defines.v"
// 这个模块用于搭建大的流水线
module network_pipeline(
    input wire clk,
    input wire rst_n,
    input wire get_fm_in_go,
    input wire[1:0] conv_compute_mode,
    
    input wire get_c2_fm_go,
    
    input wire[4:0] feature_in_width,
    input wire[4:0] feature_out_width,
    /*input wire[7:0] conv_in_channel,
    input wire[7:0] conv_out_channel,*/
    input wire[3:0] pool_o_width,
    
    output wire pool_result_act_save_end,
    output wire c2_o_act_save_end,
    
    input wire load_fc1_go,
    
    output wire fc1_o_act_save_end,
    
    input wire load_fc2_go,
    
    output wire [3:0] final_result,
    output wire final_result_valid,
    
    output wire[`FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_b0,
    output wire[`FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_b1,
    input wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_bank_0_block_0,
    input wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_bank_0_block_1
    );
    
    wire[1:0] fc1_data_addr;
    wire[799:0] fc_data_in;
    
    
    
    wire[799:0] fc_mem_o_weight;
    wire fc_compute_en;
    wire load_fc_flag;
    fc_control_in fci_0(
    .clk(clk),
    .rst_n(rst_n),
    .conv_compute_mode(conv_compute_mode),
    .fc_mem_o_weight(fc_mem_o_weight),
    .fc1_data_addr(fc1_data_addr),
    .fc_compute_en(fc_compute_en),
    .load_fc1_go(load_fc1_go),
    .load_fc_flag(load_fc_flag),
    .load_fc2_go(load_fc2_go),
    .final_result_valid(final_result_valid)
    );
    
    wire signed [`CONV_OUT_BIT_WIDTH+6:0] add_tree_result_4_channel;
    wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_0;
    wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_1;
    wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_2;
    wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_3;
    wire add_tree_result_valid;
    //wire[1:0] conv_compute_mode;
    
    wire[`BIAS_MEM_ADDR_WIDTH-1:0] bias_addr;
    wire bias_valid;
    
    wire[4:0] feature_buffer_addr_b0;
    wire[4:0] feature_buffer_addr_b1;
    
    wire b0_low_flag;
    wire [2:0] internal_row;
    wire newline_flag;
    wire direction_flag;
    
    wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_0;
    wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_1;
    wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_2;
    wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_3;
    
    conv_layer cl_0(
    .clk(clk),
    .rst_n(rst_n),
    .get_fm_in_go(get_fm_in_go),
    .get_c2_fm_go(get_c2_fm_go),
    .feature_in_width(feature_in_width),
    .feature_out_width(feature_out_width),
    /*.conv_in_channel(conv_in_channel),
    .conv_out_channel(conv_out_channel),*/
    
    .add_tree_result_4_channel(add_tree_result_4_channel),
    .add_tree_result_0(add_tree_result_0),
    .add_tree_result_1(add_tree_result_1),
    .add_tree_result_2(add_tree_result_2),
    .add_tree_result_3(add_tree_result_3),
    .add_tree_result_valid(add_tree_result_valid),
    .conv_compute_mode(conv_compute_mode),
    .bias_addr(bias_addr),
    .bias_valid(bias_valid),
    
    .feature_buffer_addr_b0(feature_buffer_addr_b0),
    .feature_buffer_addr_b1(feature_buffer_addr_b1),
    
    .b0_low_flag(b0_low_flag),
    .internal_row(internal_row),
    .newline_flag(newline_flag),
    .direction_flag(direction_flag),
    
    .feature_buffer_in_0(feature_buffer_in_0),
    .feature_buffer_in_1(feature_buffer_in_1),
    .feature_buffer_in_2(feature_buffer_in_2),
    .feature_buffer_in_3(feature_buffer_in_3),
    
    .fc_compute_en(fc_compute_en),
    .fc_mem_o_weight(fc_mem_o_weight),
    .fc_data_in(fc_data_in),
    .load_fc_flag(load_fc_flag),
    .final_result_valid(final_result_valid),
    
    .feature_addr_b0(feature_addr_b0),
    .feature_addr_b1(feature_addr_b1),
    
    .feature_bank_0_block_0(feature_bank_0_block_0),
    .feature_bank_0_block_1(feature_bank_0_block_1)
    );
    
    
    wire[`CONV_IN_BIT_WIDTH_B-1:0] bias_data;
    bias_mem_access bma_0(
    .clk(clk),
    .bias_addr(bias_addr),
    .bias_in_0(bias_data)
    );
    
    
    wire signed [31:0] conv_result_channel_0;
    wire signed [31:0] conv_result_channel_1;
    wire signed [31:0] conv_result_channel_2;
    wire signed [31:0] conv_result_channel_3;
    wire [3:0] cmr_result_valid;
    conv_mid_result cmr_0(
    .clk(clk),
    .rst_n(rst_n),
    .conv_compute_mode(conv_compute_mode),
    .add_tree_result_4_channel(add_tree_result_4_channel),
    .add_tree_result_0(add_tree_result_0),
    .add_tree_result_1(add_tree_result_1),
    .add_tree_result_2(add_tree_result_2),
    .add_tree_result_3(add_tree_result_3),
    .add_tree_result_valid(add_tree_result_valid),
    
    .bias_data(bias_data),
    .bias_valid(bias_valid),
    
    .conv_result_channel_0(conv_result_channel_0),
    .conv_result_channel_1(conv_result_channel_1),
    .conv_result_channel_2(conv_result_channel_2),
    .conv_result_channel_3(conv_result_channel_3),
    .cmr_result_valid(cmr_result_valid)
    );
    
    wire find_final_result_en;                  // 这个信号表示当前在 FC2 阶段，要求最终结果了
    assign find_final_result_en = (conv_compute_mode == `CONV_COMPUTE_MODE_FC2) ? cmr_result_valid[0] : 1'b0;
    find_final_result ffr_0(
    .clk(clk),
    .rst_n(rst_n),
    .find_final_result_en(find_final_result_en),
    .conv_result_channel_0(conv_result_channel_0),
    .final_result(final_result),
    .final_result_valid(final_result_valid)
    );
    
    
    
    
    wire [3:0] quant_en;
    assign quant_en = (conv_compute_mode != `CONV_COMPUTE_MODE_FC2) ? cmr_result_valid : 4'b0;
    
    wire [3:0] quant_valid;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c0;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c1;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c2;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data_c3;
    quantization_layer ql_0(
    .clk(clk),
    .rst_n(rst_n),
    .conv_result_channel_0(conv_result_channel_0),
    .conv_result_channel_1(conv_result_channel_1),
    .conv_result_channel_2(conv_result_channel_2),
    .conv_result_channel_3(conv_result_channel_3),
    .quant_en(quant_en),
    
    .quant_valid(quant_valid),
    .quant_o_data_c0(quant_o_data_c0),
    .quant_o_data_c1(quant_o_data_c1),
    .quant_o_data_c2(quant_o_data_c2),
    .quant_o_data_c3(quant_o_data_c3),
    .conv_compute_mode(conv_compute_mode)
    );
    
    
    
    // 直接输出 relu 激活后的结果
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c0;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c1;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c2;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1_c3;
    wire [3:0] pool_result_valid;
    
    wire[3:0] pool_en;
    assign pool_en = (!conv_compute_mode[1]) ? quant_valid : 4'b0000;
    
    pool_layer pl_0(
    .clk(clk),
    .rst_n(rst_n),
    .quant_o_data_c0(quant_o_data_c0),
    .quant_o_data_c1(quant_o_data_c1),
    .quant_o_data_c2(quant_o_data_c2),
    .quant_o_data_c3(quant_o_data_c3),
    .pool_en(pool_en),
    
    .pool_result_valid(pool_result_valid),
    .pool_result_level1_c0(pool_result_level1_c0),
    .pool_result_level1_c1(pool_result_level1_c1),
    .pool_result_level1_c2(pool_result_level1_c2),
    .pool_result_level1_c3(pool_result_level1_c3),
    .pool_o_width(pool_o_width)
    );
    
    wire[`CONV_IN_BIT_WIDTH_F-1:0] act_data_in_c0;
    assign act_data_in_c0 = (conv_compute_mode[1]) ? quant_o_data_c0 : pool_result_level1_c0;

    
    // 直接输出 relu 激活后的结果
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_result_c0;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_result_c1;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_result_c2;
    wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_result_c3;
    reg [3:0] act_result_valid;
    
    activation_unit au_0(
    .act_in(act_data_in_c0),
    .act_result(act_result_c0)
    );
    
    activation_unit au_1(
    .act_in(pool_result_level1_c1),
    .act_result(act_result_c1)
    );
    
    activation_unit au_2(
    .act_in(pool_result_level1_c2),
    .act_result(act_result_c2)
    );
    
    activation_unit au_3(
    .act_in(pool_result_level1_c3),
    .act_result(act_result_c3)
    );
    
    always @ (*) begin
        case (conv_compute_mode)
            `CONV_COMPUTE_MODE_C1: begin
                act_result_valid <= pool_result_valid;
            end
            `CONV_COMPUTE_MODE_C2: begin
                act_result_valid <= pool_result_valid;
            end
            `CONV_COMPUTE_MODE_FC1: begin
                act_result_valid <= quant_valid;
            end
            `CONV_COMPUTE_MODE_FC2: begin
                act_result_valid <= quant_valid;
            end
            default: begin
                act_result_valid <= pool_result_valid;
            end
        endcase
    end
    
    
    
    save_layer_result slr_0(
    .clk(clk),
    .rst_n(rst_n),
    .act_result_c0(act_result_c0),
    .act_result_c1(act_result_c1),
    .act_result_c2(act_result_c2),
    .act_result_c3(act_result_c3),
    .act_result_valid(act_result_valid),
    .pool_o_width(pool_o_width),
    .conv_compute_mode(conv_compute_mode),
    .pool_result_act_save_end(pool_result_act_save_end),
    
    .feature_buffer_addr_b0(feature_buffer_addr_b0),
    .feature_buffer_addr_b1(feature_buffer_addr_b1),
    .internal_row(internal_row),
    .b0_low_flag(b0_low_flag),
    .direction_flag(direction_flag),
    .newline_flag(newline_flag),
    .feature_buffer_in_0(feature_buffer_in_0),
    .feature_buffer_in_1(feature_buffer_in_1),
    .feature_buffer_in_2(feature_buffer_in_2),
    .feature_buffer_in_3(feature_buffer_in_3),
    
    .c2_o_act_save_end(c2_o_act_save_end),
    
    .fc1_data_addr(fc1_data_addr),
    .fc_data_in(fc_data_in),
    
    .fc1_o_act_save_end(fc1_o_act_save_end),
    .final_result_valid(final_result_valid)
    );
    
    
    
    
endmodule
