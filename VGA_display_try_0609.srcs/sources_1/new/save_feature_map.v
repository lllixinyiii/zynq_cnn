module save_feature_map #(
    parameter FEATURE_MAP_WIDTH = 28,
    parameter FEATURE_MEM_ADDR_WIDTH = 7,
    parameter CONV_IN_BIT_WIDTH_F = 8
    )
    (
    input wire ov5640_pclk,                  // 写数据的clk
    input wire lenet5_clk,                  // 读数据的clk
    input wire rst_n,
    input wire wr_fm_en,                   // 写特征图存储器使能信号
    input wire [CONV_IN_BIT_WIDTH_F-1:0] wr_fm_data, 
    input wire lenet5_go,                   // 写特征图存储器使能信号
    
    input wire[FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_b0,            // block0 的地址
    input wire[FEATURE_MEM_ADDR_WIDTH-1:0] feature_addr_b1,            // block1 的地址
    
    output wire[CONV_IN_BIT_WIDTH_F*5-1:0] data_fm_block_0,
    output wire[CONV_IN_BIT_WIDTH_F*5-1:0] data_fm_block_1
    );
    // 必须用伪双端口ram，因为写入数据和读出数据的时钟是不一样的
    
    reg [4:0] counter_col;              // 28列
    
    always @ (posedge ov5640_pclk or negedge rst_n) begin
        if (!rst_n) begin
            counter_col <= 0;
        end
        else if (lenet5_go) begin               // 开始卷积运算，这次特征图存储已经完毕
            counter_col <= 0;
        end
        else if (wr_fm_en) begin
            counter_col <= (counter_col == FEATURE_MAP_WIDTH-1) ? 0 : (counter_col + 1);
        end
    end
    
    reg [4:0] we_row;                   // 即起到计数的作用又能提示 wea 往第几个 Byte 写
    always @ (posedge ov5640_pclk or negedge rst_n) begin
        if (!rst_n) begin
            we_row <= 5'b00001;
        end
        else if (lenet5_go) begin
            we_row <= 5'b00001;
        end
        else if (wr_fm_en && (counter_col == FEATURE_MAP_WIDTH-1)) begin
            we_row <= (we_row[4]) ? 5'b00001 : (we_row << 1);
        end
    end
    
    reg block_1_flag;                   // 这个标志位代表当前是往b0写还是b1写
    always @ (posedge ov5640_pclk or negedge rst_n) begin
        if (!rst_n) begin
            block_1_flag <= 0;
        end
        else if (lenet5_go) begin
            block_1_flag <= 0;
        end
        else begin
            block_1_flag <= (wr_fm_en && we_row[4] && (counter_col == FEATURE_MAP_WIDTH-1)) ? !block_1_flag : block_1_flag;
        end
    end
    
    reg [6:0] base_addr;
    always @ (posedge ov5640_pclk or negedge rst_n) begin
        if(!rst_n) begin
            base_addr <= 0;
        end
        else if (lenet5_go) begin
            base_addr <= 0;
        end
        else begin
            base_addr <= (block_1_flag && wr_fm_en && we_row[4] && (counter_col == FEATURE_MAP_WIDTH-1)) ? (base_addr + FEATURE_MAP_WIDTH) : base_addr;
        end
    end
    
    wire[6:0] wr_addr;
    assign wr_addr = base_addr + counter_col;
    
    wire [4:0] we_fm_block_0;
    wire [4:0] we_fm_block_1;
    
    assign we_fm_block_0 = (wr_fm_en && (!block_1_flag)) ? we_row : 0;
    assign we_fm_block_1 = (wr_fm_en && block_1_flag) ? we_row : 0; 
    
    
    // a是写入口，b是读出口
    feature_mem_block_0 fm_b0 (
      .clka(ov5640_pclk),    // input wire clka
      .wea(we_fm_block_0),      // input wire [4 : 0] wea
      .addra(wr_addr),  // input wire [6 : 0] addra
      .dina({5{wr_fm_data}}),    // input wire [39 : 0] dina
      .clkb(lenet5_clk),    // input wire clkb
      .addrb(feature_addr_b0),  // input wire [6 : 0] addrb
      .doutb(data_fm_block_0)  // output wire [39 : 0] doutb
    );
    
    feature_mem_block_1 fm_b1 (
      .clka(ov5640_pclk),    // input wire clka
      .wea(we_fm_block_1),      // input wire [4 : 0] wea
      .addra(wr_addr),  // input wire [6 : 0] addra
      .dina({5{wr_fm_data}}),    // input wire [39 : 0] dina
      .clkb(lenet5_clk),    // input wire clkb
      .addrb(feature_addr_b1),  // input wire [6 : 0] addrb
      .doutb(data_fm_block_1)  // output wire [39 : 0] doutb
    );
    
endmodule
