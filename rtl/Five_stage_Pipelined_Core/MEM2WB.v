module MEM2WB (
    input  wire clk,
    input  wire rst,
    
    input wire [31:0] reg_data_in,       // 写寄存器数据
    input wire        reg_en_in,         // 是否要写通用寄存器
    input wire [31:0] reg_addr_in,   // 写通用寄存器地址

    output reg[31:0] reg_data,       // 写寄存器数据
    output reg       reg_en,         // 是否要写通用寄存器
    output reg[31:0] reg_addr   // 写通用寄存器地址
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        reg_data    <= 32'h0000_0000;  
        reg_en      <= 1'b0;
        reg_addr    <= 32'h0000_0000;
    end
    else begin
        reg_data    <= reg_data_in;  
        reg_en      <= reg_en_in;
        reg_addr    <= reg_addr_in;
    end
end

endmodule //MEM2WB