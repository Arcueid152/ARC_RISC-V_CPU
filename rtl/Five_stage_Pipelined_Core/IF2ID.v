module IF2ID (
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] instr_addr_in,
    input   wire [31:0] instr_in,
    input   wire        jump_hold,   // 跳转冲刷：插入 NOP

    input  wire stall,
    output  reg  [31:0] instr_addr_out,
    output  reg  [31:0] instr_out
  );

  always @(posedge clk or posedge rst)
    if(rst)
    begin
      instr_addr_out <= 32'h80000000;
      instr_out <= 32'h00000000;
    end
    else if (stall) begin
      instr_addr_out <= instr_addr_out;
      instr_out <= instr_out;
    end
    else if (jump_hold)
    begin
      // 跳转冲刷：插入 NOP
      instr_addr_out <= 32'h80000000;
      instr_out      <= 32'h00000000;
    end

    else
    begin
      instr_addr_out <= instr_addr_in;
      instr_out <= instr_in;
    end


endmodule //if_id
