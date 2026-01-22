`include "defines.v"
module activation_unit(
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_in,
    
    output wire signed [`CONV_IN_BIT_WIDTH_F-1:0] act_result
    );
    
    assign act_result = (act_in[7] == 1) ? 8'd0 : act_in;
endmodule
