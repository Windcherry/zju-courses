`include"conv_struct.vh"
module ConvOperator(
    input clk,
    input rst,
    input Conv::data_vector kernel,
    input Conv::data_vector data,
    input in_valid,
    output reg in_ready,

    output Conv::result_t result,
    output reg out_valid,
    input out_ready
);

    localparam VECTOR_WIDTH = 2*Conv::WIDTH;
    typedef struct {
        Conv::result_t data;
        logic valid;
    } mid_vector;

    mid_vector vector_stage1 [Conv::LEN-1:0];
    mid_vector vector_stage2;

    typedef enum logic [1:0] {RDATA, WORK, TDATA} fsm_state;
    fsm_state state_reg;

    // fill the code
    logic [VECTOR_WIDTH-1:0] stage1_data [Conv::LEN-1:0];
    logic finish [Conv::LEN-1:0];
    logic all_finish;
    integer i;
    
    Conv::result_t add_tmp [Conv::LEN-1:1] /* verilator split_var */;
    generate
    for(genvar i=0; i<Conv::LEN; i=i+1) begin    
        Multiplier #(
            .LEN(Conv::WIDTH)
        ) mul (
            .clk(clk),
            .rst(rst),
            .multiplicand(data.data[i]),
            .multiplier(kernel.data[i]),
            .start(in_valid),
            .product(stage1_data[i]),
            .finish(finish[i])
        );
        end
    endgenerate

    generate
    for(genvar i=1;i<Conv::LEN;i=i+1)begin
        if(i<Conv::LEN/2)begin
            assign add_tmp[i] = add_tmp[i*2] + add_tmp[i*2+1];
        end else begin
            assign add_tmp[i] = stage1_data[(i-Conv::LEN/2)*2] + stage1_data[(i-Conv::LEN/2)*2+1]; 
        end
    end
    endgenerate

    always@(posedge clk or posedge rst) begin
        if(rst) begin
            in_ready <= 0;
            out_valid <= 0;
            state_reg <= RDATA;
        end else begin
            case(state_reg)
                RDATA: begin
                    out_valid <= 0;
                    in_ready <= 1;
                    if(in_valid) begin
                        for(i=0; i<Conv::LEN; i=i+1) begin
                            vector_stage1[i].valid <= 0;
                        end
                        in_ready <= 0;
                        state_reg <= WORK;
                    end
                end
                WORK: begin
                    all_finish <= 1;
                    for(i=0; i<Conv::LEN; i=i+1) begin
                        if(finish[i]) begin
                            vector_stage1[i].data <= stage1_data[i];
                            vector_stage1[i].valid <= 1;
                        end else begin
                            vector_stage1[i].valid <= 0;
                            all_finish <= 0;
                        end
                    end
                    if(all_finish) begin
                        vector_stage2.data <= add_tmp[1];
                        vector_stage2.valid <= 1;
                        state_reg <= TDATA;
                    end else begin
                        vector_stage2.valid <= 0;
                        state_reg <= WORK;
                    end
                end
                TDATA: begin
                    out_valid <= vector_stage2.valid;
                    if(out_ready && out_valid) begin
                        state_reg <= RDATA;
                        out_valid <= 0;
                        vector_stage2.valid <= 0;
                    end
                end
                default: begin
                    in_ready <= 0;
                    out_valid <= 0;
                    state_reg <= RDATA;
                end
            endcase
        end
    end
    
    assign result = vector_stage2.data;

endmodule