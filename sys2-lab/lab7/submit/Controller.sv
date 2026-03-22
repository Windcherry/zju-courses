`include "core_struct.vh"
`include "csr_struct.vh"
module Controller (
    input CorePack::inst_t inst,
    output logic we_reg,
    output logic we_mem,
    output logic re_mem,
    output logic npc_sel,
    output logic we_csr,
    output logic [1:0] csr_ret,
    output CorePack::imm_op_enum immgen_op,
    output CorePack::alu_op_enum alu_op,
    output CorePack::cmp_op_enum cmp_op,
    output CorePack::alu_asel_op_enum alu_asel,
    output CorePack::alu_bsel_op_enum alu_bsel,
    output CorePack::wb_sel_op_enum wb_sel,
    output CorePack::mem_op_enum mem_op,
    output CsrPack::csr_alu_asel_op_enum csr_alu_asel,
    output CsrPack::csr_alu_bsel_op_enum csr_alu_bsel,
    output CsrPack::csr_alu_op_enmu csr_alu_op
    // output ControllerPack::ControllerSignals ctrl_signals
);

    import CorePack::*;
    import CsrPack::*;
    // import ControllerPack::*;
    
    // fill your code
    opcode_t opcode = inst[6:0];
    funct3_t funct3 = inst[14:12];
    funct7_t funct7 = inst[31:25];

    logic inst_load = (opcode == LOAD_OPCODE);
    logic inst_imm = (opcode == IMM_OPCODE);
    logic inst_auipc = (opcode == AUIPC_OPCODE);
    logic inst_immw = (opcode == IMMW_OPCODE);
    logic inst_store = (opcode == STORE_OPCODE);
    logic inst_reg = (opcode == REG_OPCODE);
    logic inst_lui = (opcode == LUI_OPCODE);
    logic inst_regw = (opcode == REGW_OPCODE);
    logic inst_branch = (opcode == BRANCH_OPCODE);
    logic inst_jalr = (opcode == JALR_OPCODE);
    logic inst_jal = (opcode == JAL_OPCODE);

    logic inst_csr = (opcode == CSR_OPCODE && (funct3 != 3'b000));
    logic inst_ecall = (inst == ECALL);
    logic inst_mret = (inst == MRET);
    logic inst_sret = (inst == SRET);

    assign we_reg = inst_load | inst_imm | inst_auipc | inst_immw | inst_reg | inst_lui 
                    | inst_regw | inst_jalr | inst_jal | inst_csr;
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

        we_csr = 1'b0;
        csr_ret = 2'b00;
        csr_alu_op = CSR_ALU_ADD;
        csr_alu_asel = ASEL_CSR0;
        csr_alu_bsel = BSEL_CSR0;

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
        CSR_OPCODE: begin
            if(inst_sret) csr_ret = 2'b01;
            else if(inst_mret) csr_ret = 2'b10;
            else if(inst_ecall) csr_ret = 2'b00;
            else begin
                we_csr = 1'b1;
                wb_sel = WB_SEL_CSR;
                case(funct3)
                    CSRRW_FUNCT3: begin
                        csr_alu_op = CSR_ALU_ADD;
                        csr_alu_asel = ASEL_CSRREG;
                        csr_alu_bsel = BSEL_GPREG;
                    end
                    CSRRS_FUNCT3: begin
                        csr_alu_op = CSR_ALU_OR;
                        csr_alu_asel = ASEL_CSRREG;
                        csr_alu_bsel = BSEL_GPREG;
                    end
                    CSRRC_FUNCT3: begin
                        csr_alu_op = CSR_ALU_ANDNOT;
                        csr_alu_asel = ASEL_CSRREG;
                        csr_alu_bsel = BSEL_GPREG;
                    end
                    CSRRWI_FUNCT3: begin
                        csr_alu_op = CSR_ALU_ADD;
                        csr_alu_asel = ASEL_CSRREG;
                        csr_alu_bsel = BSEL_CSRIMM;
                        immgen_op = CSR_IMM;
                    end
                    CSRRSI_FUNCT3: begin
                        csr_alu_op = CSR_ALU_OR;
                        csr_alu_asel = ASEL_CSRREG;
                        csr_alu_bsel = BSEL_CSRIMM;
                        immgen_op = CSR_IMM;
                    end
                    CSRRCI_FUNCT3: begin
                        csr_alu_op = CSR_ALU_ANDNOT;
                        csr_alu_asel = ASEL_CSRREG;
                        csr_alu_bsel = BSEL_CSRIMM;
                        immgen_op = CSR_IMM;
                    end
                    default: begin
                        we_csr = 1'b0;
                        csr_ret = 2'b00;
                    end
                endcase
            end
        end
        default: begin
        end
        endcase
    end
    
endmodule