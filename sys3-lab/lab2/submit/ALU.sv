`include "core_struct.vh"
module ALU (
  input  CorePack::data_t a,              //data 1
  input  CorePack::data_t b,              //data 2  
  input  CorePack::alu_op_enum  alu_op,   //alu operation
  output CorePack::data_t res             //result
);

  import CorePack::*;

  // fill your code 

  function CorePack::data_t sign_extend_32(input logic [31:0] val);
    return {{32{val[31]}}, val};
  endfunction

  always_comb begin
    case(alu_op)
      ALU_ADD:     res = a + b;
      ALU_SUB:     res = a - b;
      ALU_AND:     res = a & b;
      ALU_OR:      res = a | b;
      ALU_XOR:     res = a ^ b;
      ALU_SLT:     res = ($signed(a) < $signed(b)) ? 1 : 0;
      ALU_SLTU:    res = (a < b) ? 1 : 0;
      ALU_SLL:     res = a << b[5:0];
      ALU_SRL:     res = a >> b[5:0];
      ALU_SRA:     res = $signed(a) >>> b[5:0];
      ALU_ADDW:    res = sign_extend_32(a[31:0] + b[31:0]);
      ALU_SUBW:    res = sign_extend_32(a[31:0] - b[31:0]);
      ALU_SLLW:    res = sign_extend_32(a[31:0] << b[4:0]);
      ALU_SRLW:    res = sign_extend_32(a[31:0] >> b[4:0]);
      ALU_SRAW:    res = sign_extend_32($signed(a[31:0]) >>> b[4:0]);
      ALU_DEFAULT: res = 0;
    endcase
  end
  
endmodule
