// 针对输入特征图小于 2×KERNEL_SIZE 的情况，暂时不考虑，主要问题出在从上到下移动的这一步，这种情况下来不及将下面那一行我设置的 buffer 填充满
// 这种情况 LeNet5 中没有，因此暂时不做设计，要做的话可以考虑加气泡


// 处理我新设计的输入特征图的访问，这里设计了一个奇偶组，每五行特征图为一组，这五行的每一列存放在一个地址里，即一个地址对应 5×8bit，分四个通道，每个通道再分为两个 block，
// 奇数组占一个 Block，偶数组占一个 Block，即假设一个 28×28 的输入特征图，他的 1~5 行分别存在 Block0 的地址 0 到 27，6~10行存在 Block1 的 地址 0 到 27，
// 11~15 行分别存在 Block0 的地址 28 到 53，16~20行存在 Block1 的 地址 28 到 53
module feature_in_access(
    input wire clk,
    input wire rst_n,
    input wire[2:0] internal_row,
    input wire b0_low_flag,
    input wire direction_flag,                         // 从左往右走：0   从右往左走：1
    input wire newline_flag,
    

    output reg signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_0,
    input wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_bank_0_block_0,
    input wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_bank_0_block_1
    
    );
    
    // 地址进去还要一拍，比如我在这个时钟上升沿给的地址，他会下个时钟上升沿才送进 bram，因此要下下个时钟上升沿才能读出结果
    // 在 conv_5_5_in_control 模块中尝试在下降沿更新地址


    // 需要设置一个缓冲的 buffer，随时为从上往下移的那一步准备着，在从上往下的那一步将其送出去
    reg[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_buffer_0;
    
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] temp_read_block_feature_0;
    assign temp_read_block_feature_0 = (b0_low_flag) ? feature_bank_0_block_0 : feature_bank_0_block_1;
    

    // 有三点：一是要根据 b0_low_flag 取得是在下面的块，二是要根据 internal_row 确定取下面模块的第几行，三是要根据 receptive_field_change_mode 确定从左往右放还是从右往左放
    // direction_flag 从左往右走：0   从右往左走：1
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_in_buffer_0 <= 0;
        end
        else begin        // 从左往右
            case (internal_row) 
                3'd0: begin
                    feature_in_buffer_0 <= (direction_flag) ? {temp_read_block_feature_0[7:0], feature_in_buffer_0[39:8]} :
                                                              {feature_in_buffer_0[31:0], temp_read_block_feature_0[7:0]};
                end
                3'd1: begin
                    feature_in_buffer_0 <= (direction_flag) ? {temp_read_block_feature_0[15:8], feature_in_buffer_0[39:8]} :
                                                              {feature_in_buffer_0[31:0], temp_read_block_feature_0[15:8]};
                end
                3'd2: begin
                    feature_in_buffer_0 <= (direction_flag) ? {temp_read_block_feature_0[23:16], feature_in_buffer_0[39:8]} :
                                                              {feature_in_buffer_0[31:0], temp_read_block_feature_0[23:16]};
                end
                3'd3: begin
                    feature_in_buffer_0 <= (direction_flag) ? {temp_read_block_feature_0[31:24], feature_in_buffer_0[39:8]} :
                                                              {feature_in_buffer_0[31:0], temp_read_block_feature_0[31:24]};
                end
                3'd4: begin
                    feature_in_buffer_0 <= (direction_flag) ? {temp_read_block_feature_0[39:32], feature_in_buffer_0[39:8]} :
                                                              {feature_in_buffer_0[31:0], temp_read_block_feature_0[39:32]};
                end
                default: begin
                    feature_in_buffer_0 <= 40'hffffffffff;
                end
            endcase
        end
    end
    
    // 根据 internal_row 进行拼接，设置 b0_low_flag，这个信号为 1 时标志 block0在下面，否则 block0 在上面
    
    
    always @ (*) begin
        if (newline_flag) begin
            feature_in_0 = feature_in_buffer_0;
        end
        else begin
            case (internal_row) 
                3'd0: begin
                    feature_in_0 = (b0_low_flag) ? feature_bank_0_block_1: feature_bank_0_block_0;
                end
                3'd1: begin
                    feature_in_0 = (b0_low_flag) ? {feature_bank_0_block_0[7:0], feature_bank_0_block_1[39:8]} : {feature_bank_0_block_1[7:0], feature_bank_0_block_0[39:8]};
                end
                3'd2: begin
                    feature_in_0 = (b0_low_flag) ? {feature_bank_0_block_0[15:0], feature_bank_0_block_1[39:16]} : {feature_bank_0_block_1[15:0], feature_bank_0_block_0[39:16]};
                end
                3'd3: begin
                    feature_in_0 = (b0_low_flag) ? {feature_bank_0_block_0[23:0], feature_bank_0_block_1[39:24]} : {feature_bank_0_block_1[23:0], feature_bank_0_block_0[39:24]};
                end
                3'd4: begin
                    feature_in_0 = (b0_low_flag) ? {feature_bank_0_block_0[31:0], feature_bank_0_block_1[39:32]} : {feature_bank_0_block_1[31:0], feature_bank_0_block_0[39:32]};
                end
                default: begin
                    feature_in_0 = feature_in_buffer_0;
                end
            endcase
        end
    end
    
    
    
endmodule
