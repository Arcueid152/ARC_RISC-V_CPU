/*
# RISC-V 通用寄存器 ABI 名称与用途说明
# -----------------------------------------------------------------------------
# Register | ABI Name | Description                  | Saver
# -----------------------------------------------------------------------------
# x0       | zero     | 零寄存器（恒为 0）           | —
# x1       | ra       | 返回地址寄存器               | Caller（调用者保存）
# x2       | sp       | 栈指针寄存器                 | Callee（被调用者保存）
# x3       | gp       | 全局指针寄存器               | —
# x4       | tp       | 线程指针寄存器               | —
# x5-x7    | t0-t2    | 临时寄存器                   | Caller
# x8       | s0/fp    | 保存寄存器/栈帧指针          | Callee
# x9       | s1       | 保存寄存器                   | Callee
# x10-x11  | a0-a1    | 函数参数/返回值寄存器        | Caller
# x12-x17  | a2-a7    | 函数参数寄存器               | Caller
# x18-x27  | s2-s11   | 保存寄存器                   | Callee
# x28-x31  | t3-t6    | 临时寄存器                   | Caller
# -----------------------------------------------------------------------------*/
module regs (
    input  wire clk,
    input  wire rstn,
    //寄存器使能
    input  wire reg_en,
    input  wire [4:0] reg_addr,
    input  wire [31:0] reg_data,
    //输入地址
    input  wire [4:0] rs1_addr,
    input  wire [4:0] rs2_addr,
    //输出数据
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data


  );
  //32个通用寄存器，小端序
  reg [31:0] regs [0:31];

  always @( *)
  begin
    if(!rstn)
      rs1_data = 32'h0;
    else if (rs1_addr == 5'h0)
      rs1_data = 32'h0;
    else if ((rs1_addr == reg_addr) && reg_en)
      rs1_data = reg_data;//解决时序问题，若当前需要该指令，直接写入，下同
    else
      rs1_data = regs[rs1_addr];
  end

  always @( *)
  begin
    if(!rstn)
      rs2_data = 32'h0;
    else if (rs2_addr == 5'h0)
      rs2_data = 32'h0;
    else if ((rs2_addr == reg_addr) && reg_en)
      rs2_data = regs[reg_addr];
    else
      rs2_data = regs[rs2_addr];
  end

  integer i;//计数器

  always @(posedge clk or negedge rstn)
  begin
    if (!rstn)
    begin
      for (i = 0; i < 32; i = i + 1)
      begin
        regs[i] <= 32'h0;//寄存器复位置零
      end
    end
    else if (reg_en && (reg_addr != 5'h0))
    begin
      regs[reg_addr] <= reg_data;
    end
  end

endmodule //reg
