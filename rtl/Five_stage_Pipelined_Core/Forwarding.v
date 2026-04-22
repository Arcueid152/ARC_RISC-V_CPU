module ForwardingUnit (
    // 来自EX 
    input [4:0] EXReg1RA,         //ID2EX传入rs1地址
    input [4:0] EXReg2RA,         //ID2EX传入rs2地址
    
    // 来自MEM 
    input [4:0] MEM_RegWA,        // MEM阶段指令的目的寄存器
    input       MEM_RegWE,        // MEM阶段指令是否写寄存器
    
    // 来自WB 
    input [4:0] WB_RegWA,         // WB阶段指令的目的寄存器
    input       WB_RegWE,         // WB阶段指令是否写寄存器
    
    // 转发选择输出
    // 00: 不转发，使用寄存器堆的值
    // 01: 从 WB 阶段转发（MEM2WB_result）
    // 10: 从 MEM 阶段转发（EX2MEM_result）
    output reg [1:0] forward_sel1,   // 操作数1的转发选择
    output reg [1:0] forward_sel2    // 操作数2的转发选择
);

    always @(*) begin
        // default
        forward_sel1 = 2'b00;
        forward_sel2 = 2'b00;
        
        // ========== MEM → EX ==========
        // 如果 MEM 阶段指令要写寄存器，且目的地址等于 EX 的 rs1，且不是 x0
        if (MEM_RegWE && (MEM_RegWA != 5'b0) && (MEM_RegWA == EXReg1RA)) begin
            forward_sel1 = 2'b10;   // 从 MEM 结果转发
        end
        
        if (MEM_RegWE && (MEM_RegWA != 5'b0) && (MEM_RegWA == EXReg2RA)) begin
            forward_sel2 = 2'b10;   // 从 MEM 结果转发
        end
        
        // ========== WB → EX  ==========
        // 仅在 MEM 没有转发时才生效
        if (!forward_sel1 && WB_RegWE && (WB_RegWA != 5'b0) && (WB_RegWA == EXReg1RA)) begin
            forward_sel1 = 2'b01;   // 从 WB 结果转发
        end
        
        if (!forward_sel2 && WB_RegWE && (WB_RegWA != 5'b0) && (WB_RegWA == EXReg2RA)) begin
            forward_sel2 = 2'b01;   // 从 WB 结果转发
        end
    end

endmodule