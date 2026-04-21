`include "defines.vh"
module EX (
    input  wire [31:0] instr_in,
    input  wire [31:0] instr_addr_in,
    input  wire [31:0] op1,
    input  wire [31:0] op2,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    input  wire [6:0]  opcode,

    input wire      [4:0]   reg_addr_in,   // 目标寄存器地址

    output reg [31:0]  perip_addr,    // 读写地址
    output reg         perip_wen,     // 写使能（高有效）
    output reg [1:0]   perip_mask,    // 传输宽度：00=byte 01=half 10=word
    output reg [31:0]  perip_wdata,   // 写数据
    input  wire [31:0]  perip_rdata,    // 读数据

    output reg[31:0] reg_data,       // 写寄存器数据
    output reg       reg_en,         // 是否要写通用寄存器
    output reg[31:0] reg_addr,   // 写通用寄存器地址

    output reg         jump_en,
    output reg         jump_hold,
    output reg  [31:0] jump_addr
  );

  always @(*)
  begin
    perip_addr = 32'h0000_0000;    // 读写地址
    perip_wen = 1'b0;     // 写使能（高有效）
    perip_mask = 2'b00;    // 传输宽度：00=byte 01=half 10=word
    perip_wdata = 32'h0000_0000;   // 写数据

    jump_en    = 1'b0;
    jump_hold  = 1'b0;
    jump_addr  = 32'h8000_0000;

    reg_data   = 32'h0000_0000;
    reg_en     = 1'b0;
    reg_addr   = reg_addr_in;
    case (opcode)
      `INST_TYPE_I:
      begin
        reg_en = 1'b1;
        case (funct3)
          `INST_ADDI:
            reg_data = op1 + op2;
          `INST_SLTI:
            reg_data = ($signed(op1) < $signed(op2)) ? 32'h1 : 32'h0;
          `INST_SLTIU:
            reg_data = (op1 < op2) ? 32'h1 : 32'h0;
          `INST_XORI:
            reg_data = op1 ^ op2;
          `INST_ORI:
            reg_data = op1 | op2;
          `INST_ANDI:
            reg_data = op1 & op2;
          `INST_SLLI:
            reg_data = op1 << op2[4:0];
          `INST_SRI:
            if (funct7 == 7'h20)
            begin
              reg_data = (op1[31] ? (~(32'hFFFFFFFF >> op2[4:0])) : 32'h0) | (op1 >> op2[4:0]);
            end
            else
            begin
              reg_data = op1 >> op2[4:0];
            end
          default:
            reg_en = 1'b0;
        endcase
      end

      `INST_TYPE_L:
      begin
        reg_en      = 1'b1;
        perip_mask  = funct3[1:0];
        perip_addr  = op1 + op2;
        case (funct3)
          `INST_LB:
            reg_data = {{24{perip_rdata[7]}},  perip_rdata[7:0]};
          `INST_LH:
            reg_data = {{16{perip_rdata[15]}}, perip_rdata[15:0]};
          `INST_LW:
            reg_data = perip_rdata;
          `INST_LBU:
            reg_data = {24'h0, perip_rdata[7:0]};
          `INST_LHU:
            reg_data = {16'h0, perip_rdata[15:0]};
          default:
            reg_data = perip_rdata;
        endcase
      end

      `INST_TYPE_S:
      begin
        perip_mask  = funct3[1:0];
        perip_wen  = 1'b1;
        perip_addr = op1;
        perip_wdata = op2;
      end

      `INST_TYPE_R_M:
      begin
        reg_en      = 1'b1;
        case (funct3)
          `INST_ADD_SUB:
            reg_data = (funct7 == 7'h20) ? (op1 - op2) : (op1 + op2);
          `INST_SLL:
            reg_data = op1 << op2[4:0];
          `INST_SLT:
            reg_data = ($signed(op1) < $signed(op2)) ? 32'h1 : 32'h0;
          `INST_SLTU:
            reg_data = (op1 < op2) ? 32'h1 : 32'h0;
          `INST_XOR:
            reg_data = op1 ^ op2;
          `INST_SR:
            if (funct7 == 7'h20)
            begin
              reg_data = (op1[31] ? (~(32'hFFFFFFFF >> op2[4:0])) : 32'h0) | (op1 >> op2[4:0]);
            end
            else
            begin
              reg_data = op1 >> op2[4:0];
            end
          `INST_OR:
            reg_data = op1 | op2;
          `INST_AND:
            reg_data = op1 & op2;
          default:
            reg_en = 1'b0;
        endcase
      end

      `INST_TYPE_B:
      begin
        case (funct3)
          `INST_BEQ:
            jump_en = (op1 == op2);
          `INST_BNE:
            jump_en = (op1 != op2);
          `INST_BLT:
            jump_en = ($signed(op1) < $signed(op2));
          `INST_BGE:
            jump_en = ($signed(op1) >= $signed(op2));
          `INST_BLTU:
            jump_en = (op1 < op2);
          `INST_BGEU:
            jump_en = (op1 >= op2);
          default:
            jump_en = 1'b0;
        endcase
        if (jump_en)
        begin
          jump_hold = 1'b1;
          jump_addr = instr_addr_in + {{19{instr_in[31]}}, instr_in[31], instr_in[7], instr_in[30:25], instr_in[11:8], 1'b0};
        end
      end

      `INST_JAL:
      begin
        reg_en      = 1'b1;
        reg_data    = instr_addr_in + 32'h4;
        jump_en     = 1'b1;
        jump_hold   = 1'b1;
        jump_addr   = instr_addr_in + op2;
      end

      `INST_JALR:
      begin
        reg_en      = 1'b1;
        reg_data = instr_addr_in + 32'h4;
        jump_en    = 1'b1;
        jump_hold  = 1'b1;
        jump_addr  = op1 + op2;
      end

      `INST_LUI:
      begin
        reg_en      = 1'b1;
        reg_data = op2;
      end

      `INST_AUIPC:
      begin
        reg_en      = 1'b1;
        reg_data = instr_addr_in + op2;
      end

      default:
        ;
    endcase
  end

endmodule
