`include "defines.v"
module id_ex (
    input wire clk,
    input  wire rstn,

    input  wire instr_hold,

    input wire [31:0] instr_in,
    input wire [31:0] instr_addr_in,
    input wire [31:0] op1_in,
    input wire [31:0] op2_in,
    input wire [6:0]  opcode_in,

    input wire [2:0]   funct3_in,     // 功能码3位
    input wire [6:0]   funct7_in,      // 功能码7位


    output reg [31:0] instr_out,
    output reg [31:0] instr_addr_out,
    output reg [31:0] op1_out,
    output reg [31:0] op2_out,
    output reg [2:0]  funct3_out,     // 功能码3位
    output reg [6:0]  funct7_out,      // 功能码7位
    output reg [6:0]  opcode_out

  );
  //时序逻辑
  always @(posedge clk or negedge rstn)
  begin
    if(!rstn)
    begin
      instr_out         <= `INST_NOP;
      instr_addr_out    <= 32'h0;
      op1_out           <= 32'h0;
      op2_out           <= 32'h0;
      funct3_out        <= 3'h0;
      funct7_out        <= 7'h0;
      opcode_out        <= 7'h0;
    end
    else if(instr_hold)
    begin
      instr_out         <= `INST_NOP;
      instr_addr_out    <= 32'h0;
      op1_out           <= 32'h0;
      op2_out           <= 32'h0;
      funct3_out        <= 3'h0;
      funct7_out        <= 7'h0;
      opcode_out        <= 7'h0;
    end
    else
    begin
      instr_out         <=      instr_in;
      instr_addr_out    <=      instr_addr_in ;
      op1_out           <=      op1_in ;
      op2_out           <=      op2_in ;
      funct3_out        <=      funct3_in;
      funct7_out        <=      funct7_in;
      opcode_out        <=      opcode_in;
    end
  end
endmodule
