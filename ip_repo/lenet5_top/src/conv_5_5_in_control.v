`include "defines.v"
// 控制 5×5 卷积的输入信号
module conv_5_5_in_control(
    input wire clk,
    input wire rst_n,
    input wire get_fm_in_go,             // 实际上这个信号代表开始取数要进行卷积运算了，这个信号开始时开始给特征图取地址，下一个时钟上升沿才得到第一次从 mem 返回的特征图的值
    input wire[4:0] feature_in_width,
    input wire[4:0] feature_out_width,
    
    input wire [1:0] conv_compute_mode,
    input wire get_c2_fm_go,
    
    output reg conv_compute_en,
    output reg load_fm_flag,
    output wire[1:0] receptive_field_change_mode,      // 感受野切换模式   00：从左往右   01：从上往下    10：从右往左
    output reg newline_flag,
    output reg direction_flag,                          // 从左往右走：0   从右往左走：1
        
    // 控制访问 weight_mem 和 feature_mem 和 bias_mem 的地址
    output reg b0_low_flag,                                     // 根据 internal_row 进行拼接，设置 b0_low_flag，这个信号为 1 时标志 block0在下面，否则 block0 在上面
    output reg[2:0] internal_row,
    output wire[`FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_b0,
    output wire[`FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_b1,
    output reg[`WEIGHT_MEM_ADDR_WIDTH-1:0] weight_addr,
    output reg[`BIAS_MEM_ADDR_WIDTH-1:0] bias_addr,
    output reg bias_valid,                                           // 这个代表读出的 bias 是有效的
    
    output wire[4:0] feature_buffer_addr_b0,
    output wire[4:0] feature_buffer_addr_b1,
    
    input wire load_fc_flag,
    
    input wire final_result_valid
    );
    
    localparam KERNEL_SIZE = 5;
    
    reg[4:0] counter_row;
    reg[4:0] counter_col;
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter_col <= 0;
        end
        else if (conv_compute_en) begin
            counter_col <= (counter_col == feature_out_width-1) ? 0 : counter_col+1;
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter_row <= 0;
        end
        else if(conv_compute_en && (counter_col == feature_out_width-1)) begin
            counter_row <= (counter_row == feature_out_width-1) ? 0 : counter_row+1;
        end
    end
    
    reg[3:0] channel_4_cycle;                                  // 16 个输出通道，每计算完一个加一
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            channel_4_cycle <= 0;
        end
        else if ((conv_compute_mode == `CONV_COMPUTE_MODE_C2) && conv_compute_en && (counter_row == feature_out_width-1) && (counter_col == feature_out_width-2)) begin
            channel_4_cycle <= (channel_4_cycle == 4'd15) ? 4'd0 : (channel_4_cycle + 1);
        end
    end
    
    reg get_fm_finish_flag;
    always @ (*) begin
        case (conv_compute_mode)
            `CONV_COMPUTE_MODE_C1: begin
                get_fm_finish_flag = conv_compute_en && (counter_row == feature_out_width-1) && (counter_col == feature_out_width-2);   // 这个信号有效期只有这一个时钟
            end
            `CONV_COMPUTE_MODE_C2: begin
                get_fm_finish_flag = conv_compute_en && (counter_row == feature_out_width-1) && (counter_col == feature_out_width-2) && (channel_4_cycle == 4'd15);
            end
            default: begin
                get_fm_finish_flag = 0;
            end
        endcase
    end
    
    
    reg single_oc_compute_end_flag;        // 这个信号表示 C2 一个输出通道的特征图地址给完了
    //assign single_oc_compute_end_flag = (conv_compute_mode == `CONV_COMPUTE_MODE_C2) && conv_compute_en && (counter_row == feature_out_width-1) && (counter_col == feature_out_width-1);
    //assign single_oc_compute_end_flag = conv_compute_en && (counter_row == feature_out_width-1) && (counter_col == feature_out_width-1);
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            single_oc_compute_end_flag <= 0;
        end
        else begin
            single_oc_compute_end_flag = (conv_compute_en && (counter_row == feature_out_width-1) && (counter_col == feature_out_width-1)) ? 1'b1 : 1'b0;
        end
    end
    
    reg single_oc_compute_end_latch;           // 让卷积计算延迟一个时钟，好让所有数据加载进来
    always @ (posedge clk) begin
        single_oc_compute_end_latch <= single_oc_compute_end_flag;
    end
    assign c2_buffer_addr_set_0 = (conv_compute_mode == `CONV_COMPUTE_MODE_C2) && conv_compute_en && (counter_row == feature_out_width-1) && (counter_col == feature_out_width-1);

    
    
    // 这里用一个计数器，当开始加载特征图，即 load_fm_flag=1 开始，计数达到 5 时开始计算。
    reg[2:0] counter_to_start_conv;         // 计数何时开始卷积计算
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_to_start_conv <= 0;
        end
        else if (get_fm_finish_flag || single_oc_compute_end_flag || single_oc_compute_end_latch) begin
            counter_to_start_conv <= 0;
        end
        else if (load_fm_flag) begin
            counter_to_start_conv <= (counter_to_start_conv == KERNEL_SIZE) ? counter_to_start_conv : (counter_to_start_conv + 1'b1);
        end
        else begin
            counter_to_start_conv <= 0;
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            conv_compute_en <= 0;
        end
        else if (counter_to_start_conv == 4) begin
            conv_compute_en <= 1;
        end
        else begin
            conv_compute_en <= (conv_compute_en && (counter_row == feature_out_width-1) && (counter_col == feature_out_width-1)) ? 1'b0 : conv_compute_en; 
        end
    end
    // assign conv_compute_en = (counter_to_start_conv == 5);
    
    
    
    //reg load_fm_flag;               // 这个标志位代表当前在加载特征图
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_fm_flag <= 0;
        end
        else if (get_fm_in_go || get_c2_fm_go) begin
            load_fm_flag <= 1;
        end
        else begin
            load_fm_flag <= get_fm_finish_flag ? 0 : load_fm_flag;
        end
    end 

 
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            direction_flag <= 0;
        end
        else if (final_result_valid) begin
            direction_flag <= 0;
        end
        else if (single_oc_compute_end_flag) begin
            direction_flag <= 0;
        end
        else begin
            direction_flag <= (counter_col == feature_out_width-1) ? ~direction_flag : direction_flag;
        end
    end
    
    
    
    // 感受野切换模式   00：从左往右   01：从上往下    10：从右往左
    assign receptive_field_change_mode = (counter_col == feature_out_width-1) ? 2'b01 :
                                          (direction_flag) ? 2'b10 : 2'b00;
    
    
    
    // 设置一个 internal_row 内部行，计数从 0 到 4，0 时只访问上面那块，但是要准备好从上往下移时要放进来的数据。
    // 为 1 时需要从上面的块内取 4 个数，下面的块内取一个数读进
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            internal_row <= 0;
        end
        else if (final_result_valid) begin
            internal_row <= 0;
        end
        else if (single_oc_compute_end_flag) begin
            internal_row <= 0;
        end
        else if (counter_col == feature_out_width-1) begin
            internal_row <= (internal_row == 4) ? 0 : (internal_row + 1);
        end
        else begin
            internal_row <= internal_row;
        end
    end
    
    
    // 下面求访问几个特征图、权重、偏置存储器的地址  feature_addr  weight_addr   bias_addr
    
    // feature_addr 直到卷积结束前每个 clk 都要更新
    // 用一个 feature_addr_up，一个 feature_addr_down，一个在上一个在下，因为下面的地址要么和上面的地址一样，要么比上面的地址大，只有这两种情况
    // 这一点是肯定的，但是不能确定什么时候 B0 在上面，什么时候 B1 在上面，所以先确定上下地址是不是一样，再判断谁在上谁在下对应去给
    
    
    // 判断上面的地址是 Block0 还是 Block1的
    // internal_row == 4的这一行要计算完成时，接下来计算的就是一整块属于 b0 或 b1，这个时候切换 b0_low_flag
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b0_low_flag <= 0;
        end
        else if (final_result_valid) begin
            b0_low_flag <= 0;
        end
        else if (single_oc_compute_end_flag) begin
            b0_low_flag <= 0;
        end
        else if (internal_row == 4 && counter_col == feature_out_width-1) begin
            b0_low_flag <= !b0_low_flag;
        end
    end
    
    // b0_low_flag 和 internal_row 和 newline_flag 是一国的，都是跟数据走的而不是跟地址走的
    // 来到新的一行
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            newline_flag <= 1'b0;
        end
        else begin
            newline_flag <= (counter_col == feature_out_width-1-1) ? 1'b1 :1'b0;
        end
    end
    
    
    // 确定基地址，即当前所处行第一列的地址
    // 计数 internal_row 切换回到0第二次时更改基地址
    /*reg ir_change_counter;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ir_change_counter <= 0;
        end
        else if (internal_row == 4 && counter_col == feature_out_width-2) begin
            ir_change_counter <= !ir_change_counter;
        end
    end*/
    
    // 什么时候需要切换 base_addr 呢？这个时候 internal_row == 4 并且 b1 块在上面，这个时候在左移或者右移的过程中
    // feature_addr_up 和 feature_addr_down 的基数已经定了，在这个基数上每个时钟＋1或-1，此时可以选 1 个时钟放心的修改 base_addr 的值
    
    // 为了方便从上到下的切换，设定上是当 internal_row == 0 时已经默认此时取的一整个块是在上面的块了
    // 我在下降沿给地址的时候，下一个上升沿将地址给进去，下下一个上升沿才会将数据给出来送到卷积里，即地址比数据要提前一个半（2个）时钟考虑
    reg[`BIAS_MEM_ADDR_WIDTH-1:0] base_addr;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base_addr <= 0;
        end
        else if (conv_compute_mode == `CONV_COMPUTE_MODE_C1) begin
            if (get_fm_finish_flag) begin
                base_addr <= 0;
            end
            else if (internal_row == 4 && counter_col == 0 && conv_compute_en && b0_low_flag) begin          // 之后再看有没有问题，按理来说是可以的
                base_addr <= base_addr + feature_in_width;
            end
            else begin
                base_addr <= base_addr;
            end
        end
    end
    
    
    reg[`FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_up;
    wire[`FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_down;
    
    // 还是需要这个，因为数据和地址的驱动我感觉还是得分开
    reg b0_addr_up_flag;                    // feature_up_addr 给到 b0 的标志
    
    always @ (negedge clk or negedge rst_n) begin               // 0 上下地址相等   1 上下地址不等
        if (!rst_n) begin
            b0_addr_up_flag <= 1;
        end
        else if (final_result_valid) begin
            b0_addr_up_flag <= 1;
        end
        else if (single_oc_compute_end_flag) begin
            b0_addr_up_flag <= 1;
        end
        else if (internal_row == 4 && counter_col == feature_out_width-2) begin
            b0_addr_up_flag <= !b0_addr_up_flag;
        end
    end
    
    reg feature_addr_direction_flag;                // 因为给地址和取数之间存在误差，因此地址的改变需要另给一个 flag
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            feature_addr_direction_flag <= 0;
        end
        else if (final_result_valid) begin
            feature_addr_direction_flag <= 0;
        end
        else if (single_oc_compute_end_flag) begin
            feature_addr_direction_flag <= 0;
        end
        else begin
            feature_addr_direction_flag <= (counter_col == feature_out_width-2) ? ~feature_addr_direction_flag : feature_addr_direction_flag;
        end
    end
    
    
    // 不同大网络层的区别从下面开始，主要是要访问的 buffer 不同
    // base_addr 用于每次要取下一行的地址时，确定下移后的下一步要载入的1列5行的地址。
    always @ (negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_addr_up <= 0;
        end 
        else if (final_result_valid) begin
            feature_addr_up <= 0;
        end
        else if ((get_fm_in_go || load_fm_flag) && (conv_compute_mode == `CONV_COMPUTE_MODE_C1)) begin
            if (counter_col == feature_out_width-2) begin
                feature_addr_up <= direction_flag ? (base_addr + KERNEL_SIZE) : (base_addr + feature_out_width -1-1);
            end
            else begin
                feature_addr_up <= (feature_addr_direction_flag) ? (feature_addr_up - 1) : (feature_addr_up + 1);
            end
        end
        else begin
            feature_addr_up <= feature_addr_up;
        end
    end
    
    // internal_row==0 时输出的是上面 block的值，也就是说根据的地址是 feature_addr_up
    assign feature_addr_down = (b0_addr_up_flag) ? feature_addr_up : (feature_addr_up + feature_in_width);      // 这个变就变了，没关系，基础值没变就行
    
    // 再根据 B0 和 B1 谁在上面把地址给过去
    // 在这里又存在一个问题，b0_low_flag是根据计算到的位置判断的，而不是根据地址送到哪儿判断的。
    // 当我切换一行输入地址时，还没有计算到上一行的最后，也就是说这时候
    assign feature_addr_b0 = (b0_addr_up_flag) ? feature_addr_up : feature_addr_down;
    assign feature_addr_b1 = (b0_addr_up_flag) ? feature_addr_down : feature_addr_up;
    
    
    
    /*******************************下面这一段主要用来访问层与层之间的 buffer，从中取数*************************************/
    // feature_buffer_addr_b0     feature_buffer_addr_b1
    reg[4:0] buffer_base_addr;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_base_addr <= 0;
        end
        else if (final_result_valid) begin
            buffer_base_addr <= 0;
        end
        else if (conv_compute_mode == `CONV_COMPUTE_MODE_C2) begin
            if (single_oc_compute_end_flag) begin
                buffer_base_addr <= 0;
            end
            else if (internal_row == 4 && counter_col == 0 && conv_compute_en && b0_low_flag) begin          // 之后再看有没有问题，按理来说是可以的
                buffer_base_addr <= buffer_base_addr + feature_in_width;
            end
            else begin
                buffer_base_addr <= buffer_base_addr;
            end
        end
    end
    
    reg[4:0] feature_buffer_addr_up;
    wire[4:0] feature_buffer_addr_down;
    
    always @ (negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            feature_buffer_addr_up <= 0;
        end 
        else if (final_result_valid) begin
            feature_buffer_addr_up <= 0;
        end
        else if ((get_c2_fm_go || load_fm_flag) && (conv_compute_mode == `CONV_COMPUTE_MODE_C2)) begin
            if (c2_buffer_addr_set_0) begin
                feature_buffer_addr_up <= 0;
            end
            else if (counter_col == feature_out_width-2) begin
                feature_buffer_addr_up <= direction_flag ? (buffer_base_addr + KERNEL_SIZE) : (buffer_base_addr + feature_out_width -1-1);
            end
            else begin
                feature_buffer_addr_up <= (feature_addr_direction_flag) ? (feature_buffer_addr_up - 1) : (feature_buffer_addr_up + 1);
            end
        end
        else begin
            feature_buffer_addr_up <= feature_buffer_addr_up;
        end
    end
    
    // internal_row==0 时输出的是上面 block的值，也就是说根据的地址是 feature_addr_up
    assign feature_buffer_addr_down = (b0_addr_up_flag || c2_buffer_addr_set_0) ? feature_buffer_addr_up : (feature_buffer_addr_up + feature_in_width);      // 这个变就变了，没关系，基础值没变就行
    
    
    // 再根据 B0 和 B1 谁在上面把地址给过去
    // 在这里又存在一个问题，b0_low_flag是根据计算到的位置判断的，而不是根据地址送到哪儿判断的。
    // 当我切换一行输入地址时，还没有计算到上一行的最后，也就是说这时候
    assign feature_buffer_addr_b0 = (b0_addr_up_flag || c2_buffer_addr_set_0) ? feature_buffer_addr_up : feature_buffer_addr_down;
    assign feature_buffer_addr_b1 = (b0_addr_up_flag || c2_buffer_addr_set_0) ? feature_buffer_addr_down : feature_buffer_addr_up;
    
    
    // weight_addr 直到卷积整四个通道结束前，首先的 KERNEL_SIZE 个 clk 需要更新
    always @ (negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_addr <= 0;
        end 
        else if (final_result_valid) begin
            weight_addr <= 0;
        end
        else if (get_fm_in_go || get_c2_fm_go || (load_fm_flag && (counter_to_start_conv < 4))) begin
            weight_addr <= weight_addr + 1'b1;
        end
        else begin
            weight_addr <= weight_addr;
        end
    end
    
    reg[1:0] update_fc_bias_counter;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_fc_bias_counter <= 0;
        end
        else if (load_fc_flag) begin
            update_fc_bias_counter <= (update_fc_bias_counter == 2) ? 0 : (update_fc_bias_counter + 1);
        end
        else begin
            update_fc_bias_counter <= 0;
        end
    end
    
    wire bias_valid_judge;
    assign bias_valid_judge = get_fm_in_go || (load_fm_flag && (counter_to_start_conv < 3));
    // bias_addr 每个输出通道才换一个，这个要特殊处理
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bias_valid <= 1'b0;
        end
        else if (final_result_valid) begin
            bias_valid <= 0;
        end
        else begin
            case (conv_compute_mode)
                `CONV_COMPUTE_MODE_C1: begin
                    bias_valid <= (bias_valid_judge) ? 1'b1 : 1'b0;
                end
                `CONV_COMPUTE_MODE_C2: begin
                    bias_valid <= (load_fm_flag && (counter_to_start_conv == 4)) ? 1'b1 : 1'b0;
                end
                `CONV_COMPUTE_MODE_FC1: begin
                    bias_valid <= (load_fc_flag && (update_fc_bias_counter == 2)) ? 1'b1 : 1'b0;
                end
                `CONV_COMPUTE_MODE_FC2: begin
                    bias_valid <= (load_fc_flag) ? 1'b1 : 1'b0;
                end
                default: begin
                    bias_valid <= (get_fm_in_go) ? 1'b1 : 1'b0;
                end
            endcase
        end
    end
    
    
     always @ (negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bias_addr <= 0;
        end 
        else if (final_result_valid) begin
            bias_addr <= 0;
        end
        else begin
            case (conv_compute_mode)
                `CONV_COMPUTE_MODE_C1: begin
                    bias_addr <= (bias_valid_judge) ? (bias_addr + 1'b1) : bias_addr;
                end
                `CONV_COMPUTE_MODE_C2: begin
                    bias_addr <= (load_fm_flag && (counter_to_start_conv == 4)) ? (bias_addr + 1'b1) : bias_addr;
                end
                `CONV_COMPUTE_MODE_FC1: begin
                    bias_addr <= (load_fc_flag && (update_fc_bias_counter == 2)) ? (bias_addr + 1'b1) : bias_addr;
                end
                `CONV_COMPUTE_MODE_FC2: begin
                    bias_addr <= (load_fc_flag) ? (bias_addr + 1'b1) : bias_addr;
                end
                default: begin
                    bias_addr <= (get_fm_in_go) ? (bias_addr + 1'b1) : bias_addr;
                end
            endcase
        end
    end
    
    
    
    
    
    
endmodule
