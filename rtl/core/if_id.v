`include "defines.vh"
module if_id (
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] instr_addr_in,
    input   wire [31:0] instr_in,
    input   wire        instr_hold,   // 跳转冲刷：插入 NOP
    input   wire        instr_stall,  // load-use 停顿：冻结当前内容（新增）
    output  reg  [31:0] instr_addr_out,
    output  reg  [31:0] instr_out
  );

  always @(posedge clk or posedge rst)
    if(rst)
    begin
      instr_addr_out <= 32'h8000_0000;
      instr_out <= `INST_NOP;
    end
    else if (instr_stall)
    begin
      // load-use 停顿：保持当前输出不变，等待 lw 完成内存读取
      instr_addr_out <= instr_addr_out;
      instr_out      <= instr_out;
    end
    else if (instr_hold)
    begin
      // 跳转冲刷：插入 NOP
      instr_addr_out <= 32'h8000_0000;
      instr_out      <= `INST_NOP;
    end

    else
    begin
      instr_addr_out <= instr_addr_in;
      instr_out <= instr_in;
    end


endmodule //if_id
