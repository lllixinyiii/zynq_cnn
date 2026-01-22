// 这个模块要在 FC2 计算完成之后不经过量化等步骤直接输出最终的结果
module find_final_result(
    input wire clk,
    input wire rst_n,
    input wire find_final_result_en,
    input wire signed [31:0] conv_result_channel_0,
    
    output reg [3:0] final_result,
    output reg final_result_valid                           // 最终输出结果有效标记位
    );
    reg [3:0] tag_counter;                      // 计数输入的tag 0 ~ 9
    reg signed [31:0] temp_max_result = 0;          // 暂存到目前最大的结果
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tag_counter <= 0;
        end
        else if (tag_counter == 9) begin
            tag_counter <= (find_final_result_en) ? 0 : tag_counter;
        end
        else begin
            tag_counter <= (find_final_result_en) ? (tag_counter + 1) : tag_counter;
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_result_valid <= 0;
        end
        else begin
            final_result_valid <= (tag_counter == 9);
        end
    end
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            temp_max_result <= 0;
        end
        else if (find_final_result_en) begin
            temp_max_result <= (tag_counter == 0) ? conv_result_channel_0 :
                            (conv_result_channel_0 > temp_max_result) ? conv_result_channel_0 : temp_max_result;
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            final_result <= 0;
        end
        else if (find_final_result_en) begin
            final_result <= (tag_counter == 0) ? 0 :
                            (conv_result_channel_0 > temp_max_result) ? tag_counter : final_result;
        end
    end
endmodule
