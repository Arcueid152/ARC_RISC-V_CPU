module myCPU (
    input  wire         cpu_rst,
    input  wire         cpu_clk,

    // ---- 指令存储器接口
    output wire [31:0]  irom_addr,     // PC 地址 → IROM
    input  wire [31:0]  irom_data,     // 指令数据 ← IROM

    // ---- 数据 
    output wire [31:0]  perip_addr,    // 读写地址
    output wire         perip_wen,     // 写使能（高有效）
    output wire [1:0]   perip_mask,    // 传输宽度：00=byte 01=half 10=word
    output wire [31:0]  perip_wdata,   // 写数据
    input  wire [31:0]  perip_rdata    // 读数据
);

  //IF
  wire [31:0] pc_pointer;
  assign irom_addr = pc_pointer;

  //IF2ID
  wire  [31:0] IF2ID_instr_addr_out;
  wire  [31:0] IF2ID_instr_out;

  //ID
  wire     [4:0]   ID_rs1_addr;   
  wire     [4:0]   ID_rs2_addr;   
  wire     [4:0]   ID_reg_addr;   
  wire     [31:0]  ID_op1_out;    
  wire     [31:0]  ID_op2_out;   
  wire     [2:0]   ID_funct3;     
  wire     [6:0]   ID_funct7;    
  wire     [6:0]   ID_opcode;

  //Forwarding_
  wire     [4:0] Forwarding_rs1_addr_out;        //ID2EX传入rs1地址
  wire     [4:0] Forwarding_rs2_addr_out;        //ID2EX传入rs2地址
  wire     [31:0]  Forwarding_rs1_data_out;  // 源寄存器1的数据
  wire     [31:0]  Forwarding_rs2_data_out;  // 源寄存器2的数据

  //RegFile
  wire [31:0] RF_rs1_data;
  wire [31:0] RF_rs2_data;

  //ID_EX
  wire [31:0] ID2EX_instr_out;
  wire [31:0] ID2EX_instr_addr_out;
  wire [31:0] ID2EX_op1_out;
  wire [31:0] ID2EX_op2_out;
  wire [2:0]  ID2EX_funct3_out;     // 功能码3位
  wire [6:0]  ID2EX_funct7_out;     // 功能码7位
  wire [6:0]  ID2EX_opcode_out;
  wire      [4:0]   ID2EX_reg_addr_out;

  //EX_
  wire [31:0]  EX_perip_addr;    // 读写地址
  wire         EX_perip_wen;     // 写使能（高有效）
  wire [1:0]   EX_perip_mask;    // 传输宽度：00=byte 01=half 10=word
  wire [31:0]  EX_perip_wdata;   // 写数据

  wire[31:0] EX_reg_data;       // 写寄存器数据
  wire       EX_reg_en;         // 是否要写通用寄存器

  wire         EX_jump_en;
  wire         EX_jump_hold;
  wire  [31:0] EX_jump_addr;
  wire         EXMemoryRE;

  //EX2MEM_
  wire [31:0]  EX2MEM_perip_addr;    // 读写地址
  wire         EX2MEM_perip_wen;     // 写使能（高有效）
  wire [1:0]   EX2MEM_perip_mask;    // 传输宽度：00=byte 01=half 10=word
  wire [31:0]  EX2MEM_perip_wdata;   // 写数据

  wire[31:0] EX2MEM_reg_data;       // 写寄存器数据
  wire       EX2MEM_reg_en;         // 是否要写通用寄存器
  wire[4:0] EX2MEM_reg_addr;   // 写通用寄存器地址
    
  wire [2:0]  EX2MEM_funct3;
  wire        EXMemoryRE_out;


  //MemCtrl_
  wire [31:0] MemCtrl_reg_data;

  assign perip_addr = EX2MEM_perip_addr;
  assign perip_wen = EX2MEM_perip_wen;
  assign perip_mask = EX2MEM_perip_mask;
  assign perip_wdata = EX2MEM_perip_wdata;

  //MEM2WB_
  wire [31:0] MEM2WB_reg_data;       // 写寄存器数据
  wire        MEM2WB_reg_en;         // 是否要写通用寄存器
  wire [4:0] MEM2WB_reg_addr;   // 写通用寄存器地址

  //Ctrl_
  wire  PCStall;          // 阻塞PC
  wire  IFStall;          // 阻塞IF2ID
  wire  IDFlush;            // 清空ID2EX
  

IF  IF_inst (
    .clk(cpu_clk),
    .rst(cpu_rst),
    .jump_en(EX_jump_en),
    .jump_hold(EX_jump_hold),
    .jump_addr(EX_jump_addr),
    .stall(PCStall),
    .pc_pointer(pc_pointer)
  );

IF2ID  IF2ID_inst (
    .clk(cpu_clk),
    .rst(cpu_rst),
    .instr_addr_in(pc_pointer),
    .instr_in(irom_data),
    .jump_hold(EX_jump_hold),
    .stall(IFStall),
    .instr_addr_out(IF2ID_instr_addr_out),
    .instr_out(IF2ID_instr_out)
  );

ID  ID_inst (
    .instr_in(IF2ID_instr_out),
    .rs1_data(Forwarding_rs1_data_out),
    .rs2_data(Forwarding_rs2_data_out),
    .rs1_addr(ID_rs1_addr),
    .rs2_addr(ID_rs2_addr),
    .reg_addr(ID_reg_addr),
    .op1_out(ID_op1_out),
    .op2_out(ID_op2_out),
    .funct3(ID_funct3),
    .funct7(ID_funct7),
    .opcode(ID_opcode)
  );

