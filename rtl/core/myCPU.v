`include "C:/Users/darre/Documents/ARC_RISC-V_CPU/rtl/core/defines.vh"
// ============================================================
//  myCPU —— arcriscv 适配 student_top 的顶层包装
//
//  相对于 arcriscv.v 的改动：
//    1. 模块名改为 myCPU，clk/rst 改为 cpu_clk/cpu_rst
//    2. 移除内部 rom_inst → 改用外部 IROM（irom_addr / irom_data）
//    3. 移除内部 ram_inst → 改用 perip 总线（perip_bridge 负责路由）
//    4. 新增 perip_mask：由 ex_funct3_out[1:0] 决定传输宽度
//       funct3[1:0]: 00=byte  01=halfword  10=word
// ============================================================

module myCPU (
    input  wire         cpu_rst,
    input  wire         cpu_clk,

    // ---- 指令存储器接口（外部 IROM，由 student_top 提供） ----
    output wire [31:0]  irom_addr,     // PC 地址 → IROM
    input  wire [31:0]  irom_data,     // 指令数据 ← IROM

    // ---- 数据 / 外设总线接口（perip_bridge） ----
    output wire [31:0]  perip_addr,    // 读写地址
    output wire         perip_wen,     // 写使能（高有效）
    output wire [1:0]   perip_mask,    // 传输宽度：00=byte 01=half 10=word
    output wire [31:0]  perip_wdata,   // 写数据
    input  wire [31:0]  perip_rdata    // 读数据
);

  // ========================================================
  //  内部信号声明（与 arcriscv.v 保持一致）
  // ========================================================

  // --- pc_cnt ---
  wire [31:0] pc_pointer;
  wire        pc_jump_en;
  wire        pc_jump_hold;
  wire [31:0] pc_jump_addr;

  // --- IROM 桥接（替代原 rom_inst） ---
  wire [31:0] rom_instr_out;    // 指令数据（来自外部 IROM）
  wire [31:0] rom_instr_addr;   // 取指地址（送往外部 IROM）

  assign irom_addr     = rom_instr_addr;  // PC → 顶层 IROM 地址端口
  assign rom_instr_out = irom_data;       // 顶层 IROM 数据 → 流水线

  // --- if_id ---
  wire [31:0] if2id_instr_addr_out;
  wire [31:0] if2id_instr_out;
  wire [31:0] if2id_instr_addr_in;
  wire [31:0] if2id_instr_in;
  wire        if2id_instr_hold;

  // --- decode ---
  wire [31:0] decode_instr_in;
  wire [31:0] decode_rs1_data;
  wire [31:0] decode_rs2_data;
  wire [4:0]  decode_rs1_addr;
  wire [4:0]  decode_rs2_addr;
  wire [4:0]  decode_reg_addr;
  wire [31:0] decode_op1_out;
  wire [31:0] decode_op2_out;
  wire [2:0]  decode_funct3;
  wire [6:0]  decode_funct7;
  wire [6:0]  decode_opcode;
  wire [31:0] decode_rs2_data_out;

  // --- regs ---
  wire        regs_reg_en;
  wire [4:0]  regs_reg_addr;
  wire [31:0] regs_reg_data;
  wire [4:0]  regs_reg_rs1_addr;
  wire [4:0]  regs_reg_rs2_addr;
  wire [31:0] regs_reg_rs1_data;
  wire [31:0] regs_reg_rs2_data;

  // --- id_ex ---
  wire        id2ex_instr_hold;
  wire [31:0] id2ex_instr_in;
  wire [31:0] id2ex_instr_addr_in;
  wire [31:0] id2ex_op1_in;
  wire [31:0] id2ex_op2_in;
  wire [6:0]  id2ex_opcode_in;
  wire [2:0]  id2ex_funct3_in;
  wire [6:0]  id2ex_funct7_in;
  wire [31:0] id2ex_rs2_data_in;
  wire [31:0] id2ex_instr_out;
  wire [31:0] id2ex_instr_addr_out;
  wire [31:0] id2ex_op1_out;
  wire [31:0] id2ex_op2_out;
  wire [2:0]  id2ex_funct3_out;
  wire [6:0]  id2ex_funct7_out;
  wire [6:0]  id2ex_opcode_out;
  wire [31:0] id2ex_rs2_data_out;

  // --- ex ---
  wire [31:0] ex_instr_in;
  wire [31:0] ex_instr_addr_in;
  wire [31:0] ex_op1;
  wire [31:0] ex_op2;
  wire [2:0]  ex_funct3;
  wire [6:0]  ex_funct7;
  wire [6:0]  ex_opcode;
  wire [31:0] ex_rs2_data;
  wire [4:0]  ex_rd_out;
  wire [31:0] ex_alu_result;
  wire [31:0] ex_store_data;
  wire [2:0]  ex_funct3_out;
  wire [6:0]  ex_opcode_out;
  wire        ex_mem_read;
  wire        ex_mem_write;
  wire        ex_wb_en;
  wire        ex_jump_en;
  wire        ex_jump_hold;
  wire [31:0] ex_jump_addr;

  // --- ex_mem（MEM 阶段） ---
  wire        mem_ram_wr_en;
  wire [31:0] mem_ram_addr;
  wire [31:0] mem_ram_wr_data;
  wire [31:0] mem_ram_rd_data;
  wire        mem_wb_en_out;
  wire [4:0]  mem_rd_out;
  wire [31:0] mem_wb_data;

  // --- mem_wb（MEM/WB 流水线寄存器） ---
  wire        mw_wb_en;
  wire [4:0]  mw_rd;
  wire [31:0] mw_wb_data;

  // --- 流水线停顿（暂时恒为 0，后续可扩展） ---
  wire stall;
  assign stall = 1'b0;

  // ========================================================
  //  perip 总线连接（替代原 ram_inst）
  // ========================================================

  assign perip_addr      = mem_ram_addr;       // MEM 阶段地址
  assign perip_wen       = mem_ram_wr_en;       // 写使能
  assign perip_wdata     = mem_ram_wr_data;     // 写数据
  assign perip_mask      = ex_funct3_out[1:0];  // 传输宽度（来自 EX 输出的 funct3）
  assign mem_ram_rd_data = perip_rdata;         // 读数据回路

  // ========================================================
  //  assign 连接（逻辑与 arcriscv.v 完全一致）
  // ========================================================

  // pc_cnt 输入
  assign pc_jump_en   = ex_jump_en;
  assign pc_jump_hold = ex_jump_hold;
  assign pc_jump_addr = ex_jump_addr;

  // IROM 取指地址
  assign rom_instr_addr = pc_pointer;

  // if_id 输入
  assign if2id_instr_addr_in = pc_pointer;
  assign if2id_instr_in      = rom_instr_out;
  assign if2id_instr_hold    = ex_jump_hold | stall;

  // decode 输入
  assign decode_instr_in = if2id_instr_out;
  assign decode_rs1_data = regs_reg_rs1_data;
  assign decode_rs2_data = regs_reg_rs2_data;

  // regs 写回（来自 MEM/WB 阶段）
  assign regs_reg_en       = mw_wb_en;
  assign regs_reg_addr     = mw_rd;
  assign regs_reg_data     = mw_wb_data;
  assign regs_reg_rs1_addr = decode_rs1_addr;
  assign regs_reg_rs2_addr = decode_rs2_addr;

  // ---- EX→ID / MEM→ID Forwarding ----
  wire fwd_A_rs1 = ex_wb_en      && (ex_rd_out  != 5'h0) && (ex_rd_out  == decode_rs1_addr);
  wire fwd_B_rs1 = mem_wb_en_out && (mem_rd_out != 5'h0) && (mem_rd_out == decode_rs1_addr);
  wire fwd_A_rs2 = ex_wb_en      && (ex_rd_out  != 5'h0) && (ex_rd_out  == decode_rs2_addr);
  wire fwd_B_rs2 = mem_wb_en_out && (mem_rd_out != 5'h0) && (mem_rd_out == decode_rs2_addr);

  wire [31:0] fwd_rs1_val = fwd_A_rs1 ? ex_alu_result :
                             fwd_B_rs1 ? mem_wb_data   :
                                         decode_op1_out;

  wire [31:0] fwd_rs2_val = fwd_A_rs2 ? ex_alu_result :
                             fwd_B_rs2 ? mem_wb_data   :
                                         decode_rs2_data_out;

  // op2 只有 R 型和 B 型来自寄存器，其余是立即数
  wire op2_is_reg = (decode_opcode == `INST_TYPE_R_M) ||
                    (decode_opcode == `INST_TYPE_B);

  wire [31:0] fwd_op2_val = op2_is_reg ? (fwd_A_rs2 ? ex_alu_result :
                                           fwd_B_rs2 ? mem_wb_data   :
                                                        decode_op2_out)
                                        : decode_op2_out;

  // id_ex 输入
  assign id2ex_instr_hold    = ex_jump_hold | stall;
  assign id2ex_instr_in      = if2id_instr_out;
  assign id2ex_instr_addr_in = if2id_instr_addr_out;
  assign id2ex_op1_in        = fwd_rs1_val;
  assign id2ex_op2_in        = fwd_op2_val;
  assign id2ex_funct3_in     = decode_funct3;
  assign id2ex_funct7_in     = decode_funct7;
  assign id2ex_opcode_in     = decode_opcode;
  assign id2ex_rs2_data_in   = fwd_rs2_val;

  // ex 输入
  assign ex_instr_in      = id2ex_instr_out;
  assign ex_instr_addr_in = id2ex_instr_addr_out;
  assign ex_op1           = id2ex_op1_out;
  assign ex_op2           = id2ex_op2_out;
  assign ex_funct3        = id2ex_funct3_out;
  assign ex_funct7        = id2ex_funct7_out;
  assign ex_opcode        = id2ex_opcode_out;
  assign ex_rs2_data      = id2ex_rs2_data_out;

  // ========================================================
  //  模块实例化
  // ========================================================

  pc_cnt pc_cnt_inst (
    .clk        (cpu_clk),
    .rst        (cpu_rst),
    .jump_en    (pc_jump_en),
    .jump_hold  (pc_jump_hold),
    .jump_addr  (pc_jump_addr),
    .pc_pointer (pc_pointer)
  );

  // rom_inst 已移除，由顶层外部 IROM 替代

  if_id if_id_inst (
    .clk            (cpu_clk),
    .rst            (cpu_rst),
    .instr_addr_in  (if2id_instr_addr_in),
    .instr_in       (if2id_instr_in),
    .instr_hold     (if2id_instr_hold),
    .instr_addr_out (if2id_instr_addr_out),
    .instr_out      (if2id_instr_out)
  );

  decode decode_inst (
    .instr_in     (decode_instr_in),
    .rs1_data     (decode_rs1_data),
    .rs2_data     (decode_rs2_data),
    .rs1_addr     (decode_rs1_addr),
    .rs2_addr     (decode_rs2_addr),
    .reg_addr     (decode_reg_addr),
    .op1_out      (decode_op1_out),
    .op2_out      (decode_op2_out),
    .funct3       (decode_funct3),
    .funct7       (decode_funct7),
    .opcode       (decode_opcode),
    .rs2_data_out (decode_rs2_data_out)
  );

  regs regs_inst (
    .clk      (cpu_clk),
    .rst      (cpu_rst),
    .reg_en   (regs_reg_en),
    .reg_addr (regs_reg_addr),
    .reg_data (regs_reg_data),
    .rs1_addr (regs_reg_rs1_addr),
    .rs2_addr (regs_reg_rs2_addr),
    .rs1_data (regs_reg_rs1_data),
    .rs2_data (regs_reg_rs2_data)
  );

  id_ex id_ex_inst (
    .clk            (cpu_clk),
    .rst            (cpu_rst),
    .instr_hold     (id2ex_instr_hold),
    .instr_in       (id2ex_instr_in),
    .instr_addr_in  (id2ex_instr_addr_in),
    .op1_in         (id2ex_op1_in),
    .op2_in         (id2ex_op2_in),
    .opcode_in      (id2ex_opcode_in),
    .funct3_in      (id2ex_funct3_in),
    .funct7_in      (id2ex_funct7_in),
    .rs2_data_in    (id2ex_rs2_data_in),
    .instr_out      (id2ex_instr_out),
    .instr_addr_out (id2ex_instr_addr_out),
    .op1_out        (id2ex_op1_out),
    .op2_out        (id2ex_op2_out),
    .funct3_out     (id2ex_funct3_out),
    .funct7_out     (id2ex_funct7_out),
    .opcode_out     (id2ex_opcode_out),
    .rs2_data_out   (id2ex_rs2_data_out)
  );

  ex ex_inst (
    .instr_in      (ex_instr_in),
    .instr_addr_in (ex_instr_addr_in),
    .op1           (ex_op1),
    .op2           (ex_op2),
    .funct3        (ex_funct3),
    .funct7        (ex_funct7),
    .opcode        (ex_opcode),
    .rs2_data      (ex_rs2_data),
    .rd_out        (ex_rd_out),
    .alu_result    (ex_alu_result),
    .store_data    (ex_store_data),
    .funct3_out    (ex_funct3_out),
    .opcode_out    (ex_opcode_out),
    .mem_read      (ex_mem_read),
    .mem_write     (ex_mem_write),
    .wb_en         (ex_wb_en),
    .jump_en       (ex_jump_en),
    .jump_hold     (ex_jump_hold),
    .jump_addr     (ex_jump_addr)
  );

  ex_mem ex_mem_inst (
    .clk           (cpu_clk),
    .rst           (cpu_rst),
    .rd_in         (ex_rd_out),
    .alu_result_in (ex_alu_result),
    .store_data_in (ex_store_data),
    .funct3_in     (ex_funct3_out),
    .opcode_in     (ex_opcode_out),
    .mem_read_in   (ex_mem_read),
    .mem_write_in  (ex_mem_write),
    .wb_en_in      (ex_wb_en),
    .ram_wr_en     (mem_ram_wr_en),
    .ram_addr      (mem_ram_addr),
    .ram_wr_data   (mem_ram_wr_data),
    .ram_rd_data   (mem_ram_rd_data),
    .wb_en_out     (mem_wb_en_out),
    .rd_out        (mem_rd_out),
    .wb_data       (mem_wb_data)
  );

  mem_wb mem_wb_inst (
    .clk         (cpu_clk),
    .rst         (cpu_rst),
    .stall       (stall),
    .wb_en_in    (mem_wb_en_out),
    .rd_in       (mem_rd_out),
    .wb_data_in  (mem_wb_data),
    .wb_en_out   (mw_wb_en),
    .rd_out      (mw_rd),
    .wb_data_out (mw_wb_data)
  );

  // ram_inst 已移除，由顶层 perip_bridge 替代

endmodule