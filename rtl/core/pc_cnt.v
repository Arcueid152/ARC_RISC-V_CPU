module pc_cnt (
    input wire clk,
    input wire rstn,
    input wire jump_en,
    input wire [31:0] jump_addr,
    output reg [31:0] pc_pointer

  );
  always @(posedge clk or negedge rstn)
  begin
    if(~rstn)
      pc_pointer <= 'h0;
    else if (jump_en)
      pc_pointer <= jump_addr;
    else
      pc_pointer <= pc_pointer + 'h4;
  end

endmodule //pc_cnt
