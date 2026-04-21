`include "defines.vh"
module MemCtrl (
    input  wire [2:0]  funct3,
    input   wire [31:0]  perip_rdata,   // 写数据

    output  reg [31:0] reg_data

);

always @( *) begin
    case (funct3)
        `INST_LB:  reg_data = {{24{perip_rdata[7]}},  perip_rdata[7:0]};
        `INST_LH:  reg_data = {{16{perip_rdata[15]}}, perip_rdata[15:0]};
        `INST_LW:  reg_data = perip_rdata;
        `INST_LBU: reg_data = {24'h0, perip_rdata[7:0]};
        `INST_LHU: reg_data = {16'h0, perip_rdata[15:0]};
        default:   reg_data = perip_rdata;
    endcase
end
endmodule //MemCtrl