`include "defines.v"
// 我想要在这个模块中完成一整个测试集 10000 张图片的测试，并将结果输出
// 每一次结果输出时，需要将 特征图地址置到下一张，其余各种权重地址置为0
module dataset_test(
    input wire clk,
    input wire rst_n,
    input wire dataset_test_go,
    
    output reg [13:0] correct_num
    );
    wire [3:0] final_result;
    wire final_result_valid;
    
    reg dataset_test_go_pre;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dataset_test_go_pre <= 1'b0;
        end
        else begin
            dataset_test_go_pre <= dataset_test_go;
        end
    end
    
    wire dataset_test_go_posedge;
    assign dataset_test_go_posedge = dataset_test_go && !dataset_test_go_pre;
    
    reg[13:0] test_picture_counter;                 // 用来计数当前处理到测试集的第几张图片，同时可以用作地址取标签
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_picture_counter <= 0;
        end
        else if (dataset_test_go_posedge) begin
            test_picture_counter <= 0;
        end
        else if (final_result_valid) begin
            test_picture_counter <= (test_picture_counter == 0) ? 0 : (test_picture_counter + 1);
        end
    end
    
    reg lenet5_go;
    // TODO：要加一个判断逻辑，10000张测试图片全部完成后再允许判断 dataset_test_go_posedge
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lenet5_go <= 0;
        end
        else begin
            // if (dataset_test_go_posedge || (final_result_valid && !(test_picture_counter == 249))) begin
            if (dataset_test_go_posedge) begin
                lenet5_go <= 1'b1;
            end
            else begin
                lenet5_go <= 1'b0;
            end
        end
    end
    
    
    
    wire [3:0] test_label_now;                     // 当前的测试集图片 label
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            correct_num <= 0;
        end
        else if (dataset_test_go_posedge) begin
            correct_num <= 0;
        end
        else if (final_result_valid) begin
            correct_num <= (final_result == test_label_now) ? (correct_num + 1) : correct_num;
        end
    end
    
    
    lenet5_top l5t_0(
    .clk(clk),
    .rst_n(rst_n),
    .lenet5_go(lenet5_go),
    .final_result(final_result),
    .final_result_valid(final_result_valid)
    );
    
    test_dataset_label tdl_0(     
    .clka(clk),     
    .addra(test_picture_counter),     
    .douta(test_label_now)
    );
endmodule
