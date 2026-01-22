`define CONV_IN_BIT_WIDTH_F 8           // 卷积乘法运算输入特征图位宽
`define CONV_IN_BIT_WIDTH_W 8           // 卷积乘法运算输入权重位宽
`define CONV_IN_BIT_WIDTH_B 8           // 卷积乘法运算输入偏置位宽
`define CONV_OUT_BIT_WIDTH 16           // 卷积乘法运算后结果位宽

`define MULT_5_5 25                     // 5*5 结果有多少个

`define INT8_MAX 127


`define FEATURE_MEM_ADDR_WIDTH 17       // 要读入特征图存储器的地址宽度
`define WEIGHT_MEM_ADDR_WIDTH 10        // 要读入特征图存储器的地址宽度
`define BIAS_MEM_ADDR_WIDTH 10          // 要读入特征图存储器的地址宽度


`define CONV_COMPUTE_MODE_C1    2'b00   // C1 层的计算模式
`define CONV_COMPUTE_MODE_C2    2'b01   // C2 层的计算模式
`define CONV_COMPUTE_MODE_FC1   2'b10   // FC1 层的计算模式
`define CONV_COMPUTE_MODE_FC2   2'b11   // FC2 层的计算模式

