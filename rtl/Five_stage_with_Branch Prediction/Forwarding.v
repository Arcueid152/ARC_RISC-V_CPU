module Forwarding (

    input  wire     [4:0]    rs1_addr,         //ID传入rs1地址
    input  wire     [4:0]    rs2_addr,         //ID传入rs2地址
    input  wire     [31:0]   rs1_data,         //REG传入rs1 data 
    input  wire     [31:0]   rs2_data,         //REG传入rs2 data  
    
    // 来自EX 
    input  wire     [4:0]    EX_RegWA,         // EX阶段指令的目的寄存器
    input  wire              EX_RegWE ,        // EX阶段指令是否写寄存器   
    input  wire     [31:0]   EX_RegDA ,        // EX阶段data   

    // 来自MEM 
    input  wire     [4:0]    MEM_RegWA,        // MEM阶段指令的目的寄存器
    input  wire              MEM_RegWE,        // MEM阶段指令是否写寄存器
    input  wire     [31:0]   MEM_RegDA,        // MEM阶段data

    
    output  wire    [4:0]    rs1_addr_out,     // forward用于取reg data的地址
    output  wire    [4:0]    rs2_addr_out,     // forward用于取reg data的地址
    output  reg     [31:0]   rs1_data_out,     // 输出给ID rs1的正确data
    output  reg     [31:0]   rs2_data_out      // 输出给ID rs2的正确data
);

    assign rs1_addr_out = rs1_addr;
    assign rs2_addr_out = rs2_addr;

    always @(*)
    begin
        if ((rs1_addr == EX_RegWA) && (EX_RegWE) && (EX_RegWA != 5'b00000)) 
            begin
                rs1_data_out = EX_RegDA;
            end
        else if ((rs1_addr == MEM_RegWA) && MEM_RegWE) 
            begin
                rs1_data_out = MEM_RegDA;
            end
        else
            begin
                rs1_data_out = rs1_data;
            end
    end

    always @(*)
    begin
        if ((rs2_addr == EX_RegWA) && (EX_RegWE) && (EX_RegWA != 5'b00000)) 
            begin
                rs2_data_out = EX_RegDA;
            end
        else if ((rs2_addr == MEM_RegWA) && MEM_RegWE) 
            begin
                rs2_data_out = MEM_RegDA;
            end
        else
            begin
                rs2_data_out = rs2_data;
            end
    end
endmodule