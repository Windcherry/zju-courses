`include "core_struct.vh"
module PC (
    input clk,
    input rst,
    input br_taken,
    input CorePack::addr_t target_addr,
    output CorePack::addr_t pc,
    output CorePack::addr_t npc,
    output CorePack::addr_t pc_plus4
);
    import CorePack::*;

    //fill your code
    assign pc_plus4 = pc + 4;
    assign npc = br_taken ? target_addr : pc_plus4;

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            pc <= 0;
        end else begin
            pc <= npc;
        end
    end

endmodule