Forwarding  Forwarding_inst (
    .rs1_addr(ID_rs1_addr),
    .rs2_addr(ID_rs2_addr),
    .rs1_data(RF_rs1_data),
    .rs2_data(RF_rs2_data),
    .EX_RegWA(ID2EX_reg_addr_out),
    .EX_RegWE(EX_reg_en),
    .EX_RegDA(EX_reg_data),
    .MEM_RegWA(EX2MEM_reg_addr),
    .MEM_RegWE(EX2MEM_reg_en),
    .MEM_RegDA(MemCtrl_reg_data),
    .rs1_addr_out(Forwarding_rs1_addr_out),
    .rs2_addr_out(Forwarding_rs2_addr_out),
    .rs1_data_out(Forwarding_rs1_data_out),
    .rs2_data_out(Forwarding_rs2_data_out)
  );

RegFile  RegFile_inst (
    .clk(cpu_clk),
    .rst(cpu_rst),
    .reg_en(MEM2WB_reg_en),
    .reg_addr(MEM2WB_reg_addr),
    .reg_data(MEM2WB_reg_data),
    .rs1_addr(Forwarding_rs1_addr_out),
    .rs2_addr(Forwarding_rs2_addr_out),
    .rs1_data(RF_rs1_data),
    .rs2_data(RF_rs2_data)
  );

ID2EX  ID2EX_inst (
    .clk(cpu_clk),
    .rst(cpu_rst),
    .jump_hold(EX_jump_hold),
    .flush(IDFlush),
    .instr_in(IF2ID_instr_out),
    .instr_addr_in(IF2ID_instr_addr_out),
    .op1_in(ID_op1_out),
    .op2_in(ID_op2_out),
    .opcode_in(ID_opcode),
    .funct3_in(ID_funct3),
    .funct7_in(ID_funct7),
    .reg_addr_in(ID_reg_addr),
    .instr_out(ID2EX_instr_out),
    .instr_addr_out(ID2EX_instr_addr_out),
    .op1_out(ID2EX_op1_out),
    .op2_out(ID2EX_op2_out),
    .funct3_out(ID2EX_funct3_out),
    .funct7_out(ID2EX_funct7_out),
    .opcode_out(ID2EX_opcode_out),
    .reg_addr_out(ID2EX_reg_addr_out)
  );

EX  EX_inst (
    .instr_in(ID2EX_instr_out),
    .instr_addr_in(ID2EX_instr_addr_out),
    .op1(ID2EX_op1_out),
    .op2(ID2EX_op2_out),
    .funct3(ID2EX_funct3_out),
    .funct7(ID2EX_funct7_out),
    .opcode(ID2EX_opcode_out),

    .perip_addr(EX_perip_addr),
    .perip_wen(EX_perip_wen),
    .perip_mask(EX_perip_mask),
    .perip_wdata(EX_perip_wdata),
    .reg_data(EX_reg_data),
    .reg_en(EX_reg_en),

    .jump_en(EX_jump_en),
    .jump_hold(EX_jump_hold),
    .jump_addr(EX_jump_addr),
    .EXMemoryRE(EXMemoryRE)
  );

  EX2MEM  EX2MEM_inst (
    .clk(cpu_clk),
    .rst(cpu_rst),
    .perip_addr_in(EX_perip_addr),
    .perip_wen_in(EX_perip_wen),
    .perip_mask_in(EX_perip_mask),
    .perip_wdata_in(EX_perip_wdata),
    .reg_data_in(EX_reg_data),
    .reg_en_in(EX_reg_en),
    .reg_addr_in(ID2EX_reg_addr_out),
    .funct3_in(ID2EX_funct3_out),
    .EXMemoryRE(EXMemoryRE),
    .perip_addr(EX2MEM_perip_addr),
    .perip_wen(EX2MEM_perip_wen),
    .perip_mask(EX2MEM_perip_mask),
    .perip_wdata(EX2MEM_perip_wdata),
    .reg_data(EX2MEM_reg_data),
    .reg_en(EX2MEM_reg_en),
    .reg_addr(EX2MEM_reg_addr),
    .funct3(EX2MEM_funct3),
    .EXMemoryRE_out(EXMemoryRE_out)
  );

  MemCtrl  MemCtrl_inst (
    .funct3(EX2MEM_funct3),
    .EXMemoryRE(EXMemoryRE_out),
    .perip_rdata(perip_rdata),
    .reg_data_in(EX2MEM_reg_data),
    .reg_data(MemCtrl_reg_data)
  );

  MEM2WB  MEM2WB_inst (
    .clk(cpu_clk),
    .rst(cpu_rst),
    .reg_data_in(MemCtrl_reg_data),
    .reg_en_in(EX2MEM_reg_en),
    .reg_addr_in(EX2MEM_reg_addr),
    .reg_data(MEM2WB_reg_data),
    .reg_en(MEM2WB_reg_en),
    .reg_addr(MEM2WB_reg_addr)
  );

  Ctrl  Ctrl_inst (
    .Reg1RA(ID_rs1_addr),
    .Reg2RA(ID_rs2_addr),
    .RegWA(ID2EX_reg_addr_out),
    .EXRegEn(EX_reg_en),
    .EXMemoryRE(EXMemoryRE),
    .PCStall(PCStall),
    .IFStall(IFStall),
    .IDFlush(IDFlush)
  );

endmodule