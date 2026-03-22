`include "core_struct.vh"
module ImmGen(
    input CorePack::inst_t inst,
    input CorePack::imm_op_enum immgen_op,
    output CorePack::imm_t imm 
);

    //fill your code
    import CorePack::*;
    always_comb begin
        case(immgen_op)
            IMM0: begin
                imm = 0;
            end
            I_IMM: begin
                imm = {{52{inst[31]}}, inst[31:20]};
            end
            S_IMM: begin
                imm = {{52{inst[31]}}, inst[31:25], inst[11:7]};
            end
            B_IMM: begin
                imm = {{51{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            end
            U_IMM: begin
                imm = {{32{inst[31]}},inst[31:12], 12'b0};
            end
            UJ_IMM: begin
                imm = {{44{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            end
            default: begin
                imm = 0;
            end
        endcase
    end
endmodule