`include "defines.v"

module arcriscv (
    input  wire clk,
    input  wire rstn
  );

  //pc_cnt输出
  wire [31:0] pc_pointer;

  //rom输出
  wire [31:0] instr_rom_out;

  //if2id输出
  wire  [31:0] instr_addr_if2id_out;
  wire  [31:0] instr_if2id_out;

  //decode译码输出
  wire [4:0]   decode_rs1_addr;   // 源寄存器1的地址
  wire [4:0]   decode_rs2_addr;   // 源寄存器2的地址
  wire [4:0]   decode_reg_addr;   // 目标寄存器地址
  wire [31:0]  decode_op1_out;    // 操作数1输出
  wire [31:0]  decode_op2_out;    // 操作数2输出
  wire [2:0]   decode_funct3;     // 功能码3位
  wire [6:0]   decode_funct7;      // 功能码7位
  wire [6:0]   decode_opcode;

  //reg寄存器输出
    wire [31:0] reg_rs1_data;
    wire [31:0] reg_rs2_data;
  /*=================================*/

  //pc_cnt输入
  assign jump_en = ;
  assign jump_hold = ;
  assign jump_addr = ;

  //rom输入
  assign instr_addr = pc_pointer;

  //if2id输入
  assign instr_addr_if2id_in = pc_pointer;
  assign instr_if2id_in = instr_rom_out;
  assign instr_if2id_hold = ;

  //decode输入
  assign   instr_decode_in = instr_if2id_out;  // 输入的指令
  assign   decode_rs1_data = reg_rs1_data;   // 源寄存器1的数据
  assign   decode_rs2_data = reg_rs2_data;   // 源寄存器2的数据

  //reg输入
    assign reg_en = ;
    assign reg_addr = ;
    assign reg_data = ;
    assign reg_rs1_addr = decode_rs1_addr;
    assign reg_rs2_addr = decode_rs2_addr;


  pc_cnt  pc_cnt_inst (
            .clk(clk),
            .rstn(rstn),
            .jump_en(jump_en),
            .jump_hold(jump_hold),
            .jump_addr(jump_addr),
            .pc_pointer(pc_pointer)
          );

  rom rom_inst (
        .instr_addr(instr_addr),
        .instr_out(instr_rom_out)
      );

  if_id  if_id_inst (
           .clk(clk),
           .rstn(rstn),
           .instr_addr_in(instr_addr_if2id_in),
           .instr_in(instr_if2id_in),
           .instr_hold(instr_if2id_hold),
           .instr_addr_out(instr_addr_if2id_out),
           .instr_out(instr_if2id_out)
         );

  decode  decode_inst (
            .instr_in(instr_decode_in),
            .rs1_data(decode_rs1_data),
            .rs2_data(decode_rs2_data),
            .rs1_addr(decode_rs1_addr),
            .rs2_addr(decode_rs2_addr),
            .reg_addr(decode_reg_addr),
            .op1_out(decode_op1_out),
            .op2_out(decode_op2_out),
            .funct3(decode_funct3),
            .funct7(decode_funct7),
            .opcode(decode_opcode)
          );

  regs  regs_inst (
          .clk(clk),
          .rstn(rstn),
          .reg_en(reg_en),
          .reg_addr(reg_addr),
          .reg_data(reg_data),
          .rs1_addr(reg_rs1_addr),
          .rs2_addr(reg_rs2_addr),
          .rs1_data(reg_rs1_data),
          .rs2_data(reg_rs2_data)
        );


endmodule
