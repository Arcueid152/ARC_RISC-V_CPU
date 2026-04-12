`include "defines.v"

module arcriscv (
    input  wire clk,
    input  wire rst
  );

  // ========== pc_cnt 模块端口信号 ==========
  wire  [31:0]  pc_pointer;
  wire          pc_jump_en;
  wire          pc_jump_hold;
  wire  [31:0]  pc_jump_addr;

  // ========== rom 模块端口信号 ==========
  wire  [31:0]  rom_instr_out;
  wire  [31:0]  rom_instr_addr;

  // ========== if_id 模块端口信号 ==========
  wire  [31:0]  if2id_instr_addr_out;
  wire  [31:0]  if2id_instr_out;
  wire  [31:0]  if2id_instr_addr_in ;
  wire  [31:0]  if2id_instr_in ;
  wire          if2id_instr_hold;

  // ========== decode 模块端口信号 ==========
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

  // ========== regs 寄存器堆端口信号 ==========
  wire          regs_reg_en;        // 寄存器使能
  wire  [4:0]   regs_reg_addr;
  wire  [31:0]  regs_reg_data;
  wire  [4:0]   regs_reg_rs1_addr;  // 输入地址
  wire  [4:0]   regs_reg_rs2_addr;
  wire  [31:0]  regs_reg_rs1_data;
  wire  [31:0]  regs_reg_rs2_data;

  // ========== id_ex 模块端口信号 ==========
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

  // ========== ex 模块端口信号 ==========
  wire [31:0] ex_instr_in;
  wire [31:0] ex_instr_addr_in;
  wire [31:0] ex_op1;
  wire [31:0] ex_op2;
  wire [2:0]  ex_funct3; 
  wire [6:0]  ex_funct7; 
  wire [6:0]  ex_opcode; 
  wire [31:0] ex_rs2_data;   // *** NEW *** 来自 id_ex 的 rs2 数据

  // ex 输出信号（五级流水线新增部分）
  wire [4:0]  ex_rd_out;         // *** NEW ***
  wire [31:0] ex_alu_result;     // *** NEW ***
  wire [31:0] ex_store_data;     // *** NEW ***
  wire [2:0]  ex_funct3_out;     // *** NEW ***
  wire [6:0]  ex_opcode_out;     // *** NEW ***
  wire        ex_mem_read;       // *** NEW ***
  wire        ex_mem_write;      // *** NEW ***
  wire        ex_wb_en;          // *** NEW ***

  // 跳转信号（保持原名）
  wire        ex_jump_en;
  wire        ex_jump_hold;
  wire [31:0] ex_jump_addr;

  // ========== ex_mem 模块端口信号（MEM 阶段） ==========
  wire        mem_ram_wr_en;     // *** NEW ***
  wire [31:0] mem_ram_addr;      // *** NEW ***
  wire [31:0] mem_ram_wr_data;   // *** NEW ***
  wire [31:0] mem_ram_rd_data;   // *** NEW ***
  wire        mem_wb_en_out;     // *** NEW ***
  wire [4:0]  mem_rd_out;        // *** NEW ***
  wire [31:0] mem_wb_data;       // *** NEW ***

  // ========== mem_wb 模块端口信号（MEM/WB 流水线寄存器） ==========
  wire        mw_wb_en;          // *** NEW ***
  wire [4:0]  mw_rd;             // *** NEW ***
  wire [31:0] mw_wb_data;        // *** NEW ***

  // ========== ram 模块端口信号 ==========
  wire        ram_wr_en;
  wire [31:0] ram_wr_addr;
  wire [31:0] ram_wr_data;
  wire [31:0] ram_rd_addr;
  wire [31:0] ram_rd_data;

  // ========== 流水线停顿信号 ==========
  wire stall;
  assign stall = 1'b0;           // *** NEW *** 后续可扩展

  /*=================================*/
  /*          assign 连接             */
  /*=================================*/

  // pc_cnt 输入
  assign pc_jump_en   = ex_jump_en;
  assign pc_jump_hold = ex_jump_hold;
  assign pc_jump_addr = ex_jump_addr;

  // rom 输入
  assign rom_instr_addr = pc_pointer;

  // if_id 输入
  assign if2id_instr_addr_in = pc_pointer;
  assign if2id_instr_in      = rom_instr_out;
  assign if2id_instr_hold    = ex_jump_hold | stall;   // *** MODIFIED ***

  // decode 输入
  assign decode_instr_in = if2id_instr_out;
  assign decode_rs1_data = regs_reg_rs1_data;
  assign decode_rs2_data = regs_reg_rs2_data;

  // regs 输入（写回来自 MEM/WB 阶段）
  assign regs_reg_en       = mw_wb_en;        // *** MODIFIED *** 原为 ex_reg_en
  assign regs_reg_addr     = mw_rd;           // *** MODIFIED *** 原为 ex_reg_addr
  assign regs_reg_data     = mw_wb_data;      // *** MODIFIED *** 原为 ex_reg_data
  assign regs_reg_rs1_addr = decode_rs1_addr;
  assign regs_reg_rs2_addr = decode_rs2_addr;

  // ========== EX→ID Forwarding 逻辑 ==========
  // forward 源A：EX 阶段组合输出（最新，优先级最高）
  // forward 源B：MEM 阶段寄存器输出
  //
  // rs1 forwarding
  wire fwd_A_rs1 = ex_wb_en     && (ex_rd_out  != 5'h0) && (ex_rd_out  == decode_rs1_addr);
  wire fwd_B_rs1 = mem_wb_en_out && (mem_rd_out != 5'h0) && (mem_rd_out == decode_rs1_addr);
  // rs2 forwarding（同时作用于 op2 和 rs2_data_out）
  wire fwd_A_rs2 = ex_wb_en     && (ex_rd_out  != 5'h0) && (ex_rd_out  == decode_rs2_addr);
  wire fwd_B_rs2 = mem_wb_en_out && (mem_rd_out != 5'h0) && (mem_rd_out == decode_rs2_addr);

  // forwarded rs1 值
  wire [31:0] fwd_rs1_val = fwd_A_rs1 ? ex_alu_result :
                             fwd_B_rs1 ? mem_wb_data   :
                             decode_op1_out;

  // forwarded rs2 原始值（给 store 的 rs2_data_out 通路）
  wire [31:0] fwd_rs2_val = fwd_A_rs2 ? ex_alu_result :
                             fwd_B_rs2 ? mem_wb_data   :
                             decode_rs2_data_out;

  // op2 是寄存器值还是立即数？
  // R型(INST_TYPE_R_M) 和 B型(INST_TYPE_B) 的 op2 来自寄存器，其余是立即数
  wire op2_is_reg = (decode_opcode == `INST_TYPE_R_M) || (decode_opcode == `INST_TYPE_B);

  // forwarded op2：只有 op2 是寄存器时才 forward，立即数直接透传
  wire [31:0] fwd_op2_val = op2_is_reg ? (fwd_A_rs2 ? ex_alu_result :
                                           fwd_B_rs2 ? mem_wb_data   :
                                           decode_op2_out)
                                        : decode_op2_out;

  // id_ex 输入
  assign id2ex_instr_hold    = ex_jump_hold | stall;
  assign id2ex_instr_in      = if2id_instr_out;
  assign id2ex_instr_addr_in = if2id_instr_addr_out;
  assign id2ex_op1_in        = fwd_rs1_val;    // *** forwarding ***
  assign id2ex_op2_in        = fwd_op2_val;    // *** forwarding ***
  assign id2ex_funct3_in     = decode_funct3;
  assign id2ex_funct7_in     = decode_funct7;
  assign id2ex_opcode_in     = decode_opcode;
  assign id2ex_rs2_data_in   = fwd_rs2_val;    // *** forwarding（store 专用）***

  // ex 输入
  assign ex_instr_in      = id2ex_instr_out;
  assign ex_instr_addr_in = id2ex_instr_addr_out;
  assign ex_op1           = id2ex_op1_out;
  assign ex_op2           = id2ex_op2_out;
  assign ex_funct3        = id2ex_funct3_out;
  assign ex_funct7        = id2ex_funct7_out;
  assign ex_opcode        = id2ex_opcode_out;
  assign ex_rs2_data      = id2ex_rs2_data_out;   // ===== 新增 =====

  // ram 输入（连接来自 MEM 阶段）
  assign ram_wr_en   = mem_ram_wr_en;      // *** MODIFIED ***
  assign ram_wr_addr = mem_ram_addr;       // *** MODIFIED ***
  assign ram_wr_data = mem_ram_wr_data;    // *** MODIFIED ***
  assign ram_rd_addr = mem_ram_addr;       // *** MODIFIED ***
  // ram_rd_data 输出连接到 mem_ram_rd_data，见实例化

  /*=================================*/
  /*         模块实例化               */
  /*=================================*/

  pc_cnt  pc_cnt_inst (
            .clk(clk),
            .rst(rst),
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
           .rst(rst),
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
           .rs2_data_out(id2ex_rs2_data_out)     // ===== 新增 =====
         );

  // ===== ex 模块实例化（端口已更新） =====
  ex  ex_inst (
        .instr_in(ex_instr_in),
        .instr_addr_in(ex_instr_addr_in),
        .op1(ex_op1),
        .op2(ex_op2),
        .funct3(ex_funct3),
        .funct7(ex_funct7),
        .opcode(ex_opcode),
        .rs2_data(ex_rs2_data),      // *** NEW ***
        // 新增输出端口
        .rd_out(ex_rd_out),          // *** NEW ***
        .alu_result(ex_alu_result),  // *** NEW ***
        .store_data(ex_store_data),  // *** NEW ***
        .funct3_out(ex_funct3_out),  // *** NEW ***
        .opcode_out(ex_opcode_out),  // *** NEW ***
        .mem_read(ex_mem_read),      // *** NEW ***
        .mem_write(ex_mem_write),    // *** NEW ***
        .wb_en(ex_wb_en),            // *** NEW ***
        // 跳转输出
        .jump_en(ex_jump_en),
        .jump_hold(ex_jump_hold),
        .jump_addr(ex_jump_addr)
      );

  // ===== ex_mem 模块实例化（MEM 阶段） =====
  ex_mem  ex_mem_inst (
        .clk(clk),                     // *** NEW ***
        .rst(rst),                  // *** NEW ***
        .rd_in(ex_rd_out),             // *** NEW ***
        .alu_result_in(ex_alu_result), // *** NEW ***
        .store_data_in(ex_store_data), // *** NEW ***
        .funct3_in(ex_funct3_out),     // *** NEW ***
        .opcode_in(ex_opcode_out),     // *** NEW ***
        .mem_read_in(ex_mem_read),     // *** NEW ***
        .mem_write_in(ex_mem_write),   // *** NEW ***
        .wb_en_in(ex_wb_en),           // *** NEW ***
        // RAM 接口
        .ram_wr_en(mem_ram_wr_en),     // *** NEW ***
        .ram_addr(mem_ram_addr),       // *** NEW ***
        .ram_wr_data(mem_ram_wr_data), // *** NEW ***
        .ram_rd_data(mem_ram_rd_data), // *** NEW ***
        // 写回输出
        .wb_en_out(mem_wb_en_out),     // *** NEW ***
        .rd_out(mem_rd_out),           // *** NEW ***
        .wb_data(mem_wb_data)          // *** NEW ***
      );

  // ===== mem_wb 模块实例化（MEM/WB 流水线寄存器） =====
  mem_wb  mem_wb_inst (
        .clk(clk),                     // *** NEW ***
        .rst(rst),                  // *** NEW ***
        .stall(stall),                 // *** NEW ***
        .wb_en_in(mem_wb_en_out),      // *** NEW ***
        .rd_in(mem_rd_out),            // *** NEW ***
        .wb_data_in(mem_wb_data),      // *** NEW ***
        .wb_en_out(mw_wb_en),          // *** NEW ***
        .rd_out(mw_rd),                // *** NEW ***
        .wb_data_out(mw_wb_data)       // *** NEW ***
      );
 
  // ===== ram 模块实例化 =====
  ram  ram_inst (
        .clk(clk),
        .rst(rst),
        .wr_en(ram_wr_en),
        .wr_addr(ram_wr_addr),
        .wr_data(ram_wr_data),
        .rd_addr(ram_rd_addr),
        .rd_data(ram_rd_data)          // 连接到 mem_ram_rd_data 在实例化中隐式完成
      );

  // 将 ram 的读数据连接到 mem 模块的输入
  assign mem_ram_rd_data = ram_rd_data;   // *** NEW ***

endmodule