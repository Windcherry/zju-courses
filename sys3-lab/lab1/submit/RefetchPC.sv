module RefetchPC #(
    parameter ADDR_WIDTH = 64
) (
    input                   clk,
    input                   rst,
    input                   inst_is_jump_exe,   // Whether the inst in EXE stage is a jump/branch
    input                   is_jump_exe,        // The true jumping result
    input                   jump_pred_exe,      // The predicted jumping result
    input [ADDR_WIDTH-1:0]  pc_exe,             // The current EXE stage PC
    input [ADDR_WIDTH-1:0]  pc_target_pred_exe, // The predicted jump target(finished in IF stage)
    input [ADDR_WIDTH-1:0]  pc_target_exe,      // The true jump target(finished in EXE stage)
    output                  mispredict,          
    output [ADDR_WIDTH-1:0] refetch_pc          // The correct PC
);

    // Three cases for misprediction:
    // 1. Predict jump but actually not jump
    // 2. Predict not jump but actually jump
    // 3. Predict is true but target pc is wrong
    assign mispredict = inst_is_jump_exe && ((is_jump_exe != jump_pred_exe) ||
                        is_jump_exe && pc_target_exe != pc_target_pred_exe);

    // If jump actually, use pc_target_exe
    // If not jump actually, use pc_exe + 4
    assign refetch_pc = is_jump_exe ? pc_target_exe : pc_exe + 4;

endmodule