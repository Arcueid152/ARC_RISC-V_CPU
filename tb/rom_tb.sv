`include "../rtl/core/defines.v"
module rom_tb;

  // Parameters
  //Ports
  reg [31:0] instr_addr;
  wire [31:0] instr_out;

  rom # (
    .FILE(`FILE),
    .AW(31),
    .DW(31)
  )
  rom_inst (
    .instr_addr(instr_addr),
    .instr_out(instr_out)
  );

//always #5  clk = ! clk ;

endmodule