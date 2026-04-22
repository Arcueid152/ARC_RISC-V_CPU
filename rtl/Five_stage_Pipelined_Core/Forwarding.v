module ForwardingUnit (

    input [4:0] rs1_addr,         //ID2EX传入rs1地址
    input [4:0] rs2_addr,         //ID2EX传入rs2地址
    input  wire     [4:0]   rs1_data,    
    input  wire     [4:0]   rs2_data,    
    
    // 来自EX 
    input [4:0] EX_RegWA,         // WB阶段指令的目的寄存器
    input       EX_RegWE ,         // WB阶段指令是否 写寄存器   
    input       EX_RegDA ,         // WB阶段指令是否 写寄存器   

    // 来自MEM 
    input [4:0] MEM_RegWA,        // MEM阶段指令的目的寄存器
    input       MEM_RegWE,        // MEM阶段指令是否写寄存器
    input       MEM_RegDA,        // MEM阶段指令是否写寄存器

    
    output reg  [4:0] rs1_addr_out,         //ID2EX传入rs1地址
    output reg  [4:0] rs2_addr_out,         //ID2EX传入rs2地址
    output  reg     [31:0]  rs1_data_out,   // 源寄存器1的数据
    output  reg     [31:0]  rs2_data_out  // 源寄存器2的数据
);

    // always @(*) begin
    //     // default
    //     forward_sel1 = 2'b00;
    //     forward_sel2 = 2'b00;
        
    //     // ========== MEM → EX ==========
    //     // 如果 MEM 阶段指令要写寄存器，且目的地址等于 EX 的 rs1，且不是 x0
    //     if (MEM_RegWE && (MEM_RegWA != 5'b0) && (MEM_RegWA == EXReg1RA)) begin
    //         forward_sel1 = 2'b10;   // 从 MEM 结果转发
    //     end
        
    //     if (MEM_RegWE && (MEM_RegWA != 5'b0) && (MEM_RegWA == EXReg2RA)) begin
    //         forward_sel2 = 2'b10;   // 从 MEM 结果转发
    //     end
        
    //     // ========== WB → EX  ==========
    //     // 仅在 MEM 没有转发时才生效
    //     if (!forward_sel1 && WB_RegWE && (WB_RegWA != 5'b0) && (WB_RegWA == EXReg1RA)) begin
    //         forward_sel1 = 2'b01;   // 从 WB 结果转发
    //     end
        
    //     if (!forward_sel2 && WB_RegWE && (WB_RegWA != 5'b0) && (WB_RegWA == EXReg2RA)) begin
    //         forward_sel2 = 2'b01;   // 从 WB 结果转发
    //     end
    // end

endmodule