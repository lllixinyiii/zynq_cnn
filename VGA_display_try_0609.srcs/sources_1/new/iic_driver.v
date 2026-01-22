module iic_driver(
    input wire clk,
    input wire rst,
    
    input wire wr_reg_req,
    input wire rd_reg_req,
    input wire [15:0] addr,             // 可能是单字节可能是二字节
    input wire addr_mode,               // 0单字节 1二字节
    input wire[7:0] wr_data,
    output reg[7:0] rd_data,
    input wire[7:0] device_id,
    output reg rw_done,
    
    input wire[31:0] dly_cnt_max,
    
    output reg ack,
    
    output wire i2c_sclk,
    inout i2c_sdat
    
    );
    
    reg [5:0] cmd;
    reg [7:0] tx_data;
    wire trans_done;
    wire ack_o;
    reg go;
    wire [15:0] reg_addr;
    
    assign reg_addr = addr_mode ? addr : {addr[7:0], addr[15:8]};
    
    wire [7:0] rx_data;
    
    localparam
        WR      =   6'b000001,         // 写请求
        STA     =   6'b000010,         // 起始位请求
        RD      =   6'b000100,         // 读请求
        STO     =   6'b001000,         // 停止位请求
        ACK     =   6'b010000,         // 应答位请求
        NACK    =   6'b100000;         // 无应答请求
    
    iic_bit_shift iic_bs_0(
        .clk(clk),
        .rst(rst),
        .cmd(cmd),
        .go(go),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .trans_done(trans_done),
        .ack_o(ack_o),
        .i2c_sclk(i2c_sclk),
        .i2c_sdat(i2c_sdat)
    );
    
    
    reg [7:0] state;
    
    // 状态机状态 
    localparam
        IDLE         = 8'b0000_0001,         // 空闲状态
        WR_REG       = 8'b0000_0010,         // 产生起始信号
        WAIT_WR_DONE = 8'b0000_0100,         // 写数据状态
        WR_REG_DONE  = 8'b0000_1000,         // 读数据状态
        RD_REG       = 8'b0001_0000,         // 检测应答状态
        WAIT_RD_DONE = 8'b0010_0000,         // 产生应答状态
        RD_REG_DONE  = 8'b0100_0000,         // 产生停止信号
        WAIT_DLY     = 8'b1000_0000;         //等待读写完成后延迟完成
    
    reg [7:0] cnt;
    reg [31:0] dly_cnt;
    
    always @ (posedge clk or posedge rst) begin
        if (rst) begin
            cmd <= 6'b0;
            tx_data <= 8'd0;
            go <= 1'b0;
            rd_data <= 0;
            state <= IDLE;
            ack <= 0;
            cnt <= 0;
            rw_done <= 0;
            dly_cnt <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    cnt <= 0;
                    ack <= 0;
                    rw_done <= 0;
                    state <= (wr_reg_req) ? WR_REG :
                             (rd_reg_req) ? RD_REG : IDLE;
                end
                
                WR_REG: begin                   // 每写一个字段都自动跳转到等待写寄存器完成状态，完成后回来写下一个字段
                    state <= WAIT_WR_DONE;
                    case (cnt)
                        0: write_byte(WR | STA, device_id);
                        1: write_byte(WR, reg_addr[15:8]);
                        2: write_byte(WR, reg_addr[7:0]);
                        3: write_byte(WR | STO, wr_data);
                        default:;
                    endcase
                end
                
                WAIT_WR_DONE: begin
                    go <= 1'b0;
                    if (trans_done) begin
                        ack <= ack | ack_o;
                        case (cnt)
                            0: begin
                                cnt <= 1;
                                state <= WR_REG;
                            end
                            1: begin
                                state <= WR_REG;
                                cnt <= (addr_mode) ? 2 : 3;
                            end
                            2: begin
                                cnt <= 3;
                                state <= WR_REG;
                            end
                            3: begin
                                state <= WR_REG_DONE;
                            end
                            default: state <= IDLE;
                        endcase
                    end
                end
                
                WR_REG_DONE: begin
                    /*rw_done <= 1'b1;
                    state <= IDLE;*/
                    state <= WAIT_DLY;
                end
                
                RD_REG: begin                   // 每写一个字段都自动跳转到等待写寄存器完成状态，完成后回来写下一个字段
                    state <= WAIT_RD_DONE;
                    case (cnt)
                        0: write_byte(WR | STA, device_id);
                        1: write_byte(WR, reg_addr[15:8]);
                        2: write_byte(WR | STO, reg_addr[7:0]);
                        3: write_byte(WR | STA, device_id | 8'd1);      // |1 因为是读请求
                        4: read_byte(RD | NACK | STO);
                        default:;
                    endcase
                end
                
                WAIT_RD_DONE: begin
                    go <= 1'b0;
                    if (trans_done) begin
                        ack <= (cnt <= 3) ? (ack | ack_o) : ack;
                        case (cnt)
                            0: begin
                                cnt <= 1;
                                state <= RD_REG;
                            end
                            1: begin
                                state <= RD_REG;
                                cnt <= (addr_mode) ? 2 : 3;
                            end
                            2: begin
                                cnt <= 3;
                                state <= RD_REG;
                            end
                            3: begin
                                cnt <= 4;
                                state <= RD_REG;
                            end
                            4: begin
                                state <= RD_REG_DONE;
                            end
                            default: state <= IDLE;
                        endcase
                    end
                end
                RD_REG_DONE: begin
                    // rw_done <= 1'b1;
                    rd_data <= rx_data;
                    // state <= IDLE;
                    state <= WAIT_DLY;
                end
                WAIT_DLY: begin
                    if(dly_cnt <= dly_cnt_max) begin
                        dly_cnt <= dly_cnt + 1'b1;
                        state <= WAIT_DLY;
                    end
                    else begin
                        dly_cnt <= 0;
                        rw_done <= 1'b1;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
    
    
    task read_byte;
        input [5:0] ctrl_cmd;
        begin
            cmd <= ctrl_cmd;
            go <= 1'b1;
        end
    endtask
    
    task write_byte;
        input [5:0] ctrl_cmd;
        input [7:0] wr_byte_data;
        begin
            cmd <= ctrl_cmd;
            go <= 1'b1;
            tx_data <= wr_byte_data;
        end
    endtask
    
    
endmodule
