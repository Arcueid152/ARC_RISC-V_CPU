module regs (
    input  wire clk,
    input  wire rstn,
  //寄存器使能
    input  wire reg_en,
    input  wire [4:0] reg_addr,
    input  wire [31:0] reg_data,
  //输入地址
    input  wire [4:0] rs1_addr,
    input  wire [4:0] rs2_addr,
  //输出数据
    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data


  );
  //32个通用寄存器，小端序
  reg [31:0] regs [0:31];

  always @( *)
  begin
    if(!rstn)
      rs1_data = 32'h0;
    else if (rs1_addr == 5'h0)
      rs1_data = 32'h0;
    else if ((rs1_addr == reg_addr) && reg_en)
      rs1_data = regs[reg_data];
    else
      rs1_data = regs[rs1_addr];
  end

    always @( *)
  begin
    if(!rstn)
      rs2_data = 32'h0;
    else if (rs2_addr == 5'h0)
      rs2_data = 32'h0;
    else if ((rs2_addr == reg_addr) && reg_en)
      rs2_data = regs[reg_data];
    else
      rs2_data = regs[rs2_addr];
  end

  integer i;//计数器

  always @(posedge clk or negedge rstn) 
  begin
    if (!rstn) begin
      for (i = 0; i < 32; i = i + 1) begin
        regs[i] <= 32'h0;
      end
    end
    else if (reg_en && (reg_addr != 5'h0)) begin
      regs[reg_addr] <= reg_data;
    end
  end

endmodule //reg
