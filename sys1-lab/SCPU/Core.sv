`include "core_struct.vh"
module Core (
    input clk,
    input rst,

    Mem_ift.Master imem_ift,
    Mem_ift.Master dmem_ift,

    output cosim_valid,
    output CorePack::CoreInfo cosim_core_info
);
    import CorePack::*;
    
    // fill your code

    //==========IF Stage==========
    addr_t pc,next_pc,pc_plus4;
    logic [31:0] inst;
    logic br_taken;
    logic npc_sel;

    PC pc_module (
        .clk(clk),
        .rst(rst),
        .br_taken(br_taken),
        .target_addr(alu_res),
        .pc(pc),
        .npc(next_pc),
        .pc_plus4(pc_plus4)
    );

    assign imem_ift.r_request_valid = 1'b1;
    assign imem_ift.r_request_bits.raddr = pc;
    assign inst = (pc[2] ? imem_ift.r_reply_bits.rdata[63:32] 
                        : imem_ift.r_reply_bits.rdata[31:0]);

    //==========ID Stage==========
    logic [4:0] rs1,rs2,rd;
    data_t read_data_1,read_data_2;
    logic we_reg,we_mem,re_mem;
    imm_t imm;

    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign rd = inst[11:7];

    //Register File
    RegFile reg_file(
        .clk(clk),
        .rst(rst),
        .we(we_reg),
        .read_addr_1(rs1),
        .read_addr_2(rs2),
        .write_addr(rd),
        .write_data(wb_val),
        .read_data_1(read_data_1),
        .read_data_2(read_data_2)
    );

    imm_op_enum immgen_op;
    alu_op_enum alu_op;
    cmp_op_enum cmp_op;
    alu_asel_op_enum alu_asel;
    alu_bsel_op_enum alu_bsel;
    wb_sel_op_enum wb_sel;
    mem_op_enum mem_op;

    //Controller
    controller ctrl(
        .inst(inst),
        .we_reg(we_reg),
        .we_mem(we_mem),
        .re_mem(re_mem),
        .npc_sel(npc_sel),
        .immgen_op(immgen_op),
        .alu_op(alu_op),
        .cmp_op(cmp_op),
        .alu_asel(alu_asel),
        .alu_bsel(alu_bsel),
        .wb_sel(wb_sel),
        .mem_op(mem_op)
    );

    //Immediate Generator
    ImmGen immgen(
        .inst(inst),
        .immgen_op(immgen_op),
        .imm(imm)
    );

    //==========EXE Stage==========
    data_t alu_res;
    data_t alu_a,alu_b;
    logic cmp_res;

    always_comb begin
        case(alu_asel)
            ASEL0: alu_a = 0;
            ASEL_PC: alu_a = pc;
            ASEL_REG: alu_a = read_data_1;
            default: alu_a = read_data_1;
        endcase
    end

    always_comb begin
        case(alu_bsel)
            BSEL0: alu_b = 0;
            BSEL_REG: alu_b = read_data_2;
            BSEL_IMM: alu_b = imm;
            default: alu_b = read_data_2;
        endcase
    end

    ALU alu(
        .a(alu_a),
        .b(alu_b),
        .alu_op(alu_op),
        .res(alu_res)
    );

    Cmp cmp(
        .a(read_data_1),
        .b(read_data_2),
        .cmp_op(cmp_op),
        .cmp_res(cmp_res)
    );

    assign br_taken = (inst[6:0] == BRANCH_OPCODE) ? cmp_res : ((inst[6:0] == JAL_OPCODE) || (inst[6:0] == JALR_OPCODE)) ? 1'b1 : 1'b0;

    //==========MEM Stage==========
    data_t dmem_wdata;
    mask_t dmem_mask;
    data_t mem_rdata;

    assign dmem_ift.r_request_valid = re_mem;
    assign dmem_ift.r_request_bits.raddr = alu_res;
    assign dmem_ift.w_request_valid = we_mem;
    assign dmem_ift.w_request_bits.waddr = alu_res;

    DataPkg data_package(
        .mem_op(mem_op),
        .reg_data(read_data_2),
        .dmem_waddr(alu_res),
        .dmem_wdata(dmem_wdata)
    );

    MaskGen mask_generator(
        .mem_op(mem_op),
        .dmem_waddr(alu_res),
        .dmem_wmask(dmem_mask)
    );

    assign dmem_ift.w_request_bits.wdata = dmem_wdata;
    assign dmem_ift.w_request_bits.wmask = dmem_mask;
    
    DataTrunc data_trunc(
        .dmem_rdata(dmem_ift.r_reply_bits.rdata),
        .mem_op(mem_op),
        .dmem_raddr(alu_res),
        .read_data(mem_rdata)
    );

    //==========WB Stage==========
    data_t wb_val;

    always_comb begin
        case(wb_sel)
            WB_SEL0: wb_val = 0;
            WB_SEL_ALU: wb_val = alu_res;
            WB_SEL_MEM: wb_val = mem_rdata;
            WB_SEL_PC: wb_val = pc_plus4;
        endcase
    end

    assign cosim_valid = 1'b1;
    assign cosim_core_info.pc        = pc;
    assign cosim_core_info.inst      = {32'b0,inst};   
    assign cosim_core_info.rs1_id    = {59'b0, rs1};
    assign cosim_core_info.rs1_data  = read_data_1;
    assign cosim_core_info.rs2_id    = {59'b0, rs2};
    assign cosim_core_info.rs2_data  = read_data_2;
    assign cosim_core_info.alu       = alu_res;
    assign cosim_core_info.mem_addr  = dmem_ift.r_request_bits.raddr;
    assign cosim_core_info.mem_we    = {63'b0, dmem_ift.w_request_valid};
    assign cosim_core_info.mem_wdata = dmem_ift.w_request_bits.wdata;
    assign cosim_core_info.mem_rdata = dmem_ift.r_reply_bits.rdata;
    assign cosim_core_info.rd_we     = {63'b0, we_reg};
    assign cosim_core_info.rd_id     = {59'b0, rd}; 
    assign cosim_core_info.rd_data   = wb_val;
    assign cosim_core_info.br_taken  = {63'b0, br_taken};
    assign cosim_core_info.npc       = next_pc;

endmodule