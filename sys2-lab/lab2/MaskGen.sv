`include "core_struct.vh"

module MaskGen(
    input CorePack::mem_op_enum mem_op,
    input CorePack::addr_t dmem_waddr,
    output CorePack::mask_t dmem_wmask
);

  import CorePack::*;

  // Mask generation
  // fill your code

  logic [2:0] byte_offset = dmem_waddr[2:0];
  
  always_comb begin
    dmem_wmask = 8'b0;
    
    case(mem_op)
      MEM_D: dmem_wmask = 8'b11111111;
      
      MEM_W: begin  // 32-bit mask
        case(byte_offset)
          3'b000: dmem_wmask = 8'b00001111;
          3'b100: dmem_wmask = 8'b11110000;
          default: dmem_wmask = 8'b0;
        endcase
      end
      
      MEM_H: begin  // 16-bit mask
        case(byte_offset)
          3'b000: dmem_wmask = 8'b00000011;
          3'b001: dmem_wmask = 8'b00000110;
          3'b010: dmem_wmask = 8'b00001100;
          3'b011: dmem_wmask = 8'b00011000;
          3'b100: dmem_wmask = 8'b00110000;
          3'b101: dmem_wmask = 8'b01100000;
          3'b110: dmem_wmask = 8'b11000000;
          default: dmem_wmask = 8'b0;
        endcase
      end
      
      MEM_B: begin  // 8-bit mask
        case(byte_offset)
          3'b000: dmem_wmask = 8'b00000001;
          3'b001: dmem_wmask = 8'b00000010;
          3'b010: dmem_wmask = 8'b00000100;
          3'b011: dmem_wmask = 8'b00001000;
          3'b100: dmem_wmask = 8'b00010000;
          3'b101: dmem_wmask = 8'b00100000;
          3'b110: dmem_wmask = 8'b01000000;
          3'b111: dmem_wmask = 8'b10000000;
          default: dmem_wmask = 8'b0;
        endcase
      end
      
      default: dmem_wmask = 8'b0;
    endcase
  end

endmodule
