module IF2ID (
    input   wire        clk,
    input   wire        rst,
    input   wire [31:0] instr_addr_in,
    input   wire [31:0] instr_in,
    input   wire        jump_hold,   // 跳转冲刷：插入 NOP

    input  wire stall,
    output  reg  [31:0] instr_addr_out,
    output  reg  [31:0] instr_out,

    //BPU输入与输出
    input   wire        mispredict,       // EX反馈：预测失败（预测跳但实际没跳），需要冲刷

    input   wire        pred_taken_in,    // BPU预测结果，随指令传给EX比对
    input   wire [31:0] pred_addr_in,     // BPU预测地址，随指令传给EX比对
    output  reg         pred_taken_out,   // 传给ID2EX
    output  reg  [31:0] pred_addr_out     // 传给ID2EX
  );

  always @(posedge clk or posedge rst)
    if(rst)
    begin
      instr_addr_out <= 32'h80000000;
      instr_out <= 32'h00000000;
      pred_taken_out  <= 1'b0;
      pred_addr_out   <= 32'h80000000;
    end
    else if (stall) 
    begin
      instr_addr_out <= instr_addr_out;
      instr_out <= instr_out;
      pred_taken_out  <= pred_taken_out;
      pred_addr_out   <= pred_addr_out;
    end
    else if (jump_hold || mispredict)
    begin
      instr_addr_out  <= 32'h80000000;
      instr_out       <= 32'h00000000;
      pred_taken_out  <= 1'b0;
      pred_addr_out   <= 32'h80000000;
    end

    else
    begin
      instr_addr_out <= instr_addr_in;
      instr_out <= instr_in;
      pred_taken_out  <= pred_taken_in;
      pred_addr_out   <= pred_addr_in;
    end


endmodule
