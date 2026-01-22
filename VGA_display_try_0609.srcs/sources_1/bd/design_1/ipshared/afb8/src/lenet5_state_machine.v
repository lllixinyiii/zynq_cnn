
module lenet5_state_machine(
    input wire clk,
    input wire rst_n,
    input wire lenet5_go,
    input wire pool_act_end,        // 上一整层结束了
    
    output reg get_fm_in_go,
    output reg[1:0] conv_compute_mode,
    output reg get_c2_fm_go,
    output reg[4:0] feature_in_width,
    output reg[4:0] feature_out_width,
    output reg[3:0] pool_o_width,
    
    input wire c2_o_act_save_end,
    output reg load_fc1_go,
    
    input wire fc1_o_act_save_end,
    output reg load_fc2_go,
    
    input wire final_result_valid
    );
    reg[2:0] lenet5_state;
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lenet5_state <= 3'b000;                 
        end
        else begin
            case (lenet5_state)
                3'b000: begin                       // Idle
                    lenet5_state <= (lenet5_go) ? 3'b001 : lenet5_state;
                end
                3'b001: begin                       // C1
                    lenet5_state <= (pool_act_end) ? 3'b010 : lenet5_state;
                end
                3'b010: begin                       // C2
                    //lenet5_state <= (pool_act_end) ? 3'b011 : lenet5_state;
                    lenet5_state <= (c2_o_act_save_end) ? 3'b011 : lenet5_state;
                end
                3'b011: begin                       // FC1
                    lenet5_state <= (fc1_o_act_save_end) ? 3'b100 : lenet5_state;
                end
                3'b100: begin                       // FC2
                    lenet5_state <= (final_result_valid) ? 3'b000 : lenet5_state;
                end
            
            endcase
        end
    end
    
    always @ (*) begin
        case (lenet5_state)
            3'b000: begin                       // Idle
                conv_compute_mode <= `CONV_COMPUTE_MODE_C1;
            end
            3'b001: begin                       // C1
                conv_compute_mode <= `CONV_COMPUTE_MODE_C1;
            end
            3'b010: begin                       // C2
                conv_compute_mode <= `CONV_COMPUTE_MODE_C2;
            end
            3'b011: begin                       // FC1
                conv_compute_mode <= `CONV_COMPUTE_MODE_FC1;
            end
            3'b100: begin                       // FC1
                conv_compute_mode <= `CONV_COMPUTE_MODE_FC2;
            end
            default: begin
                conv_compute_mode <= `CONV_COMPUTE_MODE_C1;
            end
        endcase
    end
    
    always @ (*) begin
        case (lenet5_state)
            3'b000: begin                       // Idle
                feature_in_width <= 5'd0;
                feature_out_width <= 5'd0;     
                pool_o_width <= 4'd0;           
            end
            3'b001: begin                       // C1
                feature_in_width <= 5'd28;
                feature_out_width <= 5'd24;
                pool_o_width <= 4'd12;
            end
            3'b010: begin                       // C2
                feature_in_width <= 5'd12;
                feature_out_width <= 5'd8;
                pool_o_width <= 4'd4;
            end
            default: begin
                feature_in_width <= 5'd0;
                feature_out_width <= 5'd0;     
                pool_o_width <= 4'd0; 
            end
        endcase
    end
    
    
    reg lenet5_go_prev;       // 存储上一个周期的 lenet5_go
    wire lenet5_go_posedge;   // 检测上升沿
    
    // 检测 lenet5_go 的上升沿
    assign lenet5_go_posedge = lenet5_go && !lenet5_go_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lenet5_go_prev <= 1'b0;
            get_fm_in_go <= 1'b0;
        end
        else begin
            lenet5_go_prev <= lenet5_go;  // 存储上一个周期的值
            // 在 lenet5_go 上升沿后的第一个 clk 上升沿置 1
            if (lenet5_go_posedge) begin
                get_fm_in_go <= 1'b1;        // 第一个 clk 上升沿置 1
            end
            else if (get_fm_in_go) begin
                get_fm_in_go <= 1'b0;        // 下一个 clk 上升沿置 0
            end
        end
    end
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            get_c2_fm_go <= 0;
        end
        else begin
            get_c2_fm_go <= ((lenet5_state == 3'b001) && pool_act_end);
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_fc1_go <= 0;
        end
        else begin
            load_fc1_go <= ((lenet5_state == 3'b010) && c2_o_act_save_end);
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_fc2_go <= 0;
        end
        else begin
            load_fc2_go <= ((lenet5_state == 3'b011) && fc1_o_act_save_end);
        end
    end
endmodule
