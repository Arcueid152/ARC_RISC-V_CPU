`timescale 1ns / 1ps
`include "../rtl/core/defines.v"

module decode_tb;

    // 测试参数
    parameter CLK_PERIOD = 10;      // 时钟周期 10ns (100MHz)

    // 信号声明
    reg [31:0] instr_in;
    reg [31:0] rs1_data;
    reg [31:0] rs2_data;
    wire [4:0] rs1_addr;
    wire [4:0] rs2_addr;
    wire [4:0] reg_addr;
    wire [31:0] op1_out;
    wire [31:0] op2_out;

    integer test_pass;          // 测试通过标志
    integer test_num;           // 测试编号
    reg [639:0] test_name_str; // 80字符 * 8位

    // 实例化被测试模块
    decode u_decode (
        .instr_in(instr_in),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .reg_addr(reg_addr),
        .op1_out(op1_out),
        .op2_out(op2_out)
    );

    // 检查结果任务
    task check_result;
        input [4:0] expected_rs1_addr;
        input [4:0] expected_rs2_addr;
        input [4:0] expected_reg_addr;
        input [31:0] expected_op1;
        input [31:0] expected_op2;
        begin
            test_num = test_num + 1;
            if (rs1_addr !== expected_rs1_addr ||
                rs2_addr !== expected_rs2_addr ||
                reg_addr !== expected_reg_addr ||
                op1_out !== expected_op1 ||
                op2_out !== expected_op2) begin
                $display("[TEST %0d FAIL] %s:", test_num, test_name_str);
                $display("  Expected: rs1_addr=%h, rs2_addr=%h, reg_addr=%h, op1_out=%h, op2_out=%h",
                         expected_rs1_addr, expected_rs2_addr, expected_reg_addr, expected_op1, expected_op2);
                $display("  Actual:   rs1_addr=%h, rs2_addr=%h, reg_addr=%h, op1_out=%h, op2_out=%h",
                         rs1_addr, rs2_addr, reg_addr, op1_out, op2_out);
                test_pass = 0;
            end else begin
                $display("[TEST %0d PASS] %s", test_num, test_name_str);
            end
        end
    endtask

    // 主测试过程
    initial begin
        // 初始化测试变量
        test_pass = 1;
        test_num = 0;

        // 初始化寄存器数据
        rs1_data = 32'h12345678;
        rs2_data = 32'h87654321;

        $display("=== Decode Module Test Start ===");
        $display("Time: %t", $time);

        // Test 1: ADDI 指令 (I-type)
        $display("\n--- Test 1: ADDI Instruction (I-type) ---");
        // ADDI: rd=2, rs1=1, imm=0x123
        // 指令格式: {imm[11:0], rs1, funct3, rd, opcode}
        instr_in = {12'h123, 5'h1, `INST_ADDI, 5'h2, `INST_TYPE_I};
        test_name_str = "ADDI x2, x1, 0x123";
        #10; // 等待组合逻辑稳定
        // 期望输出: rs1_addr=1, rs2_addr=0, reg_addr=2, op1_out=rs1_data, op2_out=符号扩展的0x123
        check_result(5'h1, 5'h0, 5'h2, 32'h12345678, { {20{1'b0}}, 12'h123 });

        // Test 2: LW 指令 (L-type)
        $display("\n--- Test 2: LW Instruction (L-type) ---");
        // LW: rd=4, rs1=3, imm=0x456
        instr_in = {12'h456, 5'h3, `INST_LW, 5'h4, `INST_TYPE_L};
        test_name_str = "LW x4, 0x456(x3)";
        #10;
        check_result(5'h3, 5'h0, 5'h4, 32'h12345678, { {20{1'b0}}, 12'h456 });

        // Test 3: SW 指令 (S-type)
        $display("\n--- Test 3: SW Instruction (S-type) ---");
        // SW: rs2=5, rs1=3, imm=0x789
        // S型指令格式: {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode}
        // imm=0x789 = 12'b0111_1000_1001, imm[11:5]=7'h3c, imm[4:0]=5'h9
        instr_in = {7'h3c, 5'h5, 5'h3, `INST_SW, 5'h9, `INST_TYPE_S};
        test_name_str = "SW x5, 0x789(x3)";
        #10;
        check_result(5'h3, 5'h5, 5'h0, 32'h12345678, { {20{1'b0}}, 12'h789 });

        // Test 4: ADD 指令 (R-type)
        $display("\n--- Test 4: ADD Instruction (R-type) ---");
        // ADD: rd=7, rs1=1, rs2=6, funct7=0
        // R型指令格式: {funct7, rs2, rs1, funct3, rd, opcode}
        instr_in = {7'h00, 5'h6, 5'h1, `INST_ADD_SUB, 5'h7, `INST_TYPE_R_M};
        test_name_str = "ADD x7, x1, x6";
        #10;
        check_result(5'h1, 5'h6, 5'h7, 32'h12345678, 32'h87654321);

        // Test 5: JAL 指令
        $display("\n--- Test 5: JAL Instruction ---");
        // JAL: rd=8, imm=0x12345 (20位符号扩展后左移1位)
        // J型指令格式较复杂，这里使用一个示例立即数
        // imm_j = {1'b0, 10'h123, 1'b1, 8'h45}? 简化测试，使用0立即数
        // 使用0立即数测试基本功能
        instr_in = {20'h0, 5'h8, `INST_JAL}; // JAL x8, 0
        test_name_str = "JAL x8, 0";
        #10;
        // 期望: rs1_addr=0, rs2_addr=0, reg_addr=8, op1_out=0, op2_out=符号扩展的立即数(0)
        check_result(5'h0, 5'h0, 5'h8, 32'h0, 32'h0);

        // Test 6: JALR 指令
        $display("\n--- Test 6: JALR Instruction ---");
        // JALR: rd=9, rs1=2, imm=0x321
        // 指令格式: {imm[11:0], rs1, funct3(3'b000), rd, opcode}
        instr_in = {12'h321, 5'h2, 3'b000, 5'h9, `INST_JALR};
        test_name_str = "JALR x9, x2, 0x321";
        #10;
        check_result(5'h2, 5'h0, 5'h9, 32'h12345678, { {20{1'b0}}, 12'h321 });

        // Test 7: LUI 指令
        $display("\n--- Test 7: LUI Instruction ---");
        // LUI: rd=10, imm=0x54321 (高20位)
        // 指令格式: {imm[31:12], rd, opcode}
        instr_in = {20'h54321, 5'h10, `INST_LUI};
        test_name_str = "LUI x10, 0x54321";
        #10;
        check_result(5'h0, 5'h0, 5'h10, 32'h0, {20'h54321, 12'h0});

        // Test 8: AUIPC 指令
        $display("\n--- Test 8: AUIPC Instruction ---");
        // AUIPC: rd=11, imm=0x67890
        instr_in = {20'h67890, 5'h11, `INST_AUIPC};
        test_name_str = "AUIPC x11, 0x67890";
        #10;
        check_result(5'h0, 5'h0, 5'h11, 32'h0, {20'h67890, 12'h0});

        // Test 9: BEQ 指令 (B-type)
        $display("\n--- Test 9: BEQ Instruction (B-type) ---");
        // BEQ: rs1=12, rs2=13, imm=0x1f4 (简化，实际B型立即数格式复杂)
        // B型指令格式: {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode}
        // 为简化测试，使用0立即数
        instr_in = {1'b0, 6'h0, 5'h13, 5'h12, `INST_BEQ, 4'h0, 1'b0, `INST_TYPE_B};
        test_name_str = "BEQ x12, x13, 0";
        #10;
        check_result(5'h12, 5'h13, 5'h0, 32'h12345678, 32'h87654321);

        // Test 10: FENCE 指令
        $display("\n--- Test 10: FENCE Instruction ---");
        // FENCE指令
        instr_in = { `INST_FENCE, 5'h0, 12'h0, 5'h0, 7'h0 }; // 简化表示
        test_name_str = "FENCE";
        #10;
        check_result(5'h0, 5'h0, 5'h0, 32'h0, 32'h0);

        // Test 11: CSRRW 指令 (CSR)
        $display("\n--- Test 11: CSRRW Instruction (CSR) ---");
        // CSRRW: rd=14, rs1=15, csr=0x300 (mstatus)
        // 指令格式: {csr[11:0], rs1, funct3, rd, opcode}
        instr_in = {12'h300, 5'h15, `INST_CSRRW, 5'h14, `INST_CSR};
        test_name_str = "CSRRW x14, mstatus, x15";
        #10;
        check_result(5'h15, 5'h0, 5'h14, 32'h12345678, { {20{1'b0}}, 12'h300 });

        // Test 12: 未知指令
        $display("\n--- Test 12: Unknown Instruction ---");
        instr_in = 32'hffffffff;
        test_name_str = "Unknown instruction (0xdeadbeef)";
        #10;
        // 期望输出全0 (default case)
        check_result(5'h0, 5'h0, 5'h0, 32'h0, 32'h0);

        // Test summary
        $display("\n=== Test Summary ===");
        if (test_pass) begin
            $display("All %0d tests passed!", test_num);
            $display("Decode module functions correctly.");
        end else begin
            $display("Test failed! Please check the design.");
        end

        $display("Test completion time: %t", $time);
        $finish;
    end

    // 信号监控 (可选)
    initial begin
        $monitor("Time: %t ns | instr_in=%h | rs1_addr=%h | rs2_addr=%h | reg_addr=%h | op1_out=%h | op2_out=%h",
                 $time, instr_in, rs1_addr, rs2_addr, reg_addr, op1_out, op2_out);
    end

    // 仿真超时保护
    initial begin
        #(CLK_PERIOD * 100); // 100个时钟周期超时
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

endmodule