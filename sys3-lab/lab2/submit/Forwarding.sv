`include "csr_struct.vh"
`include "core_struct.vh"
module Forwarding(
    input we_reg_exe,
    input we_reg_mem,
    input we_reg_wb,
    input CorePack::reg_ind_t rd_exe,
    input CorePack::reg_ind_t rd_mem,
    input CorePack::reg_ind_t rd_wb,
    input CorePack::reg_ind_t rs1_id,
    input CorePack::reg_ind_t rs2_id,

    input we_csr_exe,
    input we_csr_mem,
    input we_csr_wb,
    input CsrPack::csr_reg_ind_t csr_addr_id,
    input CsrPack::csr_reg_ind_t csr_addr_exe,
    input CsrPack::csr_reg_ind_t csr_addr_mem,
    input CsrPack::csr_reg_ind_t csr_addr_wb,

    output CorePack::fwd_sel_enum forwarding_sel_A,
    output CorePack::fwd_sel_enum forwarding_sel_B,
    output CorePack::fwd_sel_enum forwarding_sel_csr
);

    import CorePack::*;
    import CsrPack::*;

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

    always_comb begin
        if(we_csr_exe && csr_addr_exe == csr_addr_id) begin
            forwarding_sel_csr = FWD_EXE;
        end
        else if(we_csr_mem && csr_addr_mem == csr_addr_exe) begin
            forwarding_sel_csr = FWD_MEM;
        end
        else if(we_csr_wb && csr_addr_wb == csr_addr_mem) begin
            forwarding_sel_csr = FWD_WB;
        end
        else begin
            forwarding_sel_csr = FWD_NO;
        end
    end

endmodule