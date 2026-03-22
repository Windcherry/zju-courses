`timescale 1ns / 1ps
`include"mem_ift.vh"
`include"bus_struct.vh"

module MEM_Dram #(
    parameter FILE_PATH = "",
    parameter DATA_WIDTH = 64,
    parameter CAPACITY = 4096
) (
    input clk,
    input rstn,
    Mem_ift.Slave imem_ift,
    Mem_ift.Slave dmem_ift
);

    import BusPack::*;

    localparam BYTE_NUM = DATA_WIDTH / 8;
    localparam DEPTH = CAPACITY / BYTE_NUM;
    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam ADDR_OFFSET = $clog2(BYTE_NUM); 

    `Mem_Slave_Shank_Hand(dmem_ift, w, clk)
    assign dmem_ift_w_ready =  ~dmem_ift_w_busy | dmem_ift_w_reply_fire;
    assign dmem_ift_w_valid = dmem_ift_w_busy;

    always@(posedge clk or negedge rstn)begin
        if(~rstn)begin
            dmem_ift.w_reply_bits <= '{bresp:OKAY};
        end else if(dmem_ift_w_request_fire)begin
            dmem_ift.w_reply_bits.bresp <= OKAY;
        end
    end

    `Mem_Slave_Shank_Hand(dmem_ift, r, clk)
    assign dmem_ift_r_ready =  ~dmem_ift_r_busy | dmem_ift_r_reply_fire;
    assign dmem_ift_r_valid = dmem_ift_r_busy;

    logic [dmem_ift.DATA_WIDTH-1:0] dmem_rdata;
    always@(posedge clk or negedge rstn)begin
        if(~rstn)begin
            dmem_ift.r_reply_bits.rdata <= {dmem_ift.DATA_WIDTH{1'b0}};
            dmem_ift.r_reply_bits.rresp <= OKAY;
        end else if(dmem_ift_r_request_fire)begin
            dmem_ift.r_reply_bits.rdata <= dmem_rdata;
            dmem_ift.r_reply_bits.rresp <= OKAY;
        end
    end

    `Mem_Slave_Shank_Hand(imem_ift, r, clk)
    assign imem_ift_r_ready =  ~imem_ift_r_busy | imem_ift_r_reply_fire;
    assign imem_ift_r_valid = imem_ift_r_busy;

    logic [imem_ift.DATA_WIDTH-1:0] imem_rdata;
    always@(posedge clk or negedge rstn)begin
        if(~rstn)begin
            imem_ift.r_reply_bits.rdata <= {imem_ift.DATA_WIDTH{1'b0}};
            imem_ift.r_reply_bits.rresp <= OKAY;
        end else if(imem_ift_r_request_fire)begin
            imem_ift.r_reply_bits.rdata <= imem_rdata;
            imem_ift.r_reply_bits.rresp <= OKAY;
        end
    end

    assign imem_ift.w_request_ready = 1'b0;
    assign imem_ift.w_reply_bits = '{bresp:SLVERR};
    assign imem_ift.w_reply_valid = 1'b0;

    DRAM #(
        .FILE_PATH(FILE_PATH),
        .DATA_WIDTH(DATA_WIDTH),
        .CAPACITY(CAPACITY)
    ) dram (
        .clk(clk),
        .wen(dmem_ift_w_request_fire),
        .waddr(dmem_ift.w_request_bits.waddr[ADDR_WIDTH+ADDR_OFFSET-1:ADDR_OFFSET]),
        .wdata(dmem_ift.w_request_bits.wdata),
        .wmask(dmem_ift.w_request_bits.wmask),

        .raddr0(imem_ift.r_request_bits.raddr[ADDR_WIDTH+ADDR_OFFSET-1:ADDR_OFFSET]),
        .rdata0(imem_rdata),

        .raddr1(dmem_ift.r_request_bits.raddr[ADDR_WIDTH+ADDR_OFFSET-1:ADDR_OFFSET]),
        .rdata1(dmem_rdata)
    );

endmodule

module MEM_Single_Dram #(
    parameter FILE_PATH = "",
    parameter DATA_WIDTH = 64,
    parameter CAPACITY = 4096
) (
    input clk,
    input rstn,
    Mem_ift.Slave imem_ift,
    Mem_ift.Slave dmem_ift
);
    import BusPack::*;

    localparam BYTE_NUM = DATA_WIDTH / 8;
    localparam DEPTH = CAPACITY / BYTE_NUM;
    localparam ADDR_WIDTH = $clog2(DEPTH);
    localparam ADDR_OFFSET = $clog2(BYTE_NUM); 

    DRAM #(
        .FILE_PATH(FILE_PATH),
        .DATA_WIDTH(DATA_WIDTH),
        .CAPACITY(CAPACITY)
    ) dram (
        .clk(clk),
        .wen(dmem_ift.w_request_valid & dmem_ift.w_request_ready),
        .waddr(dmem_ift.w_request_bits.waddr[ADDR_WIDTH+ADDR_OFFSET-1:ADDR_OFFSET]),
        .wdata(dmem_ift.w_request_bits.wdata),
        .wmask(dmem_ift.w_request_bits.wmask),

        .raddr0(imem_ift.r_request_bits.raddr[ADDR_WIDTH+ADDR_OFFSET-1:ADDR_OFFSET]),
        .rdata0(imem_ift.r_reply_bits.rdata),

        .raddr1(dmem_ift.r_request_bits.raddr[ADDR_WIDTH+ADDR_OFFSET-1:ADDR_OFFSET]),
        .rdata1(dmem_ift.r_reply_bits.rdata)
    );

    assign dmem_ift.w_request_ready = 1'b1;
    assign dmem_ift.w_reply_valid = 1'b1;
    assign dmem_ift.w_reply_bits = '{bresp:OKAY};

    assign dmem_ift.r_request_ready = 1'b1;
    assign dmem_ift.r_reply_bits.rresp = OKAY;
    assign dmem_ift.r_reply_valid = 1'b1;

    assign imem_ift.w_request_ready = 1'b0;
    assign imem_ift.w_reply_valid = 1'b0;
    assign imem_ift.w_reply_bits = '{bresp:OKAY};

    assign imem_ift.r_request_ready = 1'b1;
    assign imem_ift.r_reply_bits.rresp = OKAY;
    assign imem_ift.r_reply_valid = 1'b1;

endmodule

module DRAM #(
    parameter FILE_PATH = "",
    parameter DATA_WIDTH = 64,
    parameter CAPACITY = 4096
) (
    input  clk,
    input  wen,
    input  [$clog2(CAPACITY/(DATA_WIDTH/8))-1:0] waddr,
    input  [DATA_WIDTH-1:0] wdata,
    input  [DATA_WIDTH/8-1:0] wmask,
    input  [$clog2(CAPACITY/(DATA_WIDTH/8))-1:0] raddr0,
    output [DATA_WIDTH-1:0] rdata0,
    input  [$clog2(CAPACITY/(DATA_WIDTH/8))-1:0] raddr1,
    output [DATA_WIDTH-1:0] rdata1
);

    localparam BYTE_NUM = DATA_WIDTH / 8;
    localparam DEPTH = CAPACITY / BYTE_NUM;
    integer i;
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    initial begin
        $readmemh(FILE_PATH, mem);
    end

    always @(posedge clk) begin
        if (wen) begin
            for(i = 0; i < BYTE_NUM; i = i+1) begin
                if(wmask[i]) begin
                    mem[waddr][i*8 +: 8] <= wdata[i*8 +: 8];
                end
            end
        end
    end

    assign rdata0 = mem[raddr0];
    assign rdata1 = mem[raddr1];
endmodule
