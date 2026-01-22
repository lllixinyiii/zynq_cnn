module digit_rom_ctl(
    input wire clk,
    input wire rst_n,
    input wire [10:0] col_cnt,
    input wire [9:0] row_cnt,
    
    input wire vga_vsync,
    
    output reg [6:0] digit_rom_addr
    );
    
    reg addr_update_en;
    //reg rom_show_en;
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_update_en <= 0;
        end
        else if (row_cnt <= 'd15) begin
            addr_update_en <= (col_cnt == 'd629) ? 1'b1 :
                              (col_cnt == 'd637) ? 1'b0 : addr_update_en;
        end
    end
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_rom_addr <= 0;
        end
        else if (vga_vsync) begin
            digit_rom_addr <= 0;
        end
        else if (addr_update_en) begin
            digit_rom_addr <= digit_rom_addr + 1'b1;
        end
    end
    
    
endmodule
