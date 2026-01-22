`include "defines.v"
// 卷积乘法结果到加法树之间的缓冲器
module mul_add_buffer(
    input wire clk,
    input wire rst_n,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_0_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_1_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_2_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_3_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_4_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_5_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_6_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_7_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_8_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_9_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_10_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_11_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_12_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_13_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_14_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_15_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_16_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_17_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_18_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_19_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_20_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_21_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_22_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_23_i,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_24_i,
    input wire c4c_compute_en,
    
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_0_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_1_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_2_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_3_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_4_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_5_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_6_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_7_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_8_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_9_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_10_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_11_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_12_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_13_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_14_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_15_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_16_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_17_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_18_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_19_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_20_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_21_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_22_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_23_o,
    output reg signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_24_o,
    output reg add_tree_result_valid
    );
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_result_0_o <= 0;
            mul_result_1_o <= 0;
            mul_result_2_o <= 0;
            mul_result_3_o <= 0;
            mul_result_4_o <= 0;
            mul_result_5_o <= 0;
            mul_result_6_o <= 0;
            mul_result_7_o <= 0;
            mul_result_8_o <= 0;
            mul_result_9_o <= 0;
            mul_result_10_o <= 0;
            mul_result_11_o <= 0;
            mul_result_12_o <= 0;
            mul_result_13_o <= 0;
            mul_result_14_o <= 0;
            mul_result_15_o <= 0;
            mul_result_16_o <= 0;
            mul_result_17_o <= 0;
            mul_result_18_o <= 0;
            mul_result_19_o <= 0;
            mul_result_20_o <= 0;
            mul_result_21_o <= 0;
            mul_result_22_o <= 0;
            mul_result_23_o <= 0;
            mul_result_24_o <= 0; 
            add_tree_result_valid <= 0;
        end
        else begin
            mul_result_0_o <= mul_result_0_i;
            mul_result_1_o <= mul_result_1_i;
            mul_result_2_o <= mul_result_2_i;
            mul_result_3_o <= mul_result_3_i;
            mul_result_4_o <= mul_result_4_i;
            mul_result_5_o <= mul_result_5_i;
            mul_result_6_o <= mul_result_6_i;
            mul_result_7_o <= mul_result_7_i;
            mul_result_8_o <= mul_result_8_i;
            mul_result_9_o <= mul_result_9_i;
            mul_result_10_o <= mul_result_10_i;
            mul_result_11_o <= mul_result_11_i;
            mul_result_12_o <= mul_result_12_i;
            mul_result_13_o <= mul_result_13_i;
            mul_result_14_o <= mul_result_14_i;
            mul_result_15_o <= mul_result_15_i;
            mul_result_16_o <= mul_result_16_i;
            mul_result_17_o <= mul_result_17_i;
            mul_result_18_o <= mul_result_18_i;
            mul_result_19_o <= mul_result_19_i;
            mul_result_20_o <= mul_result_20_i;
            mul_result_21_o <= mul_result_21_i;
            mul_result_22_o <= mul_result_22_i;
            mul_result_23_o <= mul_result_23_i;
            mul_result_24_o <= mul_result_24_i; 
            add_tree_result_valid <= c4c_compute_en;
        end
    end
    
    
endmodule