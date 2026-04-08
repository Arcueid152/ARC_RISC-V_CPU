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
    output reg [31:0]jump_addr,

    output  reg            wr_en,
    output  reg [31:0]     wr_addr,
    output  reg [31:0]     wr_data,
    output  reg [31:0]     rd_addr,
    input   wire[31:0]     rd_data,     //原ram数据
    input   wire[31:0]     rs2_data,     //reg直接提取数据
    input   wire           periph_write_back,    //id输入

    input   wire wr_reg_en    //由id_ex输入
  );

  // 指令字段定义
  wire [4:0] rd;          // 目标寄存器
  wire [31:0] imm_b;      // B型立即数

  // 从指令中提取各字段
  assign rd       = instr_in[11:7];
  assign imm_b    = {{19{instr_in[31]}}, instr_in[31], instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0}; // B型立即数拼接，末位补0，符号扩展

  always @( *)
  begin
    //初始置零
    reg_en = 1'b0;
    reg_addr = 5'h0;
    reg_data = 32'b0;
    jump_en = 1'b0;
    jump_addr = 'h0;
    jump_hold = 1'b0;
    wr_en = 1'b0;
    wr_addr = 32'h0;
    wr_data = 32'h0;
    rd_addr = 32'h0;
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
    reg_en = 1'b0;
    wr_en = 1'b0;
    jump_en = 1'b0;
    jump_addr = 'h0;
    jump_hold = 1'b0;
    case(funct3)
        `INST_LB:
        begin
            reg_en   = wr_reg_en;
            rd_addr  = op1 + op2;
            reg_addr = rd;
            case (rd_addr[1:0])
                2'b00   : reg_data = {{24{rd_data[7]}},rd_data[7:0]};
                2'b01   : reg_data = {{24{rd_data[15]}},rd_data[15:8]};
                2'b10   : reg_data = {{24{rd_data[23]}},rd_data[23:16]};
                2'b11   : reg_data = {{24{rd_data[31]}},rd_data[31:24]};
                default : reg_data = {{24{rd_data[7]}},rd_data[7:0]};
            endcase
        end
        `INST_LH:
        begin
            reg_en   = wr_reg_en;
            rd_addr  = op1 + op2;
            reg_addr = rd;
            case (rd_addr[1])
                1'b0    : reg_data = {{16{rd_data[15]}},rd_data[15:0]};
                1'b1    : reg_data = {{16{rd_data[31]}},rd_data[31:16]};
                default : reg_data = {{16{rd_data[15]}},rd_data[15:0]};
            endcase
        end
        `INST_LW:
        begin
            reg_en   = wr_reg_en;
            rd_addr  = op1 + op2;
            reg_addr = rd;
            reg_data = rd_data;
        end
        `INST_LBU:
        begin
            reg_en   = wr_reg_en;
            rd_addr  = op1 + op2;
            reg_addr = rd;
            case (rd_addr[1:0])
                2'b00   : reg_data = {24'h0,rd_data[7:0]};
                2'b01   : reg_data = {24'h0,rd_data[15:8]};
                2'b10   : reg_data = {24'h0,rd_data[23:16]};
                2'b11   : reg_data = {24'h0,rd_data[31:24]};
                default : reg_data = {24'h0,rd_data[7:0]};
            endcase
        end
        `INST_LHU:
        begin
            reg_en   = wr_reg_en;
            rd_addr  = op1 + op2;
            reg_addr = rd;
            case (rd_addr[1])
                1'b0    : reg_data = {16'h0,rd_data[15:0]};
                1'b1    : reg_data = {16'h0,rd_data[31:16]};
                default : reg_data = {16'h0,rd_data[15:0]};
            endcase
        end
        default:
        begin
            reg_en   = 1'b0;
            reg_addr = 5'h0;
            reg_data = 32'b0;
            rd_addr  = 32'h0;
        end
    endcase
end
      `INST_TYPE_S:
      begin
            wr_en = 1'b0;
            wr_addr = 5'h0;
            wr_data = 32'b0;
            jump_en = 1'b0;
            jump_addr = 'h0;
            jump_hold = 1'b0;
        case (funct3)
          `INST_SB:
          begin
            wr_en = wr_reg_en;
            wr_addr = op1 + op2;
            rd_addr = op1 + op2;
        case (wr_addr[1:0])
            2'b00  :  wr_data = {rd_data[31:8],rs2_data[7:0]};
            2'b01  :  wr_data = {rd_data[31:16],rs2_data[7:0],rd_data[7:0]};
            2'b10  :  wr_data = {rd_data[31:24],rs2_data[7:0],rd_data[15:0]};
            2'b11  :  wr_data = {rs2_data[7:0],rd_data[23:0]};
            default :wr_data = {rd_data[31:8],rs2_data[7:0]};
        endcase
          end
          `INST_SH:
          begin
            wr_en = wr_reg_en;
            wr_addr = op1 + op2;
            rd_addr = op1 + op2;
        case (wr_addr[1])
            1'b0  :  wr_data = {rd_data[31:16],rs2_data[15:0]};
            1'b1  :  wr_data = {rs2_data[15:0],rd_data[15:0]};
            default :wr_data = {rd_data[31:16],rs2_data[15:0]};
        endcase
          end
          `INST_SW:
          begin
            wr_en = wr_reg_en;
            wr_addr = op1 + op2;
            rd_addr = op1 + op2;
            wr_data = rs2_data;
          end
          default:
          begin
            wr_en = 1'b0;
            wr_addr = 5'h0;
            wr_data = 32'b0;
            rd_addr = 32'h0;
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
