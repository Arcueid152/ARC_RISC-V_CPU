`include "defines.v"

module arcriscv (
    input  wire clk,
    input  wire rstn
  );

  //pc_cnt
  wire  [31:0]  pc_pointer;
  wire          pc_jump_en;
  wire          pc_jump_hold;
  wire  [31:0]  pc_jump_addr;

  //rom
  wire  [31:0]  rom_instr_out;
  wire  [31:0]  rom_instr_addr;

  //if2id
  wire  [31:0]  if2id_instr_addr_out;
  wire  [31:0]  if2id_instr_out;
  wire  [31:0]  if2id_instr_addr_in ;
  wire  [31:0]  if2id_instr_in ;
  wire          if2id_instr_hold;

  //decode
  wire  [31:0]  decode_instr_in;   // 输入的指令
  wire  [31:0]  decode_rs1_data;   // 源寄存器1的数据
  wire  [31:0]  decode_rs2_data;   // 源寄存器2的数据
  wire  [4:0]   decode_rs1_addr;   // 源寄存器1的地址
  wire  [4:0]   decode_rs2_addr;   // 源寄存器2的地址
  wire  [4:0]   decode_reg_addr;   // 目标寄存器地址
  wire  [31:0]  decode_op1_out;    // 操作数1输出
  wire  [31:0]  decode_op2_out;    // 操作数2输出
  wire  [2:0]   decode_funct3;     // 功能码3位
  wire  [6:0]   decode_funct7;     // 功能码7位
  wire  [6:0]   decode_opcode;

  //regs寄存器
  wire          regs_reg_en;//寄存器使能
  wire  [4:0]   regs_reg_addr;
  wire  [31:0]  regs_reg_data;
  wire  [4:0]   regs_reg_rs1_addr;//输入地址
  wire  [4:0]   regs_reg_rs2_addr;
  wire  [31:0]  regs_reg_rs1_data;
  wire  [31:0]  regs_reg_rs2_data;

  //id2ex
  wire          id2ex_instr_hold;
  wire [31:0]   id2ex_instr_in;
  wire [31:0]   id2ex_instr_addr_in;
  wire [31:0]   id2ex_op1_in;
  wire [31:0]   id2ex_op2_in;
  wire [6:0]    id2ex_opcode_in;
  wire [2:0]    id2ex_funct3_in;     // 功能码3位
  wire [6:0]    id2ex_funct7_in;      // 功能码7位
  wire [31:0]   id2ex_instr_out;
  wire [31:0]   id2ex_instr_addr_out;
  wire [31:0]   id2ex_op1_out;
  wire [31:0]   id2ex_op2_out;
  wire [2:0]    id2ex_funct3_out;     // 功能码3位
  wire [6:0]    id2ex_funct7_out;      // 功能码7位
  wire [6:0]    id2ex_opcode_out;

  //ex
  wire [31:0] ex_instr_in;
  wire [31:0] ex_instr_addr_in;

  wire [31:0] ex_op1;
  wire [31:0] ex_op2;
  wire [2:0] ex_funct3; 
  wire [6:0] ex_funct7; 
  wire [6:0] ex_opcode; 

  wire ex_reg_en;
  wire [4:0] ex_reg_addr;
  wire [31:0] ex_reg_data;
    //跳转传回pc_cnt
  wire ex_jump_en;
  wire ex_jump_hold;
  wire [31:0]ex_jump_addr;
  /*=================================*/

  //pc_cnt输入
  assign pc_jump_en = ex_jump_en;
  assign pc_jump_hold = ex_jump_hold;
  assign pc_jump_addr = ex_jump_addr;

  //rom输入
  assign rom_instr_addr = pc_pointer;

  //if2id输入
  assign if2id_instr_addr_in = pc_pointer;
  assign if2id_instr_in = rom_instr_out;
  assign if2id_instr_hold = ex_jump_hold;

  //decode输入
  assign   decode_instr_in = if2id_instr_out;  // 输入的指令
  assign   decode_rs1_data = regs_reg_rs1_data;   // 源寄存器1的数据
  assign   decode_rs2_data = regs_reg_rs2_data;   // 源寄存器2的数据

  //reg输入
  assign regs_reg_en = ex_reg_en;
  assign regs_reg_addr = ex_reg_addr;
  assign regs_reg_data = ex_reg_data;
  assign regs_reg_rs1_addr = decode_rs1_addr;
  assign regs_reg_rs2_addr = decode_rs2_addr;

  //id2ex
  assign  id2ex_instr_hold   =       ex_jump_hold;
  assign  id2ex_instr_in     =       if2id_instr_out;
  assign  id2ex_instr_addr_in=       if2id_instr_addr_out;
  assign  id2ex_op1_in       =       decode_op1_out;
  assign  id2ex_op2_in       =       decode_op2_out;
  assign  id2ex_funct3_in    =       decode_funct3;
  assign  id2ex_funct7_in    =       decode_funct7;
  assign  id2ex_opcode_in    =       decode_opcode;

  //ex
  assign  ex_instr_in = id2ex_instr_out;
  assign  ex_instr_addr_in = id2ex_instr_addr_out;

  assign  ex_op1 = id2ex_op1_out;
  assign  ex_op2 = id2ex_op2_out;
  assign ex_funct3 = id2ex_funct3_out; 
  assign ex_funct7 = id2ex_funct7_out; 
  assign ex_opcode = id2ex_opcode_out; 


  pc_cnt  pc_cnt_inst (
            .clk(clk),
            .rstn(rstn),
            .jump_en(pc_jump_en),
            .jump_hold(pc_jump_hold),
            .jump_addr(pc_jump_addr),
            .pc_pointer(pc_pointer)
          );

  rom rom_inst (
        .instr_addr(rom_instr_addr),
        .instr_out(rom_instr_out)
      );

  if_id  if_id_inst (
           .clk(clk),
           .rstn(rstn),
           .instr_addr_in(if2id_instr_addr_in),
           .instr_in(if2id_instr_in),
           .instr_hold(if2id_instr_hold),
           .instr_addr_out(if2id_instr_addr_out),
           .instr_out(if2id_instr_out)
         );

  decode  decode_inst (
            .instr_in(decode_instr_in),
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
          .reg_en(regs_reg_en),
          .reg_addr(regs_reg_addr),
          .reg_data(regs_reg_data),
          .rs1_addr(regs_reg_rs1_addr),
          .rs2_addr(regs_reg_rs2_addr),
          .rs1_data(regs_reg_rs1_data),
          .rs2_data(regs_reg_rs2_data)
        );
  id_ex  id_ex_inst (
           .clk(clk),
           .rstn(rstn),
           .instr_hold(id2ex_instr_hold),
           .instr_in(id2ex_instr_in),
           .instr_addr_in(id2ex_instr_addr_in),
           .op1_in(id2ex_op1_in),
           .op2_in(id2ex_op2_in),
           .opcode_in(id2ex_opcode_in),
           .funct3_in(id2ex_funct3_in),
           .funct7_in(id2ex_funct7_in),
           .instr_out(id2ex_instr_out),
           .instr_addr_out(id2ex_instr_addr_out),
           .op1_out(id2ex_op1_out),
           .op2_out(id2ex_op2_out),
           .funct3_out(id2ex_funct3_out),
           .funct7_out(id2ex_funct7_out),
           .opcode_out(id2ex_opcode_out)
         );

  ex  ex_inst (
        .instr_in(ex_instr_in),
        .instr_addr_in(ex_instr_addr_in),
        .op1(ex_op1),
        .op2(ex_op2),
        .funct3(ex_funct3),
        .funct7(ex_funct7),
        .opcode(ex_opcode),
        .reg_en(ex_reg_en),
        .reg_addr(ex_reg_addr),
        .reg_data(ex_reg_data),
        .jump_en(ex_jump_en),
        .jump_hold(ex_jump_hold),
        .jump_addr(ex_jump_addr)
      );


endmodule
