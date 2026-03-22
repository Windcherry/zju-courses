`include"conv_struct.vh"
module ConvUnit (
    input clk,
    input rst,
    input Conv::data_t in_data,
    input Conv::data_vector kernel,
    input in_valid,
    output in_ready,

    output Conv::result_t result,
    output out_valid,
    input out_ready
);

    // fill the code
    Conv::data_vector data_reg;
    logic shift_valid;
    logic Convoperator_ready;
    Shift shift_reg(
        .clk(clk),
        .rst(rst),
        .in_data(in_data),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .data(data_reg),
        .out_valid(shift_valid),
        .out_ready(Convoperator_ready)
    );
    ConvOperator conv_reg(
        .clk(clk),
        .rst(rst),
        .kernel(kernel),
        .data(data_reg),
        .in_valid(shift_valid),
        .in_ready(Convoperator_ready),
        .result(result),
        .out_valid(out_valid),
        .out_ready(out_ready)
    );
endmodule