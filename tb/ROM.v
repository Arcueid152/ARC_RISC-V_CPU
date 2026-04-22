module ROM (
    input      [31:0] instr_addr,
    output reg [31:0] instr_out
  );

  // 定义ROM存储深度：4096个32位存储单元
  reg [31:0] rom_mem [0:4095];

  // 初始化：从hex文件加载指令
  initial
  begin
    $readmemh("C:/Users/13227/Documents/2026_JXS/ARC_RISC-V_CPU/test1.txt", rom_mem);
  end

  always @(*)
  begin
    // 字节地址转字地址（RISC-V 32位指令对齐）
    instr_out = rom_mem[instr_addr[13:2]];
  end

endmodule
