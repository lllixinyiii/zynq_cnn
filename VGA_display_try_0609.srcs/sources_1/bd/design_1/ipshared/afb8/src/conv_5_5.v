// 这个模块完成 1 个 5×5 的卷积（1个感受野）
`include "defines.v"
module conv_5_5 //#(
    //parameter FEATURE_MAP_WIDTH = 28,
    //parameter FEATURE_MAP_HEIGHT = 28,
    //parameter STRIDE = 1,
    //parameter KERNEL_SIZE = 5,
    //parameter O_FEATURE_MAP_WIDTH = 24,      // 也可以计算得到，感觉直接给更方便
    //parameter O_FEATURE_MAP_HEIGHT = 24
    //)
    (
    input wire clk,
    input wire rst_n,
     
    //input wire[4:0] feature_in_width,
    //input wire[4:0] feature_out_width,
    
    input wire signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in,      // 一次输入 一行（即5个）特征图像素
    input wire signed [`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in,       // 卷积核也一起一行一行读进来
    
    input wire c4c_compute_en,
    input wire load_fm_flag,
    input wire[1:0] receptive_field_change_mode,            // 感受野切换模式   00：从左往右   01：从上往下    10：从右往左
    
    output wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result,   // 输出的卷积结果（加法树结果）
    output wire add_tree_result_valid,                       // 表示输出的 add_tree_result 是否有效
    
    input wire[199:0] fc_mem_o_weight,
    input wire[199:0] fc_data_in,
    input wire load_fc_flag
    );
    
    localparam KERNEL_SIZE = 5;
    
    wire signed [`CONV_OUT_BIT_WIDTH-1:0] mult_result_i[0:`MULT_5_5-1];
    wire signed [`CONV_OUT_BIT_WIDTH-1:0] mult_result_o[0:`MULT_5_5-1];
    
    
