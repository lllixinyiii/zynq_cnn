`include "defines.v"
// 这是一个在一个时钟周期内计算完的加法树
module conv_5_5_add_tree(
    // 25 个乘法器的计算结果
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_0_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_1_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_2_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_3_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_4_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_5_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_6_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_7_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_8_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_9_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_10_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_11_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_12_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_13_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_14_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_15_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_16_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_17_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_18_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_19_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_20_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_21_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_22_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_23_o,
    input wire signed [`CONV_OUT_BIT_WIDTH-1:0] mul_result_24_o,
    
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result            // 这里位宽变了，因为考虑到两个 20bit 相加最大情况可能 ×2
    );
    
    // 第 1 层加法树
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_0;              // 这里位宽变了，因为考虑到两个 16bit 相加最大情况可能 ×2
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_1;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_2;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_3;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_4;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_5;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_6;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_7;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_8;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_9;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_10;
    wire signed [`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_11;
    //wire[`CONV_OUT_BIT_WIDTH:0] add_tree_result_0_12;
    
    assign add_tree_result_0_0 = mul_result_0_o + mul_result_1_o;
    assign add_tree_result_0_1 = mul_result_2_o + mul_result_3_o;
    assign add_tree_result_0_2 = mul_result_4_o + mul_result_5_o;
    assign add_tree_result_0_3 = mul_result_6_o + mul_result_7_o;
    assign add_tree_result_0_4 = mul_result_8_o + mul_result_9_o;
    assign add_tree_result_0_5 = mul_result_10_o + mul_result_11_o;
    assign add_tree_result_0_6 = mul_result_12_o + mul_result_13_o;
    assign add_tree_result_0_7 = mul_result_14_o + mul_result_15_o;
    assign add_tree_result_0_8 = mul_result_16_o + mul_result_17_o;
    assign add_tree_result_0_9 = mul_result_18_o + mul_result_19_o;
    assign add_tree_result_0_10 = mul_result_20_o + mul_result_21_o;
    assign add_tree_result_0_11 = mul_result_22_o + mul_result_23_o;
    //assign add_tree_result_0_12 = mul_result_24_o;
    
    
    // 第 2 层加法树
    wire signed [`CONV_OUT_BIT_WIDTH+1:0] add_tree_result_1_0;              // 这里位宽变了，因为考虑到两个 17bit 相加最大情况可能 ×2
    wire signed [`CONV_OUT_BIT_WIDTH+1:0] add_tree_result_1_1;
    wire signed [`CONV_OUT_BIT_WIDTH+1:0] add_tree_result_1_2;
    wire signed [`CONV_OUT_BIT_WIDTH+1:0] add_tree_result_1_3;
    wire signed [`CONV_OUT_BIT_WIDTH+1:0] add_tree_result_1_4;
    wire signed [`CONV_OUT_BIT_WIDTH+1:0] add_tree_result_1_5;
    //wire[`CONV_OUT_BIT_WIDTH+1:0] add_tree_result_1_6;
    
    assign add_tree_result_1_0 = add_tree_result_0_0 + add_tree_result_0_1;
    assign add_tree_result_1_1 = add_tree_result_0_2 + add_tree_result_0_3;
    assign add_tree_result_1_2 = add_tree_result_0_4 + add_tree_result_0_5;
    assign add_tree_result_1_3 = add_tree_result_0_6 + add_tree_result_0_7;
    assign add_tree_result_1_4 = add_tree_result_0_8 + add_tree_result_0_9;
    assign add_tree_result_1_5 = add_tree_result_0_10 + add_tree_result_0_11;
    //assign add_tree_result_1_6 = add_tree_result_0_12;
    
    // 第 3 层加法树
    wire signed [`CONV_OUT_BIT_WIDTH+2:0] add_tree_result_2_0;              // 这里位宽变了，因为考虑到两个 18bit 相加最大情况可能 ×2
    wire signed [`CONV_OUT_BIT_WIDTH+2:0] add_tree_result_2_1;
    wire signed [`CONV_OUT_BIT_WIDTH+2:0] add_tree_result_2_2;
    wire signed [`CONV_OUT_BIT_WIDTH+2:0] add_tree_result_2_3;
    wire signed [`CONV_OUT_BIT_WIDTH+2:0] add_tree_result_2_4;
    
    assign add_tree_result_2_0 = add_tree_result_1_0 + add_tree_result_1_1;
    assign add_tree_result_2_1 = add_tree_result_1_2 + add_tree_result_1_3;
    assign add_tree_result_2_2 = add_tree_result_1_4 + add_tree_result_1_5;
    
    // 第 4 层加法树
    wire signed [`CONV_OUT_BIT_WIDTH+3:0] add_tree_result_3_0;              // 这里位宽变了，因为考虑到两个 19bit 相加最大情况可能 ×2
    wire signed [`CONV_OUT_BIT_WIDTH+3:0] add_tree_result_3_1;
    
    assign add_tree_result_3_0 = add_tree_result_2_0 + add_tree_result_2_1;
    assign add_tree_result_3_1 = add_tree_result_2_2 + mul_result_24_o;
    
    // 第 5 层加法树
    assign add_tree_result = add_tree_result_3_0 + add_tree_result_3_1;
    
    
    
endmodule
