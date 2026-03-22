module FSM(
    input rstn,
    input clk,
    input a,
    input b,
    output [1:0] state
);

    // fill your code
    localparam [1:0] S0 = 2'b00;
    localparam [1:0] S1 = 2'b01;
    localparam [1:0] S2 = 2'b10;
    localparam [1:0] S3 = 2'b11;

    reg [1:0] curr_state,next_state;
    reg [1:0] out_reg;

    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            curr_state <= S0;
        end else begin
            curr_state <= next_state;
        end
    end

    always@(*) begin
        if(!rstn) begin
            next_state = S0;
        end else begin
            case(curr_state)
            S0:begin
            if(a==1'b1) next_state = S1;
            else next_state = S0;
            end
            S1: begin
                if(a==1'b1) next_state = S2;
                else if(a==1'b0 && b==1'b1) next_state = S0;
                else next_state = S1;
            end
            S2: begin
                if(a==1'b1) next_state = S3;
                else if(a==1'b0 && b==1'b1) next_state = S0;
                else next_state = S2;
            end
            S3: begin
                next_state = S3;
            end
            default: next_state = S0;
            endcase
        end
    end

    always@(posedge clk or negedge rstn) begin
        if(!rstn) begin
            out_reg <= S0;
        end else begin
            out_reg <= next_state;
        end
    end

    assign state = out_reg;

endmodule