`include "defines.v"
module if_id (
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] instr_addr_in,
    input   wire [31:0] instr_in,
    input   wire        instr_hold,
    output  reg  [31:0] instr_addr_out,
    output  reg  [31:0] instr_out,
    output  reg         periph_hold_pc,
    output  reg         wr_periph_reg,
    output  reg         rd_periph_reg
  );



reg  [31:0] instr_in_last;
reg  [31:0] instr_addr_in_last;
wire [6:0]  opcode;
wire [2:0]  func3;

  assign opcode = instr_in[6:0];
  assign func3  = instr_in[14:12];
  
always @(*) begin
    periph_hold_pc = wr_periph_reg | rd_periph_reg;
end

  //存一拍用于原地踏步一拍
always @(posedge clk or posedge rst) begin
  if(rst)
    begin
      instr_in_last <= 1'h0;
      instr_addr_in_last <= 1'h0;
    end
  else
    begin
      instr_in_last <= instr_in;
      instr_addr_in_last <= instr_addr_in;
    end
  end

  
  //流水线寄存器
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
    else if (periph_hold_pc)
    begin
      instr_addr_out <= instr_addr_in_last;
      instr_out <= instr_in_last;
    end
    else
    begin
      instr_addr_out <= instr_addr_in;
      instr_out <= instr_in;
    end

    


//外设访问
   always @(posedge clk or posedge rst)
    if(rst)
    begin
      wr_periph_reg <= 1'b0;
      rd_periph_reg <= 1'b0;
    end
    else if (instr_hold || periph_hold_pc)
    begin
      wr_periph_reg <= 1'b0;
      rd_periph_reg <= 1'b0;
    end
    else if (opcode == `INST_TYPE_L)
    begin
      wr_periph_reg <= 1'b0;
      rd_periph_reg <= 1'b1;
    end
    else if (opcode == `INST_TYPE_S)
    begin
      wr_periph_reg <= 1'b1;
      rd_periph_reg <= (func3 == `INST_SB || func3 == `INST_SH) ? 1'b1 : 1'b0;
    end
    else
    begin
      wr_periph_reg <= 1'b0;
      rd_periph_reg <= 1'b0;
    end


endmodule //if_id