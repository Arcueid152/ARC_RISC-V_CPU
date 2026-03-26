`timescale 1ns/1ns 

`include "../rtl/core/defines.v"

module tb_arcriscv;

reg                 clk;          // 时钟信号（时序逻辑用reg）
reg                 rstn;         // 复位信号（低有效，与pc_cnt模块一致）

// 例化pc_cnt模块（Verilog-2001端口映射格式）
arcriscv  arcriscv_inst (
    .clk(clk),
    .rstn(rstn)
  );

// 生成5ns周期的时钟（Verilog-2001合法写法）
always #5 clk = ~clk;

// 初始化和测试激励（Verilog-2001语法）
initial begin
    // 初始信号赋值（Verilog-2001支持'0，但推荐显式赋值）
    clk         = 1'b0;
    rstn        = 1'b0;
    // 复位阶段
    #1000;
    rstn        = 1'b1;
end


endmodule