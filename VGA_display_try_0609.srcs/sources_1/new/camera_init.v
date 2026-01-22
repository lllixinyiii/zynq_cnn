module camera_init # (
    parameter IMAGE_WIDTH       = 16'd640,
    parameter IMAGE_HEIGHT      = 16'd480,
    parameter IMAGE_FLIP_EN     = 1'b0,
    parameter IMAGE_MIRROR_EN   = 1'b0
)
(
    input wire clk_100M,
    input wire clk_24M,
    input wire rst,
    
    output reg init_done,
    output wire ov5640_xclk,
    output wire ov5640_rst_n,
    output wire ov5640_pwdn,
    
    output i2c_sclk,
    inout i2c_sdat
    );
    
    assign ov5640_xclk = clk_24M;
    
    wire [15:0]addr;
    reg wr_reg_req;
    reg rd_reg_req = 0;
    wire [7:0]wr_data;
    wire [7:0]rd_data;
    wire rw_done;
    wire ack;
    reg [31:0] i2c_dly_cnt_max;

    reg [9:0]cnt;                   // 用来计数配置到第几个寄存器
    wire [23:0]lut;
    
    wire [9:0]lut_size;
    wire [7:0]device_id;
    wire addr_mode;
    
    //reg init_done;

    // 使用寄存器进行复位
    assign ov5640_pwdn = 0;
    
    assign device_id = 8'h78;
    assign addr_mode = 1'b1;
    assign addr = lut[23:8];        // 往哪个地址写入多少数据
    assign wr_data = lut[7:0];
    
    assign lut_size = 252;
    
    ov5640_init_table_rgb #(
        .IMAGE_WIDTH     (IMAGE_WIDTH     ),
        .IMAGE_HEIGHT    (IMAGE_HEIGHT    ),
        .IMAGE_FLIP_EN   (IMAGE_FLIP_EN   ),
        .IMAGE_MIRROR_EN (IMAGE_MIRROR_EN )
      )ov5640_init_table_rgb_inst
      (
        .addr (cnt      ),
        .clk  (clk_100M ),
        .q    (lut      )
      );
  
    iic_driver iic_driver_0(
        .clk         (clk_100M        ),    // 100M
        .rst         (rst             ),
        .wr_reg_req  (wr_reg_req      ),
        .rd_reg_req  (rd_reg_req      ),
        .addr        (addr            ),
        .addr_mode   (addr_mode       ),
        .wr_data     (wr_data         ),
        .rd_data     (rd_data         ),
        .device_id   (device_id       ),
        .rw_done     (rw_done         ),
        .ack         (ack             ),
        .dly_cnt_max (i2c_dly_cnt_max ),
        .i2c_sclk    (i2c_sclk        ),
        .i2c_sdat    (i2c_sdat        )
    );
  
    wire go;                    // 使能初始化
    reg [21:0] delay_cnt;       // 用来计时什么时候开始配置寄存器
  
    //上电并复位完成20ms后再配置摄像头，所以从上电到开始配置应该是1.0034 + 20 = 21.0034ms
    //这里为了优化逻辑，简化比较器逻辑，直接使延迟比较值为24'h100800，是21.0125ms
    always@(posedge clk_100M or posedge rst)
        if(rst)
            delay_cnt <= 22'd0;
        else if (delay_cnt == 22'h201000)
            delay_cnt <= 22'h201000;
        else
            delay_cnt <= delay_cnt + 1'd1;

    //当延时时间到，开始使能初始化模块对OV5640的寄存器进行写入  
    assign go = (delay_cnt == 22'h200FFF) ? 1'b1 : 1'b0;
  
    //5640要求上电后其复位状态需要保持1ms，所以上电后需要1ms之后再使能释放摄像头的复位信号
    //这里为了优化逻辑，简化比较器逻辑，直接使延迟比较值为24'hC400，是1.003520ms
    //assign camera_rst_n = (delay_cnt > 21'h00C400);

    assign ov5640_rst_n = 1;
  
    always@(posedge clk_100M or posedge rst)
    if(rst)
        cnt <= 0;
    else if(go) 
        cnt <= 0;
    else if(cnt < lut_size)begin
        if(rw_done)       // SCCB是don't care 虽然实际上好像还是会按照iic的规定给应答信号，但是这里还是设置为不需要考虑ack
            cnt <= cnt + 1'b1;
        else
            cnt <= cnt;
    end
    else
        //cnt <= 0;
        cnt <= cnt;                 // 测试是否能 init_done
    
    always@(posedge clk_100M or posedge rst)
        if(rst)
            init_done <= 0;
        else if(go) 
            init_done <= 0;
        else if(cnt == lut_size)
            init_done <= 1;

    reg [1:0]state;         // 这里的状态机是摄像头初始化的状态机

    always@(posedge clk_100M or posedge rst)
        if(rst)begin
            state <= 0;
            wr_reg_req <= 1'b0;
            i2c_dly_cnt_max <= 32'd0;
        end
        else if(cnt < lut_size)begin
            case(state)
                0:
                    if(go)
                        state <= 1;
                    else
                        state <= 0;
                1: begin
                    wr_reg_req <= 1'b1;
                    state <= 2;
                    if(cnt == 1)
                        i2c_dly_cnt_max <= 32'h80000; //延时5ms       // 当写完 rom[1] 复位后需要延时 5ms
                    else
                        i2c_dly_cnt_max <= 32'd0;
                end
                2: begin
                    wr_reg_req <= 1'b0;
                    if(rw_done)
                        state <= 1;
                    else
                        state <= 2;
                end
                default:state <= 0;
            endcase
        end
        else begin
            state <= 0;
        end
    
endmodule
