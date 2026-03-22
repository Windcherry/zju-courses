`ifndef __MEM_STRUCT__
`define __MEM_STRUCT__
`include"uart_struct.vh"
package MemPack;

    parameter uart_start = 64'h10000000;
    parameter uart_len   = 64'h100;

    typedef struct {
        UartPack::UartInfo uart_info;
    } MemInfo;

endpackage

`endif