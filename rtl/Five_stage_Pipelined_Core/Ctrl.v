module Ctrl (

    input clk,
    input rst,
    // 来自 ID 
    input [4:0] Reg1RA,            // 源寄存器1地址
    input [4:0] Reg2RA,            // 源寄存器2地址
    
    // 来自 EX
    input [4:0] RegWA,             // EX阶段指令的目的寄存器
    input       EXRegWriteSrc,     // EX阶段指令是否写寄存器
    input       EXMemoryRE,        // EX阶段指令是否是L型指令
    
    // 来自 MEM 
    input [4:0] MEMRegWA,          // MEM阶段指令的目的寄存器
    input       MEMRegWE,          // MEM阶段指令是否写寄存器
    
    // 输出控制信号
    output reg  PCStall,           // 阻塞PC
    output reg  IFStall,           // 阻塞IF2ID
    //output reg  IFFlush,           // 清空IF2ID   （好像没用到？）
    output reg  IDFlush            // 清空ID2EX
);

    reg   [1:0]  stall_cnt;                //load_use专用计数
    // ========== 1. EX阶段 普通冒险检测 (不含load_use) ==========

    wire rs1_hazard_ex = (Reg1RA != 5'b0) && 
                         (Reg1RA == RegWA) && 
                         EXRegWriteSrc;
    
    wire rs2_hazard_ex = (Reg2RA != 5'b0) && 
                         (Reg2RA == RegWA) && 
                         EXRegWriteSrc;
    
    // ========== 2. MEM阶段普通冒险检测 (不含load_use) ==========

    wire rs1_hazard_mem = (Reg1RA != 5'b0) && 
                          (Reg1RA == MEMRegWA) && 
                          MEMRegWE;
    
    wire rs2_hazard_mem = (Reg2RA != 5'b0) && 
                          (Reg2RA == MEMRegWA) && 
                          MEMRegWE;
    
    // ========== 3. Load-Use冒险检测 ==========
    // 条件: EX阶段是加载指令，且ID阶段的指令依赖它的结果
    wire load_use_hazard = EXMemoryRE &&           // EX是加载指令
                           EXRegWriteSrc &&          // 要写寄存器
                           ((Reg1RA == RegWA) || (Reg2RA == RegWA)) &&
                           (RegWA != 5'b0);         // rd不是x0
    
    //综合结果
    wire data_hazard = rs1_hazard_ex || rs2_hazard_ex || 
                       rs1_hazard_mem || rs2_hazard_mem;
            
    //为load_use的两拍单独设立计数
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            stall_cnt <= 0;
        end else if (load_use_hazard && stall_cnt == 0) begin
            // 检测到 Load-Use，需要阻塞 2 拍
            stall_cnt <= 2;
        end else if (stall_cnt > 0) begin
            stall_cnt <= stall_cnt - 1;
        end
    end
    
    // ========== 生成控制信号 ==========
    always @(*) begin
        if (data_hazard || (stall_cnt > 0)) begin
            PCStall  = 1'b1;
            IFStall  = 1'b1;
            IDFlush  = 1'b1;
        end else begin
            PCStall  = 1'b0;
            IFStall  = 1'b0;
            IDFlush  = 1'b0;
        end
    end

endmodule