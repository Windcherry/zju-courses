`include "core_struct.vh"
module Cache #(
    parameter integer ADDR_WIDTH = 64,
    parameter integer DATA_WIDTH = 64,
    parameter integer BANK_NUM   = 4,
    parameter integer CAPACITY   = 1024
) (
    // 来自 core 的数据请求
    input                     clk,
    input                     rst,
    input   CorePack::addr_t  addr_cpu,     // 需要读写的地址信号
    input   CorePack::data_t  wdata_cpu,    // s型指令需要写入的数据
    input                     wen_cpu,      // 写使能信号
    input   CorePack::mask_t  wmask_cpu,    // 写使能配套的掩码信号
    input                     ren_cpu,      // 读使能信号
    output  CorePack::data_t  rdata_cpu,    // 读到的数据输出
    output                    hit_cpu,      // cache 是否命中
    output                    ren_mem,      // 发生写失配时从内存读取 miss 的 cacheline 的读使能信号
    output                    wen_mem,      // 需要将 write back buffer 中内容写回内存的写使能信号

    output    CorePack::addr_t   raddr_out, // 发生写失配时从内存读取 miss 的 cacheline 的地址
    output    CorePack::addr_t   waddr_out, // 需要将 write back buffer 中内容写回内存的地址
    output    CorePack::data_t   wdata_out, // 需要将 write back buffer 中内容写回内存的数据
    output    CorePack::mask_t   wmask_out, // 将 write back buffer 中内容写回内存的掩码信号
    input     CorePack::data_t   rdata_in,  // 总线传回的读取的内容
    input                        wvalid_in, // 总线给出的写操作完成信号
    input                        rvalid_in, // 总线给出的读操作完成信号
    input                        switch_mode, // 切换特权态的信号

    output                       finish_rd
); 
    import CorePack::*;

    addr_t raddr_mem, waddr_mem;
    data_t wdata_mem, rdata_mem;
    mask_t wmask_mem;
    logic wvalid_mem, rvalid_mem;

    assign raddr_out = raddr_mem;
    assign waddr_out = waddr_mem;
    assign wdata_out = wdata_mem;
    assign wmask_out = wmask_mem;
    assign rdata_mem = rdata_in;
    assign rvalid_mem = rvalid_in;
    assign wvalid_mem = wvalid_in;

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

    typedef logic [TAG_LEN-1:0] tag_t;
    typedef logic [INDEX_LEN-1:0] index_t;
    typedef logic [OFFSET_LEN-1:0] offset_t;

    addr_t addr_wb, addr_cache, addr_rd;
    data_t data_rd;
    logic busy_wb, need_wb, miss_cache, set_cache, busy_rd, wen_rd, set_rd;
    logic [BANK_NUM*DATA_WIDTH-1:0] data_wb;

    CacheBank #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BANK_NUM  (BANK_NUM),
        .CAPACITY  (CAPACITY)
    ) cache_bank (
        .clk      (clk),
        .rst      (rst),
        .addr_cpu (addr_cpu),
        .wdata_cpu(wdata_cpu),
        .wen_cpu  (wen_cpu),
        .wmask_cpu(wmask_cpu),
        .ren_cpu  (ren_cpu),
        .rdata_cpu(rdata_cpu),
        .hit_cpu  (hit_cpu),

        .addr_wb(addr_wb),
        .data_wb(data_wb),
        .busy_wb(busy_wb),
        .need_wb(need_wb),

        .addr_cache(addr_cache),
        .miss_cache(miss_cache),
        .set_cache (set_cache),

        .busy_rd  (busy_rd),
        .addr_rd  (addr_rd),
        .data_rd  (data_rd),
        .wen_rd   (wen_rd),
        .set_rd   (set_rd),
        .finish_rd(finish_rd),
        .switch_mode(switch_mode)
    );

    addr_t addr_mem;
    data_t data_mem;
    offset_t bank_index;
    logic finish_wb;

    CacheWriteBuffer #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BANK_NUM  (BANK_NUM)
    ) cache_write_buffer (
        .clk       (clk),
        .rst       (rst),
        .addr_wb   (addr_wb),
        .data_wb   (data_wb),
        .busy_wb   (busy_wb),
        .need_wb   (need_wb),
        .miss_cache(miss_cache),

        .addr_mem  (addr_mem),
        .data_mem  (data_mem),
        .bank_index(bank_index),
        .finish_wb (finish_wb)
    );

    CMU #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BANK_NUM  (BANK_NUM),
        .CAPACITY(CAPACITY)
    ) cmu (
        .clk(clk),
        .rst(rst),

        // 与 CacheBank 交互
        .addr_cache(addr_cache),
        .set_cache(set_cache),
        .miss_cache(miss_cache),
        .busy_rd(busy_rd),
        .wen_rd(wen_rd),
        .set_rd(set_rd),
        .data_rd(data_rd),
        .addr_rd(addr_rd),
        .finish_rd(finish_rd),

        // 与总线交互
        .rvalid_in(rvalid_mem),
        .rdata_in(rdata_mem),
        .raddr_out(raddr_mem),
        .ren_mem(ren_mem),
        .wvalid_in(wvalid_mem),
        .wen_mem(wen_mem),
        .wmask_mem(wmask_mem),
        .waddr_mem(waddr_mem),
        .wdata_mem(wdata_mem),

        // 与 CacheWriteBuffer 交互
        .busy_wb(busy_wb),
        .addr_mem(addr_mem),
        .data_mem(data_mem),
        .bank_index(bank_index),
        .finish_wb(finish_wb)
    );

endmodule
