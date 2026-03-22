module Cnt2num #(
    parameter BASE = 24,
    parameter INITIAL = 16
)(
    input en,
    input clk,
    input rstn,
    input high_rst,
    input low_co,
    output co,
    output [7:0] cnt
);

    localparam HIGH_BASE = 10;
    localparam LOW_BASE  = 10;
    localparam HIGH_INIT = INITIAL/10;
    localparam LOW_INIT  = INITIAL%10;
    localparam HIGH_CO   = (BASE-1)/10;
    localparam LOW_CO    = (BASE-1)%10;

    // fill the code
    reg [3:0] cnt_high,cnt_low;
    reg temp_co1,temp_co2;
    wire rst_in;
    assign rst_in = high_rst || (cnt_low == LOW_CO[3:0] && cnt_high == HIGH_CO[3:0]);

    //cnt_low
    Cnt #(
        .BASE(LOW_BASE),
        .INITIAL(LOW_INIT)
    ) low_cnt (
        .en(en),
        .clk(clk),
        .rstn(rstn),
        .low_co(1'b1),
        .high_rst(rst_in),
        .co(temp_co1),
        .cnt(cnt_low)
    );

    //cnt_high
    Cnt #(
        .BASE(HIGH_BASE),
        .INITIAL(HIGH_INIT)
    ) high_cnt (
        .en(en),
        .clk(clk),
        .rstn(rstn),
        .low_co(temp_co1),
        .high_rst(rst_in),
        .co(temp_co2),
        .cnt(cnt_high)
    );

    assign co = (cnt_low == LOW_CO[3:0] && cnt_high == HIGH_CO[3:0]);
    assign cnt = {cnt_high,cnt_low};


endmodule