`include "defines.v"

// 译码模块
module decode (
    input  wire     [31:0]  instr_in,   // 输入的指令
    input  wire     [31:0]  rs1_data,   // 源寄存器1的数据
    input  wire     [31:0]  rs2_data,   // 源寄存器2的数据
    output reg      [4:0]   rs1_addr,   // 源寄存器1的地址
    output reg      [4:0]   rs2_addr,   // 源寄存器2的地址
    output reg      [4:0]   reg_addr,   // 目标寄存器地址
    output reg      [31:0]  op1_out,    // 操作数1输出
    output reg      [31:0]  op2_out,    // 操作数2输出
    output wire     [2:0]   funct3,     // 功能码3位
    output wire     [6:0]   funct7,      // 功能码7位
    output wire     [6:0]   opcode
  );

  // 指令字段定义
  wire [4:0] rd;          // 目标寄存器
  wire [4:0] rs1;         // 源寄存器1
  wire [4:0] rs2;         // 源寄存器2   
  wire [11:0] imm_i;      // I型立即数
  wire [11:0] imm_s;      // S型立即数
  wire [19:0] imm_u;      // U型立即数
  wire [20:0] imm_j;      // J型立即数

  assign opcode   = instr_in[6:0];
  assign rd       = instr_in[11:7];
  assign funct3   = instr_in[14:12];
  assign rs1      = instr_in[19:15];
  assign rs2      = instr_in[24:20];
  assign funct7   = instr_in[31:25];
  assign imm_i    = instr_in[31:20];                      // I型立即数直接取高位
  assign imm_s    = {instr_in[31:25], instr_in[11:7]};   // S型立即数拼接
  assign imm_u    = instr_in[31:12];                      // U型立即数取高20位
  assign imm_j    = {instr_in[31], instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0}; // J型立即数拼接，末位补0

  always @( *)
  begin
    // 默认值赋值（避免锁存器）
    rs1_addr  =   5'h0;
    rs2_addr  =   5'h0;
    op1_out   =   32'h0;
    op2_out   =   32'h0;
    reg_addr  =   5'h0;

    // 根据操作码进行指令译码
    case (opcode)
      `INST_TYPE_I:
      begin // I型指令（算术立即数运算）
        rs1_addr = rs1;                         // 源寄存器1地址
        rs2_addr = 5'h0;                        // I型指令无需第二个源寄存器
        op1_out  = rs1_data;                    // 操作数1为寄存器值
        op2_out  = {{20{imm_i[11]}}, imm_i};    // 操作数2为符号扩展的12位立即数
        reg_addr = rd;                          // 目标寄存器地址
      end

      `INST_TYPE_L:
      begin // 加载指令（lw, lh, lb等）
        rs1_addr = rs1;                         // 基址寄存器
        rs2_addr = 5'h0;
        op1_out  = rs1_data;                    // 基址寄存器的值
        op2_out  = {{20{imm_i[11]}}, imm_i};    // 符号扩展的偏移量
        reg_addr = rd;                          // 加载数据的目标寄存器
      end

      `INST_TYPE_S:
      begin // 存储指令（sw, sh, sb等）
        rs1_addr = rs1;                         // 基址寄存器
        rs2_addr = rs2;                         // 存储数据的源寄存器
        op1_out  = rs1_data;                    // 基址寄存器的值
        op2_out  = {{20{imm_s[11]}}, imm_s};    // 符号扩展的偏移量
        reg_addr = 5'h0;                        // 存储指令无目标寄存器
      end

      `INST_TYPE_R_M:
      begin // R型指令（寄存器-寄存器运算）和M型指令（乘除）
        rs1_addr = rs1;                         // 源寄存器1地址
        rs2_addr = rs2;                         // 源寄存器2地址
        op1_out  = rs1_data;                    // 操作数1为寄存器1的值
        op2_out  = rs2_data;                    // 操作数2为寄存器2的值
        reg_addr = rd;                          // 目标寄存器地址
      end

      `INST_JAL:
      begin // JAL指令（跳转并链接）
        rs1_addr = 5'h0;                        // 无需源寄存器
        rs2_addr = 5'h0;
        op1_out  = 32'h0;                       // 操作数1将在后续阶段添加PC值
        op2_out  = {{11{imm_j[20]}}, imm_j};    // 符号扩展的21位立即数（实际为20位左移1位）
        reg_addr = rd;                          // 返回地址存入目标寄存器
      end

      `INST_JALR:
      begin // JALR指令（寄存器间接跳转并链接）
        rs1_addr = rs1;                         // 基址寄存器
        rs2_addr = 5'h0;
        op1_out  = rs1_data;                    // 基址寄存器的值
        op2_out  = {{20{imm_i[11]}}, imm_i};    // 符号扩展的12位立即数偏移量
        reg_addr = rd;                          // 返回地址存入目标寄存器
      end

      `INST_LUI:
      begin // LUI指令（加载高位立即数）
        rs1_addr = 5'h0;                        // 无需源寄存器
        rs2_addr = 5'h0;
        op1_out  = 32'h0;
        op2_out  = {imm_u, 12'h0};              // 立即数左移12位
        reg_addr = rd;                          // 目标寄存器
      end

      `INST_AUIPC:
      begin // AUIPC指令（PC加高位立即数）
        rs1_addr = 5'h0;
        rs2_addr = 5'h0;
        op1_out  = 32'h0;                       // 操作数1将在后续阶段添加PC值
        op2_out  = {imm_u, 12'h0};              // 立即数左移12位
        reg_addr = rd;                          // 目标寄存器
      end

      `INST_TYPE_B:
      begin // B型指令（分支指令）
        rs1_addr = rs1;                         // 比较源寄存器1
        rs2_addr = rs2;                         // 比较源寄存器2
        op1_out  = rs1_data;                    // 操作数1为寄存器1的值
        op2_out  = rs2_data;                    // 操作数2为寄存器2的值
        // 分支偏移量将在后续阶段使用imm_b计算
        reg_addr = 5'h0;                        // 分支指令无目标寄存器
      end

      `INST_FENCE:
      begin // FENCE指令（内存屏障）
        // 无操作数依赖
        rs1_addr = 5'h0;
        rs2_addr = 5'h0;
        op1_out  = 32'h0;
        op2_out  = 32'h0;
        reg_addr = 5'h0;
      end

      // `INST_CSR:
      // begin // CSR指令（控制状态寄存器操作）
      //   rs1_addr = rs1;                         // 源寄存器（可能为x0）
      //   rs2_addr = 5'h0;
      //   op1_out  = rs1_data;                    // 源寄存器值
      //   op2_out  = {{20{imm_i[11]}}, imm_i};    // CSR立即数（符号扩展或零扩展，具体由funct3决定）
      //   reg_addr = rd;                          // 目标寄存器
      // end

      default:
      begin
        // 未知指令，保持默认值（全0）
        rs1_addr  =   5'h0;
        rs2_addr  =   5'h0;
        op1_out   =   32'h0;
        op2_out   =   32'h0;
        reg_addr  =   5'h0;
      end
    endcase
  end

endmodule
