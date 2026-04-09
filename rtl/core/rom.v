`include "defines.v"
module rom (
    // 取指端口（IF 阶段）
    input      [31:0] instr_addr,
    output reg [31:0] instr_out,

    //数据读端口（load 指令）
    input      [31:0] data_addr,
    output reg [31:0] data_out
  );

  // 定义ROM存储深度：4096个32位存储单元
  reg [31:0] rom_mem [0:4095];

  // 初始化：从hex文件加载指令
  initial
  begin
    $readmemh(`FILE, rom_mem);
  end

  // 取指读口
  always @(*)
  begin
    instr_out = rom_mem[instr_addr[31:2]];
  end

  //数据读口（组合逻辑，和取指口独立）
  always @(*)
  begin
    data_out = rom_mem[data_addr[31:2]];
  end

endmodule