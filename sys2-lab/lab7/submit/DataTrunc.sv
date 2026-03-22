`include "core_struct.vh"

module DataTrunc (
    input CorePack::data_t dmem_rdata,
    input CorePack::mem_op_enum mem_op,
    input CorePack::addr_t dmem_raddr,
    output CorePack::data_t read_data
);

  import CorePack::*;

  // Data trunction
  // fill your code

  logic [2:0] byte_offset = dmem_raddr[2:0];
  logic [7:0] byte_data;
  logic [15:0] half_data;
  logic [31:0] word_data;
  
  always_comb begin
    case(byte_offset)
      3'b000: byte_data = dmem_rdata[7:0];
      3'b001: byte_data = dmem_rdata[15:8];
      3'b010: byte_data = dmem_rdata[23:16];
      3'b011: byte_data = dmem_rdata[31:24];
      3'b100: byte_data = dmem_rdata[39:32];
      3'b101: byte_data = dmem_rdata[47:40];
      3'b110: byte_data = dmem_rdata[55:48];
      3'b111: byte_data = dmem_rdata[63:56];
      default: byte_data = 0;
    endcase
    
    case(byte_offset)
      3'b000: half_data = dmem_rdata[15:0];
      3'b010: half_data = dmem_rdata[31:16];
      3'b100: half_data = dmem_rdata[47:32];
      3'b110: half_data = dmem_rdata[63:48];
      default: half_data = 0;
    endcase
    
    case(byte_offset)
      3'b000: word_data = dmem_rdata[31:0];
      3'b100: word_data = dmem_rdata[63:32];
      default: word_data = 0;
    endcase

    case(mem_op)
      MEM_D: read_data = dmem_rdata;
      
      MEM_W: read_data = {{32{word_data[31]}}, word_data};
      MEM_H: read_data = {{48{half_data[15]}}, half_data};
      MEM_B: read_data = {{56{byte_data[7]}}, byte_data};
      
      MEM_UW: read_data = {32'b0, word_data};
      MEM_UH: read_data = {48'b0, half_data};
      MEM_UB: read_data = {56'b0, byte_data};
      
      default: read_data = 0;
    endcase
  end

endmodule
