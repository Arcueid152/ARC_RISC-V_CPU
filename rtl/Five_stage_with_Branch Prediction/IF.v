module IF (
    input   wire          clk,
    input   wire          rst,
    input   wire          jump_en,
    input   wire          jump_hold,
    input   wire  [31:0]  jump_addr,
    input  wire           stall,
    output  reg   [31:0]  pc_pointer,

    //BPU输入
    input  wire           pred_taken,   // BPU预测：是否跳转
    input  wire  [31:0]   pred_addr,    // BPU预测：跳转目标地址
    input  wire           mispredict   // EX反馈：预测失败（预测跳但实际没跳）

  );

  always @(posedge clk or posedge rst)
  begin
    if(rst)
      pc_pointer <= 32'h8000_0000;//复位
    else if (mispredict)
      pc_pointer <= {4'b1000, jump_addr[27:0]}; // PC已在EX加4，由jump_addr传入
    else if (jump_en)
      pc_pointer <= {4'b1000, jump_addr[27:0]};//跳转地址
    else if ((jump_hold || stall) && (!mispredict))
      pc_pointer <= pc_pointer;
    else if (pred_taken)
      pc_pointer <= pred_addr;   // BPU预测跳，直接取预测目标地址
    else
      pc_pointer <= pc_pointer + 32'h4;//每周期加四
  end
endmodule