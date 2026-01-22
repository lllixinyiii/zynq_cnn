`include "defines.v"
module lenet5_top(
    input wire clk,
    input wire rst_n,
    input wire lenet5_go,
    output wire [3:0] final_result,
    output wire final_result_valid
    );
    
    wire pool_act_end;
    wire get_fm_in_go;
    wire get_c2_fm_go;
    wire [1:0] conv_compute_mode;
    wire [4:0] feature_in_width;
    wire [4:0] feature_out_width;
    wire [3:0] pool_o_width;
    
    wire c2_o_act_save_end;
    wire load_fc1_go;
    
    wire fc1_o_act_save_end;
    
    wire load_fc2_go;
    lenet5_state_machine lsm_0(
    .clk(clk),
    .rst_n(rst_n),
    .lenet5_go(lenet5_go),
    .pool_act_end(pool_act_end),
    .get_fm_in_go(get_fm_in_go),
    .conv_compute_mode(conv_compute_mode),
    .get_c2_fm_go(get_c2_fm_go),
    .feature_in_width(feature_in_width),
    .feature_out_width(feature_out_width),
    .pool_o_width(pool_o_width),
    .c2_o_act_save_end(c2_o_act_save_end),
    .load_fc1_go(load_fc1_go),
    .fc1_o_act_save_end(fc1_o_act_save_end),
    .load_fc2_go(load_fc2_go),
    .final_result_valid(final_result_valid)
    );
    
    
    network_pipeline np_0(
    .clk(clk),
    .rst_n(rst_n),
    .get_fm_in_go(get_fm_in_go),
    .conv_compute_mode(conv_compute_mode),
    .get_c2_fm_go(get_c2_fm_go),
    .feature_in_width(feature_in_width),
    .feature_out_width(feature_out_width),
    /*.conv_in_channel(1),
    .conv_out_channel(4),*/
    .pool_o_width(pool_o_width),
    .pool_result_act_save_end(pool_act_end),
    .c2_o_act_save_end(c2_o_act_save_end),
    .load_fc1_go(load_fc1_go),
    .fc1_o_act_save_end(fc1_o_act_save_end),
    .load_fc2_go(load_fc2_go),
    .final_result(final_result),
    .final_result_valid(final_result_valid)
    );
    
endmodule
