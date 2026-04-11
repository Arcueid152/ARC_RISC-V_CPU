`include "defines.v"
module id_ex (
    input wire clk,
    input  wire rst,

    input  wire instr_hold,

    input wire [31:0] instr_in,
    input wire [31:0] instr_addr_in,
    input wire [31:0] op1_in,
    input wire [31:0] op2_in,
    input wire [6:0]  opcode_in,

    input   wire      periph_hold_pc,

    input wire [2:0]   funct3_in,     // 功能码3位
    input wire [6:0]   funct7_in,     // 功能码7位

    input  wire [31:0] rs2_data_in,   // ===== 新增：输入的 rs2_data =====

    output reg [31:0] instr_out,
    output reg [31:0] instr_addr_out,
    output reg [31:0] op1_out,
    output reg [31:0] op2_out,
    output reg [2:0]  funct3_out,     // 功能码3位
    output reg [6:0]  funct7_out,     // 功能码7位
    output reg [6:0]  opcode_out,
    output reg [31:0] rs2_data_out,    // ===== 新增：输出的 rs2_data =====
    output reg        periph_write_back,

    input  wire       wr_periph_reg_in,   //来自if_id的外设写信号
    input  wire       rd_periph_reg_in,   //来自if_id的外设读信号
    output reg        wr_reg_en      //输出给ex
  );

  wire wr_reg_en_in;
  assign wr_reg_en_in = (opcode_in == `INST_TYPE_L) || (opcode_in == `INST_TYPE_S);

  //时序逻辑
  always @(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      instr_out         <= `INST_NOP;
      instr_addr_out    <= 32'h0;
      op1_out           <= 32'h0;
      op2_out           <= 32'h0;
      funct3_out        <= 3'h0;
      funct7_out        <= 7'h0;
      opcode_out        <= 7'h0;
      rs2_data_out      <= 32'h0;     // ===== 新增 =====
      wr_reg_en         <= 1'b0;
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
      rs2_data_out      <= 32'h0;     // ===== 新增 =====
      wr_reg_en         <= 1'b0;      
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
      rs2_data_out      <=      rs2_data_in;   // ===== 新增 =====
      wr_reg_en         <=      wr_reg_en_in;      
    end
  end

  always @(posedge clk or posedge rst)begin
    if(rst)
      periph_write_back <= 1'b0;
    else if(periph_hold_pc)
      periph_write_back <= 1'b1;
    else
      periph_write_back <= 1'b0;
  end
endmodule