`include "core_struct.vh"
`include "csr_struct.vh"
module CSRALU(
    input CorePack::data_t a,
    input CorePack::data_t b,
    input CsrPack::csr_alu_op_enmu csr_alu_op,
    output CorePack::data_t res
);
    import CorePack::*;
    import CsrPack::*;

    always_comb begin
        case(csr_alu_op)
            CSR_ALU_ADD: res = b;
            CSR_ALU_OR: res = a | b;
            CSR_ALU_ANDNOT: res = a & ~b;
            default: res = b;
        endcase
    end

endmodule