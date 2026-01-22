`include "defines.v"
// 这个模块处理单个通道的池化
// 目前暂时完成 2×2 的最大池化
module pool_single_channel(
    input wire clk,
    input wire rst_n,
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data,
    input wire pool_single_channel_en,                          // 池化使能信号，4bit 代表 4 块池化硬件
    //input wire[3:0] pool_out_width,                              // 池化输出的宽度
    
    output wire pool_result_valid,
    output wire signed[`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level1,                           // 池化分为两级，这里是第 1 级的结果，并且该值在 counter_to_pool == 1 时有效
    
    input wire[3:0] pool_o_width
    );
    reg signed [`CONV_IN_BIT_WIDTH_F-1:0] reg_temp_level0;           // 两两进行行池化，一次吐一个数，前面进来的先暂存
    reg counter_to_pool;                    // 用于判断行池化是否完成，因为现在是 2×2 池化，暂时只需要计数1位即可
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_to_pool <= 1'b0;
        end
        else begin
            counter_to_pool <= (pool_single_channel_en) ? !counter_to_pool : 1'b0;
        end
    end
    
    // 给 reg_temp_0 放值
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_temp_level0 <= 32'd0;
        end
        else if (pool_single_channel_en && !counter_to_pool) begin
            reg_temp_level0 <= quant_o_data;
        end
        else begin
            reg_temp_level0 <= reg_temp_level0;
        end
    end
    
    wire signed[`CONV_IN_BIT_WIDTH_F-1:0] pool_result_level0;                            // 池化分为两级，这里是第 0 级的结果，并且该值在 counter_to_pool == 1 时有效
    assign pool_result_level0 = (reg_temp_level0 > quant_o_data) ? reg_temp_level0 : quant_o_data;
    
    // 前一行的结果出来之后不能马上接着下一行的结果比较，因此暂存一下
    reg signed[`CONV_IN_BIT_WIDTH_F-1:0] temp_save_result_level0[0:11];                        // 保存 level0 的比较结果
    
    reg[3:0] counter_save_tag;                  // 要保存到第几号，以及读的时候从第几号读
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_save_tag <= 0;
        end
        else if (counter_to_pool == 1) begin
            counter_save_tag <= (counter_save_tag == pool_o_width - 1) ? 0 : counter_save_tag + 1;
        end
    end
    
    reg line_2_flag;    // 代表当前在处理第二行了
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_2_flag <= 0;
        end
        else if ((counter_to_pool == 1) && (counter_save_tag == (pool_o_width - 1))) begin
            line_2_flag <= !line_2_flag;
        end
    end
    
    integer i;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 12; i = i + 1) begin
                temp_save_result_level0[i] <= 0;
            end
        end
        else begin                    // line_2_flag == 0时往里存，==1时往外读
            if ((counter_to_pool == 1) && (line_2_flag == 0)) begin
                temp_save_result_level0[counter_save_tag] <= pool_result_level0;
            end
        end
    end
    
    wire signed[`CONV_IN_BIT_WIDTH_F-1:0] temp_test;
    assign temp_test = temp_save_result_level0[pool_o_width - 1 - counter_save_tag];
    
    assign pool_result_level1 = (temp_test > pool_result_level0) ? temp_test : pool_result_level0;
    
    //assign pool_result_level1 = (temp_save_result_level0[4'd11 - counter_save_tag] > pool_result_level0) ? temp_save_result_level0[4'd11 - counter_save_tag] : pool_result_level0;
    assign pool_result_valid = (counter_to_pool == 1) & line_2_flag;
    
endmodule
