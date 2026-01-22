module module_top(
    input wire clk,
    input wire rst_n,
    input wire dataset_test_go,
    output wire[7:0] an,
    output wire[7:0] seg_o
    );
    
    wire clk_25M;
    clk_div cd_0(
    .clk_100M(clk),
    .clk_25M(clk_25M),
    .rst_n(rst_n)
    );
    
    wire [13:0] correct_num;
    dataset_test dt_0(
    .clk(clk_25M),
    .rst_n(rst_n),
    .dataset_test_go(dataset_test_go),
    .correct_num(correct_num)
    );
    
    
    
    seg_7 seg_7_0(
    .clk(clk),
    .rst_n(rst_n),
    .correct_num(correct_num),
    .an(an),
    .seg_o(seg_o)
    );


endmodule
