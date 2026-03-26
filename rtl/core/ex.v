`include "defines.v"
module ex (
    input wire [31:0] instr_in,
    input wire [31:0] instr_addr_in,

    input wire [31:0] op1,
    input wire [31:0] op2,
    input wire [2:0] funct3, 
    input wire [6:0] funct7, 
    input wire [6:0] opcode, 

    output  reg reg_en,
    output  reg [4:0] reg_addr,
    output  reg [31:0] reg_data,
    //跳转传回pc_cnt
    output reg jump_en,
    output reg jump_hold,
    output reg [31:0]jump_addr
  );

  // 指令字段定义
  wire [4:0] rd;          // 目标寄存器
  wire [11:0] imm_i;      // I型立即数
  wire [11:0] imm_s;      // S型立即数
  wire [12:0] imm_b;      // B型立即数
  wire [19:0] imm_u;      // U型立即数
  wire [20:0] imm_j;      // J型立即数

  // 从指令中提取各字段
  assign rd       = instr_in[11:7];
  assign imm_i    = instr_in[31:20];                      // I型立即数直接取高位
  assign imm_s    = {instr_in[31:25], instr_in[11:7]};   // S型立即数拼接
  assign imm_b    = {instr_in[31], instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0}; // B型立即数拼接，末位补0
  assign imm_u    = instr_in[31:12];                      // U型立即数取高20位
  assign imm_j    = {instr_in[31], instr_in[19:12], instr_in[20], instr_in[30:21], 1'b0}; // J型立即数拼接，末位补0

  always @( *)
  begin
    //初始置零
    reg_en = 1'b0;
    reg_addr = 5'h0;
    reg_data = 32'b0;
    jump_en = 1'b0;
    jump_addr = 'h0;
    jump_hold = 1'b0;
    case (opcode)
      `INST_TYPE_I:
      begin
        case (funct3)
          `INST_ADDI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 + op2;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_SLTI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = ($signed(op1) < $signed(op2)) ? 1:0;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_SLTIU:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = (op1 < op2) ? 1:0;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_XORI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 ^ op2;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_ORI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 | op2;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_ANDI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 & op2;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_SLLI:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 << op2[4:0];
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_SRI:
          begin
            if (funct7 == 'h0)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 >> op2[4:0];
              jump_en = 1'b0;
              jump_addr = 'h0;
              jump_hold = 1'b0;
            end
            else if (funct7 == 'h20)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 >>> op2[4:0];
              jump_en = 1'b0;
              jump_addr = 'h0;
              jump_hold = 1'b0;
            end
            else
            begin
              reg_en = 1'b0;
              reg_addr = 5'h0;
              reg_data = 32'b0;
              jump_en = 1'b0;
              jump_addr = 'h0;
              jump_hold = 1'b0;
            end
          end
          default:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
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
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            jump_en = (op1 == op2);
            jump_addr = (op1 == op2) ? (instr_addr_in + imm_b):'h0 ;
            jump_hold = (op1 == op2);
          end
          `INST_BNE:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            jump_en = (op1 != op2);
            jump_addr = (op1 != op2) ? (instr_addr_in + imm_b):'h0 ;
            jump_hold = (op1 != op2);
          end
          `INST_BLT:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            jump_en = ($signed(op1) < $signed(op2));
            jump_addr = ($signed(op1) < $signed(op2)) ? (instr_addr_in + imm_b):'h0 ;
            jump_hold = ($signed(op1) < $signed(op2));
          end
          `INST_BGE:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            jump_en = ($signed(op1) >= $signed(op2));
            jump_addr = ($signed(op1) >= $signed(op2)) ? (instr_addr_in + imm_b):'h0 ;
            jump_hold = ($signed(op1) >= $signed(op2));
          end
          `INST_BLTU:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            jump_en = (op1 < op2);
            jump_addr = (op1 < op2) ? (instr_addr_in + imm_b):'h0 ;
            jump_hold = (op1 < op2);
          end
          `INST_BGEU:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            jump_en = (op1 >= op2);
            jump_addr = (op1 >= op2) ? (instr_addr_in + imm_b):'h0 ;
            jump_hold = (op1 >= op2);
          end
          default:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
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
              jump_en = 1'b0;
              jump_addr = 'h0;
              jump_hold = 1'b0;
            end
            else if(funct7 == 'h20)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 - op2;
              jump_en = 1'b0;
              jump_addr = 'h0;
              jump_hold = 1'b0;
            end
            else
            begin
              reg_en = 1'b0;
              reg_addr = 5'h0;
              reg_data = 32'b0;
              jump_en = 1'b0;
              jump_addr = 'h0;
              jump_hold = 1'b0;
            end
          end
          `INST_SLL:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 << op2[4:0];
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_SLT:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = ($signed(op1) < $signed(op2)) ? 1:0;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_SLTU:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = (op1 < op2) ? 1:0;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_XOR:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 ^ op2;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_SR:
          begin
            if (funct7 == 'h0)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 >> op2[4:0];
              jump_en = 1'b0;
              jump_addr = 'h0;
              jump_hold = 1'b0;
            end
            else if(funct7 == 'h20)
            begin
              reg_en = 1'b1;
              reg_addr = rd;
              reg_data = op1 >>> op2[4:0];
              jump_en = 1'b0;
              jump_addr = 'h0;
              jump_hold = 1'b0;
            end
            else
            begin
              reg_en = 1'b0;
              reg_addr = 5'h0;
              reg_data = 32'b0;
              jump_en = 1'b0;
              jump_addr = 'h0;
              jump_hold = 1'b0;
            end
          end
          `INST_OR:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 | op2;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          `INST_AND:
          begin
            reg_en = 1'b1;
            reg_addr = rd;
            reg_data = op1 & op2;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
          default:
          begin
            reg_en = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
          end
        endcase
      end
      `INST_JAL:
      begin
        reg_en = 1'b1;
        reg_addr = rd;
        reg_data = instr_addr_in + 32'h4;
        jump_en = 1'b1;
        jump_addr = instr_addr_in + op2;
        jump_hold = 1'b1;
      end
      `INST_JALR:
      begin
        reg_en = 1'b1;
        reg_addr = rd;
        reg_data = instr_addr_in + 32'h4;
        jump_en = 1'b1;
        jump_addr = op1 + op2;
        jump_hold = 1'b1;
      end
      `INST_LUI:
      begin
        reg_en = 1'b1;
        reg_addr = rd;
        reg_data = op2;
        jump_en = 1'b0;
        jump_addr = 'h0;
        jump_hold = 1'b0;
      end
      `INST_AUIPC:
      begin
        reg_en = 1'b1;
        reg_addr = rd;
        reg_data = instr_addr_in + op2;
        jump_en = 1'b0;
        jump_addr = 'h0;
        jump_hold = 1'b0;
      end
      default:
      begin
        reg_en = 1'b0;
        reg_addr = 5'h0;
        reg_data = 32'b0;
        jump_en = 1'b0;
        jump_addr = 'h0;
        jump_hold = 1'b0;
      end
    endcase
  end

endmodule //ex
