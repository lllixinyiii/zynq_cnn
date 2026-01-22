// 控制消隐区 data 为 0
module vga_data(
    // system signals
    input wire clk,
    input wire rst_n,
    // VGA
    input wire vga_vsync,
    input wire vga_hsync,
    input wire active_video,
    //
    input wire[15:0] rgb_data_i,        // VDMA
    output reg[11:0] rgb_data_o,
    
    output wire [6:0] digit_rom_addr,
    input wire [9:0] rom_data,
    
    input wire final_result_valid,
    input wire [3:0] final_result

    );
    
    reg [10:0] col_cnt;                 // 1024
    reg [9:0] row_cnt;                  // 720
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt <= 'd0;
        end
        else if (vga_hsync) begin
            col_cnt <= 'd0;
        end
        else if (active_video) begin
            col_cnt <= col_cnt + 1;
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_cnt <= 'd0;
        end
        else if (vga_vsync) begin
            row_cnt <= 'd0;
        end
        else if (active_video && col_cnt == 639) begin
            row_cnt <= row_cnt + 1;
        end
    end
    
    
    
    digit_rom_ctl drc_0(
    .clk(clk),
    .rst_n(rst_n),
    .col_cnt(col_cnt),
    .row_cnt(row_cnt),
    .vga_vsync(vga_vsync),
    .digit_rom_addr(digit_rom_addr)
    );
    
    wire rom_data_to_use;
    
    // final_result_valid 是24M时钟下的，调整一下试试
    wire final_result_valid_posedge;
    reg final_result_valid_r;
    
    always @ (posedge clk) begin
        final_result_valid_r <= final_result_valid;
    end
    
    assign final_result_valid_posedge = !final_result_valid_r & final_result_valid;
    
    reg[3:0] rom_data_sel;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_sel <= 0;
        end
        else begin
            rom_data_sel <= (final_result_valid_posedge) ? final_result : rom_data_sel;
        end
    end
    
    assign rom_data_to_use = (rom_data_sel == 4'd0) ? rom_data[0] :
                             (rom_data_sel == 4'd1) ? rom_data[1] :
                             (rom_data_sel == 4'd2) ? rom_data[2] :
                             (rom_data_sel == 4'd3) ? rom_data[3] :
                             (rom_data_sel == 4'd4) ? rom_data[4] :
                             (rom_data_sel == 4'd5) ? rom_data[5] :
                             (rom_data_sel == 4'd6) ? rom_data[6] :
                             (rom_data_sel == 4'd7) ? rom_data[7] :
                             (rom_data_sel == 4'd8) ? rom_data[8] :
                             (rom_data_sel == 4'd9) ? rom_data[9] : 1'b1;
    
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rgb_data_o <= 12'h0;
        end
        /*else if (col_cnt == 111 && row_cnt <= 111) begin
            rgb_data_o <= 12'h0;
        end
        else if (row_cnt == 111 && col_cnt <= 111) begin
            rgb_data_o <= 12'h0;
        end*/
        else if (row_cnt <= 'd15 && col_cnt >= 'd632 && col_cnt <= 'd639) begin
            rgb_data_o <= {12{rom_data_to_use}};
        end
        else if (active_video) begin
            // rgb_data_o <= {rgb_data_i[3:0], rgb_data_i[15:12], rgb_data_i[11:8]};
            rgb_data_o <= {rgb_data_i[11:8], rgb_data_i[7:4], rgb_data_i[3:0]};
        end
        else begin
            rgb_data_o <= 12'h0;
        end
    end
    
    //assign rgb_data_o = (active_video) ? {rgb_data_i[3:0], rgb_data_i[15:12], rgb_data_i[11:8]} : 0;
    //assign rgb_data_o = (active_video) ? {3{rgb_data_i[7:4]}} : 0;                // 这种情况不显示
endmodule
