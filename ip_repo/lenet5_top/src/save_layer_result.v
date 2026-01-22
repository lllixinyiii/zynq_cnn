`include "defines.v"
// 这里的保存层结果指的是保存一整个完整卷积层（卷积、量化、池化、激活）的结果到buffer中，以便作为下一次卷积的输入

// 思路：
// 1. 经过了蛇形卷积、池化的输出结果每一输出行都是从右往左输出的，因此存的时候注意给地址要从右往左给
// 2. 上一层的输出要作为下一层的输入，因此需要按照读输入的对应格式去存储
// 3. 需要一个列计数器，计数到输出列数时切换下一列
// 4. 还需要一个行计数器，但是由于存储格式，行计数器只需要能计数到4，0  1  2  3  4，这个主要计数往每个地址的第几个字节写数
// 5. 还需要一个标志位，这个标志位用于确定往哪一个 block 写数
// 6. 同样需要一个 base_addr，切换到 b1 后再切换回 b0 时，需要加上 pool_o_width。池化输出的图像宽度
module save_layer_result(
    input wire clk,
    input wire rst_n,
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_result_c0,
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_result_c1,
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_result_c2,
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_result_c3,
    input wire [3:0] act_result_valid,
    
    input wire[3:0] pool_o_width,                             // 池化输出图像宽度
    input wire [1:0] conv_compute_mode,
    output reg pool_result_act_save_end,                         // 池化激活的结果全部写入 bram
    
    input wire[4:0] feature_buffer_addr_b0,
    input wire[4:0] feature_buffer_addr_b1,
    input wire[2:0] internal_row,
    input wire b0_low_flag,
    input wire direction_flag,                         // 从左往右走：0   从右往左走：1
    input wire newline_flag,
    output reg signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_0,
    output reg signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_1,
    output reg signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_2,
    output reg signed [`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_in_3,
    
    output reg c2_o_act_save_end,                      // 标志 c2 的输出存储完毕
    
    input wire[1:0] fc1_data_addr,
    output wire[799:0] fc_data_in,
    
    output reg fc1_o_act_save_end,
    
    input wire final_result_valid
    );
    
    // 列也分成两部分，一部分每次计数到3，存完一个时钟送进来的结果，另一个根据这个计算每计数满一次加 1，计数到2完成一整行的存储
    // posedge pool_result_valid_act[0] 的时候就开始计数了，直到一整行的结果计算完停止计数，等待下一个 posedge pool_result_valid_act[0]
    
    wire[799:0] fc1_data_in;
    wire[799:0] fc2_data_in;
    
    assign fc_data_in = (conv_compute_mode[0]) ? fc2_data_in : fc1_data_in;
    
    reg [3:0] counter_col;
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_col <= 0;
        end
        else if (final_result_valid) begin
            counter_col <= 0;
        end
        else if (act_result_valid[0]) begin
            counter_col <= (counter_col == pool_o_width-1) ? 0 : (counter_col + 1);
        end
    end
    
    reg [3:0] counter_row;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_row <= 0;
        end
        else if (final_result_valid) begin
            counter_row <= 0;
        end
        else if (act_result_valid[0] && (counter_col == pool_o_width-1)) begin
            counter_row <= (counter_row == pool_o_width-1) ? 0 : (counter_row + 1);
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pool_result_act_save_end <= 0;
        end
        else if (act_result_valid[0]) begin
            pool_result_act_save_end <= ((conv_compute_mode == `CONV_COMPUTE_MODE_C1) && (counter_col == pool_o_width-1) && (counter_row == pool_o_width-1)) ? 1'b1 : 1'b0;
        end
        else begin
            pool_result_act_save_end <= 0;
        end
    end
    
    reg [4:0] we_row;                   // 即起到计数的作用又能提示 wea 往第几个 Byte 写
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            we_row <= 5'b00001;
        end
        else if (pool_result_act_save_end) begin
            we_row <= 5'b00001;
        end
        else if (act_result_valid[0] && (counter_col == pool_o_width-1) && ((conv_compute_mode == `CONV_COMPUTE_MODE_C1))) begin
            we_row <= (we_row[4]) ? 5'b00001 : (we_row << 1);
        end
    end
    
    reg block_1_flag;                   // 这个标志位代表当前是往b0写还是b1写
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            block_1_flag <= 0;
        end
        else if (final_result_valid) begin
            block_1_flag <= 0;
        end
        else begin
            block_1_flag <= (act_result_valid[0] && (we_row[4]) && (counter_col == pool_o_width-1)) ? !block_1_flag : block_1_flag;
        end
    end
    
    reg [4:0] base_addr;
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            base_addr <= 0;
        end
        else if (final_result_valid) begin
            base_addr <= 0;
        end
        else begin
            base_addr <= (block_1_flag && (act_result_valid[0] && (we_row[4]) && (counter_col == pool_o_width-1))) ? (base_addr + pool_o_width) : base_addr;
        end
    end
    
    wire[4:0] wr_addr;
    assign wr_addr = base_addr + (pool_o_width - 1 - counter_col);
    
    wire [4:0] wea_bank_0_block_0;
    wire [4:0] wea_bank_0_block_1;
    wire [4:0] wea_bank_1_block_0;
    wire [4:0] wea_bank_1_block_1;
    wire [4:0] wea_bank_2_block_0;
    wire [4:0] wea_bank_2_block_1;
    wire [4:0] wea_bank_3_block_0;
    wire [4:0] wea_bank_3_block_1;
    
    assign wea_bank_0_block_0 = ((conv_compute_mode == `CONV_COMPUTE_MODE_C1) && (act_result_valid[0]) && (!block_1_flag)) ? we_row : 0;
    assign wea_bank_0_block_1 = ((conv_compute_mode == `CONV_COMPUTE_MODE_C1) && (act_result_valid[0]) && (block_1_flag)) ? we_row : 0;
    assign wea_bank_1_block_0 = ((conv_compute_mode == `CONV_COMPUTE_MODE_C1) && (act_result_valid[1]) && (!block_1_flag)) ? we_row : 0;
    assign wea_bank_1_block_1 = ((conv_compute_mode == `CONV_COMPUTE_MODE_C1) && (act_result_valid[1]) && (block_1_flag)) ? we_row : 0;
    assign wea_bank_2_block_0 = ((conv_compute_mode == `CONV_COMPUTE_MODE_C1) && (act_result_valid[2]) && (!block_1_flag)) ? we_row : 0;
    assign wea_bank_2_block_1 = ((conv_compute_mode == `CONV_COMPUTE_MODE_C1) && (act_result_valid[2]) && (block_1_flag)) ? we_row : 0;
    assign wea_bank_3_block_0 = ((conv_compute_mode == `CONV_COMPUTE_MODE_C1) && (act_result_valid[3]) && (!block_1_flag)) ? we_row : 0;
    assign wea_bank_3_block_1 = ((conv_compute_mode == `CONV_COMPUTE_MODE_C1) && (act_result_valid[3]) && (block_1_flag)) ? we_row : 0;
    
    
    
    
    /**********************************读操作************************************/
    
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_bank_0_block_0, feature_buffer_bank_0_block_1;
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_bank_1_block_0, feature_buffer_bank_1_block_1;
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_bank_2_block_0, feature_buffer_bank_2_block_1;
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_buffer_bank_3_block_0, feature_buffer_bank_3_block_1;
    
    reg [4:0] buffer_access_addr_b0, buffer_access_addr_b1;
    always @ (*) begin
        case (conv_compute_mode)
            `CONV_COMPUTE_MODE_C1: begin
                buffer_access_addr_b0 <= (pool_result_act_save_end) ? feature_buffer_addr_b0 : wr_addr;
                buffer_access_addr_b1 <= (pool_result_act_save_end) ? feature_buffer_addr_b1 : wr_addr;
            end
            `CONV_COMPUTE_MODE_C2: begin
                buffer_access_addr_b0 <= feature_buffer_addr_b0;
                buffer_access_addr_b1 <= feature_buffer_addr_b1;
            end
            /*2'b10: begin
                
            end
            2'b11: begin
                
            end*/
            default: begin
                buffer_access_addr_b0 <= 0;
                buffer_access_addr_b1 <= 0;
            end
        endcase
    end
    

    // 存的是C1的结果，
    buffer_c1_o_b0 buffer_between_layer_bank_0_block_0 (
    .clka(clk),
    .addra(buffer_access_addr_b0),
    .douta(feature_buffer_bank_0_block_0),
    .wea(wea_bank_0_block_0),
    .dina({5{act_result_c0}})
    );
    
    buffer_c1_o_b1 buffer_between_layer_bank_0_block_1 (
    .clka(clk),
    .addra(buffer_access_addr_b1[3:0]),
    .douta(feature_buffer_bank_0_block_1),
    .wea(wea_bank_0_block_1),
    .dina({5{act_result_c0}})
    );
    
    buffer_c1_o_b0 buffer_between_layer_bank_1_block_0 (
    .clka(clk),
    .addra(buffer_access_addr_b0),
    .douta(feature_buffer_bank_1_block_0),
    .wea(wea_bank_1_block_0),
    .dina({5{act_result_c1}})
    );
    
    buffer_c1_o_b1 buffer_between_layer_bank_1_block_1 (
    .clka(clk),
    .addra(buffer_access_addr_b1[3:0]),
    .douta(feature_buffer_bank_1_block_1),
    .wea(wea_bank_1_block_1),
    .dina({5{act_result_c1}})
    );
    
    buffer_c1_o_b0 buffer_between_layer_bank_2_block_0 (
    .clka(clk),
    .addra(buffer_access_addr_b0),
    .douta(feature_buffer_bank_2_block_0),
    .wea(wea_bank_2_block_0),
    .dina({5{act_result_c2}})
    );
    
    buffer_c1_o_b1 buffer_between_layer_bank_2_block_1 (
    .clka(clk),
    .addra(buffer_access_addr_b1[3:0]),
    .douta(feature_buffer_bank_2_block_1),
    .wea(wea_bank_2_block_1),
    .dina({5{act_result_c2}})
    );
    
    buffer_c1_o_b0 buffer_between_layer_bank_3_block_0 (
    .clka(clk),
    .addra(buffer_access_addr_b0),
    .douta(feature_buffer_bank_3_block_0),
    .wea(wea_bank_3_block_0),
    .dina({5{act_result_c3}})
    );
    
    buffer_c1_o_b1 buffer_between_layer_bank_3_block_1 (
    .clka(clk),
    .addra(buffer_access_addr_b1[3:0]),
    .douta(feature_buffer_bank_3_block_1),
    .wea(wea_bank_3_block_1),
    .dina({5{act_result_c3}})
    );
    
    // 需要设置一个缓冲，随时为从上往下移的那一步准备着，在从上往下的那一步将其送出去
    reg[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_move_down_0;
    reg[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_move_down_1;
    reg[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_move_down_2;
    reg[`CONV_IN_BIT_WIDTH_F*5-1:0] feature_in_move_down_3;
    
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] temp_read_block_feature_0;
    assign temp_read_block_feature_0 = (b0_low_flag) ? feature_buffer_bank_0_block_0 : feature_buffer_bank_0_block_1;
    
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] temp_read_block_feature_1;
    assign temp_read_block_feature_1 = (b0_low_flag) ? feature_buffer_bank_1_block_0 : feature_buffer_bank_1_block_1;
    
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] temp_read_block_feature_2;
    assign temp_read_block_feature_2 = (b0_low_flag) ? feature_buffer_bank_2_block_0 : feature_buffer_bank_2_block_1;
    
    wire[`CONV_IN_BIT_WIDTH_F*5-1:0] temp_read_block_feature_3;
    assign temp_read_block_feature_3 = (b0_low_flag) ? feature_buffer_bank_3_block_0 : feature_buffer_bank_3_block_1;
    
    // 有三点：一是要根据 b0_low_flag 取得是在下面的块，二是要根据 internal_row 确定取下面模块的第几行，三是要根据 receptive_field_change_mode 确定从左往右放还是从右往左放
    // direction_flag 从左往右走：0   从右往左走：1
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_in_move_down_0 <= 0;
        end
        else begin        // 从左往右
            case (internal_row) 
                3'd0: begin
                    feature_in_move_down_0 <= (direction_flag) ? {temp_read_block_feature_0[7:0], feature_in_move_down_0[39:8]} :
                                                              {feature_in_move_down_0[31:0], temp_read_block_feature_0[7:0]};
                end
                3'd1: begin
                    feature_in_move_down_0 <= (direction_flag) ? {temp_read_block_feature_0[15:8], feature_in_move_down_0[39:8]} :
                                                              {feature_in_move_down_0[31:0], temp_read_block_feature_0[15:8]};
                end
                3'd2: begin
                    feature_in_move_down_0 <= (direction_flag) ? {temp_read_block_feature_0[23:16], feature_in_move_down_0[39:8]} :
                                                              {feature_in_move_down_0[31:0], temp_read_block_feature_0[23:16]};
                end
                3'd3: begin
                    feature_in_move_down_0 <= (direction_flag) ? {temp_read_block_feature_0[31:24], feature_in_move_down_0[39:8]} :
                                                              {feature_in_move_down_0[31:0], temp_read_block_feature_0[31:24]};
                end
                3'd4: begin
                    feature_in_move_down_0 <= (direction_flag) ? {temp_read_block_feature_0[39:32], feature_in_move_down_0[39:8]} :
                                                              {feature_in_move_down_0[31:0], temp_read_block_feature_0[39:32]};
                end
                default: begin
                    feature_in_move_down_0 <= 40'hffffffffff;
                end
            endcase
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_in_move_down_1 <= 0;
        end
        else begin        // 从左往右
            case (internal_row) 
                3'd0: begin
                    feature_in_move_down_1 <= (direction_flag) ? {temp_read_block_feature_1[7:0], feature_in_move_down_1[39:8]} :
                                                              {feature_in_move_down_1[31:0], temp_read_block_feature_1[7:0]};
                end
                3'd1: begin
                    feature_in_move_down_1 <= (direction_flag) ? {temp_read_block_feature_1[15:8], feature_in_move_down_1[39:8]} :
                                                              {feature_in_move_down_1[31:0], temp_read_block_feature_1[15:8]};
                end
                3'd2: begin
                    feature_in_move_down_1 <= (direction_flag) ? {temp_read_block_feature_1[23:16], feature_in_move_down_1[39:8]} :
                                                              {feature_in_move_down_1[31:0], temp_read_block_feature_1[23:16]};
                end
                3'd3: begin
                    feature_in_move_down_1 <= (direction_flag) ? {temp_read_block_feature_1[31:24], feature_in_move_down_1[39:8]} :
                                                              {feature_in_move_down_1[31:0], temp_read_block_feature_1[31:24]};
                end
                3'd4: begin
                    feature_in_move_down_1 <= (direction_flag) ? {temp_read_block_feature_1[39:32], feature_in_move_down_1[39:8]} :
                                                              {feature_in_move_down_1[31:0], temp_read_block_feature_1[39:32]};
                end
            endcase
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_in_move_down_2 <= 0;
        end
        else begin        // 从左往右
            case (internal_row) 
                3'd0: begin
                    feature_in_move_down_2 <= (direction_flag) ? {temp_read_block_feature_2[7:0], feature_in_move_down_2[39:8]} :
                                                              {feature_in_move_down_2[31:0], temp_read_block_feature_2[7:0]};
                end
                3'd1: begin
                    feature_in_move_down_2 <= (direction_flag) ? {temp_read_block_feature_2[15:8], feature_in_move_down_2[39:8]} :
                                                              {feature_in_move_down_2[31:0], temp_read_block_feature_2[15:8]};
                end
                3'd2: begin
                    feature_in_move_down_2 <= (direction_flag) ? {temp_read_block_feature_2[23:16], feature_in_move_down_2[39:8]} :
                                                              {feature_in_move_down_2[31:0], temp_read_block_feature_2[23:16]};
                end
                3'd3: begin
                    feature_in_move_down_2 <= (direction_flag) ? {temp_read_block_feature_2[31:24], feature_in_move_down_2[39:8]} :
                                                              {feature_in_move_down_2[31:0], temp_read_block_feature_2[31:24]};
                end
                3'd4: begin
                    feature_in_move_down_2 <= (direction_flag) ? {temp_read_block_feature_2[39:32], feature_in_move_down_2[39:8]} :
                                                              {feature_in_move_down_2[31:0], temp_read_block_feature_2[39:32]};
                end
            endcase
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_in_move_down_3 <= 0;
        end
        else begin        // 从左往右
            case (internal_row) 
                3'd0: begin
                    feature_in_move_down_3 <= (direction_flag) ? {temp_read_block_feature_3[7:0], feature_in_move_down_3[39:8]} :
                                                              {feature_in_move_down_3[31:0], temp_read_block_feature_3[7:0]};
                end
                3'd1: begin
                    feature_in_move_down_3 <= (direction_flag) ? {temp_read_block_feature_3[15:8], feature_in_move_down_3[39:8]} :
                                                              {feature_in_move_down_3[31:0], temp_read_block_feature_3[15:8]};
                end
                3'd2: begin
                    feature_in_move_down_3 <= (direction_flag) ? {temp_read_block_feature_3[23:16], feature_in_move_down_3[39:8]} :
                                                              {feature_in_move_down_3[31:0], temp_read_block_feature_3[23:16]};
                end
                3'd3: begin
                    feature_in_move_down_3 <= (direction_flag) ? {temp_read_block_feature_3[31:24], feature_in_move_down_3[39:8]} :
                                                              {feature_in_move_down_3[31:0], temp_read_block_feature_3[31:24]};
                end
                3'd4: begin
                    feature_in_move_down_3 <= (direction_flag) ? {temp_read_block_feature_3[39:32], feature_in_move_down_3[39:8]} :
                                                              {feature_in_move_down_3[31:0], temp_read_block_feature_3[39:32]};
                end
            endcase
        end
    end
    
    
    // 根据 internal_row 进行拼接，设置 b0_low_flag，这个信号为 1 时标志 block0在下面，否则 block0 在上面
    
    
    always @ (*) begin
        if (newline_flag) begin
            feature_buffer_in_0 = feature_in_move_down_0;
        end
        else begin
            case (internal_row) 
                3'd0: begin
                    feature_buffer_in_0 = (b0_low_flag) ? feature_buffer_bank_0_block_1: feature_buffer_bank_0_block_0;
                end
                3'd1: begin
                    feature_buffer_in_0 = (b0_low_flag) ? {feature_buffer_bank_0_block_0[7:0], feature_buffer_bank_0_block_1[39:8]} : {feature_buffer_bank_0_block_1[7:0], feature_buffer_bank_0_block_0[39:8]};
                end
                3'd2: begin
                    feature_buffer_in_0 = (b0_low_flag) ? {feature_buffer_bank_0_block_0[15:0], feature_buffer_bank_0_block_1[39:16]} : {feature_buffer_bank_0_block_1[15:0], feature_buffer_bank_0_block_0[39:16]};
                end
                3'd3: begin
                    feature_buffer_in_0 = (b0_low_flag) ? {feature_buffer_bank_0_block_0[23:0], feature_buffer_bank_0_block_1[39:24]} : {feature_buffer_bank_0_block_1[23:0], feature_buffer_bank_0_block_0[39:24]};
                end
                3'd4: begin
                    feature_buffer_in_0 = (b0_low_flag) ? {feature_buffer_bank_0_block_0[31:0], feature_buffer_bank_0_block_1[39:32]} : {feature_buffer_bank_0_block_1[31:0], feature_buffer_bank_0_block_0[39:32]};
                end
                default: begin
                    feature_buffer_in_0 = feature_in_move_down_0;
                end
            endcase
        end
    end
    
    
    always @ (*) begin
        if (newline_flag) begin
            feature_buffer_in_1 = feature_in_move_down_1;
        end
        else begin
            case (internal_row) 
                3'd0: begin
                    feature_buffer_in_1 = (b0_low_flag) ? feature_buffer_bank_1_block_1: feature_buffer_bank_1_block_0;
                end
                3'd1: begin
                    feature_buffer_in_1 = (b0_low_flag) ? {feature_buffer_bank_1_block_0[7:0], feature_buffer_bank_1_block_1[39:8]} : {feature_buffer_bank_1_block_1[7:0], feature_buffer_bank_1_block_0[39:8]};
                end
                3'd2: begin
                    feature_buffer_in_1 = (b0_low_flag) ? {feature_buffer_bank_1_block_0[15:0], feature_buffer_bank_1_block_1[39:16]} : {feature_buffer_bank_1_block_1[15:0], feature_buffer_bank_1_block_0[39:16]};
                end
                3'd3: begin
                    feature_buffer_in_1 = (b0_low_flag) ? {feature_buffer_bank_1_block_0[23:0], feature_buffer_bank_1_block_1[39:24]} : {feature_buffer_bank_1_block_1[23:0], feature_buffer_bank_1_block_0[39:24]};
                end
                3'd4: begin
                    feature_buffer_in_1 = (b0_low_flag) ? {feature_buffer_bank_1_block_0[31:0], feature_buffer_bank_1_block_1[39:32]} : {feature_buffer_bank_1_block_1[31:0], feature_buffer_bank_1_block_0[39:32]};
                end
                default: begin
                    feature_buffer_in_1 = feature_in_move_down_1;
                end
            endcase
        end
    end
    
    
    always @ (*) begin
        if (newline_flag) begin
            feature_buffer_in_2 = feature_in_move_down_2;
        end
        else begin
            case (internal_row) 
                3'd0: begin
                    feature_buffer_in_2 = (b0_low_flag) ? feature_buffer_bank_2_block_1: feature_buffer_bank_2_block_0;
                end
                3'd1: begin
                    feature_buffer_in_2 = (b0_low_flag) ? {feature_buffer_bank_2_block_0[7:0], feature_buffer_bank_2_block_1[39:8]} : {feature_buffer_bank_2_block_1[7:0], feature_buffer_bank_2_block_0[39:8]};
                end
                3'd2: begin
                    feature_buffer_in_2 = (b0_low_flag) ? {feature_buffer_bank_2_block_0[15:0], feature_buffer_bank_2_block_1[39:16]} : {feature_buffer_bank_2_block_1[15:0], feature_buffer_bank_2_block_0[39:16]};
                end
                3'd3: begin
                    feature_buffer_in_2 = (b0_low_flag) ? {feature_buffer_bank_2_block_0[23:0], feature_buffer_bank_2_block_1[39:24]} : {feature_buffer_bank_2_block_1[23:0], feature_buffer_bank_2_block_0[39:24]};
                end
                3'd4: begin
                    feature_buffer_in_2 = (b0_low_flag) ? {feature_buffer_bank_2_block_0[31:0], feature_buffer_bank_2_block_1[39:32]} : {feature_buffer_bank_2_block_1[31:0], feature_buffer_bank_2_block_0[39:32]};
                end
                default: begin
                    feature_buffer_in_2 = feature_in_move_down_2;
                end
            endcase
        end
    end
    
    
    always @ (*) begin
        if (newline_flag) begin
            feature_buffer_in_3 = feature_in_move_down_3;
        end
        else begin
            case (internal_row) 
                3'd0: begin
                    feature_buffer_in_3 = (b0_low_flag) ? feature_buffer_bank_3_block_1: feature_buffer_bank_3_block_0;
                end
                3'd1: begin
                    feature_buffer_in_3 = (b0_low_flag) ? {feature_buffer_bank_3_block_0[7:0], feature_buffer_bank_3_block_1[39:8]} : {feature_buffer_bank_3_block_1[7:0], feature_buffer_bank_3_block_0[39:8]};
                end
                3'd2: begin
                    feature_buffer_in_3 = (b0_low_flag) ? {feature_buffer_bank_3_block_0[15:0], feature_buffer_bank_3_block_1[39:16]} : {feature_buffer_bank_3_block_1[15:0], feature_buffer_bank_3_block_0[39:16]};
                end
                3'd3: begin
                    feature_buffer_in_3 = (b0_low_flag) ? {feature_buffer_bank_3_block_0[23:0], feature_buffer_bank_3_block_1[39:24]} : {feature_buffer_bank_3_block_1[23:0], feature_buffer_bank_3_block_0[39:24]};
                end
                3'd4: begin
                    feature_buffer_in_3 = (b0_low_flag) ? {feature_buffer_bank_3_block_0[31:0], feature_buffer_bank_3_block_1[39:32]} : {feature_buffer_bank_3_block_1[31:0], feature_buffer_bank_3_block_0[39:32]};
                end
                default: begin
                    feature_buffer_in_3 = feature_in_move_down_3;
                end
            endcase
        end
    end
    
    
    /*******************************************下面这部分用来存放 C2 的结果*************************************************/
    // C2 的结果有 256 个，但是无需考虑进入顺序，并且在每个输出通道上输入的同一个像素只计算一次
    // 完全可以设置 5 个 bram，每个地址仍然对应 5×8bit，即一个时钟可以读出所有数
    // C2 输出会有 256个数，不如直接设置一个 BRAM，数据宽度是 25×8bit
    // 要不然就进来一个顺着写一个，我调整一下 weight 的顺序就行
    
    
    
    reg [1:0] addr_c2_o_fc1_in;                 // 这里设的是 100 个8bit数存放的一个地址
    
    reg [99:0] we_c2_o_fc1_in;                  // 即起到计数的作用又能提示 wea 往第几个 Byte 写
    
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            we_c2_o_fc1_in <= 100'h1;
        end
        else if (c2_o_act_save_end) begin
            we_c2_o_fc1_in <= 100'h1;
        end
        else if ((conv_compute_mode == `CONV_COMPUTE_MODE_C2) && act_result_valid[0]) begin
            if (we_c2_o_fc1_in[99]) begin
                we_c2_o_fc1_in <= 100'h1;
            end
            else begin
                we_c2_o_fc1_in <= we_c2_o_fc1_in << 1;
            end 
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_c2_o_fc1_in <= 0;
        end
        else if (c2_o_act_save_end) begin
            addr_c2_o_fc1_in <= 0;
        end
        else if ((conv_compute_mode == `CONV_COMPUTE_MODE_C2) && act_result_valid[0] && we_c2_o_fc1_in[99]) begin
            addr_c2_o_fc1_in <= addr_c2_o_fc1_in + 1;
        end
    end
    
    reg[3:0] counter_channel_c2_o;           // 计数 c2 输出通道 16
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_channel_c2_o <= 0;
        end
        else if (act_result_valid[0] && (counter_col == pool_o_width-1) && (counter_row == pool_o_width-1) && (conv_compute_mode == `CONV_COMPUTE_MODE_C2)) begin
            counter_channel_c2_o <= (counter_channel_c2_o == 15) ? 0 : (counter_channel_c2_o + 1);
        end
    end
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c2_o_act_save_end <= 0;
        end
        else if (act_result_valid[0]) begin
            c2_o_act_save_end <= ((conv_compute_mode == `CONV_COMPUTE_MODE_C2) && (counter_channel_c2_o == 15) && (counter_col == pool_o_width-1) && (counter_row == pool_o_width-1)) ? 1'b1 : 1'b0;
        end
        else begin
            c2_o_act_save_end <= 0;
        end
    end
    
    wire [99:0] wea_c2_o_fc1_in;
    
    assign wea_c2_o_fc1_in = ((conv_compute_mode == `CONV_COMPUTE_MODE_C2) && (act_result_valid[0])) ? we_c2_o_fc1_in : 0;
    
    
    
    /**********************************读操作************************************/
    reg[1:0] addr_c2_o_buffer;
    always @ (*) begin
        case (conv_compute_mode)
            `CONV_COMPUTE_MODE_C2: begin
                addr_c2_o_buffer <= (c2_o_act_save_end) ? 0 : addr_c2_o_fc1_in;
            end
            `CONV_COMPUTE_MODE_FC1: begin
                addr_c2_o_buffer <= fc1_data_addr;
            end
            default: begin
                addr_c2_o_buffer <= 0;
            end
        endcase
    end
    
    
    c2_out_fc1_in_buffer c2_out_fc1_in_buffer_0(
    .clka(clk),
    .addra(addr_c2_o_buffer),
    .douta(fc1_data_in),
    .wea(wea_c2_o_fc1_in),
    .dina({100{act_result_c0}})
    );
    
    /*******************************************下面这部分用来存放 FC1 的结果*************************************************/
    // FC1 的结果有 100 个，但是无需考虑进入顺序，并且在每个输出通道上输入的同一个像素只计算一次
    // 直接设置一个 BRAM，数据宽度是 100×8bit(4个通道，每个通道是5×5) 
    // 实际上只需要1个地址就可以
    
    reg [99:0] we_fc1_o_fc2_in;                  // 即起到计数的作用又能提示 wea 往第几个 Byte 写
    
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            we_fc1_o_fc2_in <= 100'h1;
        end
        else if ((conv_compute_mode == `CONV_COMPUTE_MODE_FC1) && act_result_valid[0]) begin
            if (we_fc1_o_fc2_in[99]) begin
                we_fc1_o_fc2_in <= 100'h1;
            end
            else begin
                we_fc1_o_fc2_in <= we_fc1_o_fc2_in << 1;
            end 
        end
    end
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fc1_o_act_save_end <= 0;
        end
        else if (act_result_valid[0]) begin
            fc1_o_act_save_end <= we_fc1_o_fc2_in[99];
        end
        else begin
            fc1_o_act_save_end <= 0;
        end
    end
    
    wire [99:0] wea_fc1_o_fc2_in;
    
    assign wea_fc1_o_fc2_in = ((conv_compute_mode == `CONV_COMPUTE_MODE_FC1) && (act_result_valid[0])) ? we_fc1_o_fc2_in : 0;
    
    
    
    /**********************************读操作************************************/   
    
    fc1_o_fc2_i_buffer fc1_o_fc2_i_buffer_0(
    .clka(clk),
    .addra(1'b0),
    .douta(fc2_data_in),
    .wea(wea_fc1_o_fc2_in),
    .dina({100{act_result_c0}})
    );
    
    
    
    
    
    
endmodule
