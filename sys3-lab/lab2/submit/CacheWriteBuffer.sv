`include "core_struct.vh"
module CacheWriteBuffer #(
    parameter integer ADDR_WIDTH = 64,
    parameter integer DATA_WIDTH = 64,
    parameter integer BANK_NUM   = 4
) (
    // 和来自 CacheBank 的数据交互，载入 cachebank 的脏数据
    input clk,
    input rst,

    input  CorePack::addr_t addr_wb,          // cachebank 脏数据的地址
    input [BANK_NUM*DATA_WIDTH-1:0] data_wb, // cachebank 脏数据的内容
    output busy_wb,                          // 告诉 cachebank 自己是否被占用
    input need_wb,                           // cachebank 表示自己有脏数据需要写入
    input miss_cache,                        // cachebank 表示自己发生了失配，miss_cache=1 的时候 need_wb 才有意义

    // 和 CMU 交互，将数据发送给 CMU 写入内存
    input [$clog2(BANK_NUM)-1:0] bank_index, // CMU 写回数据时向 writebackbuffer 请求要写回第几个 subword
    output CorePack::addr_t addr_mem,        // 提供需要写回的地址，地址仅到 index 部分，不包括 offset
    output CorePack::data_t data_mem,        // 提供需要写回的数据
    input finish_wb                          // CMU 告知 writebackbuffer 写回完毕，write back buffer 再次空闲
);
    import CorePack::*;

    logic busy;
    addr_t addr;
    logic [DATA_WIDTH*BANK_NUM-1:0] data;
    
    always @(posedge clk) begin
        if (rst) begin
            addr <= {ADDR_WIDTH{1'b0}};
            data <= {BANK_NUM * DATA_WIDTH{1'b0}};
            busy <= 1'b0;
        end else if (miss_cache & need_wb) begin
            addr <= addr_wb;
            data <= data_wb;
            busy <= 1'b1;
        end else if (finish_wb) begin
            busy <= 1'b0;
        end
    end

    assign busy_wb  = busy;
    assign addr_mem = addr;
    data_t word [BANK_NUM-1:0];
    genvar i;
    generate
        for (i = 0; i < BANK_NUM ; i = i + 1) begin
            assign word[i] = data[(i+1)*DATA_WIDTH-1:i*DATA_WIDTH];
        end
    endgenerate
    assign data_mem = word[bank_index];
endmodule
