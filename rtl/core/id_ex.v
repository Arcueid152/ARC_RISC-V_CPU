module id_ex (
    input wire clk,
    input  wire rstn,

    input wire [31:0] instr_in,
    input wire [31:0] instr_addr_in,
    input wire [31:0] op1_in,
    input wire [31:0] op2_in,

    output reg [31:0] instr_out,
    output reg [31:0] instr_addr_out,
    output reg [31:0] op1_out,
    output reg [31:0] op2_out
  );
  //时序逻辑
  always @(posedge clk or negedge rstn)
  begin
    if(!rstn)
    begin
      instr_out         <= 32'h0;
      instr_addr_out    <= 32'h0;
      op1_out           <= 32'h0;
      op2_out           <= 32'h0;
    end
    else
    begin
      instr_out         <=      instr_in;
      instr_addr_out    <=      instr_addr_in ;
      op1_out           <=      op1_in ;
      op2_out           <=      op2_in ;
    end
  end
endmodule
