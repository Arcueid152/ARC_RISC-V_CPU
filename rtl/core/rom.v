module rom #(
    parameter FILE    = "rv32ui-p-addi.txt",  // 指令文件
    parameter AW      = 32,                  // 地址位宽
    parameter DW      = 32                   // 数据位宽
  )(
    input      [AW-1:0] instr_addr,
    output reg [DW-1:0] instr_out
  );

  // 定义ROM存储深度：4096个32位存储单元
  reg [DW-1:0] rom_mem [0:4095];

  // 初始化：从hex文件加载指令
  initial
  begin
    $readmemh({"../../tests/", FILE}, rom_mem);
  end

  always @(*)
  begin
    // 字节地址转字地址（RISC-V 32位指令对齐）
    instr_out = rom_mem[instr_addr[AW-1:2]];
  end

endmodule
