module IF (
    input   wire          clk,
    input   wire          rst,
    input   wire          jump_en,
    input   wire          jump_hold,
    input   wire  [31:0]  jump_addr,
    output  reg   [31:0]  pc_pointer

  );

  always @(posedge clk or posedge rst)
  begin
    if(rst)
      pc_pointer <= 32'h8000_0000;//复位
    else if (jump_en)
      pc_pointer <= {4'b1000, jump_addr[27:0]};//跳转地址
    else if (jump_hold)
      pc_pointer <= pc_pointer;
    else
      pc_pointer <= pc_pointer + 32'h4;//每周期加四
  end
endmodule