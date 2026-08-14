`include"core_struct.vh"
module Cmp (
    input CorePack::data_t a,
    input CorePack::data_t b,
    input CorePack::cmp_op_enum cmp_op,
    output logic cmp_res
);

    import CorePack::*;

    // fill your code
    
    always_comb begin
        case(cmp_op)
            CMP_NO: begin 
                cmp_res = 1'b0;
            end
            CMP_EQ: begin
                cmp_res = (a == b);
            end
            CMP_NE: begin
                cmp_res = (a != b);
            end
            CMP_LT: begin 
                cmp_res = ($signed(a) < $signed(b));
            end
            CMP_GE: begin
                cmp_res = ($signed(a) >= $signed(b));
            end
            CMP_LTU: begin 
                cmp_res = (a < b);
            end
            CMP_GEU: begin 
                cmp_res = (a >= b);
            end
            CMP7: begin 
                cmp_res = 1'b0;
            end
        endcase
    end
endmodule