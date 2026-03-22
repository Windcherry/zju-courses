`include "core_struct.vh"

module AxiCore (
    input logic clk,
    input logic rstn,
    Axi_ift.Master imem_ift,
    Axi_ift.Master dmem_ift,

    output logic cosim_valid,
    output CorePack::CoreInfo cosim_core_info
);

    import CorePack::*;

    wire rst=~rstn;

    Mem_ift #(
        .ADDR_WIDTH(xLen),
        .DATA_WIDTH(xLen)
    ) imem_mem_ift ();

    Mem_ift #(
        .ADDR_WIDTH(xLen),
        .DATA_WIDTH(xLen)
    ) dmem_mem_ift ();
    
    Core core (
        .clk(clk),
        .rst(rst),
        .imem_ift(imem_mem_ift.Master),
        .dmem_ift(dmem_mem_ift.Master),
        .cosim_valid(cosim_valid),
        .cosim_core_info(cosim_core_info)
    );

    Mem2Axi imem2axi (
        .clk(clk),
        .rstn(rstn),
        .mem_ift(imem_mem_ift),
        .axi_ift(imem_ift)
    );

    Mem2Axi dmem2axi (
        .clk(clk),
        .rstn(rstn),
        .mem_ift(dmem_mem_ift),
        .axi_ift(dmem_ift)
    );

endmodule