`include "defines.v"
module ex (
    input wire [31:0] instr_in,
    input wire [31:0] instr_addr_in,

    input wire [31:0] op1,
    input wire [31:0] op2,

    output  reg reg_en,
    output  reg [4:0] reg_addr,
    output  reg [31:0] reg_data
  );

  // 指令字段定义
  wire [6:0] opcode;      // 操作码
  wire [4:0] rd;          // 目标寄存器
  wire [2:0] funct3;      // 功能码3位
  wire [4:0] rs1;         // 源寄存器1
  wire [4:0] rs2;         // 源寄存器2
  wire [6:0] funct7;      // 功能码7位
  wire [11:0] imm_i;      // I型立即数
  wire [11:0] imm_s;      // S型立即数
  wire [12:0] imm_b;      // B型立即数
  wire [19:0] imm_u;      // U型立即数
  wire [20:0] imm_j;      // J型立即数

  // 从指令中提取各字段
  assign opcode   = instr_in[6:0];
  assign rd       = instr_in[11:7];
  assign funct3   = instr_in[14:12];
  assign rs1      = instr_in[19:15];
  assign rs2      = instr_in[24:20];
  assign funct7   = instr_in[31:25];
  assign imm_i    = instr_in[31:20];                      // I型立即数直接取高位
  assign imm_s    = {instr_in[31:25], instr_in[11:7]};   // S型立即数拼接
  assign imm_b    = {instr_in[31], instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0}; // B型立即数拼接，末位补0
  assign imm_u    = instr_in[31:12];                      // U型立即数取高20位
  assign imm_j    = {instr_in[31], instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0}; // J型立即数拼接，末位补0

  always @( *)
  begin
    case (opcode)
      `INST_TYPE_I:
      begin
        case (funct3)
          `INST_ADDI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 + op2;
          end
          `INST_SLTI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = (op1 < op2) ? 1:0;
          end
          `INST_SLTIU:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = (op1 < op2) ? 1:0;
          end
          `INST_XORI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 ^ op2;
          end
          `INST_ORI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 | op2;
          end
          `INST_ANDI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 & op2;
          end
          `INST_SLLI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 << op2;
          end
          `INST_SRI:
          begin
            if (funct7 == 'h0)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 >> op2;
            end
            else if (funct7 == 'h20)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 >>> op2;
            end
            else
            begin
              reg_en = 1'b0;
              reg_addr = 5'h0;
              reg_data = 32'b0;
            end
          end
          default:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
          end
        endcase
      end
      `INST_TYPE_L:
      begin
        case(funct3)
          `INST_LB:
          begin

          end
          `INST_LH:
          begin

          end
          `INST_LW:
          begin

          end
          `INST_LBU:
          begin

          end
          `INST_LHU:
          begin

          end
          default:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
          end
        endcase
      end
      `INST_TYPE_S:
      begin
        case (funct3)
          `INST_SB:
          begin

          end
          `INST_SH:
          begin

          end
          `INST_SW:
          begin

          end
          default:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
          end
        endcase
      end
      `INST_TYPE_B:
      begin
        case (funct3)
          `INST_BEQ:
          begin

          end
          `INST_BNE:
          begin

          end
          `INST_BLT:
          begin

          end
          `INST_BGE:
          begin

          end
          `INST_BLTU:
          begin

          end
          `INST_BGEU:
          begin

          end
          default:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
          end
        endcase
      end
      `INST_TYPE_R_M:
      begin
        case (funct3)
          `INST_ADD_SUB:
          begin
            if(funct7 == 'h0)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 + op2;
            end
            else if(funct7 == 'h20)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 - op2;
            end
            else
            begin
              reg_en = 1'b0;
              reg_addr = 5'h0;
              reg_data = 32'b0;
            end
          end
          `INST_SLL:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 << op2;
          end
          `INST_SLT:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = ($signed(op1) < $signed(op2)) ? 1:0;
          end
          `INST_SLTU:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = (op1 < op2) ? 1:0;
          end
          `INST_XOR:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 ^ op2;
          end
          `INST_SR:
          begin
            if (funct7 == 'h0)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 >> op2;
            end
            else if(funct7 == 'h20)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 >>> op2;
            end
            else
            begin
              reg_en = 1'b0;
              reg_addr = 5'h0;
              reg_data = 32'b0;
            end
          end
          `INST_OR:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 | op2;
          end
          `INST_AND:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 & op2;
          end
          default:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
          end
        endcase
      end
      `INST_JAL:
      begin

      end
      `INST_JALR:
      begin

      end
      `INST_LUI:
      begin

      end
      `INST_AUIPC:
      begin

      end
      default:
      begin
        reg_en = 1'b0;
        reg_addr = 5'h0;
        reg_data = 32'b0;
      end
    endcase
  end

endmodule //ex
