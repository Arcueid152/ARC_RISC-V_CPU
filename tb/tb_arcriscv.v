`timescale 1ns/1ns 

`include "../rtl/core/defines.v"

module tb_arcriscv;

// 定义地址位宽参数（Verilog-2001支持parameter定义）
parameter AW = 32;

reg                 clk;          // 时钟信号（时序逻辑用reg）
reg                 rstn;         // 复位信号（低有效，与pc_cnt模块一致）
reg                 jump_en;      // 跳转使能信号
reg                 jump_hold;    // 跳转保持信号
reg     [AW-1:0]    jump_addr;    // 跳转目标地址
wire    [AW-1:0]    pc_pointer;   // PC指针输出（模块输出用wire）

// 例化pc_cnt模块（Verilog-2001端口映射格式）
pc_cnt u_pc_cnt_inst(
    .clk        (clk),        // 时钟信号连接
    .rstn       (rstn),       // 复位信号
    .jump_en    (jump_en),    // 跳转使能
    .jump_hold  (jump_hold),  // 跳转保持
    .jump_addr  (jump_addr),  // 跳转地址
    .pc_pointer (pc_pointer)  // PC指针输出
);

// 生成5ns周期的时钟（Verilog-2001合法写法）
always #5 clk = ~clk;

// 初始化和测试激励（Verilog-2001语法）
initial begin
    // 初始信号赋值（Verilog-2001支持'0，但推荐显式赋值）
    clk         = 1'b0;
    rstn        = 1'b0;
    jump_en     = 1'b0;
    jump_hold   = 1'b0;
    jump_addr   = 32'h00000000;  // 替代'h0，Verilog-2001更推荐显式位宽

    // 复位阶段
    #1000;
    rstn        = 1'b1;
    $display("复位释放，PC初始值: 0x%08h", pc_pointer);

    // 测试正常计数（每周期+4）
    #5000;
    $display("正常计数后PC值: 0x%08h", pc_pointer);

    // 测试跳转功能（跳转到4096）
    generate_jump(32'd4096);   
    $display("跳转到4096后PC值: 0x%08h", pc_pointer);

    // 测试再次跳转（跳转到2048）
    #6000;                 
    generate_jump(32'd2048);   
    $display("跳转到2048后PC值: 0x%08h", pc_pointer);

    // 验证跳转后继续计数
    #2000;
    $display("跳转后继续计数的PC值: 0x%08h", pc_pointer);

    #1000;                 
    $finish;
end

// 定义跳转激励任务（Verilog-2001标准写法）
task generate_jump;
    input [31:0] addr;  // Verilog-2001任务参数格式（无logic关键字）
begin
    @(posedge clk);
    jump_en   = 1'b1;
    jump_addr = addr;
    
    @(posedge clk);
    jump_en   = 1'b0;
    jump_addr = 32'h00000000;
end
endtask

endmodule