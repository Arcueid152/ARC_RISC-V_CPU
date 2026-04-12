module pc_cnt (
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
      pc_pointer <= 32'h0;//复位置零
    else if (jump_en)
      pc_pointer <= jump_addr;//跳转地址
    else
      pc_pointer <= pc_pointer + 32'h4;//每周期加四
  end
endmodule //pc_cnt