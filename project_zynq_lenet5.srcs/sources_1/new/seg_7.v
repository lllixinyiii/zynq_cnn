module seg_7(
    input wire clk,
    input wire rst_n,
    
    input wire[13:0] correct_num,
    
    output reg[7:0] an,
    output reg[7:0] seg_o
    );
    // SEG CODE
    // 8'babcd_efg(dp)
    localparam [7:0] DIGIT0 = 8'b0000_0011;
    localparam [7:0] DIGIT1 = 8'b1001_1111;
    localparam [7:0] DIGIT2 = 8'b0010_0101;
    localparam [7:0] DIGIT3 = 8'b0000_1101;
    localparam [7:0] DIGIT4 = 8'b1001_1001;
    localparam [7:0] DIGIT5 = 8'b0100_1001;
    localparam [7:0] DIGIT6 = 8'b0100_0001;
    localparam [7:0] DIGIT7 = 8'b0001_1111;
    localparam [7:0] DIGIT8 = 8'b0000_0001;
    localparam [7:0] DIGIT9 = 8'b0000_1001;
    localparam [7:0] DIGITNULL = 8'b1111_1111;
    
    localparam count_num = 20'd50000;                       // 数到这个数切下一个，对于50M = 50000000 等于分频 1000 hz，每秒钟切 1000次，即 1ms 计数
    reg[19:0] seg_counter;
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seg_counter <= 0;
        end
        else begin
            seg_counter <= (seg_counter == count_num - 1) ? 0 : (seg_counter + 1);
        end
    end
    
    reg[2:0] sel_seg;                                   // 选择用哪个七段
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_seg <= 0;
        end
        else if (seg_counter == count_num - 1) begin
            sel_seg <= sel_seg + 1;
        end
    end
    
    reg [3:0] thousands, hundreds, tens, ones;
    always @(*) begin
        thousands = (correct_num / 1000) % 10;   // 提取千位
        hundreds = (correct_num / 100) % 10;    // 提取百位
        tens = (correct_num / 10) % 10;         // 提取十位
        ones = correct_num % 10;                // 提取个位
    end
    
    reg[3:0] digit_to_show;
    always @ (*) begin
        if (!rst_n) begin
            an = 8'b1111_1111;
        end
        else begin
            case(sel_seg)
                3'd0: begin
                    an = 8'b1111_1110;
                    digit_to_show = ones;
                end
                3'd1: begin
                    an = 8'b1111_1101;
                    digit_to_show = tens;
                end
                3'd2: begin
                    an = 8'b1111_1011;
                    digit_to_show = hundreds;
                end
                3'd3: begin
                    an = 8'b1111_0111;
                    digit_to_show = thousands;
                end
                3'd4: begin
                    an = 8'b1111_1111;
                    digit_to_show = 0;
                end
                3'd5: begin
                    an = 8'b1111_1111;
                    digit_to_show = 0;
                end
                3'd6: begin
                    an = 8'b1111_1111;
                    digit_to_show = 0;
                end
                3'd7: begin
                    an = 8'b1111_1111;
                    digit_to_show = 0;
                end
            endcase
        end
    end
    
    always @ (*) begin
        if (!rst_n) begin
            seg_o = 8'b1111_1111;
        end
        else begin
            case(digit_to_show)
                4'd0: begin
                    seg_o = DIGIT0;
                end
                4'd1: begin
                    seg_o = DIGIT1;
                end
                4'd2: begin
                    seg_o = DIGIT2;
                end
                4'd3: begin
                    seg_o = DIGIT3;
                end
                4'd4: begin
                    seg_o = DIGIT4;
                end
                4'd5: begin
                    seg_o = DIGIT5;
                end
                4'd6: begin
                    seg_o = DIGIT6;
                end
                4'd7: begin
                    seg_o = DIGIT7;
                end
                4'd8: begin
                    seg_o = DIGIT8;
                end
                4'd9: begin
                    seg_o = DIGIT9;
                end
                default: begin
                    seg_o = DIGITNULL;
                end
            endcase
        end
    end
endmodule
