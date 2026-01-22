`include "defines.v"

// bias 一次只读 8bit 的数
module bias_mem_access(
    input wire clk,
    input wire[`BIAS_MEM_ADDR_WIDTH-1:0] bias_addr,
    output wire[`CONV_IN_BIT_WIDTH_B-1:0] bias_in_0
    
    );
    
    bias_mem bias_mem_0(
        .clka(clk),
        .addra(bias_addr),
        .douta(bias_in_0)
    );
    
endmodule
