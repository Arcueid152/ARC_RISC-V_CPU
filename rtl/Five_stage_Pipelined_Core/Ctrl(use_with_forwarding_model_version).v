module Ctrl (

    // 来自 ID 
    input [4:0] Reg1RA,            // 源寄存器1地址
    input [4:0] Reg2RA,            // 源寄存器2地址
    
    // 来自 EX
    input [4:0] RegWA,             // EX阶段指令的目的寄存器
    input       EXRegEn,     // EX阶段指令是否写寄存器
    input       EXMemoryRE,        // EX阶段指令是否是L型指令
    
    
    // 输出控制信号
    output reg  PCStall,           // 阻塞PC
    output reg  IFStall,           // 阻塞IF2ID
    output reg  IDFlush            // 清空ID2EX
);


    // ========== Load-Use冒险检测 ==========

    wire load_use_hazard = EXMemoryRE &&           // EX是加载指令
                           EXRegEn &&          // 要写寄存器
                           ((Reg1RA == RegWA) || (Reg2RA == RegWA)) &&
                           (RegWA != 5'b0);         // rd不是x0
    
    
    // ========== 生成控制信号 ==========
    always @(*) begin
        if (load_use_hazard) begin
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