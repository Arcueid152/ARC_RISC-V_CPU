`include "defines.vh"

module ex_mem (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,        // load-use 停顿：冻结组合逻辑输出（新增）

    // 来自 EX 阶段
    input  wire [4:0]  rd_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] store_data_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  opcode_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        wb_en_in,

    // RAM 接口
    // *** 关键修复：ram_wr_en / ram_addr / ram_wr_data 改为组合逻辑输出 ***
    // *** 这样 RAM 在 EX 阶段就能看到地址，MEM 阶段时钟沿才锁 wb_data  ***
    output reg         ram_wr_en,
    output reg  [31:0] ram_addr,
    output reg  [31:0] ram_wr_data,
    input  wire [31:0] ram_rd_data,

    // 输出到 MEM/WB 流水线寄存器
    output reg         wb_en_out,
    output reg  [4:0]  rd_out,
    output reg  [31:0] wb_data
);


 // -------------------------------------------------------
  // 寄存器：保存上一拍的组合逻辑输出，stall 时用于冻结
  // -------------------------------------------------------
  reg        ram_wr_en_r;
  reg [31:0] ram_addr_r;
  reg [31:0] ram_wr_data_r;
 
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ram_wr_en_r   <= 1'b0;
      ram_addr_r    <= 32'h0;
      ram_wr_data_r <= 32'h0;
    end else begin
      ram_wr_en_r   <= mem_write_in;
      ram_addr_r    <= alu_result_in;
      ram_wr_data_r <= store_data_in;
    end
  end

  // 组合逻辑：提前驱动 RAM 端口（让 RAM 在本周期就能读出数据）
  // stall 期间 EX 输出的是 NOP 气泡（地址=0，wr_en=0），
  // 直接透传会导致 perip_addr 错误，因此 stall 时保持上一拍的值。
  // -------------------------------------------------------
  always @(*) begin
    if (stall) begin
      ram_wr_en   = ram_wr_en_r;
      ram_addr    = ram_addr_r;
      ram_wr_data = ram_wr_data_r;
    end else begin
      ram_wr_en   = mem_write_in;
      ram_addr    = alu_result_in;
      ram_wr_data = store_data_in;
    end
  end

  // -------------------------------------------------------
  // 时序逻辑：在时钟沿锁存写回数据（此时 RAM 读数据已稳定）
  // -------------------------------------------------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      wb_en_out <= 1'b0;
      rd_out    <= 5'h0;
      wb_data   <= 32'h0;
    end else begin
      wb_en_out <= wb_en_in;
      rd_out    <= rd_in;

      if (mem_read_in) begin
        // RAM 读端口是组合逻辑，时钟沿时 ram_rd_data 已经是正确数据
        case (funct3_in)
          `INST_LB:  wb_data <= {{24{ram_rd_data[7]}},  ram_rd_data[7:0]};
          `INST_LH:  wb_data <= {{16{ram_rd_data[15]}}, ram_rd_data[15:0]};
          `INST_LW:  wb_data <= ram_rd_data;
          `INST_LBU: wb_data <= {24'h0, ram_rd_data[7:0]};
          `INST_LHU: wb_data <= {16'h0, ram_rd_data[15:0]};
          default:   wb_data <= ram_rd_data;
        endcase
      end else if (!mem_write_in) begin
        // 非访存指令：直接传 ALU 结果
        wb_data <= alu_result_in;
      end
      // Store 指令：wb_en_in 已经是 0，wb_data 无意义，不用处理
    end
  end

endmodule