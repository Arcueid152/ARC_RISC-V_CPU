module RAM (
    input wire        clk,
    input wire [17:0] perip_addr,
    input wire [31:0] perip_wdata,
    input wire [1:0]  perip_mask,
    input wire        dram_wen,
    output reg [31:0] perip_rdata
);

// 存储阵列：65536 个 32 位字（地址由 perip_addr[17:2] 索引）
reg [31:0] mem [0:65535];

// ------------------------------------------------------------------
// 读操作：组合逻辑，根据 mask 和地址低 2 位提取并零扩展
// ------------------------------------------------------------------
wire [15:0] rd_addr = perip_addr[17:2];
wire [1:0]  offset  = perip_addr[1:0];
wire [31:0] rd_raw  = mem[rd_addr];

always @(*) begin
    case (perip_mask)
        2'b00:  // lb / lbu
            case (offset)
                2'b00:   perip_rdata = {24'b0, rd_raw[7:0]};
                2'b01:   perip_rdata = {24'b0, rd_raw[15:8]};
                2'b10:   perip_rdata = {24'b0, rd_raw[23:16]};
                2'b11:   perip_rdata = {24'b0, rd_raw[31:24]};
            endcase
        2'b01:  // lh / lhu
            case (offset[1])
                1'b0:    perip_rdata = {16'b0, rd_raw[15:0]};
                1'b1:    perip_rdata = {16'b0, rd_raw[31:16]};
            endcase
        2'b10:  // lw
            perip_rdata = rd_raw;
        default:
            perip_rdata = 32'b0;
    endcase
end

// ------------------------------------------------------------------
// 写操作：同步时序，读‑修改‑写（支持字节/半字/字）
// ------------------------------------------------------------------
wire [15:0] wr_addr = perip_addr[17:2];
reg [31:0] current;
reg [31:0] merged;
always @(posedge clk) begin
    if (dram_wen) begin

        current = mem[wr_addr];   // 读取当前存储值（写前值）

        case (perip_mask)
            2'b10:  // sw
                merged = perip_wdata;
            2'b01:  // sh
                case (perip_addr[1])
                    1'b0: merged = {current[31:16], perip_wdata[15:0]};
                    1'b1: merged = {perip_wdata[15:0], current[15:0]};
                endcase
            2'b00:  // sb
                case (perip_addr[1:0])
                    2'b00: merged = {current[31:8],  perip_wdata[7:0]};
                    2'b01: merged = {current[31:16], perip_wdata[7:0], current[7:0]};
                    2'b10: merged = {current[31:24], perip_wdata[7:0], current[15:0]};
                    2'b11: merged = {perip_wdata[7:0], current[23:0]};
                endcase
            default:
                merged = perip_wdata;
        endcase

        mem[wr_addr] <= merged;
    end
end

endmodule