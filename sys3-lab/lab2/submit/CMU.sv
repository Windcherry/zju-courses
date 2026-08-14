`include "core_struct.vh"

module CMU #(
    parameter integer ADDR_WIDTH = 64,
    parameter integer DATA_WIDTH = 64,
    parameter integer BANK_NUM   = 4,
    parameter integer CAPACITY   = 1024
) ( 
    input                         clk,
    input                         rst,

    input  CorePack::addr_t       addr_cache,
    input  logic                  set_cache,
    input  logic                  miss_cache,
    output logic                  busy_rd,
    output logic                  wen_rd,
    output logic                  set_rd,
    output CorePack::data_t       data_rd,
    output CorePack::addr_t       addr_rd,
    output logic                  finish_rd,

    input  logic                  rvalid_in,
    input  logic                  wvalid_in,    
    input  CorePack::data_t       rdata_in,
    output CorePack::addr_t       raddr_out,
    output logic                  ren_mem,
    output logic                  wen_mem,
    output CorePack::mask_t       wmask_mem,
    output CorePack::addr_t       waddr_mem,
    output CorePack::data_t       wdata_mem,

    input  logic                  busy_wb,
    input  CorePack::addr_t       addr_mem,
    input  CorePack::data_t       data_mem,
    output [$clog2(BANK_NUM)-1:0] bank_index,
    output logic                  finish_wb
);

    import CorePack::*;

    localparam BYTE_NUM = DATA_WIDTH / 8;  // 8
    localparam LINE_NUM = CAPACITY / 2 / (BANK_NUM * BYTE_NUM);  // 16
    localparam GRANU_LEN = $clog2(BYTE_NUM);  // 3
    localparam GRANU_BEGIN = 0;
    localparam GRANU_END = GRANU_BEGIN + GRANU_LEN - 1;  // 2
    localparam OFFSET_LEN = $clog2(BANK_NUM);  // 2
    localparam OFFSET_BEGIN = GRANU_END + 1;  // 3
    localparam OFFSET_END = OFFSET_BEGIN + OFFSET_LEN - 1;  // 4
    localparam INDEX_LEN = $clog2(LINE_NUM);  // 4
    localparam INDEX_BEGIN = OFFSET_END + 1;    // 5 
    localparam INDEX_END = INDEX_BEGIN + INDEX_LEN - 1;  // 8
    localparam TAG_BEGIN = INDEX_END + 1;  // 9
    localparam TAG_END = ADDR_WIDTH - 1;   // 63
    localparam TAG_LEN = ADDR_WIDTH - TAG_BEGIN;  // 55

    CMU_STATE curr_state, next_state;

    addr_t reg_addr_rd;
    logic  reg_set_rd;

    logic [1:0] rcount, wcount;

    always_ff@(posedge clk or posedge rst) begin
        if(rst) begin
            curr_state <= CMU_IDLE;
        end
        else begin
            curr_state <= next_state;
        end
    end

    always_comb begin
        next_state = curr_state;
        raddr_out = 0;
        ren_mem = 1'b0;

        wen_rd = 1'b0;
        set_rd = 1'b0;
        data_rd = 0;
        addr_rd = 0;
        finish_rd = 1'b0;

        bank_index = 2'b0;
        wen_mem = 1'b0;
        wmask_mem = 0;
        waddr_mem = 0;
        wdata_mem = 0;
        finish_wb = 0;

        case(curr_state)
            CMU_IDLE: begin
                if(miss_cache) begin
                    next_state = CMU_READ;
                end
                else begin
                    next_state = CMU_IDLE;
                end
            end
            CMU_READ: begin
                ren_mem = 1'b1;
                raddr_out = {reg_addr_rd[TAG_END:INDEX_BEGIN], rcount, 3'b000};

                addr_rd = raddr_out;
                data_rd = rdata_in;
                set_rd = reg_set_rd;
                wen_rd = rvalid_in;

                if(rvalid_in && rcount == 2'b11) begin
                    finish_rd = 1'b1;
                    if(!busy_wb) begin
                        next_state = CMU_IDLE;
                    end
                    else begin
                        next_state = CMU_WRITE;
                    end
                end
                else begin
                    next_state = CMU_READ;
                end
            end
            CMU_WRITE: begin
                bank_index = wcount;
                wen_mem = 1'b1;

                waddr_mem = {addr_mem[TAG_END:INDEX_BEGIN], wcount, 3'b000};
                wdata_mem = data_mem;
                wmask_mem = 8'hff;

                if(wvalid_in && wcount == 2'b11) begin
                    finish_wb = 1'b1;
                    next_state = CMU_IDLE;
                end
                else begin
                    next_state = CMU_WRITE;
                end
            end
            default: begin
                next_state = CMU_IDLE;
            end
        endcase
    end

    always_ff@(posedge clk or posedge rst) begin
        if(rst) begin
            reg_addr_rd <= 0;
            reg_set_rd <= 0;
            rcount <= 2'b0;
            wcount <= 2'b0;
        end
        else begin
            case(curr_state)
                CMU_IDLE: begin
                    if(miss_cache) begin
                        reg_addr_rd <= addr_cache;
                        reg_set_rd <= set_cache;
                        rcount <= 2'b0;
                        wcount <= 2'b0;
                    end
                end
                CMU_READ: begin
                    if(rvalid_in) begin
                        rcount <= rcount + 1'b1;
                    end
                end
                CMU_WRITE: begin
                    if(wvalid_in) begin
                        wcount <= wcount + 1'b1;
                    end
                end
                default: begin
                    reg_addr_rd <= 0;
                    reg_set_rd <= 0;
                    rcount <= 2'b0;
                    wcount <= 2'b0;
                end
            endcase
        end 
    end

    assign busy_rd = (curr_state != CMU_IDLE);

endmodule