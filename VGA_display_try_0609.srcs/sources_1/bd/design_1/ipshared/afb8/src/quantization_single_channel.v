`include "defines.v"
module quantization_single_channel(
    input wire clk,
    input wire rst_n,
    input wire signed [31:0] conv_o_data,
    input wire quant_en,               // 量化使能信号
    output reg signed [`CONV_IN_BIT_WIDTH_F-1:0] quant_o_data,
    output reg quant_valid,
    input wire[1:0] conv_compute_mode
    );
    
    wire signed [31:0] conv_o_data_temp;
    assign conv_o_data_temp = conv_o_data[31] ? -conv_o_data : conv_o_data;
    wire negative_flag;
    assign negative_flag = conv_o_data[31];
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quant_o_data <= 8'b0;
        end
        else begin
            case (conv_compute_mode)
                `CONV_COMPUTE_MODE_C1: begin
                    quant_o_data <= negative_flag ? -conv_o_data_temp[16:10] : conv_o_data_temp[16:10];
                end
                `CONV_COMPUTE_MODE_C2: begin
                    quant_o_data <= negative_flag ? -conv_o_data_temp[15:9] : conv_o_data_temp[15:9];
                end
                `CONV_COMPUTE_MODE_FC1: begin
                    quant_o_data <= negative_flag ? -conv_o_data_temp[15:9] : conv_o_data_temp[15:9];
                end
                default: begin
                    quant_o_data <= negative_flag ? -conv_o_data_temp[15:9] : conv_o_data_temp[15:9];
                end
            endcase
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            quant_valid <= 1'b0;
        end
        else begin
            quant_valid <= quant_en;
        end
    end
endmodule
