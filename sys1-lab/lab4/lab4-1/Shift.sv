`include"conv_struct.vh"
module Shift (
    input clk,
    input rst,
    input Conv::data_t in_data,
    input in_valid,
    output reg in_ready,

    output Conv::data_vector data,
    output reg out_valid,
    input out_ready
);

    typedef enum logic {RDATA, TDATA} fsm_state;
    fsm_state state_reg;
    Conv::data_t data_reg [Conv::LEN-1:0];

    // fill the code
    integer i;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            in_ready <= 0;
            out_valid <= 0;
            state_reg <= RDATA;
            for(i=0; i<Conv::LEN; i=i+1) begin
                data_reg[i] <= 0;
            end
        end else begin
            case(state_reg)
                RDATA: begin
                    out_valid <= 0;
                    if(in_valid && in_ready) begin
                        for(i=0; i<Conv::LEN-1; i=i+1) begin
                            data_reg[i] <= data_reg[i+1];
                        end
                        data_reg[Conv::LEN-1] <= in_data;
                        state_reg <= TDATA;
                        in_ready <= 0;
                    end else begin
                        in_ready <= 1;
                    end
                end
                TDATA: begin
                    if(out_ready) begin
                        out_valid <= 1;
                        state_reg <= RDATA;
                    end
                end
            endcase
        end
    end

    generate
        for(genvar i=0; i<Conv::LEN; i=i+1) begin 
            assign data.data[i] = data_reg[i];
        end
    endgenerate

endmodule