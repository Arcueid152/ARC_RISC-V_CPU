`include "defines.v"

module ex (
    input  wire [31:0] instr_in,
    input  wire [31:0] instr_addr_in,
    input  wire [31:0] op1,
    input  wire [31:0] op2,
    input  wire [2:0]  funct3,
    input  wire [6:0]  funct7,
    input  wire [6:0]  opcode,
    input  wire [31:0] rs2_data,

    output reg  [4:0]  rd_out,
    output reg  [31:0] alu_result,
    output reg  [31:0] store_data,
    output reg  [2:0]  funct3_out,
    output reg  [6:0]  opcode_out,
    output reg         mem_read,
    output reg         mem_write,
    output reg         wb_en,

    output reg         jump_en,
    output reg         jump_hold,
    output reg  [31:0] jump_addr
);

  wire [4:0]  rd    = instr_in[11:7];
  wire [31:0] imm_b = {{19{instr_in[31]}}, instr_in[31], instr_in[7],
                       instr_in[30:25], instr_in[11:8], 1'b0};

  // -------------------------------------------------------
  // 算术右移辅助函数：完全用位操作实现，不依赖 $signed / >>>
  // 原理：若 op1[31]=1（负数），右移后在高位填 1
  //        mask = 32'hFFFFFFFF << (32 - shamt)，当 shamt=0 时需特判
  // -------------------------------------------------------
  function [31:0] arith_shr;
    input [31:0] val;
    input [4:0]  shamt;
    reg   [31:0] shifted;
    reg   [31:0] fill_mask;
    begin
      shifted   = val >> shamt;
      // 当 shamt=0 时 fill_mask 应为 0（不填充任何位）
      fill_mask = (shamt == 5'h0) ? 32'h0
                                  : (32'hFFFFFFFF << (6'd32 - {1'b0, shamt}));
      arith_shr = val[31] ? (shifted | fill_mask) : shifted;
    end
  endfunction

  always @(*) begin
    rd_out     = 5'h0;
    alu_result = 32'h0;
    store_data = 32'h0;
    funct3_out = 3'h0;
    opcode_out = 7'h0;
    mem_read   = 1'b0;
    mem_write  = 1'b0;
    wb_en      = 1'b0;
    jump_en    = 1'b0;
    jump_hold  = 1'b0;
    jump_addr  = 32'h0;

    case (opcode)

      `INST_TYPE_I: begin
        wb_en      = 1'b1;
        rd_out     = rd;
        funct3_out = funct3;
        opcode_out = opcode;
        case (funct3)
          `INST_ADDI:  alu_result = op1 + op2;
          `INST_SLTI:  alu_result = ($signed(op1) < $signed(op2)) ? 32'h1 : 32'h0;
          `INST_SLTIU: alu_result = (op1 < op2) ? 32'h1 : 32'h0;
          `INST_XORI:  alu_result = op1 ^ op2;
          `INST_ORI:   alu_result = op1 | op2;
          `INST_ANDI:  alu_result = op1 & op2;
          `INST_SLLI:  alu_result = op1 << op2[4:0];
          `INST_SRI:   alu_result = (funct7 == 7'h20) ?
                                    arith_shr(op1, op2[4:0]) :
                                    (op1 >> op2[4:0]);
          default:     wb_en = 1'b0;
        endcase
      end

      `INST_TYPE_L: begin
        mem_read   = 1'b1;
        wb_en      = 1'b1;
        rd_out     = rd;
        alu_result = op1 + op2;
        funct3_out = funct3;
        opcode_out = opcode;
      end

      `INST_TYPE_S: begin
        mem_write  = 1'b1;
        wb_en      = 1'b0;
        alu_result = op1 + op2;
        store_data = rs2_data;
        funct3_out = funct3;
        opcode_out = opcode;
      end

      `INST_TYPE_R_M: begin
        wb_en      = 1'b1;
        rd_out     = rd;
        funct3_out = funct3;
        opcode_out = opcode;
        case (funct3)
          `INST_ADD_SUB: alu_result = (funct7 == 7'h20) ? (op1 - op2) : (op1 + op2);
          `INST_SLL:     alu_result = op1 << op2[4:0];
          `INST_SLT:     alu_result = ($signed(op1) < $signed(op2)) ? 32'h1 : 32'h0;
          `INST_SLTU:    alu_result = (op1 < op2) ? 32'h1 : 32'h0;
          `INST_XOR:     alu_result = op1 ^ op2;
          `INST_SR:      alu_result = (funct7 == 7'h20) ?
                                      arith_shr(op1, op2[4:0]) :
                                      (op1 >> op2[4:0]);
          `INST_OR:      alu_result = op1 | op2;
          `INST_AND:     alu_result = op1 & op2;
          default:       wb_en = 1'b0;
        endcase
      end

      `INST_TYPE_B: begin
        case (funct3)
          `INST_BEQ:  jump_en = (op1 == op2);
          `INST_BNE:  jump_en = (op1 != op2);
          `INST_BLT:  jump_en = ($signed(op1) < $signed(op2));
          `INST_BGE:  jump_en = ($signed(op1) >= $signed(op2));
          `INST_BLTU: jump_en = (op1 < op2);
          `INST_BGEU: jump_en = (op1 >= op2);
          default:    jump_en = 1'b0;
        endcase
        if (jump_en) begin
          jump_hold = 1'b1;
          jump_addr = instr_addr_in + imm_b;
        end
      end

      `INST_JAL: begin
        wb_en      = 1'b1;
        rd_out     = rd;
        alu_result = instr_addr_in + 32'h4;
        jump_en    = 1'b1;
        jump_hold  = 1'b1;
        jump_addr  = instr_addr_in + op2;
      end

      `INST_JALR: begin
        wb_en      = 1'b1;
        rd_out     = rd;
        alu_result = instr_addr_in + 32'h4;
        jump_en    = 1'b1;
        jump_hold  = 1'b1;
        jump_addr  = op1 + op2;
      end

      `INST_LUI: begin
        wb_en      = 1'b1;
        rd_out     = rd;
        alu_result = op2;
      end

      `INST_AUIPC: begin
        wb_en      = 1'b1;
        rd_out     = rd;
        alu_result = instr_addr_in + op2;
      end

      default: ;
    endcase
  end

endmodule