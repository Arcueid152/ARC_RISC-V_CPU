`include "defines.vh"
module if_id (
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] instr_addr_in,
    input   wire [31:0] instr_in,
    input   wire        instr_hold,
    output  reg  [31:0] instr_addr_out,
    output  reg  [31:0] instr_out
  );

  always @(posedge clk or posedge rst)
    if(rst)
    begin
      instr_addr_out <= 32'h0;
      instr_out <= `INST_NOP;
    end
    else if (instr_hold)
    begin
      instr_addr_out <= 32'h0;
      instr_out <= `INST_NOP;
    end

    else
    begin
      instr_addr_out <= instr_addr_in;
      instr_out <= instr_in;
    end


endmodule //if_id
