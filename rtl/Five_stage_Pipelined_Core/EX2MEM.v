module EX2MEM (
    input  wire clk,
    input  wire rst,
    //MEM
    input   wire [31:0]  perip_addr_in,    // 读写地址
    input   wire         perip_wen_in,     // 写使能（高有效）
    input   wire [1:0]   perip_mask_in,    // 传输宽度：00=byte 01=half 10=word
    input   wire [31:0]  perip_wdata_in,   // 写数据
    //RegFile
    input wire [31:0] reg_data_in,       // 写寄存器数据
    input wire        reg_en_in,         // 是否要写通用寄存器
    input wire [31:0] reg_addr_in,   // 写通用寄存器地址

    //ID2EX阶段的funct3
    input  wire [2:0]  funct3_in,
    input   wire       EXMemoryRE,

    //OUT
    output   reg [31:0]  perip_addr,    // 读写地址
    output   reg         perip_wen,     // 写使能（高有效）
    output   reg [1:0]   perip_mask,    // 传输宽度：00=byte 01=half 10=word
    output   reg [31:0]  perip_wdata,   // 写数据

    output reg[31:0] reg_data,       // 写寄存器数据
    output reg       reg_en,         // 是否要写通用寄存器
    output reg[31:0] reg_addr,   // 写通用寄存器地址
    
    output  reg [2:0]  funct3,
    output  reg        EXMemoryRE_out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        perip_addr   <= 32'h0000_0000;      
        perip_wen    <= 1'b0;
        perip_mask   <= 2'b00;
        perip_wdata  <= 32'h0000_0000;

        reg_data    <= 32'h0000_0000;  
        reg_en      <= 1'b0;
        reg_addr    <= 32'h0000_0000;
        funct3      <= 3'b0;
    end
    else begin
        perip_addr   <= perip_addr_in;      
        perip_wen    <= perip_wen_in;
        perip_mask   <= perip_mask_in;
        perip_wdata  <= perip_wdata_in;

        reg_data    <= reg_data_in;  
        reg_en      <= reg_en_in;
        reg_addr    <= reg_addr_in;
        funct3      <= funct3_in;
    end
end

endmodule 