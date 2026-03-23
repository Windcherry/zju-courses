`include "core_struct.vh"
module RegDataMux(
  input CorePack::data_t           reg_data,
  input CorePack::data_t           alu_res_exe,
  input CorePack::data_t           alu_res_mem,
  input CorePack::data_t           wb_val,
  input CorePack::fwd_sel_enum     forwarding_sel,
  output CorePack::data_t          read_data
);

  import CorePack::*;

  always_comb begin
    case(forwarding_sel)

      FWD_NO: begin
        read_data = reg_data;
      end

      FWD_EXE: begin
        read_data = alu_res_exe;
      end

      FWD_MEM: begin
        read_data = alu_res_mem;
      end

      FWD_WB: begin
        read_data = wb_val;
      end

      default: begin
        read_data = reg_data;
      end
    endcase
  end

endmodule