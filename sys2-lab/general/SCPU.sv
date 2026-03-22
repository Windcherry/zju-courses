`include "core_struct.vh"
`include "mem_struct.vh"
module SCPU (
    input logic core_clk,                  /* 时钟 */ 
    input logic rstn,                      /* 重置信号 */ 
    output logic cosim_valid,
    output CorePack::CoreInfo cosim_core_info,
    output MemPack::MemInfo cosim_mem_info,

    input logic sys_clk,
    input logic rxd,
    output logic rts,
    input logic cts,
    output logic txd
);
    import CorePack::*;

    `include "initial_mem.vh"

    wire rst=~rstn;

    Mem_ift #(
        .ADDR_WIDTH(xLen),
        .DATA_WIDTH(xLen)
    ) imem_ift ();

    Mem_ift #(
        .ADDR_WIDTH(xLen),
        .DATA_WIDTH(xLen)
    ) dmem_ift ();
    
    Core core (
        .clk(core_clk),
        .rst(rst),
        .imem_ift(imem_ift.Master),
        .dmem_ift(dmem_ift.Master),
        .cosim_valid(cosim_valid),
        .cosim_core_info(cosim_core_info)
    );

    Mem_ift #(
        .ADDR_WIDTH(xLen),
        .DATA_WIDTH(xLen)
    ) dmem_ift_array [1:0] ();

    Mem_InterConnect_1To2 #(
        .MEM_BEGIN({64'h10000000, 64'h0}),
        .MEM_LENGTH({64'h100, 64'h10000000})
    ) mem_interconnect (
        .clk(core_clk),
        .rstn(rstn),
        .master0(dmem_ift.Slave),
        .slave0(dmem_ift_array[0].Master),
        .slave1(dmem_ift_array[1].Master)
    );

    MEM_Dram #(
        .FILE_PATH(FILE_PATH),
        .DATA_WIDTH(xLen),
        .CAPACITY(8192)
    ) dram (
        .clk(core_clk),
        .rstn(rstn),
        .imem_ift(imem_ift.Slave),
        .dmem_ift(dmem_ift_array[0].Slave)
    );

    UartPack::UartInfo cosim_uart_info;
    Mem_UartUnit #(
        .ClkFrequency(100000000),
    `ifdef VERILATE
        .Baud(10000000),
    `else
        .Baud(9600),
    `endif
        .FIFO_DEPTH(8),
        .FIFO_KIND("async")
    ) mem_uart (
        .core_clk(core_clk),
        .rstn(rstn),
        .mem_ift(dmem_ift_array[1].Slave),
        .sys_clk(sys_clk),
        .rxd(rxd),
        .rts(rts),
        .txd(txd),
        .cts(cts),
        .cosim_uart_info(cosim_uart_info)
    );

    assign cosim_mem_info.uart_info = cosim_uart_info;



endmodule
