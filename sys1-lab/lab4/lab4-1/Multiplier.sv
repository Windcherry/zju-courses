`include "conv_struct.vh"
module Multiplier #(
    parameter LEN = 32
) (
    input clk,
    input rst,
    input [LEN-1:0] multiplicand,
    input [LEN-1:0] multiplier,
    input start,
    
    output [LEN*2-1:0] product,
    output finish
);

    localparam PRODUCT_LEN = LEN*2;
    logic [LEN-1:0] multiplicand_reg;
    logic [PRODUCT_LEN-1:0] product_reg;

    localparam CNT_LEN = $clog2(LEN); //CNT_LEN = 5
    localparam CNT_NUM = LEN - 1;     //CNT_NUM = 31
    typedef enum logic [1:0] {IDLE, WORK_SHIFT, WORK_ADD, FINAL} fsm_state;
    fsm_state fsm_state_reg;
    logic [CNT_LEN:0] work_cnt;

    // fill the code

    logic [PRODUCT_LEN:0] result;
    logic finish_signal;

    assign product = product_reg;
    assign finish = finish_signal;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            fsm_state_reg <= IDLE;
            product_reg <= 0;
            work_cnt <= 0;
        end else begin
            case(fsm_state_reg)
                IDLE: begin
                    finish_signal <= 0;
                    if(start) begin
                        multiplicand_reg <= multiplicand;
                        result <= {{(LEN+1){1'b0}}, multiplier};
                        work_cnt <= 0;
                        fsm_state_reg <= WORK_ADD;
                    end
                end
                WORK_ADD: begin
                    if(result[0]) begin
                        result[PRODUCT_LEN:LEN] <= result[PRODUCT_LEN:LEN] + multiplicand_reg;
                    end
                        fsm_state_reg <= WORK_SHIFT;
                    end
                WORK_SHIFT: begin
                    if(work_cnt == CNT_NUM) begin
                        result <= result >> 1;
                        fsm_state_reg <= FINAL;
                    end else begin
                        result <= result >> 1;
                        work_cnt <= work_cnt + 1;
                        fsm_state_reg <= WORK_ADD;
                    end
                end
                FINAL: begin
                    product_reg <= result[PRODUCT_LEN-1:0];
                    finish_signal <= 1;
                    fsm_state_reg <= IDLE;
                end
            endcase
        end
    end


    
endmodule