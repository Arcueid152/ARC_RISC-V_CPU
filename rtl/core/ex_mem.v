`include "defines.vh"

module ex_mem (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,           // 新增停顿信号

    input  wire [4:0]  rd_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] store_data_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  opcode_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        wb_en_in,

    // RAM 组合逻辑接口
    output wire        ram_wr_en,
    output wire [31:0] ram_addr,
    output wire [31:0] ram_wr_data,
    input  wire [31:0] ram_rd_data,

    // 写回寄存器输出（时序）
    output reg         wb_en_out,
    output reg  [4:0]  rd_out,
    output reg  [31:0] wb_data
);

  // 组合逻辑：RAM 端口
  assign ram_wr_en   = mem_write_in;
  assign ram_addr    = alu_result_in;
  assign ram_wr_data = store_data_in;

  // 时序逻辑：写回信息，仅在非 stall 时更新
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      wb_en_out <= 1'b0;
      rd_out    <= 5'h0;
      wb_data   <= 32'h0;
    end else if (!stall) begin
      wb_en_out <= wb_en_in;
      rd_out    <= rd_in;

      if (mem_read_in) begin
        case (funct3_in)
          `INST_LB:  wb_data <= {{24{ram_rd_data[7]}},  ram_rd_data[7:0]};
          `INST_LH:  wb_data <= {{16{ram_rd_data[15]}}, ram_rd_data[15:0]};
          `INST_LW:  wb_data <= ram_rd_data;
          `INST_LBU: wb_data <= {24'h0, ram_rd_data[7:0]};
          `INST_LHU: wb_data <= {16'h0, ram_rd_data[15:0]};
          default:   wb_data <= ram_rd_data;
        endcase
      end else if (!mem_write_in) begin
        wb_data <= alu_result_in;
      end
      // store 指令：wb_en_in = 0，wb_data 无需赋值
    end
  end

endmodule