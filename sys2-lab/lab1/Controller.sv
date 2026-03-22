`include "core_struct.vh"
module controller (
    input CorePack::inst_t inst,
    output logic we_reg,
    output logic we_mem,
    output logic re_mem,
    output logic npc_sel,
    output CorePack::imm_op_enum immgen_op,
    output CorePack::alu_op_enum alu_op,
    output CorePack::cmp_op_enum cmp_op,
    output CorePack::alu_asel_op_enum alu_asel,
    output CorePack::alu_bsel_op_enum alu_bsel,
    output CorePack::wb_sel_op_enum wb_sel,
    output CorePack::mem_op_enum mem_op
    // output ControllerPack::ControllerSignals ctrl_signals
);

    import CorePack::*;
    // import ControllerPack::*;
    
    // fill your code
    wire CorePack::opcode_t opcode = inst[6:0];
    wire CorePack::funct3_t funct3 = inst[14:12];
    wire CorePack::funct7_t funct7 = inst[31:25];

    wire inst_load = (opcode == LOAD_OPCODE);
    wire inst_imm = (opcode == IMM_OPCODE);
    wire inst_auipc = (opcode == AUIPC_OPCODE);
    wire inst_immw = (opcode == IMMW_OPCODE);
    wire inst_store = (opcode == STORE_OPCODE);
    wire inst_reg = (opcode == REG_OPCODE);
    wire inst_lui = (opcode == LUI_OPCODE);
    wire inst_regw = (opcode == REGW_OPCODE);
    wire inst_branch = (opcode == BRANCH_OPCODE);
    wire inst_jalr = (opcode == JALR_OPCODE);
    wire inst_jal = (opcode == JAL_OPCODE);

    assign we_reg = inst_load | inst_imm | inst_auipc | inst_immw | inst_reg | inst_lui | inst_regw | inst_jalr | inst_jal;
    assign we_mem = inst_store;
    assign re_mem = inst_load;
    assign npc_sel = inst_branch | inst_jalr | inst_jal;

    always_comb begin
        //Initialization
        immgen_op = IMM0;
        alu_op = ALU_ADD;
        cmp_op = CMP_NO;
        alu_asel = ASEL0;
        alu_bsel = BSEL0;
        wb_sel = WB_SEL0;
        mem_op = MEM_NO;

        case(opcode)
        //Load Opcode
        LOAD_OPCODE : begin
            immgen_op = I_IMM;
            alu_asel = ASEL_REG;
            alu_bsel = BSEL_IMM;
            alu_op   = ALU_ADD;
            wb_sel   = WB_SEL_MEM;
            case(funct3)
                3'b000: begin
                    mem_op = MEM_B;
                end
                3'b001: begin
                    mem_op = MEM_H;
                end
                3'b010: begin
                    mem_op = MEM_W;
                end
                3'b011: begin
                    mem_op = MEM_D;
                end
                3'b100: begin
                    mem_op = MEM_UB;
                end
                3'b101: begin
                    mem_op = MEM_UH;
                end
                3'b110: begin
                    mem_op = MEM_UW;
                end
                default: begin
                    mem_op = MEM_NO;
                end
            endcase
            end
        //Imm Opcode
        IMM_OPCODE: begin
            immgen_op = I_IMM;
            alu_asel = ASEL_REG;
            alu_bsel = BSEL_IMM;
            wb_sel = WB_SEL_ALU;
            case(funct3) 
                3'b000: begin
                    alu_op = ALU_ADD;
                end
                3'b001: begin
                    alu_op = ALU_SLL;
                end
                3'b010: begin
                    alu_op = ALU_SLT;
                end
                 3'b011: begin
                    alu_op = ALU_SLTU;
                end
                3'b100: begin
                    alu_op = ALU_XOR;
                end
                3'b101: begin
                    if(funct7[5]) begin
                        alu_op = ALU_SRA;
                    end else begin
                        alu_op = ALU_SRL;
                    end
                end
                3'b110: begin
                    alu_op = ALU_OR;
                end
                3'b111: begin
                    alu_op = ALU_AND;
                end
            endcase
            end
        //Auipc Opcode
        AUIPC_OPCODE: begin
            immgen_op = U_IMM;
            alu_asel = ASEL_PC;
            alu_bsel = BSEL_IMM;
            alu_op   = ALU_ADD; 
            wb_sel = WB_SEL_ALU;
        end
        //Immw Opcode
        IMMW_OPCODE: begin
            immgen_op = I_IMM;
            alu_asel = ASEL_REG;
            alu_bsel = BSEL_IMM;
            wb_sel = WB_SEL_ALU;
            case(funct3)
                3'b000: begin
                    alu_op = ALU_ADDW;
                end
                3'b001: begin
                    alu_op = ALU_SLLW;
                end
                3'b101: begin
                    if(funct7[5]) begin
                        alu_op = ALU_SRAW;
                    end else begin
                        alu_op = ALU_SRLW;
                    end
                end
                default: begin
                    alu_op = ALU_ADDW;
                end
            endcase
            end
        //Store Opcode
        STORE_OPCODE: begin
            immgen_op = S_IMM;
            alu_asel = ASEL_REG;
            alu_bsel = BSEL_IMM;
            alu_op   = ALU_ADD;
            case(funct3)
                3'b000: begin
                    mem_op = MEM_B;
                end
                3'b001: begin
                    mem_op = MEM_H;
                end
                3'b010: begin
                    mem_op = MEM_W;
                end
                3'b011: begin
                    mem_op = MEM_D;
                end
                default: begin
                    mem_op = MEM_NO;
                end
            endcase
            end
        //Reg Opcode
        REG_OPCODE: begin
            immgen_op = IMM0;
            alu_asel = ASEL_REG;
            alu_bsel = BSEL_REG;
            wb_sel = WB_SEL_ALU;
                case(funct3)
                3'b000: begin
                    if(funct7[5]) begin
                         alu_op = ALU_SUB;
                    end else begin
                        alu_op = ALU_ADD;
                    end
                end
                3'b001: begin
                    alu_op = ALU_SLL;
                end
                3'b010: begin
                    alu_op = ALU_SLT;
                end
                3'b011: begin
                    alu_op = ALU_SLTU;
                end
                3'b100: begin
                    alu_op = ALU_XOR;
                end
                3'b101: begin
                    if(funct7[5]) begin
                        alu_op = ALU_SRA;
                    end else begin
                        alu_op = ALU_SRL;
                    end
                end
                3'b110: begin
                    alu_op = ALU_OR;
                end
                3'b111: begin
                    alu_op = ALU_AND;
                end
                endcase
            end
        //Lui Opcode
        LUI_OPCODE: begin
            immgen_op = U_IMM;
            alu_asel = ASEL0;
            alu_bsel = BSEL_IMM;
            alu_op   = ALU_ADD;
            wb_sel = WB_SEL_ALU;
        end
        //Regw Opcode
        REGW_OPCODE: begin
            immgen_op = IMM0;
            alu_asel = ASEL_REG;
            alu_bsel = BSEL_REG;
            wb_sel = WB_SEL_ALU;
            case(funct3)
                3'b000: begin
                    if(funct7[5]) begin
                        alu_op = ALU_SUBW;
                    end else begin
                        alu_op = ALU_ADDW;
                    end
                end
                3'b001: begin
                    alu_op = ALU_SLLW;
                end
                3'b101: begin
                     if(funct7[5]) begin
                        alu_op = ALU_SRAW;
                    end else begin
                        alu_op = ALU_SRLW;
                    end
                end
                default: begin
                    alu_op = ALU_ADDW;
                end
            endcase
        end
        //Branch Opcode
        BRANCH_OPCODE: begin
            immgen_op = B_IMM;
            alu_asel = ASEL_PC;
            alu_bsel = BSEL_IMM;
            alu_op   = ALU_ADD;
            case(funct3)
                3'b000: begin
                    cmp_op = CMP_EQ;
                end
                3'b001: begin
                    cmp_op = CMP_NE;
                end
                3'b100: begin
                    cmp_op = CMP_LT;
                end
                3'b101: begin
                    cmp_op = CMP_GE;
                end
                3'b110: begin
                    cmp_op = CMP_LTU;
                end
                3'b111: begin
                    cmp_op = CMP_GEU;
                end
                default: begin
                    cmp_op = CMP_NO;
                end
            endcase
        end
        //Jalr Opcode
        JALR_OPCODE: begin
            immgen_op = I_IMM;
            alu_asel = ASEL_REG;
            alu_bsel = BSEL_IMM;
            alu_op   = ALU_ADD;
            wb_sel   = WB_SEL_PC;
        end
        //Jal Opcode
        JAL_OPCODE: begin
            immgen_op = UJ_IMM;
            alu_asel = ASEL_PC;
            alu_bsel = BSEL_IMM;
            alu_op   = ALU_ADD;
            wb_sel   = WB_SEL_PC;
        end
        default: begin
            immgen_op = IMM0;
        end
        endcase
    end
endmodule