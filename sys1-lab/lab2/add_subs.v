module AddSubers #(
    parameter LENGTH = 32
)(
    input [LENGTH-1:0] a,
    input [LENGTH-1:0] b,
    input do_sub,
    output [LENGTH-1:0] s,
    output c
);
    //fill your code here
    wire [LENGTH-1:0] result;
    wire [LENGTH-1:0] temp_sum;
    wire c1;
    wire c2;

    Adders adder1(
        .a(do_sub ? (b^{LENGTH{1'b1}}) : (b^{LENGTH{1'b0}})),
        .b(do_sub ? LENGTH'h1 : LENGTH'h0),
        .c_in(1'b0),
        .s(temp_sum),
        .c_out(c1)
    );

    Adders adder2(
        .a(a),
        .b(temp_sum),
        .c_in(c1),
        .s(result),
        .c_out(c2)
    );
    assign s = result;
    assign c = c2;

endmodule
