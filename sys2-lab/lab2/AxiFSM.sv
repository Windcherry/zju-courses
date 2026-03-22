`include "core_struct.vh"

module AxiFSM(
    input logic clk,
    input logic rst,

    input logic re_mem,
    input logic we_mem,

    input logic imem_ift_r_request_ready,
    input logic imem_ift_r_reply_valid,
    input logic dmem_ift_r_request_ready,
    input logic dmem_ift_r_reply_valid,
    input logic dmem_ift_w_request_ready,
    input logic dmem_ift_w_reply_valid,

    output logic if_stall,
    output logic mem_stall,

    output CorePack::STATE current_state,
    output CorePack::STATE next_state,

    output logic imem_ift_r_request_valid,
    output logic imem_ift_r_reply_ready,
    output logic dmem_ift_r_request_valid,
    output logic dmem_ift_r_reply_ready,
    output logic dmem_ift_w_request_valid,
    output logic dmem_ift_w_reply_ready
);

    import CorePack::*;

    always_ff@(posedge clk or posedge rst) begin
        if(rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    logic mem_request;
    assign mem_request = we_mem || re_mem;

    logic mem_load, mem_store;

    always_comb begin
        next_state = current_state;     // default: current_state

        imem_ift_r_request_valid = 1'b0;
        imem_ift_r_reply_ready = 1'b0;
        dmem_ift_r_request_valid = 1'b0;
        dmem_ift_r_reply_ready = 1'b0;
        dmem_ift_w_request_valid = 1'b0;
        dmem_ift_w_reply_ready = 1'b0;
        if_stall = 1'b0;
        mem_stall = 1'b0;

        case(current_state)
            IDLE: begin
                next_state = IF1;
            end
            IF1: begin
                imem_ift_r_request_valid = 1'b1;
                if_stall = 1'b1;

                if(mem_request) begin
                    next_state = WAITFOR1;
                end
                else if(imem_ift_r_request_valid && imem_ift_r_request_ready) begin
                    next_state = IF2;
                end
            end
            IF2: begin
                imem_ift_r_reply_ready = 1'b1;
                if_stall = 1'b1;

                if(imem_ift_r_reply_valid && imem_ift_r_reply_ready) begin
                    next_state = IDLE;
                end
            end
            WAITFOR1: begin
                imem_ift_r_request_valid = 1'b1;
                mem_stall = 1'b1;

                if(imem_ift_r_request_valid && imem_ift_r_request_ready) begin
                    next_state = WAITFOR2;
                end
            end
            WAITFOR2: begin
                imem_ift_r_reply_ready = 1'b1;
                mem_stall = 1'b1;

                if(imem_ift_r_reply_valid && imem_ift_r_reply_ready) begin
                    if(re_mem) begin
                        next_state = MEM_LOAD1;
                    end
                    else if(we_mem) begin
                        next_state = MEM_STORE1;
                    end
                    else begin
                        next_state = IDLE;
                    end
                end
            end
            MEM_LOAD1: begin
                mem_stall = 1'b1;
                dmem_ift_r_request_valid = 1'b1;

                if(dmem_ift_r_request_valid && dmem_ift_r_request_ready) begin
                    next_state = MEM_LOAD2;
                end
            end
            MEM_LOAD2: begin
                mem_stall = 1'b1;
                dmem_ift_r_reply_ready = 1'b1;

                if(dmem_ift_r_reply_valid && dmem_ift_r_reply_ready) begin
                    next_state = IDLE;
                end
            end
            MEM_STORE1: begin
                mem_stall = 1'b1;
                dmem_ift_w_request_valid = 1'b1;

                if(dmem_ift_w_request_valid && dmem_ift_w_request_ready) begin
                    next_state = MEM_STORE2;
                end
            end
            MEM_STORE2: begin
                mem_stall = 1'b1;
                dmem_ift_w_reply_ready = 1'b1;
                if(dmem_ift_w_reply_valid && dmem_ift_w_reply_ready) begin
                    next_state = IDLE;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase

    end

endmodule