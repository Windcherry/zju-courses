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
    import ControllerPack::*;
    
    // Signal Definition

    //==========IF Stage===========
    logic flush_if, flush_id;
    addr_t pc_if, next_pc;
    inst_t inst_if, inst_id, inst_exe, inst_mem, inst_wb;
    logic valid_if;

    //=========ID Stage============
    logic valid_id;
    addr_t pc_id;
    reg_ind_t rs1_id, rs2_id, rd_id;
    data_t reg_data_1, reg_data_2;
    data_t read_data_1_id, read_data_2_id;
    ControllerSignals ctrl_id;
    fwd_sel_enum fwd_sel_A, fwd_sel_B;
    imm_t imm_id;

    //=========EXE Stage===========
    logic valid_exe;
    addr_t pc_exe, target_addr_exe;
    imm_t imm_exe;
    data_t read_data_1_exe, read_data_2_exe;
    reg_ind_t rd_exe, rs1_exe, rs2_exe;
    logic br_taken_exe;
    data_t alu_res_exe, alu_a_exe, alu_b_exe;
    logic cmp_res_exe;
    ControllerSignals ctrl_exe;

    //=========MEM Stage===========
    logic valid_mem;
    addr_t pc_mem;
    data_t alu_res_mem, read_data_1_mem, read_data_2_mem;
    reg_ind_t rd_mem, rs1_mem, rs2_mem;
    logic br_taken_mem;
    ControllerSignals ctrl_mem;
    data_t dmem_wdata_mem, mem_rdata_mem;
    mask_t dmem_mask_mem;
    data_t read_data_mem;
    data_t mem_rdata_latched, read_data_latched;

    //=========WB Stage============
    logic valid_wb;
    addr_t pc_wb;
    data_t alu_res_wb;
    data_t dmem_wdata_wb, mem_rdata_wb, read_data_wb;
    data_t read_data_1_wb, read_data_2_wb;
    reg_ind_t rd_wb, rs1_wb, rs2_wb;
    logic br_taken_wb;
    ControllerSignals ctrl_wb;
    data_t wb_val;

    //========Stall Signals========
    logic if_stall_axi, mem_stall_axi;

    //========State of FSM=========
    STATE current_state, next_state;

    //=======AxiFSM Outputs=======
    logic imem_ift_r_request_valid, imem_ift_r_reply_ready;
    logic dmem_ift_r_request_valid, dmem_ift_r_reply_ready;
    logic dmem_ift_w_request_valid, dmem_ift_w_reply_ready;

    // Datapath
    //===========AxiFSM===========
    AxiFSM axi_fsm(
        .clk(clk),
        .rst(rst),
        .re_mem(ctrl_exe.re_mem),
        .we_mem(ctrl_exe.we_mem),
        .imem_ift_r_request_ready(imem_ift.r_request_ready),
        .imem_ift_r_reply_valid(imem_ift.r_reply_valid),
        .dmem_ift_r_request_ready(dmem_ift.r_request_ready),
        .dmem_ift_r_reply_valid(dmem_ift.r_reply_valid),
        .dmem_ift_w_request_ready(dmem_ift.w_request_ready),
        .dmem_ift_w_reply_valid(dmem_ift.w_reply_valid),
        .if_stall(if_stall_axi),
        .mem_stall(mem_stall_axi),
        .current_state(current_state),
        .next_state(next_state),
        .imem_ift_r_request_valid(imem_ift_r_request_valid),
        .imem_ift_r_reply_ready(imem_ift_r_reply_ready),
        .dmem_ift_r_request_valid(dmem_ift_r_request_valid),
        .dmem_ift_r_reply_ready(dmem_ift_r_reply_ready),
        .dmem_ift_w_request_valid(dmem_ift_w_request_valid),
        .dmem_ift_w_reply_ready(dmem_ift_w_reply_ready)
    );

    //=======Load-Use Hazard Control=======
    logic exe_load, mem_load;
    assign exe_load = valid_exe && ctrl_exe.re_mem && (rd_exe != 5'b0);
    assign mem_load = valid_mem && ctrl_mem.re_mem && (rd_mem != 5'b0);

    logic exe_hazard, mem_hazard;
    assign exe_hazard = valid_id && (rs1_id == rd_exe && rs1_id != 0 ||
                                     rs2_id == rd_exe && rs2_id != 0);
    assign mem_hazard = valid_id && (rs1_id == rd_mem && rs1_id != 0 ||
                                     rs2_id == rd_mem && rs2_id != 0);

    logic load_use_hazard;
    assign load_use_hazard = (exe_load && exe_hazard) || (mem_load && mem_hazard);

    //==========IF Stage==========
    
    always_ff@(posedge clk or posedge rst) begin
        if(rst) begin
            pc_if <= 0;
        end
        else if(br_taken_exe) begin
            pc_if <= target_addr_exe;
        end
        else if((current_state == IF2 && next_state == IDLE) && imem_ift.r_reply_valid) 
        begin
            pc_if <= pc_if + 4;
        end
        else if(current_state == WAITFOR2 && (next_state == MEM_LOAD1 || next_state == MEM_STORE1) && imem_ift.r_reply_valid)
        begin
            pc_if <= pc_if + 4;
        end
        else if (mem_stall_axi || load_use_hazard) begin
            pc_if <= pc_if;
        end
    end 

    assign imem_ift.r_request_bits.raddr = pc_if;

    assign imem_ift.r_request_valid = imem_ift_r_request_valid;
    assign imem_ift.r_reply_ready = imem_ift_r_reply_ready;

    assign inst_if = pc_if[2] ? imem_ift.r_reply_bits.rdata[63:32] 
                        : imem_ift.r_reply_bits.rdata[31:0];

    //==========IF/ID Register==========
    assign valid_if = 1'b1;

    always_ff@(posedge clk or posedge rst) begin
        if(rst || flush_if) begin
            pc_id <= 0;
            valid_id <= 0;
            inst_id <= 0;
        end
        else if((current_state == IF2 || current_state == WAITFOR2) && imem_ift.r_reply_valid) 
        begin
            pc_id <= pc_if;
            valid_id <= valid_if;
            inst_id <= inst_if;
        end
        else if(mem_stall_axi || load_use_hazard) begin
        end
        else begin
            valid_id <= 0;
        end
    end 

    //==========ID Stage==========
    
    assign rs1_id = inst_id[19:15];
    assign rs2_id = inst_id[24:20];
    assign rd_id = inst_id[11:7];

    //Register File
    RegFile reg_file(
        .clk(clk),
        .rst(rst),
        .we(ctrl_wb.we_reg && valid_wb),
        .read_addr_1(rs1_id),
        .read_addr_2(rs2_id),
        .write_addr(rd_wb),
        .write_data(wb_val),
        .read_data_1(reg_data_1),
        .read_data_2(reg_data_2)
    );

    Forwarding forwarding(
        .we_reg_exe(ctrl_exe.we_reg && valid_exe),
        .we_reg_mem(ctrl_mem.we_reg && valid_mem),
        .we_reg_wb(ctrl_wb.we_reg && valid_wb),
        .mem_stall(mem_stall_axi),
        .rd_exe(rd_exe),
        .rd_mem(rd_mem),
        .rd_wb(rd_wb),
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .forwarding_sel_A(fwd_sel_A),
        .forwarding_sel_B(fwd_sel_B)
    );

    RegDataMux reg_data_mux1(
        .reg_data(reg_data_1),
        .alu_res_exe(alu_res_exe),
        .alu_res_mem(alu_res_mem),
        .wb_val(wb_val),
        .forwarding_sel(fwd_sel_A),
        .read_data(read_data_1_id)
    );

    RegDataMux reg_data_mux2(
        .reg_data(reg_data_2),
        .alu_res_exe(alu_res_exe),
        .alu_res_mem(alu_res_mem),
        .wb_val(wb_val),
        .forwarding_sel(fwd_sel_B),
        .read_data(read_data_2_id)
    );

    //Controller
    controller ctrl(
        .inst(inst_id),
        .we_reg(ctrl_id.we_reg),
        .we_mem(ctrl_id.we_mem),
        .re_mem(ctrl_id.re_mem),
        .npc_sel(ctrl_id.npc_sel),
        .immgen_op(ctrl_id.immgen_op),
        .alu_op(ctrl_id.alu_op),
        .cmp_op(ctrl_id.cmp_op),
        .alu_asel(ctrl_id.alu_a_sel),
        .alu_bsel(ctrl_id.alu_b_sel),
        .wb_sel(ctrl_id.wb_sel),
        .mem_op(ctrl_id.mem_op)
    );

    //Immediate Generator
    ImmGen immgen(
        .inst(inst_id),
        .immgen_op(ctrl_id.immgen_op),
        .imm(imm_id)
    );

    //==========ID/EXE Register==========
    always_ff@(posedge clk or posedge rst) begin
        if(rst || flush_id) begin
            ctrl_exe.we_mem <= 0;
            ctrl_exe.re_mem <= 0;
            ctrl_exe.npc_sel <= 0;
            ctrl_exe.immgen_op <= IMM0;
            ctrl_exe.alu_op <= ALU_DEFAULT;
            ctrl_exe.cmp_op <= CMP_NO;
            ctrl_exe.alu_a_sel <= ASEL0;
            ctrl_exe.alu_b_sel <= BSEL0;
            ctrl_exe.wb_sel <= WB_SEL0;
            ctrl_exe.mem_op <= MEM_NO;

            valid_exe <= 0;
        end
        else if(load_use_hazard) begin
            // 注入气泡 (NOP)
            ctrl_exe.we_mem <= 0;
            ctrl_exe.re_mem <= 0;
            ctrl_exe.npc_sel <= 0;
            ctrl_exe.immgen_op <= IMM0;
            ctrl_exe.alu_op <= ALU_DEFAULT;
            ctrl_exe.cmp_op <= CMP_NO;
            ctrl_exe.alu_a_sel <= ASEL0;
            ctrl_exe.alu_b_sel <= BSEL0;
            ctrl_exe.wb_sel <= WB_SEL0;
            ctrl_exe.mem_op <= MEM_NO;
            ctrl_exe.we_reg <= 0; // 关键：NOP不写寄存器
            valid_exe <= 0;       // 关键：无效指令
            
            // 保持其他信号为0，防止错误转发
            pc_exe <= 0;
            imm_exe <= 0;
            read_data_1_exe <= 0;
            read_data_2_exe <= 0;
            rd_exe <= 0;
            rs1_exe <= 0;
            rs2_exe <= 0;
            inst_exe <= 0;
        end
        else if(!mem_stall_axi) begin
            ctrl_exe <= ctrl_id;
            pc_exe <= pc_id;
            imm_exe <= imm_id;
            read_data_1_exe <= read_data_1_id;
            read_data_2_exe <= read_data_2_id;
            rd_exe <= rd_id;
            rs1_exe <= rs1_id;
            rs2_exe <= rs2_id;
            inst_exe <= inst_id;

            valid_exe <= valid_id;
        end
    end

    //==========EXE Stage==========
    always_comb begin
        case(ctrl_exe.alu_a_sel)
            ASEL0: alu_a_exe = 0;
            ASEL_REG: alu_a_exe = read_data_1_exe;
            ASEL_PC: alu_a_exe = pc_exe;
            default: alu_a_exe = read_data_1_exe;
        endcase
    end

    always_comb begin
        case(ctrl_exe.alu_b_sel)
            BSEL0: alu_b_exe = 0;
            BSEL_REG: alu_b_exe = read_data_2_exe;
            BSEL_IMM: alu_b_exe = imm_exe;
            default: alu_b_exe = read_data_2_exe;
        endcase
    end

    ALU alu(
        .a(alu_a_exe),
        .b(alu_b_exe),
        .alu_op(ctrl_exe.alu_op),
        .res(alu_res_exe)
    );

    Cmp cmp(
        .a(read_data_1_exe),
        .b(read_data_2_exe),
        .cmp_op(ctrl_exe.cmp_op),
        .cmp_res(cmp_res_exe)
    );

    assign br_taken_exe = valid_exe && ( ((inst_exe[6:0] == BRANCH_OPCODE) && cmp_res_exe) || (inst_exe[6:0] == JAL_OPCODE) || (inst_exe[6:0] == JALR_OPCODE) );
    assign target_addr_exe = alu_res_exe;

    //==========EXE/MEM Register=========
    always_ff@(posedge clk or posedge rst) begin
        if(rst) begin
            ctrl_mem.we_reg <= 0;
            ctrl_mem.we_mem <= 0;
            ctrl_mem.re_mem <= 0;
            ctrl_mem.npc_sel <= 0;
            ctrl_mem.immgen_op <= IMM0;
            ctrl_mem.alu_op <= ALU_DEFAULT;
            ctrl_mem.cmp_op <= CMP_NO;
            ctrl_mem.alu_a_sel <= ASEL0;
            ctrl_mem.alu_b_sel <= BSEL0;
            ctrl_mem.wb_sel <= WB_SEL0;
            ctrl_mem.mem_op <= MEM_NO;

            pc_mem <= 0;
            alu_res_mem <= 0;
            read_data_1_mem <= 0;
            read_data_2_mem <= 0;
            rd_mem <= 0;
            rs1_mem <= 0;
            rs2_mem <= 0;
            br_taken_mem <= 0;
            inst_mem <= 0;

            valid_mem <= 0;
        end
        else if(!mem_stall_axi) begin
            ctrl_mem <= ctrl_exe;
            pc_mem <= pc_exe;
            alu_res_mem <= alu_res_exe;
            read_data_1_mem <= read_data_1_exe;
            read_data_2_mem <= read_data_2_exe;
            rd_mem <= rd_exe;
            rs1_mem <= rs1_exe;
            rs2_mem <= rs2_exe;
            br_taken_mem <= br_taken_exe;

            inst_mem <= inst_exe;

            valid_mem <= valid_exe;
        end
    end
            
    //==========MEM Stage==========
    DataPkg data_package(
        .mem_op(ctrl_mem.mem_op),
        .reg_data(read_data_2_mem),
        .dmem_waddr(alu_res_mem),
        .dmem_wdata(dmem_wdata_mem)
    );

    MaskGen mask_generator(
        .mem_op(ctrl_mem.mem_op),
        .dmem_waddr(alu_res_mem),
        .dmem_wmask(dmem_mask_mem)
    );

    assign dmem_ift.r_request_bits.raddr = alu_res_mem;
    assign dmem_ift.r_request_valid = dmem_ift_r_request_valid && ctrl_mem.re_mem && valid_mem;
    assign dmem_ift.r_reply_ready = dmem_ift_r_reply_ready;

    assign dmem_ift.w_request_bits.waddr = alu_res_mem;
    assign dmem_ift.w_request_bits.wdata = dmem_wdata_mem;
    assign dmem_ift.w_request_bits.wmask = dmem_mask_mem;
    assign dmem_ift.w_request_valid = dmem_ift_w_request_valid && ctrl_mem.we_mem && valid_mem;
    assign dmem_ift.w_reply_ready = dmem_ift_w_reply_ready;

    assign mem_rdata_mem = (current_state == MEM_LOAD2 && dmem_ift.r_reply_valid) ? dmem_ift.r_reply_bits.rdata : 0;

    DataTrunc data_trunc(
        .dmem_rdata(mem_rdata_mem),
        .mem_op(ctrl_mem.mem_op),
        .dmem_raddr(alu_res_mem),
        .read_data(read_data_mem)
    );

    always_ff@(posedge clk or posedge rst) begin
        if(rst) begin
            mem_rdata_latched <= 0;
            read_data_latched <= 0;
        end
        else begin
            mem_rdata_latched <= mem_rdata_mem;
            read_data_latched <= read_data_mem;
        end
    end
    
    //==========MEM/WB Register==========
    always_ff@(posedge clk or posedge rst) begin
        if(rst || mem_stall_axi) begin
            ctrl_wb.we_reg <= 0;
            ctrl_wb.we_mem <= 0;
            ctrl_wb.re_mem <= 0;
            ctrl_wb.npc_sel <= 0;
            ctrl_wb.immgen_op <= IMM0;
            ctrl_wb.alu_op <= ALU_DEFAULT;
            ctrl_wb.cmp_op <= CMP_NO;
            ctrl_wb.alu_a_sel <= ASEL0;
            ctrl_wb.alu_b_sel <= BSEL0;
            ctrl_wb.wb_sel <= WB_SEL0;
            ctrl_wb.mem_op <= MEM_NO;

            pc_wb <= 0;
            alu_res_wb <= 0;
            mem_rdata_wb <= 0;
            read_data_1_wb <= 0;
            read_data_2_wb <= 0;
            rd_wb <= 0;
            rs1_wb <= 0;
            rs2_wb <= 0;
            br_taken_wb <= 0;
            read_data_wb <= 0;
            dmem_wdata_wb <= 0;
            inst_wb <= 0;

            valid_wb <= 0;
        end
        else begin
            pc_wb <= pc_mem;
            alu_res_wb <= alu_res_mem;
            mem_rdata_wb <= mem_rdata_latched;
            read_data_wb <= read_data_latched;
            ctrl_wb <= ctrl_mem;
            read_data_1_wb <= read_data_1_mem;
            read_data_2_wb <= read_data_2_mem;
            rd_wb <= rd_mem;
            rs1_wb <= rs1_mem;
            rs2_wb <= rs2_mem;
            br_taken_wb <= br_taken_mem;
            dmem_wdata_wb <= dmem_wdata_mem;
            inst_wb <= inst_mem;

            valid_wb <= valid_mem;
        end
    end

    //==========WB Stage==========
    always_comb begin
        case(ctrl_wb.wb_sel)
            WB_SEL0: wb_val = 0;
            WB_SEL_ALU: wb_val = alu_res_wb;
            WB_SEL_MEM: wb_val = read_data_wb;
            WB_SEL_PC: wb_val = pc_wb + 4;
        endcase
    end

    assign flush_if = br_taken_exe;
    assign flush_id = br_taken_exe;

    assign next_pc = br_taken_exe ? target_addr_exe : (pc_if + 4);

    assign cosim_valid               = valid_wb;
    assign cosim_core_info.pc        = pc_wb;
    assign cosim_core_info.inst      = {32'b0,inst_wb};   
    assign cosim_core_info.rs1_id    = {59'b0, rs1_wb};
    assign cosim_core_info.rs1_data  = read_data_1_wb;
    assign cosim_core_info.rs2_id    = {59'b0, rs2_wb};
    assign cosim_core_info.rs2_data  = read_data_2_wb;
    assign cosim_core_info.alu       = alu_res_wb;
    assign cosim_core_info.mem_addr  = alu_res_wb;
    assign cosim_core_info.mem_we    = {63'b0, ctrl_wb.we_mem && valid_wb};
    assign cosim_core_info.mem_wdata = dmem_wdata_wb;
    assign cosim_core_info.mem_rdata = mem_rdata_wb;
    assign cosim_core_info.rd_we     = {63'b0, ctrl_wb.we_reg && valid_wb};
    assign cosim_core_info.rd_id     = {59'b0, rd_wb}; 
    assign cosim_core_info.rd_data   = wb_val;
    assign cosim_core_info.br_taken  = {63'b0, br_taken_wb};
    assign cosim_core_info.npc       = next_pc;

endmodule