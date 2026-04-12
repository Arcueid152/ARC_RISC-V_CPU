`include "defines.v"

module ram (
    input                  clk,
    input                  rst,
    input  wire            wr_en,
    input  wire [31:0]     wr_addr,
    input  wire [31:0]     wr_data,
    input  wire [31:0]     rd_addr,
    output reg  [31:0]      rd_data
);

reg [31:0] ram_mem[0:8191];

// 写操作
integer i;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i=0; i<8192; i=i+1)
            ram_mem[i] <= 'h0;
    end
    else if(wr_en)
        ram_mem[wr_addr[31:2]] <= wr_data;
end

// 读操作
always @(*) begin
    if (wr_en && (wr_addr[31:2] == rd_addr[31:2])) begin
        rd_data = wr_data;
    end else begin
        rd_data = ram_mem[rd_addr[31:2]];
    end
end
endmodule