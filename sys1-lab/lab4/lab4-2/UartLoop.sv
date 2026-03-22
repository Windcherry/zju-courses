`include"uart_struct.vh"
module UartLoop(
    input clk,
    input rstn,
    Decoupled_ift.Slave uart_rdata,
    Decoupled_ift.Master uart_tdata,
    input UartPack::uart_t debug_data,
    input logic debug_send,
    output UartPack::uart_t debug_rdata,
    output UartPack::uart_t debug_tdata
);
    import UartPack::*;

    uart_t rdata;
    logic rdata_valid;

    uart_t tdata;
    logic tdata_valid;

    // fill the code
    logic uart_tdata_valid_reg;
    uart_t uart_tdata_data_reg;

    assign uart_rdata.ready = (~rdata_valid) && (~tdata_valid || uart_tdata.ready) && (~debug_send);

    always@(posedge clk or negedge rstn) begin
        if(~rstn) begin
            rdata_valid <= 0;
            rdata <= {UartPack::UART_DATA_WIDTH{1'b0}};
        end else begin
            if(uart_rdata.valid && uart_rdata.ready) begin
                rdata <= uart_rdata.data;
                rdata_valid <= 1;
            end else if (rdata_valid && !tdata_valid) begin
                rdata_valid <= 0;
            end else if(debug_send) begin
                rdata_valid <= 0;
            end
        end
    end

    always@(posedge clk or negedge rstn) begin
        if(~rstn) begin
            tdata_valid <= 0;
            tdata <= {UartPack::UART_DATA_WIDTH{1'b0}};
        end else begin
            if(!tdata_valid && rdata_valid) begin
                if(debug_send) begin
                    tdata <= debug_data;
                    tdata_valid <= 1;
                end else begin
                    tdata <= rdata;
                    tdata_valid <= 1;
                end
            end
            if (uart_tdata.ready && tdata_valid) begin
                tdata_valid <= 0;
            end
        end
    end

    always@(posedge clk or negedge rstn) begin
        if(~rstn) begin
            uart_tdata_valid_reg <= 0;
            uart_tdata_data_reg <= {UartPack::UART_DATA_WIDTH{1'b0}};
        end else begin
            if(tdata_valid) begin
                uart_tdata_valid_reg <= 1;
                uart_tdata_data_reg <= tdata;
            end else if(uart_tdata.ready) begin
                uart_tdata_valid_reg <= 0;
            end
        end
    end

    assign uart_tdata.valid = uart_tdata_valid_reg;
    assign uart_tdata.data = uart_tdata_data_reg;
    
    assign debug_rdata = rdata;
    assign debug_tdata = tdata;

endmodule