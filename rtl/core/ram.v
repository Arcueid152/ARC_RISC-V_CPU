`include "defines.v"

module ram (
    input                  clk,
    input                  rst_n,
    input  wire            wr_en,
    input  wire [31:0]     wr_addr,
    input  wire [31:0]     wr_data,
    input  wire [31:0]     rd_addr,
    output reg  [31:0]      rd_data
);

reg [31:0] ram_mem[0:8191];

// 写操作
integer i;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<8192; i=i+1)
            ram_mem[i] <= 'h0;
    end
    else if(wr_en)
        ram_mem[wr_addr[31:2]] <= wr_data;
end

// 读操作
always @(*) begin
        rd_data = ram_mem[rd_addr[31:2]];
end
endmodule