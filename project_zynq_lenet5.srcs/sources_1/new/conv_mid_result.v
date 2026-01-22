`include "defines.v"
// 这个模块要处理卷积中间结果，无论从暂存的 BRAM 取数相加还是存暂存的 BRAM 还是跳过都要经过这里
// 现在暂时不用暂存，先把结果输出到这然后扩展到 32bit 然后再输出到池化模块，再接量化和激活
// 偏置 bias 也放在这个里面加，偏置 bias 是一个输出通道一个

module conv_mid_result(
    input clk,
    input rst_n,
    input wire[1:0] conv_compute_mode,                  // 00: 计算 4 输入通道         01：输入通道 1，输出通道 4，硬件同时计算 4 个输出通道
    input wire signed [`CONV_OUT_BIT_WIDTH+6:0] add_tree_result_4_channel,
    input wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_0,
    input wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_1,
    input wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_2,
    input wire signed [`CONV_OUT_BIT_WIDTH+4:0] add_tree_result_3,
    input wire add_tree_result_valid,
    
    input wire signed [`CONV_IN_BIT_WIDTH_B-1:0] bias_data,                 // 我想在这个模块给它加上 bias
    input wire bias_valid,
    
    output reg signed [31:0] conv_result_channel_0,
    output reg signed [31:0] conv_result_channel_1,
    output reg signed [31:0] conv_result_channel_2,
    output reg signed [31:0] conv_result_channel_3,
    output reg[3:0] cmr_result_valid                                         // 量化使能信号，4bit 代表 4 块量化硬件
    
    );
    
    // 考虑存放 bias_data
    reg[1:0] tag_load_bias_buffer;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tag_load_bias_buffer <= 2'b00;
        end
        else begin
            tag_load_bias_buffer <= (bias_valid) ? (tag_load_bias_buffer + 1'b1) : tag_load_bias_buffer;
        end
    end
    
    reg signed [`CONV_IN_BIT_WIDTH_B-1:0] bias_data_buffer[0:3];
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bias_data_buffer[0] <= 0;
            bias_data_buffer[1] <= 0;
            bias_data_buffer[2] <= 0;
            bias_data_buffer[3] <= 0;
        end
        else if (bias_valid) begin
            case (conv_compute_mode)
            `CONV_COMPUTE_MODE_C1: begin
                bias_data_buffer[tag_load_bias_buffer] <= bias_data;
            end
            `CONV_COMPUTE_MODE_C2: begin
                bias_data_buffer[0] <= bias_data;
            end
            default: begin
                bias_data_buffer[0] <= bias_data;
            end
        endcase
        end
    end
    
    reg[1:0] counter_fc1_channel_end;                    // 这个计数器判定什么时候全连接层1一个输出通道计算完成，要3个时钟
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_fc1_channel_end <= 0;
        end
        else if ((conv_compute_mode == `CONV_COMPUTE_MODE_FC1) && add_tree_result_valid) begin
            counter_fc1_channel_end <= (counter_fc1_channel_end == 2) ? 0 : (counter_fc1_channel_end + 1);
        end
    end 
    
    reg signed [31:0] fc_o_data_temp;                   // 暂存FC输出结果。3个时钟要全部加起来
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fc_o_data_temp <= 0;
        end
        else if ((conv_compute_mode == `CONV_COMPUTE_MODE_FC1) && add_tree_result_valid) begin
            fc_o_data_temp <= (counter_fc1_channel_end == 2) ? 0 : (fc_o_data_temp + add_tree_result_4_channel);
        end
    end
    // 先处理特殊情况，conv_compute_mode==`CONV_COMPUTE_MODE_C1，输入通道 1，输出通道 4，直接传入池化
    always @ (*) begin
        case (conv_compute_mode)
            `CONV_COMPUTE_MODE_C1: begin
                conv_result_channel_0 <= add_tree_result_0 + bias_data_buffer[0];
                conv_result_channel_1 <= add_tree_result_1 + bias_data_buffer[1];
                conv_result_channel_2 <= add_tree_result_2 + bias_data_buffer[2];
                conv_result_channel_3 <= add_tree_result_3 + bias_data_buffer[3];
            end
            `CONV_COMPUTE_MODE_C2: begin
                conv_result_channel_0 <= add_tree_result_4_channel + bias_data_buffer[0];
                conv_result_channel_1 <= 0;
                conv_result_channel_2 <= 0;
                conv_result_channel_3 <= 0;
            end
            `CONV_COMPUTE_MODE_FC1: begin
                conv_result_channel_0 <= (counter_fc1_channel_end == 2) ? (add_tree_result_4_channel + fc_o_data_temp + bias_data_buffer[0]) : 0;
                conv_result_channel_1 <= 0;
                conv_result_channel_2 <= 0;
                conv_result_channel_3 <= 0;
            end
            `CONV_COMPUTE_MODE_FC2: begin
                conv_result_channel_0 <= add_tree_result_4_channel + bias_data_buffer[0];
                conv_result_channel_1 <= 0;
                conv_result_channel_2 <= 0;
                conv_result_channel_3 <= 0;
            end
            default: begin
                conv_result_channel_0 <= add_tree_result_0;
                conv_result_channel_1 <= add_tree_result_1;
                conv_result_channel_2 <= add_tree_result_2;
                conv_result_channel_3 <= add_tree_result_3;
            end
        endcase
    end
    

    
    // 池化使能
    always @ (*) begin
        case (conv_compute_mode)
            `CONV_COMPUTE_MODE_C1: begin
                cmr_result_valid <= (add_tree_result_valid) ? 4'b1111 : 4'b0000;
            end
            `CONV_COMPUTE_MODE_C2: begin
                cmr_result_valid <= (add_tree_result_valid) ? 4'b0001 : 4'b0000;
            end
            `CONV_COMPUTE_MODE_FC1: begin
                cmr_result_valid <= ((counter_fc1_channel_end == 2) && add_tree_result_valid) ? 4'b0001 : 4'b0000;
            end
            `CONV_COMPUTE_MODE_FC2: begin
                cmr_result_valid <= (add_tree_result_valid) ? 4'b0001 : 4'b0000;
            end
            default: begin
                cmr_result_valid <= 4'b0000;
            end
        endcase
    end
endmodule
