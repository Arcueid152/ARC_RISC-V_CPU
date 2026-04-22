module tb_myCPU;
  reg cpu_clk;
  reg cpu_rst;


  wire [31:0] perip_addr;
  wire        perip_wen;
  wire [1:0]  perip_mask;
  wire [31:0] perip_wdata;
  wire [31:0] irom_addr;
  wire [31:0] irom_data;
  wire [31:0] perip_rdata;
  
  myCPU  myCPU_inst (
    .cpu_rst(cpu_rst),
    .cpu_clk(cpu_clk),
    .irom_addr(irom_addr),
    .irom_data(irom_data),
    .perip_addr(perip_addr),
    .perip_wen(perip_wen),
    .perip_mask(perip_mask),
    .perip_wdata(perip_wdata),
    .perip_rdata(perip_rdata)
  );

  ROM  ROM_inst (
    .instr_addr(irom_addr),
    .instr_out(irom_data)
  );

  RAM  RAM_inst (
    .clk(cpu_clk),
    .perip_addr(perip_addr[17:0]),
    .perip_wdata(perip_wdata),
    .perip_mask(perip_mask),
    .dram_wen(dram_wen),
    .perip_rdata(perip_rdata)
  );

  always #5 cpu_clk = ~cpu_clk;

  initial begin
    cpu_clk         = 1'b0;
    cpu_rst        = 1'b1;
    // 复位阶段
    #100;
    cpu_rst        = 1'b0;
end
endmodule


