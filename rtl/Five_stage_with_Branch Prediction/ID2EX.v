module ID2EX (
    input wire clk,
    input  wire rst,

    input  wire jump_hold,
    input  wire flush,

    input wire [31:0] instr_in,
    input wire [31:0] instr_addr_in,
    input wire [31:0] op1_in,
    input wire [31:0] op2_in,
    input wire [6:0]  opcode_in,

    input wire [2:0]   funct3_in,     // 功能码3位
    input wire [6:0]   funct7_in,     // 功能码7位
    input wire [4:0]   reg_addr_in,

    output reg [31:0] instr_out,
    output reg [31:0] instr_addr_out,
    output reg [31:0] op1_out,
    output reg [31:0] op2_out,
    output reg [2:0]  funct3_out,     // 功能码3位
    output reg [6:0]  funct7_out,     // 功能码7位
    output reg [6:0]  opcode_out,

    output reg      [4:0]   reg_addr_out,

    input  wire        mispredict,        // EX反馈：预测失败，需要冲刷
    input  wire        pred_taken_in,     // 来自IF2ID的预测结果
    input  wire [31:0] pred_addr_in,      // 来自IF2ID的预测地址
    output reg         pred_taken_out     // 传给EX，用于比对是否预测正确
    //output reg [31:0] pred_addr_out        EX已有正确地址，可能不用这个
  );

  //时序逻辑
  always @(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      instr_out         <= 32'h0000_0000;
      instr_addr_out    <= 32'h8000_0000;
      op1_out           <= 32'h0;
      op2_out           <= 32'h0;
      funct3_out        <= 3'h0;
      funct7_out        <= 7'h0;
      opcode_out        <= 7'h0;
      reg_addr_out      <= 5'b0;
      pred_taken_out    <= 1'b0;
      //pred_addr_out     <= 32'h8000_0000;
    end
    else if(jump_hold || flush || mispredict)
    begin
      instr_out         <= 32'h0000_0000;
      instr_addr_out    <= 32'h8000_0000;
      op1_out           <= 32'h0;
      op2_out           <= 32'h0;
      funct3_out        <= 3'h0;
      funct7_out        <= 7'h0;
      opcode_out        <= 7'h0;
      reg_addr_out      <= 5'b0;
      pred_taken_out    <= 1'b0;
      //pred_addr_out     <= 32'h8000_0000;
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
      reg_addr_out      <=      reg_addr_in;
      pred_taken_out    <=      pred_taken_in;
      //pred_addr_out     <=    pred_addr_in;
    end
  end
endmodule