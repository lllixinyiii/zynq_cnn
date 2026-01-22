module clk_div(
    input wire clk_100M,
    input wire rst_n,
    output reg clk_25M
    );
    reg[19:0] counter;
    
    always @ (posedge clk_100M or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end
        else begin
            counter <= (counter == 1)? 0 : (counter + 1);
        end
    end
    
    always @ (posedge clk_100M or negedge rst_n) begin
        if(!rst_n) begin
            clk_25M <= 1'b0;
        end
        else begin
            clk_25M <= (counter == 1)? ~clk_25M : clk_25M;
        end
    end

    
endmodule