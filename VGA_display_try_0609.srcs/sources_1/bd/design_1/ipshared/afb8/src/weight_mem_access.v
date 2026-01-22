`include "defines.v"

module weight_mem_access(
    input wire clk,
    input wire[`WEIGHT_MEM_ADDR_WIDTH-1:0] weight_addr,
    output wire signed [`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in_0,
    output wire signed [`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in_1,
    output wire signed [`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in_2,
    output wire signed [`CONV_IN_BIT_WIDTH_W*5-1:0] weight_in_3
    
    );
    
    weight_mem_bank_0 weight_mem_bank_0(
        .clka(clk),
        .addra(weight_addr),
        .douta(weight_in_0)
    );
    
    weight_mem_bank_1 weight_mem_bank_1(
        .clka(clk),
        .addra(weight_addr),
        .douta(weight_in_1)
    );
    
    weight_mem_bank_2 weight_mem_bank_2(
        .clka(clk),
        .addra(weight_addr),
        .douta(weight_in_2)
    );
    
    weight_mem_bank_3 weight_mem_bank_3(
        .clka(clk),
        .addra(weight_addr),
        .douta(weight_in_3)
    );
endmodule