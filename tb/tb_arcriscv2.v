`include "../rtl/core/defines.v"

module tb_riscv_top;


reg         clk;
reg         rst;
reg  [31:0] tmp;
wire [31:0] x3;
wire [31:0] x26;
wire [31:0] x27;

wire [31:0] x29;
wire [31:0] x30;


assign x3  = tb_riscv_top.u_riscv_inst.regs_inst.regs[3];
assign x26 = tb_riscv_top.u_riscv_inst.regs_inst.regs[26];
assign x27 = tb_riscv_top.u_riscv_inst.regs_inst.regs[27];

assign x29 = tb_riscv_top.u_riscv_inst.regs_inst.regs[29];
assign x30 = tb_riscv_top.u_riscv_inst.regs_inst.regs[30];

// =============================================
// 实例化被测处理器

arcriscv u_riscv_inst (
    .clk  (clk  ),
    .rst (rst)   
);

// =============================================
// 时钟生成
// =============================================
always #5 clk = ~clk;

// =============================================
// 初始化：时钟、复位
// =============================================
initial begin
    clk   = 1'b0;
    rst = 1'b1;
    tmp   = 32'h0;
    #1000;
    rst = 1'b0;
end

// =============================================
integer i;  

initial begin
    forever begin
        tmp = x3;
        @(posedge clk);

        if (tmp != x3) begin
            $display("test[%0d]", x3);
        end
        else if (x26 == 32'h1) begin
            repeat(10) @(posedge clk);

            if (x27 == 32'h1) begin
                $display("\n");
                repeat(3) $display("*************************************");
                $display("\n");
                $display("%s  test passed !!!!! ", `FILE);
                $display("\n");
                repeat(3) $display("*************************************");
                $display("\n");

                for (i = 0; i < 32; i = i + 1) begin
                    $display("%0d register value is %0d",
                        i,
                        tb_riscv_top.u_riscv_inst.regs_inst.regs[i]);
                end
                $finish;
            end
            else begin
                repeat(3) $display("*************************************");
                $display("\n");
                $display("%s  test failed !!!!! ", `FILE);
                repeat(3) $display("*************************************");
                $display("The failed test case is test[%0d]", x3);

                for (i = 0; i < 32; i = i + 1) begin
                    $display("%0d register value is %0d",
                        i,
                        tb_riscv_top.u_riscv_inst.regs_inst.regs[i]);
                end
            end
        end
    end
end

endmodule