/*    reg [`CONV_IN_BIT_WIDTH_F-1:0] conv_in_feature[0:`MULT_5_5-1];      // MAC PE 的输入特征图*/
    reg signed [`CONV_IN_BIT_WIDTH_F-1:0] conv_in_feature[0:`MULT_5_5-1];      // MAC PE 的输入特征图
    reg signed [`CONV_IN_BIT_WIDTH_W-1:0] conv_in_weight[0:`MULT_5_5-1];       // MAC PE 的输入卷积核
    
    
    // 读取的部分特征图数据写入感受野
    integer i,j;
    always @ (posedge clk or negedge rst_n) begin           // 按一列一列排布，         TODO：看RTL级
        if (!rst_n) begin
            for (i = 0; i <= (`MULT_5_5-1); i = i + 1) begin // 自动遍历所有元素
                conv_in_feature[i] <= 0;
            end
        end
        else if (load_fc_flag) begin
            conv_in_feature[0]  <= fc_data_in[7:0];
            conv_in_feature[1]  <= fc_data_in[15:8];    
            conv_in_feature[2]  <= fc_data_in[23:16];   
            conv_in_feature[3]  <= fc_data_in[31:24];
            conv_in_feature[4]  <= fc_data_in[39:32];   
            conv_in_feature[5]  <= fc_data_in[47:40];   
            conv_in_feature[6]  <= fc_data_in[55:48];   
            conv_in_feature[7]  <= fc_data_in[63:56];   
            conv_in_feature[8]  <= fc_data_in[71:64];   
            conv_in_feature[9]  <= fc_data_in[79:72];   
            conv_in_feature[10] <= fc_data_in[87:80];   
            conv_in_feature[11] <= fc_data_in[95:88];   
            conv_in_feature[12] <= fc_data_in[103:96];  
            conv_in_feature[13] <= fc_data_in[111:104]; 
            conv_in_feature[14] <= fc_data_in[119:112]; 
            conv_in_feature[15] <= fc_data_in[127:120]; 
            conv_in_feature[16] <= fc_data_in[135:128]; 
            conv_in_feature[17] <= fc_data_in[143:136]; 
            conv_in_feature[18] <= fc_data_in[151:144]; 
            conv_in_feature[19] <= fc_data_in[159:152]; 
            conv_in_feature[20] <= fc_data_in[167:160]; 
            conv_in_feature[21] <= fc_data_in[175:168]; 
            conv_in_feature[22] <= fc_data_in[183:176]; 
            conv_in_feature[23] <= fc_data_in[191:184]; 
            conv_in_feature[24] <= fc_data_in[199:192];
        end
        else if(load_fm_flag) begin         // 是否要用状态机？ 00：从左往右   01：从上往下    10：从右往左
            case (receptive_field_change_mode)
                2'b00: begin                        // 从左往右
                    conv_in_feature[0] <= conv_in_feature[1];
                    conv_in_feature[1] <= conv_in_feature[2];
                    conv_in_feature[2] <= conv_in_feature[3];
                    conv_in_feature[3] <= conv_in_feature[4];
                    conv_in_feature[4] <= feature_in[`CONV_IN_BIT_WIDTH_F-1:0];
                    conv_in_feature[5] <= conv_in_feature[6];
                    conv_in_feature[6] <= conv_in_feature[7];
                    conv_in_feature[7] <= conv_in_feature[8];
                    conv_in_feature[8] <= conv_in_feature[9];
                    conv_in_feature[9] <= feature_in[`CONV_IN_BIT_WIDTH_F*2-1:`CONV_IN_BIT_WIDTH_F];
                    conv_in_feature[10] <= conv_in_feature[11];
                    conv_in_feature[11] <= conv_in_feature[12];
                    conv_in_feature[12] <= conv_in_feature[13];
                    conv_in_feature[13] <= conv_in_feature[14];
                    conv_in_feature[14] <= feature_in[`CONV_IN_BIT_WIDTH_F*3-1:`CONV_IN_BIT_WIDTH_F*2];
                    conv_in_feature[15] <= conv_in_feature[16];
                    conv_in_feature[16] <= conv_in_feature[17];
                    conv_in_feature[17] <= conv_in_feature[18];
                    conv_in_feature[18] <= conv_in_feature[19];
                    conv_in_feature[19] <= feature_in[`CONV_IN_BIT_WIDTH_F*4-1:`CONV_IN_BIT_WIDTH_F*3];
                    conv_in_feature[20] <= conv_in_feature[21];
                    conv_in_feature[21] <= conv_in_feature[22];
                    conv_in_feature[22] <= conv_in_feature[23];
                    conv_in_feature[23] <= conv_in_feature[24];
                    conv_in_feature[24] <= feature_in[`CONV_IN_BIT_WIDTH_F*5-1:`CONV_IN_BIT_WIDTH_F*4];  
                end
                2'b01: begin                // 从上往下
                    {conv_in_feature[20], conv_in_feature[21], conv_in_feature[22], conv_in_feature[23], conv_in_feature[24]} <= feature_in;
                            
                    for (j = 0; j < (`MULT_5_5-KERNEL_SIZE); j = j + 1) begin
                        conv_in_feature[j] <= conv_in_feature[j+KERNEL_SIZE];
                    end
                end
                2'b10: begin                // 10：从右往左
                    conv_in_feature[0] <= feature_in[`CONV_IN_BIT_WIDTH_F-1:0];
                    conv_in_feature[1] <= conv_in_feature[0];
                    conv_in_feature[2] <= conv_in_feature[1];
                    conv_in_feature[3] <= conv_in_feature[2];
                    conv_in_feature[4] <= conv_in_feature[3];
                    conv_in_feature[5] <= feature_in[`CONV_IN_BIT_WIDTH_F*2-1:`CONV_IN_BIT_WIDTH_F];
                    conv_in_feature[6] <= conv_in_feature[5];
                    conv_in_feature[7] <= conv_in_feature[6];
                    conv_in_feature[8] <= conv_in_feature[7];
                    conv_in_feature[9] <= conv_in_feature[8];
                    conv_in_feature[10] <= feature_in[`CONV_IN_BIT_WIDTH_F*3-1:`CONV_IN_BIT_WIDTH_F*2];
                    conv_in_feature[11] <= conv_in_feature[10];
                    conv_in_feature[12] <= conv_in_feature[11];
                    conv_in_feature[13] <= conv_in_feature[12];
                    conv_in_feature[14] <= conv_in_feature[13];
                    conv_in_feature[15] <= feature_in[`CONV_IN_BIT_WIDTH_F*4-1:`CONV_IN_BIT_WIDTH_F*3];
                    conv_in_feature[16] <= conv_in_feature[15];
                    conv_in_feature[17] <= conv_in_feature[16];
                    conv_in_feature[18] <= conv_in_feature[17];
                    conv_in_feature[19] <= conv_in_feature[18];
                    conv_in_feature[20] <= feature_in[`CONV_IN_BIT_WIDTH_F*5-1:`CONV_IN_BIT_WIDTH_F*4];
                    conv_in_feature[21] <= conv_in_feature[20];
                    conv_in_feature[22] <= conv_in_feature[21];
                    conv_in_feature[23] <= conv_in_feature[22];
                    conv_in_feature[24] <= conv_in_feature[23];  
                end
            endcase
        end
    end
    
    integer k;
    // 读取的卷积核
    always @ (posedge clk or negedge rst_n) begin           // 按一列一列排布，         TODO：看RTL级
        if (!rst_n) begin
            for (k = 0; k <= (`MULT_5_5-1); k = k + 1) begin // 自动遍历所有元素
                conv_in_weight[k] <= 0;
            end
        end
        else begin         // 卷积核就直接从左往右一列一列读吧......
            if (load_fc_flag) begin
                conv_in_weight[0]  <= fc_mem_o_weight[7:0];
                conv_in_weight[1]  <= fc_mem_o_weight[15:8];    
                conv_in_weight[2]  <= fc_mem_o_weight[23:16];   
                conv_in_weight[3]  <= fc_mem_o_weight[31:24];
                conv_in_weight[4]  <= fc_mem_o_weight[39:32];   
                conv_in_weight[5]  <= fc_mem_o_weight[47:40];   
                conv_in_weight[6]  <= fc_mem_o_weight[55:48];   
                conv_in_weight[7]  <= fc_mem_o_weight[63:56];   
                conv_in_weight[8]  <= fc_mem_o_weight[71:64];   
                conv_in_weight[9]  <= fc_mem_o_weight[79:72];   
                conv_in_weight[10] <= fc_mem_o_weight[87:80];   
                conv_in_weight[11] <= fc_mem_o_weight[95:88];   
                conv_in_weight[12] <= fc_mem_o_weight[103:96];  
                conv_in_weight[13] <= fc_mem_o_weight[111:104]; 
                conv_in_weight[14] <= fc_mem_o_weight[119:112]; 
                conv_in_weight[15] <= fc_mem_o_weight[127:120]; 
                conv_in_weight[16] <= fc_mem_o_weight[135:128]; 
                conv_in_weight[17] <= fc_mem_o_weight[143:136]; 
                conv_in_weight[18] <= fc_mem_o_weight[151:144]; 
                conv_in_weight[19] <= fc_mem_o_weight[159:152]; 
                conv_in_weight[20] <= fc_mem_o_weight[167:160]; 
                conv_in_weight[21] <= fc_mem_o_weight[175:168]; 
                conv_in_weight[22] <= fc_mem_o_weight[183:176]; 
                conv_in_weight[23] <= fc_mem_o_weight[191:184]; 
                conv_in_weight[24] <= fc_mem_o_weight[199:192];
            end
            else if(load_fm_flag && !c4c_compute_en) begin
                conv_in_weight[0] <= conv_in_weight[1];
                conv_in_weight[1] <= conv_in_weight[2];
                conv_in_weight[2] <= conv_in_weight[3];
                conv_in_weight[3] <= conv_in_weight[4];
                conv_in_weight[4] <= weight_in[`CONV_IN_BIT_WIDTH_W-1:0];
                conv_in_weight[5] <= conv_in_weight[6];
                conv_in_weight[6] <= conv_in_weight[7];
                conv_in_weight[7] <= conv_in_weight[8];
                conv_in_weight[8] <= conv_in_weight[9];
                conv_in_weight[9] <= weight_in[`CONV_IN_BIT_WIDTH_W*2-1:`CONV_IN_BIT_WIDTH_W];
                conv_in_weight[10] <= conv_in_weight[11];
                conv_in_weight[11] <= conv_in_weight[12];
                conv_in_weight[12] <= conv_in_weight[13];
                conv_in_weight[13] <= conv_in_weight[14];
                conv_in_weight[14] <= weight_in[`CONV_IN_BIT_WIDTH_W*3-1:`CONV_IN_BIT_WIDTH_W*2];
                conv_in_weight[15] <= conv_in_weight[16];
                conv_in_weight[16] <= conv_in_weight[17];
                conv_in_weight[17] <= conv_in_weight[18];
                conv_in_weight[18] <= conv_in_weight[19];
                conv_in_weight[19] <= weight_in[`CONV_IN_BIT_WIDTH_W*4-1:`CONV_IN_BIT_WIDTH_W*3];
                conv_in_weight[20] <= conv_in_weight[21];
                conv_in_weight[21] <= conv_in_weight[22];
                conv_in_weight[22] <= conv_in_weight[23];
                conv_in_weight[23] <= conv_in_weight[24];
                conv_in_weight[24] <= weight_in[`CONV_IN_BIT_WIDTH_W*5-1:`CONV_IN_BIT_WIDTH_W*4];  
            end
        end
    end
    
    genvar u;
    generate
        for (u = 0; u < `MULT_5_5; u = u + 1) begin: multiply
            conv_mult cm0(.feature_map_pixel(conv_in_feature[u]), 
                          .conv_kernel_pixel(conv_in_weight[u]), 
                          .mult_result(mult_result_i[u]));
        end
    endgenerate
    
    // 乘法器和加法器之间的缓冲器
    mul_add_buffer mab0(
        .clk(clk),
        .rst_n(rst_n),
        .mul_result_0_i(mult_result_i[0]),
        .mul_result_1_i(mult_result_i[1]),
        .mul_result_2_i(mult_result_i[2]),
        .mul_result_3_i(mult_result_i[3]),
        .mul_result_4_i(mult_result_i[4]),
        .mul_result_5_i(mult_result_i[5]),
        .mul_result_6_i(mult_result_i[6]),
        .mul_result_7_i(mult_result_i[7]),
        .mul_result_8_i(mult_result_i[8]),
        .mul_result_9_i(mult_result_i[9]),
        .mul_result_10_i(mult_result_i[10]),
        .mul_result_11_i(mult_result_i[11]),
        .mul_result_12_i(mult_result_i[12]),
        .mul_result_13_i(mult_result_i[13]),
        .mul_result_14_i(mult_result_i[14]),
        .mul_result_15_i(mult_result_i[15]),
        .mul_result_16_i(mult_result_i[16]),
        .mul_result_17_i(mult_result_i[17]),
        .mul_result_18_i(mult_result_i[18]),
        .mul_result_19_i(mult_result_i[19]),
        .mul_result_20_i(mult_result_i[20]),
        .mul_result_21_i(mult_result_i[21]),
        .mul_result_22_i(mult_result_i[22]),
        .mul_result_23_i(mult_result_i[23]),
        .mul_result_24_i(mult_result_i[24]),
        .c4c_compute_en(c4c_compute_en),
        
        .mul_result_0_o(mult_result_o[0]),
        .mul_result_1_o(mult_result_o[1]),
        .mul_result_2_o(mult_result_o[2]),
        .mul_result_3_o(mult_result_o[3]),
        .mul_result_4_o(mult_result_o[4]),
        .mul_result_5_o(mult_result_o[5]),
        .mul_result_6_o(mult_result_o[6]),
        .mul_result_7_o(mult_result_o[7]),
        .mul_result_8_o(mult_result_o[8]),
        .mul_result_9_o(mult_result_o[9]),
        .mul_result_10_o(mult_result_o[10]),
        .mul_result_11_o(mult_result_o[11]),
        .mul_result_12_o(mult_result_o[12]),
        .mul_result_13_o(mult_result_o[13]),
        .mul_result_14_o(mult_result_o[14]),
        .mul_result_15_o(mult_result_o[15]),
        .mul_result_16_o(mult_result_o[16]),
        .mul_result_17_o(mult_result_o[17]),
        .mul_result_18_o(mult_result_o[18]),
        .mul_result_19_o(mult_result_o[19]),
        .mul_result_20_o(mult_result_o[20]),
        .mul_result_21_o(mult_result_o[21]),
        .mul_result_22_o(mult_result_o[22]),
        .mul_result_23_o(mult_result_o[23]),
        .mul_result_24_o(mult_result_o[24]),
        .add_tree_result_valid(add_tree_result_valid));
    
    
    conv_5_5_add_tree cat_5_5(
        .mul_result_0_o(mult_result_o[0]),
        .mul_result_1_o(mult_result_o[1]),
        .mul_result_2_o(mult_result_o[2]),
        .mul_result_3_o(mult_result_o[3]),
        .mul_result_4_o(mult_result_o[4]),
        .mul_result_5_o(mult_result_o[5]),
        .mul_result_6_o(mult_result_o[6]),
        .mul_result_7_o(mult_result_o[7]),
        .mul_result_8_o(mult_result_o[8]),
        .mul_result_9_o(mult_result_o[9]),
        .mul_result_10_o(mult_result_o[10]),
        .mul_result_11_o(mult_result_o[11]),
        .mul_result_12_o(mult_result_o[12]),
        .mul_result_13_o(mult_result_o[13]),
        .mul_result_14_o(mult_result_o[14]),
        .mul_result_15_o(mult_result_o[15]),
        .mul_result_16_o(mult_result_o[16]),
        .mul_result_17_o(mult_result_o[17]),
        .mul_result_18_o(mult_result_o[18]),
        .mul_result_19_o(mult_result_o[19]),
        .mul_result_20_o(mult_result_o[20]),
        .mul_result_21_o(mult_result_o[21]),
        .mul_result_22_o(mult_result_o[22]),
        .mul_result_23_o(mult_result_o[23]),
        .mul_result_24_o(mult_result_o[24]),
        .add_tree_result(add_tree_result)
    );
    
    
    
    
endmodule
