`include "core_struct.vh"

module DataPkg(
    input CorePack::mem_op_enum mem_op,
    input CorePack::data_t reg_data,
    input CorePack::addr_t dmem_waddr,
    output CorePack::data_t dmem_wdata
);

  import CorePack::*;

  // Data package
  // fill your code
  
  logic [2:0] byte_offset = dmem_waddr[2:0];
  
  always_comb begin
    case(mem_op)
      MEM_D: begin
        dmem_wdata = reg_data;  // 64-bit store
      end
      
      MEM_W: begin  // 32-bit store
        case(byte_offset)
          3'b000: dmem_wdata[31:0] = reg_data[31:0];
          3'b100: dmem_wdata[63:32] = reg_data[31:0];
          default: dmem_wdata = 0;
        endcase
      end
      
      MEM_H: begin  // 16-bit store
        case(byte_offset)
          3'b000: dmem_wdata[15:0] = reg_data[15:0];
          3'b001: dmem_wdata[23:8] = reg_data[15:0];
          3'b010: dmem_wdata[31:16] = reg_data[15:0];
          3'b011: dmem_wdata[39:24] = reg_data[15:0];
          3'b100: dmem_wdata[47:32] = reg_data[15:0];
          3'b101: dmem_wdata[55:40] = reg_data[15:0];
          3'b110: dmem_wdata[63:48] = reg_data[15:0];
          default: dmem_wdata = 0;
        endcase
      end
      
      MEM_B: begin  // 8-bit store
        case(byte_offset)
          3'b000: dmem_wdata[7:0] = reg_data[7:0];
          3'b001: dmem_wdata[15:8] = reg_data[7:0];
          3'b010: dmem_wdata[23:16] = reg_data[7:0];
          3'b011: dmem_wdata[31:24] = reg_data[7:0];
          3'b100: dmem_wdata[39:32] = reg_data[7:0];
          3'b101: dmem_wdata[47:40] = reg_data[7:0];
          3'b110: dmem_wdata[55:48] = reg_data[7:0];
          3'b111: dmem_wdata[63:56] = reg_data[7:0];
          default: dmem_wdata = 0;
        endcase
      end
      
      default: dmem_wdata = 0;
    endcase
  end 

endmodule
