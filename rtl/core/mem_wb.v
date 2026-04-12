// ========== 完全新增的模块 ==========
module mem_wb (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,        // 流水线停顿信号

    input  wire        wb_en_in,
    input  wire [4:0]  rd_in,
    input  wire [31:0] wb_data_in,

    output reg         wb_en_out,
    output reg  [4:0]  rd_out,
    output reg  [31:0] wb_data_out
);

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      wb_en_out  <= 1'b0;
      rd_out     <= 5'h0;
      wb_data_out<= 32'h0;
    end else if (!stall) begin
      wb_en_out  <= wb_en_in;
      rd_out     <= rd_in;
      wb_data_out<= wb_data_in;
    end
    // 当 stall 有效时，流水线寄存器保持原值（停顿）
  end
endmodule