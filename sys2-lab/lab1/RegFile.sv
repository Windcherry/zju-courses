`include "core_struct.vh"
module RegFile (
  input clk,
  input rst,
  input we,                                         //write enable signal
  input CorePack::reg_ind_t  read_addr_1,           //register 1 for read(5 bits)
  input CorePack::reg_ind_t  read_addr_2,           //register 2 for read(5 bits)
  input CorePack::reg_ind_t  write_addr,            //register for write(5 bits)
  input  CorePack::data_t write_data,               //data to write
  output CorePack::data_t read_data_1,              //data read from register 1
  output CorePack::data_t read_data_2               //data read from register 2
);
  import CorePack::*;

  integer i;
  data_t register [1:31]; // x1 - x31, x0 keeps zero

  // fill your code

  //Write Back stage(WB)
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      for(i=1; i<=31; i=i+1) begin
        register[i] <= {CorePack::DATA_WIDTH{1'b0}};
      end
    end else begin
        if(we && write_addr != 0) begin
          register[write_addr] <= write_data;
        end
    end
  end

  //Read stage(ID)
  assign read_data_1 = (read_addr_1 == 0) ? {CorePack::DATA_WIDTH{1'b0}} : register[read_addr_1];
  assign read_data_2 = (read_addr_2 == 0) ? {CorePack::DATA_WIDTH{1'b0}} : register[read_addr_2];

endmodule
