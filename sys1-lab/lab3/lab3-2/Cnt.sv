module Cnt #(
    parameter BASE = 10,
    parameter INITIAL = 0
) (
    input en,
    input clk,
    input rstn,
    input low_co,
    input high_rst,
    output co,
    output reg [3:0] cnt
);

    // fill the code
    assign co = (cnt == BASE - 1) && en;
    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            cnt <= INITIAL[3:0];
        end else if(high_rst)begin
            cnt <= 0;
        end else if(low_co && en) begin
                if(cnt == BASE - 1) begin
                    cnt <= 0;
                end else begin
                    cnt <= cnt + 3'd1;
                end
        end 
    end

endmodule