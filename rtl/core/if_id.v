module if_id (
    input   wire        clk,
    input   wire        rstn,
    input   wire [31:0] instr_addr_in,
    input   wire [31:0] instr_in,
    output  reg  [31:0] instr_addr_out,
    output  reg  [31:0] instr_out
  );
  always @(posedge clk or negedge rstn)
    if(~rstn)
      instr_addr_out <= 32'h0;
    else
      instr_addr_out <= instr_addr_in;

  always @(posedge clk or negedge rstn)

    if(~rstn)
      instr_out <= 32'h0;
    else
      instr_out <= instr_in;

endmodule //if_id
