`include "defines.v"
module conv_mult(
    input wire signed [`CONV_IN_BIT_WIDTH_F-1:0] feature_map_pixel,       // 输入特征图的 1 个像素
    input wire signed [`CONV_IN_BIT_WIDTH_W-1:0] conv_kernel_pixel,       // 卷积核的 1 个元素
    output wire signed [`CONV_OUT_BIT_WIDTH-1:0] mult_result
    );
    
    // TODO:测试 $signed 具体效果
    assign mult_result = feature_map_pixel * conv_kernel_pixel;
endmodule
