`include "core_struct.vh"

module CacheBank #(
    parameter integer ADDR_WIDTH = 64,  // 地址线路的宽度
    parameter integer DATA_WIDTH = 64,  // 数据线路的宽度
    parameter integer BANK_NUM = 4,     // 一个 cacheline 的 word 个数
    parameter integer CAPACITY = 1024   // cache 可以存储的最大字节数
) (
    // 来自 core 的数据请求
    input clk,
    input rst,

    input   CorePack::addr_t  addr_cpu,     // 需要读写的地址信号
    input   CorePack::data_t  wdata_cpu,    // 需要写入的数据
    input                     wen_cpu,      // 写使能信号
    input   CorePack::mask_t  wmask_cpu,    // 写使能配套的字节使能信号
    input                     ren_cpu,      // 读使能信号
    output  CorePack::data_t  rdata_cpu,    // 读到的数据输出
    output                    hit_cpu,      // 是否命中

    // 如果有数据需要写回，这组信号将写回数据送入 write back buffer
    output  CorePack::addr_t          addr_wb,     // 写回数据的地址
    output  [BANK_NUM*DATA_WIDTH-1:0] data_wb,     // 写回数据的地址的内容，直接一个 cacheline
    input                             busy_wb,     // write back buffer 回应是否忙
    output                            need_wb,     // 向 write back buffer 发送将 write back buffer 内容写回内存请求

    // cache 将自己需要读入的数据信息和要被载入的 cacheline 信息给 CMU
    output  CorePack::addr_t  addr_cache,   // cache 告知 CMU 失配数据的地址
    output                    miss_cache,   // cache 告知 CMU 发生了失配
    output                    set_cache,    // cache 告知 CMU 需要写入的 way 的编号
    input                     busy_rd,      // CMU 告诉 cache 自己是否忙碌
    input   CorePack::addr_t  addr_rd,      // CMU 告诉 cache 自己从内存读入数据的地址
    input   CorePack::data_t  data_rd,      // CMU 告诉 cache 自己从内存读入数据的值
    input                     wen_rd,       // CMU 告诉 cache 自己要修改对应 cacheline 的值
    input                     set_rd,       // CMU 告诉 cache 自己要修改的 cache way 的编号
    input                     finish_rd,    // CMU 告诉 cache 自己完成了所有的读操作，一个 cacheline 载入完毕
    input                     switch_mode   // 切换特权态 switch_mode 信号
);

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
    // tag 数据类型，address 的最前端部分，为 address[TAG_END:TAG_BEGIN]
    typedef logic [INDEX_LEN-1:0] index_t;
    // index 数据类型，address 中充当 cacheline 索引的部分，为 address[INDEX_END:INDEX_BEGIN]，大小等于 LINE_NUM
    typedef logic [OFFSET_LEN-1:0] offset_t;
    // offset 数据类型，address 中充当 cacheline 内部 quadword 索引的部分，为 address[OFFSET_END:OFFSET_BEGIN]，大小等于 BANK_NUM
    typedef logic [BANK_NUM*DATA_WIDTH-1:0] data_t;

    typedef struct {
        logic  valid;   // valid 位，当 cacheline 内容有效时等于 1，无效时等于 0
        logic  dirty;   // dirty 位，当 cacheline 数据有效且被写入时等于 1，未被写入时等于 0，数据无效则无所谓，配合 write back 策略
        logic  lru;     // lru 位，当 cacheline 这个 way 最近被访问时等于 1，另一个 way 最近被访问时等于 0，配合二路组关联策略
        tag_t  tag;     // tag 位，地址中的 tag 部分
        data_t data;    // data 位，存储的数据，注意这里重新定义了data_t类型，与CorePack中data_t数据类型不同
    } CacheLine; // 一路 cacheline

    CacheLine set [1:0][LINE_NUM-1:0];
    // 二路组相联策略，有两个 way 的 cache，每个 way 有 LINE_NUM 个 cacheline

    tag_t     tag_cpu;
    index_t   index_cpu;
    offset_t  offset_cpu;
    assign tag_cpu    = addr_cpu[TAG_END:TAG_BEGIN];
    assign index_cpu  = addr_cpu[INDEX_END:INDEX_BEGIN];
    assign offset_cpu = addr_cpu[OFFSET_END:OFFSET_BEGIN];

    tag_t    tag_rd;
    index_t  index_rd;
    offset_t offset_rd;
    assign tag_rd    = addr_rd[TAG_END:TAG_BEGIN];
    assign index_rd  = addr_rd[INDEX_END:INDEX_BEGIN];
    assign offset_rd = addr_rd[OFFSET_END:OFFSET_BEGIN];

    wire [1:0] hit;
    CacheLine index_line[1:0];
    wire [DATA_WIDTH-1:0] index_line_data[1:0] [BANK_NUM-1:0];
    assign index_line[0] = set[0][index_cpu];
    assign index_line[1] = set[1][index_cpu];
    genvar v;
    generate
        for (v = 0; v < BANK_NUM; v = v + 1) begin : unpack_index_line
            assign index_line_data[0][v] = index_line[0].data[DATA_WIDTH*v+DATA_WIDTH-1:DATA_WIDTH*v];
            assign index_line_data[1][v] = index_line[1].data[DATA_WIDTH*v+DATA_WIDTH-1:DATA_WIDTH*v];
        end
    endgenerate
    assign hit[0] = (index_line[0].tag == tag_cpu) & index_line[0].valid;
    assign hit[1] = (index_line[1].tag == tag_cpu) & index_line[1].valid;
    assign hit_cpu = |hit;
    assign rdata_cpu = hit[0] ? index_line_data[0][offset_cpu] : index_line_data[1][offset_cpu];

    assign set_cache = index_line[0].lru;
    CacheLine replace_line;
    assign replace_line = index_line[set_cache];
    wire [OFFSET_END:0] pad_zero = {(OFFSET_END + 1) {1'b0}};
    wire miss_happen = ~hit_cpu & (wen_cpu | ren_cpu);
    assign need_wb    = miss_happen & replace_line.dirty;
    assign miss_cache = miss_happen & ~busy_wb & ~busy_rd & ~switch_mode;
    assign addr_cache = {addr_cpu[TAG_END:INDEX_BEGIN], pad_zero};
    assign addr_wb    = {replace_line.tag, index_cpu, pad_zero};
    assign data_wb    = replace_line.data;

    integer i;
    integer j;
    integer k;
    integer l;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < LINE_NUM; i = i + 1) begin
                set[0][i].valid <= 1'b0;
                set[1][i].valid <= 1'b0;
            end
        end else if (finish_rd) begin
            set[set_rd][index_rd].valid <= 1'b1;
        end else if (miss_cache) begin
            set[set_cache][index_cpu].valid <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < LINE_NUM; i = i + 1) begin
                set[0][i].dirty <= 1'b0;
                set[1][i].dirty <= 1'b0;
            end
        end else if (hit_cpu & wen_cpu) begin
            if (hit[0]) set[0][index_cpu].dirty <= 1'b1;
            if (hit[1]) set[1][index_cpu].dirty <= 1'b1;
        end else if (miss_cache) begin
            set[set_cache][index_cpu].dirty <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < LINE_NUM; i = i + 1) begin
                set[0][i].lru <= 1'b0;
                set[1][i].lru <= 1'b0;
            end
        end else if (hit_cpu & (wen_cpu | ren_cpu)) begin
            set[0][index_cpu].lru <= hit[0];
            set[1][index_cpu].lru <= hit[1];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < LINE_NUM; i = i + 1) begin
                set[0][i].tag <= {TAG_LEN{1'b0}};
                set[1][i].tag <= {TAG_LEN{1'b0}};
            end
        end else if (miss_cache) begin
            set[set_cache][index_cpu].tag <= tag_cpu;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 2; i = i + 1) begin
                for (j = 0; j < LINE_NUM; j = j + 1) begin
                    set[i][j].data <= {(DATA_WIDTH * BANK_NUM) {1'b0}};
                end
            end
        end else begin
            for (i = 0; i < 2; i = i + 1) begin
                for (j = 0; j < LINE_NUM; j = j + 1) begin
                    for (k = 0; k < BANK_NUM; k = k + 1) begin
                        if (set_rd == i[0] & wen_rd & index_rd == j[INDEX_LEN-1:0] &
                            offset_rd[OFFSET_LEN-1:0] == k[OFFSET_LEN-1:0]) begin
                            set[i][j].data[k*DATA_WIDTH+:DATA_WIDTH] <= data_rd;
                        end else if (hit[i] & wen_cpu & index_cpu == j[INDEX_LEN-1:0] &
                                     k[OFFSET_LEN-1:0] == offset_cpu) begin
                            for (l = 0; l < BYTE_NUM; l = l + 1) begin
                                if (wmask_cpu[l]) set[i][j].data[k*DATA_WIDTH+8*l+:8] <= wdata_cpu[8*l+:8];
                            end
                        end
                    end
                end
            end
        end
    end
endmodule
