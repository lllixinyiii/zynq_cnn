`timescale 1ns / 1ns
module dataset_test_tb();
    reg clk;
    reg rst_n;
    reg dataset_test_go;
    wire [13:0] correct_num;
    
    initial begin
        rst_n = 1;
        clk = 0;
        dataset_test_go = 0;
        #40
        rst_n = 0;
        #40
        rst_n = 1;
        #50
        dataset_test_go = 1;
        #51
        dataset_test_go = 0;
    end
    
    always #5 clk = ~clk;

    dataset_test dt_0(
    .clk(clk),
    .rst_n(rst_n),
    .dataset_test_go(dataset_test_go),
    .correct_num(correct_num)
    );
endmodule
