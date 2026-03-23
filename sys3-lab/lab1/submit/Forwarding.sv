`include "core_struct.vh"
module Forwarding(
    input logic we_reg_exe,
    input logic we_reg_mem,
    input logic we_reg_wb,
    input CorePack::reg_ind_t rd_exe,
    input CorePack::reg_ind_t rd_mem,
    input CorePack::reg_ind_t rd_wb,
    input CorePack::reg_ind_t rs1_id,
    input CorePack::reg_ind_t rs2_id,
    output CorePack::fwd_sel_enum forwarding_sel_A,
    output CorePack::fwd_sel_enum forwarding_sel_B
);

    import CorePack::*;

    always_comb begin
        if (we_reg_exe && rs1_id == rd_exe && rs1_id != 5'b0) begin
            forwarding_sel_A = FWD_EXE;
        end
        else if (we_reg_mem && rs1_id == rd_mem && rs1_id != 5'b0) begin
            forwarding_sel_A = FWD_MEM;
        end
        else if (we_reg_wb && rs1_id == rd_wb && rs1_id != 5'b0) begin
            forwarding_sel_A = FWD_WB;
        end
        else begin
            forwarding_sel_A = FWD_NO;
        end
    end

    always_comb begin
        if (we_reg_exe && rs2_id == rd_exe && rs2_id != 5'b0) begin
            forwarding_sel_B = FWD_EXE;
        end
        else if (we_reg_mem && rs2_id == rd_mem && rs2_id != 5'b0) begin
            forwarding_sel_B = FWD_MEM;
        end
        else if (we_reg_wb && rs2_id == rd_wb && rs2_id != 5'b0) begin
            forwarding_sel_B = FWD_WB;
        end
        else begin
            forwarding_sel_B = FWD_NO;
        end
    end

endmodule