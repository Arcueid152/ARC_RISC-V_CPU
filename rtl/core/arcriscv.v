`include "defines.v"

module arcriscv (
    input  wire clk,
    input  wire rst
  );

  //pc_cnt
  wire  [31:0]  pc_pointer;
  wire          pc_jump_en;
  wire          pc_jump_hold;
  wire  [31:0]  pc_jump_addr;
  wire          pc_periph_hold_pc;

  //rom
  wire  [31:0]  rom_instr_out;
  wire  [31:0]  rom_instr_addr;
  wire  [31:0]  rom_data_out;   // ★ 新增：ROM 数据读口输出
  wire  [31:0]  rom_data_addr;  // ★ 新增：ROM 数据读口地址

  //if2id
  wire  [31:0]  if2id_instr_addr_out;
  wire  [31:0]  if2id_instr_out;
  wire  [31:0]  if2id_instr_addr_in ;
  wire  [31:0]  if2id_instr_in ;
  wire          if2id_instr_hold;
  wire          if2id_periph_hold_pc;
  wire          if2id_wr_periph_reg;
  wire          if2id_rd_periph_reg;


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
  wire  [31:0]  decode_rs2_data_out; // ===== 新增：decode 输出的 rs2_data =====

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
  wire [31:0]   id2ex_rs2_data_in;    // ===== 新增：id_ex 输入的 rs2_data =====
  wire [31:0]   id2ex_instr_out;
  wire [31:0]   id2ex_instr_addr_out;
  wire [31:0]   id2ex_op1_out;
  wire [31:0]   id2ex_op2_out;
  wire [2:0]    id2ex_funct3_out;     // 功能码3位
  wire [6:0]    id2ex_funct7_out;      // 功能码7位
  wire [6:0]    id2ex_opcode_out;
  wire [31:0]   id2ex_rs2_data_out;   // ===== 新增：id_ex 输出的 rs2_data =====
  wire          id2ex_periph_write_back;
  wire          id2ex_wr_reg_en;
  wire          id2ex_wr_periph_reg;
  wire          id2ex_rd_periph_reg;
  wire          id2ex_periph_hold_pc;

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

  wire ex_wr_en;
  wire [31:0]ex_wr_addr;
  wire [31:0]ex_wr_data;
  wire [31:0]ex_rd_addr;
  wire [31:0]ex_rd_data;
  wire [31:0]ex_rs2_data;   // 改为来自 id_ex 的输出
  wire       ex_periph_write_back;
  wire       ex_wr_reg_en;

  //ram
  wire ram_wr_en;
  wire [31:0]ram_wr_addr;
  wire [31:0]ram_wr_data;
  wire [31:0]ram_rd_addr;
  wire [31:0]ram_rd_data;
  wire        load_from_rom;  //  新增：load 地址落在 ROM 范围标志

  /*=================================*/

  //pc_cnt输入
  assign pc_jump_en = ex_jump_en;
  assign pc_jump_hold = ex_jump_hold;
  assign pc_jump_addr = ex_jump_addr;
  assign pc_periph_hold_pc = if2id_periph_hold_pc;

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

  //id2ex 输入连接
  assign  id2ex_instr_hold   =       ex_jump_hold | if2id_periph_hold_pc;
  assign  id2ex_instr_in     =       if2id_instr_out;
  assign  id2ex_instr_addr_in=       if2id_instr_addr_out;
  assign  id2ex_op1_in       =       decode_op1_out;
  assign  id2ex_op2_in       =       decode_op2_out;
  assign  id2ex_funct3_in    =       decode_funct3;
  assign  id2ex_funct7_in    =       decode_funct7;
  assign  id2ex_opcode_in    =       decode_opcode;
  assign  id2ex_rs2_data_in  =       decode_rs2_data_out;   // ===== 新增 =====
  assign  id2ex_wr_periph_reg =      if2id_wr_periph_reg;
  assign  id2ex_rd_periph_reg =      if2id_rd_periph_reg;
  assign  id2ex_periph_hold_pc =     if2id_periph_hold_pc;

  //ex输入
  assign  ex_instr_in = id2ex_instr_out;
  assign  ex_instr_addr_in = id2ex_instr_addr_out;

  assign  ex_op1 = id2ex_op1_out;
  assign  ex_op2 = id2ex_op2_out;
  assign ex_funct3 = id2ex_funct3_out; 
  assign ex_funct7 = id2ex_funct7_out; 
  assign ex_opcode = id2ex_opcode_out; 
  // 修改：load 地址在 ROM 范围(0~0x3FFF)内读 ROM，否则读 RAM
  assign rom_data_addr = ex_rd_addr;
  assign load_from_rom = (ex_rd_addr < 32'h4000);
  assign ex_rd_data    = load_from_rom ? rom_data_out : ram_rd_data;
  assign ex_rs2_data = id2ex_rs2_data_out;   // ===== 修改：从 id_ex 输出获取 rs2_data =====
  assign ex_periph_write_back = id2ex_periph_write_back;
  assign ex_wr_reg_en = id2ex_wr_reg_en;

  //ram输入
  assign ram_wr_en = ex_wr_en;
  assign ram_wr_addr = ex_wr_addr;
  assign ram_wr_data = ex_wr_data;
  assign ram_rd_addr = ex_rd_addr;


  pc_cnt  pc_cnt_inst (
            .clk(clk),
            .rst(rst),
            .jump_en(pc_jump_en),
            .jump_hold(pc_jump_hold),
            .jump_addr(pc_jump_addr),
            .periph_hold_pc(pc_periph_hold_pc),
            .pc_pointer(pc_pointer)
          );

  rom rom_inst (
        .instr_addr(rom_instr_addr),
        .instr_out(rom_instr_out),
        .data_addr(rom_data_addr),   
        .data_out(rom_data_out)      
      );

  if_id  if_id_inst (
           .clk(clk),
           .rst(rst),
           .instr_addr_in(if2id_instr_addr_in),
           .instr_in(if2id_instr_in),
           .instr_hold(if2id_instr_hold),
           .instr_addr_out(if2id_instr_addr_out),
           .instr_out(if2id_instr_out),
           .periph_hold_pc(if2id_periph_hold_pc),
           .wr_periph_reg(if2id_wr_periph_reg),
           .rd_periph_reg(if2id_rd_periph_reg)
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
            .opcode(decode_opcode),
            .rs2_data_out(decode_rs2_data_out)   // ===== 新增 =====
          );

  regs  regs_inst (
          .clk(clk),
          .rst(rst),
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
           .rst(rst),
           .instr_hold(id2ex_instr_hold),
           .instr_in(id2ex_instr_in),
           .instr_addr_in(id2ex_instr_addr_in),
           .op1_in(id2ex_op1_in),
           .op2_in(id2ex_op2_in),
           .opcode_in(id2ex_opcode_in),
           .funct3_in(id2ex_funct3_in),
           .funct7_in(id2ex_funct7_in),
           .rs2_data_in(id2ex_rs2_data_in),      // ===== 新增 =====
           .instr_out(id2ex_instr_out),
           .instr_addr_out(id2ex_instr_addr_out),
           .op1_out(id2ex_op1_out),
           .op2_out(id2ex_op2_out),
           .funct3_out(id2ex_funct3_out),
           .funct7_out(id2ex_funct7_out),
           .opcode_out(id2ex_opcode_out),
           .rs2_data_out(id2ex_rs2_data_out),     // ===== 新增 =====
           .wr_periph_reg_in(id2ex_wr_periph_reg),
           .rd_periph_reg_in(id2ex_rd_periph_reg),
           .periph_write_back(id2ex_periph_write_back),
           .wr_reg_en(id2ex_wr_reg_en),
           .periph_hold_pc(id2ex_periph_hold_pc)
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
        .jump_addr(ex_jump_addr),
        .wr_en(ex_wr_en),
        .wr_addr(ex_wr_addr),
        .wr_data(ex_wr_data),
        .rd_addr(ex_rd_addr),
        .rd_data(ex_rd_data),
        .rs2_data(ex_rs2_data),      // 已修改为来自 id_ex 的输出
        .periph_write_back(ex_periph_write_back),
        .wr_reg_en(ex_wr_reg_en)
      );
 
  ram  ram_inst (
     .clk(clk),
     .rst(rst),
     .wr_en(ram_wr_en),
     .wr_addr(ram_wr_addr),
     .wr_data(ram_wr_data),
     .rd_addr(ram_rd_addr),
     .rd_data(ram_rd_data)
     );
  
endmodule