module iic_bit_shift(
    input wire clk,
    input wire rst,
    
    input wire [5:0] cmd,
    input wire go,
    input wire [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg trans_done,
    output reg ack_o,
    output reg i2c_sclk,
    inout i2c_sdat
    );
    
    reg i2c_sdat_o;
    
    // 系统时钟 100MHz
    parameter SYS_CLOCK = 100_000_000;
    // SCL总线时钟 400KHz
    parameter SCL_CLOCK = 100_000;
    // 产生 SCL 时钟的计数器的最大值
    localparam SCL_CNT_MAX = SYS_CLOCK/SCL_CLOCK/4 - 1;             // 将一个时钟分成 4 个时刻，2 个为低电平，2 个为高电平
    
    reg i2c_sdat_oe;
    
    // 指令
    localparam
        WR      =   6'b000001,         // 写请求
        STA     =   6'b000010,         // 起始位请求
        RD      =   6'b000100,         // 读请求
        STO     =   6'b001000,         // 停止位请求
        ACK     =   6'b010000,         // 应答位请求
        NACK    =   6'b100000;         // 无应答请求
    
    reg [19:0] div_cnt;
    reg en_div_cnt;
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            div_cnt <= 0;
        end
        else if (en_div_cnt) begin
            div_cnt <= (div_cnt == SCL_CNT_MAX) ? 0 : (div_cnt + 1'b1);
        end
        else begin
            div_cnt <= 0;
        end
    end
    
    wire sclk_plus = (div_cnt == SCL_CNT_MAX);      // 得到每个时钟的 4 个时刻脉冲信号
    
    // 因为 i2c 总线有上拉电阻，所以如果想要 i2c_sdat 输出 1，只需要让线上状态为高阻即可
    assign i2c_sdat = i2c_sdat_oe ? i2c_sdat_o : 1'bz;
    
    reg [6:0] state;
    
    // 状态机状态 
    localparam
        IDLE        = 7'b000_0001,         // 空闲状态
        GEN_STA     = 7'b000_0010,         // 产生起始信号
        WR_DATA     = 7'b000_0100,         // 写数据状态
        RD_DATA     = 7'b000_1000,         // 读数据状态
        CHECK_ACK   = 7'b001_0000,         // 检测应答状态
        GEN_ACK     = 7'b010_0000,         // 产生应答状态
        GEN_STO     = 7'b100_0000;         // 产生停止信号
    
    reg [4:0] cnt;
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            rx_data <= 0;
            i2c_sdat_oe <= 1'b0;
            en_div_cnt <= 1'b0;
            i2c_sdat_o <= 1'b1;
            i2c_sclk <= 1'b1;
            trans_done <= 1'b0;
            ack_o <= 1'b0;
            state <= IDLE;
            cnt <= 'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    trans_done <= 1'b0;
                    i2c_sdat_oe <= 1'b1;
                    if (go) begin
                        en_div_cnt <= 1'b1;
                        state <= (cmd & STA) ? GEN_STA :           // 将 cmd 与每条指令按位与，看结果是否为 0 知道是否有该操作，如 cmd=000011，即有 cmd&WR==000001 cmd&STA==000010判断时逻辑为真
                                 (cmd & WR)  ? WR_DATA :
                                 (cmd & RD)  ? RD_DATA : IDLE;  
                    end
                    else begin
                        en_div_cnt <= 1'b0;
                        state <= IDLE;
                    end
                end
                GEN_STA: begin
                    if (sclk_plus) begin
                        cnt <= (cnt == 3) ? 0 : (cnt + 1'b1);
                        case (cnt)
                            0: begin i2c_sdat_o <= 1'b1; i2c_sdat_oe <= 1'b1; end
                            1: begin i2c_sclk <= 1'b1; end
                            2: begin i2c_sdat_o <= 1'b0; i2c_sclk <= 1'b1; end
                            3: begin i2c_sclk <= 1'b0; end
                            default: begin i2c_sdat_o <= 1'b1; i2c_sclk <= 1'b1; end
                        endcase
                        if (cnt == 3) begin
                            state <= (cmd & WR) ? WR_DATA :
                                     (cmd & RD) ? RD_DATA : state;
                        end
                    end
                end
                WR_DATA: begin
                    if (sclk_plus) begin
                        cnt <= (cnt == 31) ? 0 : (cnt + 1'b1);
                        case (cnt)                              // 上一个状态结尾 sclk 为低电平，这个状态一开始为低电平的中点
                            0,4,8,12,16,20,24,28:  begin i2c_sdat_o <= tx_data[7-cnt[4:2]]; i2c_sdat_oe <= 1'b1; end
                            1,5,9,13,17,21,25,29:  begin i2c_sclk <= 1'b1; end
                            2,6,10,14,18,22,26,30: begin i2c_sclk <= 1'b1; end
                            3,7,11,15,19,23,27,31: begin i2c_sclk <= 1'b0; end
                            default: begin i2c_sdat_o <= 1'b1; i2c_sclk <= 1'b1; end
                        endcase
                        state <= (cnt == 31) ? CHECK_ACK : state;
                    end
                end
                RD_DATA: begin
                    if (sclk_plus) begin
                        cnt <= (cnt == 31) ? 0 : (cnt + 1'b1);
                        case (cnt)                              
                            0,4,8,12,16,20,24,28:  begin i2c_sclk <= 1'b0; i2c_sdat_oe <= 1'b0; end
                            1,5,9,13,17,21,25,29:  begin i2c_sclk <= 1'b1; end
                            2,6,10,14,18,22,26,30: begin i2c_sclk <= 1'b1; rx_data <= {rx_data[6:0], i2c_sdat}; end     // 高电平中点读取总线数据并输出
                            3,7,11,15,19,23,27,31: begin i2c_sclk <= 1'b0; end
                            default: begin i2c_sdat_o <= 1'b1; i2c_sclk <= 1'b1; end
                        endcase
                        state <= (cnt == 31) ? GEN_ACK : state;
                    end
                end
                CHECK_ACK: begin
                    if (sclk_plus) begin
                        cnt <= (cnt == 3) ? 0 : (cnt + 1'b1);
                        case (cnt)
                            0: begin i2c_sclk <= 1'b0; i2c_sdat_oe <= 1'b0; end     // 总线为输入状态
                            1: begin i2c_sclk <= 1'b1; end
                            2: begin ack_o <= i2c_sdat; i2c_sclk <= 1'b1; end       // sclk 高电平中点采样输出处理
                            3: begin i2c_sclk <= 1'b0; end
                            default: begin i2c_sdat_o <= 1'b1; i2c_sclk <= 1'b1; end
                        endcase
                        if (cnt == 3) begin
                            state <= (cmd & STO) ? GEN_STO : IDLE;
                            trans_done <= (cmd & STO) ? trans_done : 1'b1;
                        end
                    end
                end
                GEN_ACK: begin
                    if (sclk_plus) begin
                        cnt <= (cnt == 3) ? 0 : (cnt + 1'b1);
                        case (cnt)
                            0: begin 
                                i2c_sclk <= 1'b0; 
                                i2c_sdat_oe <= 1'b1; 
                                i2c_sdat_o <= (cmd & ACK)  ? 1'b0 :
                                              (cmd & NACK) ? 1'b1 : i2c_sdat_o;
                            end
                            1: begin i2c_sclk <= 1'b1; end
                            2: begin i2c_sclk <= 1'b1; end       // sclk 高电平中点采样输出处理
                            3: begin i2c_sclk <= 1'b0; end
                            default: begin i2c_sdat_o <= 1'b1; i2c_sclk <= 1'b1; end
                        endcase
                        if (cnt == 3) begin
                            state <= (cmd & STO) ? GEN_STO : IDLE;
                            trans_done <= (cmd & STO) ? trans_done : 1'b1;
                        end
                    end
                end
                GEN_STO: begin
                    if (sclk_plus) begin
                        cnt <= (cnt == 3) ? 0 : (cnt + 1'b1);
                        case (cnt)
                            0: begin i2c_sclk <= 1'b0; i2c_sdat_o <= 1'b0; i2c_sdat_oe <= 1'b1; end     // 总线为输出状态
                            1: begin i2c_sclk <= 1'b1; end
                            2: begin i2c_sdat_o <= 1'b1; i2c_sclk <= 1'b1; end       
                            3: begin i2c_sclk <= 1'b1; end
                            default: begin i2c_sdat_o <= 1'b1; i2c_sclk <= 1'b1; end
                        endcase
                        if (cnt == 3) begin
                            state <= IDLE;
                            trans_done <= 1'b1;
                        end
                    end
                end
                default: begin
                
                end
            endcase
        end
    end
 
endmodule
