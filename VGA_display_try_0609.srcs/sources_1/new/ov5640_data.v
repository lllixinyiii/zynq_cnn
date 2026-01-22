module ov5640_data #(
    parameter CONV_IN_BIT_WIDTH_F = 8
    )
    (
    input wire rst,
    // ov5640
    input wire ov5640_pclk,
    input wire ov5640_href,
    input wire ov5640_vsync,
    input wire [7:0] ov5640_data,
    // User Interface
    output wire [11:0] data_pixel_o,       // 拼接的一个像素值
    output reg        wr_pixel_en,
    
    //input wire[7:0] binar_threshold,             // 二值化的阈值
    
    output wire wr_fm_en,                   // 写特征图存储器使能信号
    output wire [CONV_IN_BIT_WIDTH_F-1:0] wr_fm_data, 
    output reg lenet5_go                   // 写特征图存储器使能信号
    );
    
    reg [11:0] data_pixel;
    
    wire ov5640_href_posedge;
    reg ov5640_href_r;
    
    always @ (posedge ov5640_pclk)
        ov5640_href_r <= ov5640_href;
    
    assign ov5640_href_posedge = (ov5640_href & !ov5640_href_r);
    //
    wire ov5640_vsync_posedge;
    reg ov5640_vsync_r;
    
    always @ (posedge ov5640_pclk)
        ov5640_vsync_r <= ov5640_vsync;
    
    assign ov5640_vsync_posedge = (ov5640_vsync & !ov5640_vsync_r);
    
    reg byte_flag;              // 表示当前图像数据是哪一个部分   0: first byte-{4'b0,r[3:0]}   1: second byte-{g[3:0],b[3:0]}
    
    always @ (posedge ov5640_pclk or posedge rst) begin
        if (rst) begin
            data_pixel <= 'h0;
        end
        else if (!byte_flag)
            data_pixel[11:8] <= ov5640_data[3:0];
        else 
            data_pixel[7:0] <= ov5640_data;
    end
    
    always @ (posedge ov5640_pclk or posedge rst) begin
        if (rst)
            byte_flag <= 1'b0;
        else if (ov5640_href)
            byte_flag <= ~byte_flag;
        else 
            byte_flag <= 1'b0;
    end
    
    reg [3:0] frame_cnt;            // 计数，前 10 帧数据丢弃
    wire frame_valid;               // 帧有效标志信号
    always @ (posedge ov5640_pclk or posedge rst) begin
        if (rst)
            frame_cnt <= 'd0;
        else if (!frame_valid && ov5640_vsync_posedge)
            frame_cnt <= frame_cnt + 1;
    end
    
    always @ (posedge ov5640_pclk or posedge rst) begin
        if (rst)
            wr_pixel_en <= 1'b0;
        else if (frame_valid && byte_flag)              // byte_flag 为 1 的下一个时钟周期数据才拼接完成
            wr_pixel_en <= 1'b1;
        else 
            wr_pixel_en <= 1'b0;
    end
    
    assign frame_valid = (frame_cnt >= 'd10) ? 1'b1 : 1'b0;
    
    reg [10:0] col_cnt;                 // 1024
    reg [9:0] row_cnt;                  // 720
    
    always @ (posedge ov5640_pclk or posedge rst) begin
        if (rst) begin
            col_cnt <= 'd0;
        end
        else if (!ov5640_href) begin
            col_cnt <= 'd0;
        end
        else if (byte_flag) begin
            col_cnt <= col_cnt + 1;
        end
    end
    
    always @ (posedge ov5640_pclk or posedge rst) begin
        if (rst) begin
            row_cnt <= 'd0;
        end
        else if (ov5640_vsync) begin
            row_cnt <= 'd0;
        end
        else if (ov5640_href && col_cnt == 639 && byte_flag) begin
            row_cnt <= row_cnt + 1;
        end
    end
     
    // binarization
    reg binar_en;                   // 标志当前部分的数据需要进行二值化
    always @ (posedge ov5640_pclk or posedge rst) begin
        if (rst) begin
            binar_en <= 'd0;
        end
        //else if (row_cnt >= 'd185 && row_cnt <= 'd212 && byte_flag) begin
        else if (row_cnt >= 'd185 && row_cnt <= 'd296 && byte_flag) begin
            //binar_en <= (col_cnt == 'd255) ? 1'b1 :
                        //(col_cnt == 'd283) ? 1'b0 : binar_en;
            binar_en <= (col_cnt == 'd255) ? 1'b1 :
                        (col_cnt == 'd367) ? 1'b0 : binar_en;
        end
    end
    
    // Gray = 0.299R+0.587G+0.114B
    // Gray = (76R+150G+29B) / 256 
    // Gray = (76R+150G+29B) >> 8
    
    reg[15:0] r_to_gray, g_to_gray, b_to_gray;
    wire[15:0] rgb_to_gray_sum;
    wire[7:0] gray_data_pixel;
    
    wire[3:0] r_data, g_data, b_data;
    assign r_data = data_pixel[11:8];
    assign g_data = data_pixel[7:4];
    assign b_data = data_pixel[3:0];
    
    always @ (posedge ov5640_pclk) begin
        r_to_gray <= {r_data, 4'h0} * 76;
        g_to_gray <= {g_data, 4'h0} * 150;
        b_to_gray <= {b_data, 4'h0} * 29;
    end
    
    assign rgb_to_gray_sum = (r_to_gray + g_to_gray + b_to_gray);
    
    assign gray_data_pixel = rgb_to_gray_sum[15:8];
    
    wire[11:0] binar_data_pixel;
    assign binar_data_pixel = (gray_data_pixel < 'd100) ? 12'hfff : 12'h0;
        
    assign data_pixel_o = (binar_en) ? binar_data_pixel : data_pixel;
    
    // 要将二值化后的数据写入feature_mem
    assign wr_fm_en = binar_en & byte_flag & ((col_cnt % 4) == 0);            // 降采样
    //assign wr_fm_en = binar_en & byte_flag;            // 无降采样
    assign wr_fm_data = {1'b0, binar_data_pixel[6:0]};
    
    always @ (posedge ov5640_pclk) begin
        lenet5_go <= (row_cnt == 'd297 && col_cnt <= 'd1);
    end
    
endmodule
