`include "defines.v"

module fc_control_in(
    input wire clk,
    input wire rst_n,
    input wire[1:0] conv_compute_mode,
    output wire[799:0] fc_mem_o_weight,
    output reg[1:0] fc1_data_addr,
    output reg fc_compute_en,                // 开始全连接计算
    input wire load_fc1_go,
    output reg load_fc_flag,
    input wire load_fc2_go,
    
    input wire final_result_valid
    );
    reg[9:0] fc_wm_addr;
    
    reg get_fc_data_finish_flag;
    
    always @ (negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fc_wm_addr <= 0;
        end
        else if (final_result_valid) begin
            fc_wm_addr <= 0;
        end
        else if ((load_fc_flag && !get_fc_data_finish_flag) || load_fc1_go || load_fc2_go) begin                 // 啥时候结束再看
            fc_wm_addr <= fc_wm_addr + 1;
        end
    end
    
    always @ (negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fc1_data_addr <= 0;
        end
        else if (final_result_valid) begin
            fc1_data_addr <= 0;
        end
        else if ((load_fc_flag && !conv_compute_mode[0]) || load_fc1_go) begin                 // 啥时候结束再看
            fc1_data_addr <= (fc1_data_addr == 2'b10) ? 0 : (fc1_data_addr + 1);
        end
    end
    
    reg[8:0] counter_to_end_fc;                 // 一个输出通道要读 3 次，120 个输出通道要读 360 次
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_to_end_fc <= 0;
        end
        else if (load_fc_flag) begin
            if (conv_compute_mode == `CONV_COMPUTE_MODE_FC1) begin
                counter_to_end_fc <= (counter_to_end_fc == 299) ? 0 : (counter_to_end_fc + 1);
            end
            else if (conv_compute_mode == `CONV_COMPUTE_MODE_FC2) begin
                counter_to_end_fc <= (counter_to_end_fc == 9) ? 0 : (counter_to_end_fc + 1);
            end
        end
    end
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            get_fc_data_finish_flag <= 0;
        end
        else if (((counter_to_end_fc == 298) && (conv_compute_mode == `CONV_COMPUTE_MODE_FC1)) || ((counter_to_end_fc == 8) && (conv_compute_mode == `CONV_COMPUTE_MODE_FC2))) begin
            get_fc_data_finish_flag <= 1;
        end
        else begin
            get_fc_data_finish_flag <= 0;
        end
    end
    
/*    reg fc_compute_end;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fc_compute_end <= 0;
        end
        else begin
            fc_compute_end <= get_fc_data_finish_flag;
        end
    end*/
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_fc_flag <= 0;
        end
        else if (load_fc1_go || load_fc2_go) begin
            load_fc_flag <= 1;
        end
        else begin
            load_fc_flag <= get_fc_data_finish_flag ? 0 : load_fc_flag;
        end
    end 
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fc_compute_en <= 0;
        end
        else begin
            fc_compute_en <= load_fc_flag;
        end/*
        else if (load_fc_flag && (conv_compute_mode[1])) begin
            fc_compute_en <= 1;
        end*/
    end
    
    fc_weight_mem fc_weight_mem_0(
    .clka(clk),
    .addra(fc_wm_addr),
    .douta(fc_mem_o_weight)
    );
endmodule
