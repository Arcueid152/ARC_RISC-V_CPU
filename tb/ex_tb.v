`timescale 1ns / 1ps
`include "../rtl/core/defines.v"

module ex_tb;

    // 测试参数
    parameter DELAY = 10;      // 延迟时间 10ns

    // 信号声明
    reg [31:0] instr_in;
    reg [31:0] instr_addr_in;
    reg [31:0] op1;
    reg [31:0] op2;
    wire reg_en;
    wire [4:0] reg_addr;
    wire [31:0] reg_data;

    integer test_pass;          // 测试通过标志
    integer test_num;           // 测试编号
    reg [639:0] test_name_str; // 80字符 * 8位

    // 实例化被测试模块
    ex u_ex (
        .instr_in(instr_in),
        .instr_addr_in(instr_addr_in),
        .op1(op1),
        .op2(op2),
        .reg_en(reg_en),
        .reg_addr(reg_addr),
        .reg_data(reg_data)
    );

    // 检查结果任务
    task check_result;
        input expected_reg_en;
        input [4:0] expected_reg_addr;
        input [31:0] expected_reg_data;
        begin
            test_num = test_num + 1;
            if (reg_en !== expected_reg_en ||
                reg_addr !== expected_reg_addr ||
                reg_data !== expected_reg_data) begin
                $display("[TEST %0d FAIL] %s:", test_num, test_name_str);
                $display("  Expected: reg_en=%b, reg_addr=%h, reg_data=%h",
                         expected_reg_en, expected_reg_addr, expected_reg_data);
                $display("  Actual:   reg_en=%b, reg_addr=%h, reg_data=%h",
                         reg_en, reg_addr, reg_data);
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
        instr_addr_in = 32'h0;

        $display("=== EX Module Test Start ===");
        $display("Time: %t", $time);

        // 初始化操作数
        op1 = 32'h12345678;
        op2 = 32'h87654321;

        // Test 1: ADDI 指令 (I-type)
        $display("\n--- Test 1: ADDI Instruction (I-type) ---");
        // ADDI: rd=2, rs1=1, imm=0x123
        // 指令格式: {imm[11:0], rs1, funct3, rd, opcode}
        instr_in = {12'h123, 5'h1, `INST_ADDI, 5'h2, `INST_TYPE_I};
        test_name_str = "ADDI x2, x1, 0x123";
        op2 = { {20{1'b0}}, 12'h123 }; // 符号扩展立即数 0x00000123
        #DELAY;
        // 期望输出: reg_en=1, reg_addr=2, reg_data=op1 + op2
        check_result(1'b1, 5'h2, 32'h12345678 + op2);

        // Test 2: SLTI 指令 (I-type)
        $display("\n--- Test 2: SLTI Instruction (I-type) ---");
        // SLTI: rd=3, rs1=1, imm=0x800 (负数符号扩展)
        instr_in = {12'h800, 5'h1, `INST_SLTI, 5'h3, `INST_TYPE_I};
        test_name_str = "SLTI x3, x1, 0x800";
        op2 = { {20{1'b1}}, 12'h800 }; // 符号扩展立即数 0xfffff800
        #DELAY;
        // ex模块使用无符号比较: (op1 < op2) ? 1:0
        // op1=0x12345678, op2=0xfffff800, 无符号比较: 0x12345678 < 0xfffff800 = 1
        check_result(1'b1, 5'h3, 32'h1);

        // Test 3: SLTIU 指令 (I-type)
        $display("\n--- Test 3: SLTIU Instruction (I-type) ---");
        // SLTIU: rd=4, rs1=1, imm=0x800
        instr_in = {12'h800, 5'h1, `INST_SLTIU, 5'h4, `INST_TYPE_I};
        test_name_str = "SLTIU x4, x1, 0x800";
        op2 = { {20{1'b1}}, 12'h800 }; // 符号扩展立即数 0xfffff800
        #DELAY;
        // ex模块使用无符号比较: (op1 < op2) ? 1:0 (与SLTI相同)
        check_result(1'b1, 5'h4, 32'h1);

        // Test 4: XORI 指令 (I-type)
        $display("\n--- Test 4: XORI Instruction (I-type) ---");
        // XORI: rd=5, rs1=1, imm=0xfff
        instr_in = {12'hfff, 5'h1, `INST_XORI, 5'h5, `INST_TYPE_I};
        test_name_str = "XORI x5, x1, 0xfff";
        op2 = { {20{1'b1}}, 12'hfff }; // 符号扩展立即数 0xffffffff
        #DELAY;
        check_result(1'b1, 5'h5, 32'h12345678 ^ op2);

        // Test 5: ORI 指令 (I-type)
        $display("\n--- Test 5: ORI Instruction (I-type) ---");
        // ORI: rd=6, rs1=1, imm=0xaaa
        instr_in = {12'haaa, 5'h1, `INST_ORI, 5'h6, `INST_TYPE_I};
        test_name_str = "ORI x6, x1, 0xaaa";
        op2 = { {20{1'b0}}, 12'haaa }; // 符号扩展立即数 0x00000aaa
        #DELAY;
        check_result(1'b1, 5'h6, 32'h12345678 | op2);

        // Test 6: ANDI 指令 (I-type)
        $display("\n--- Test 6: ANDI Instruction (I-type) ---");
        // ANDI: rd=7, rs1=1, imm=0x555
        instr_in = {12'h555, 5'h1, `INST_ANDI, 5'h7, `INST_TYPE_I};
        test_name_str = "ANDI x7, x1, 0x555";
        op2 = { {20{1'b0}}, 12'h555 }; // 符号扩展立即数 0x00000555
        #DELAY;
        check_result(1'b1, 5'h7, 32'h12345678 & op2);

        // Test 7: SLLI 指令 (I-type)
        $display("\n--- Test 7: SLLI Instruction (I-type) ---");
        // SLLI: rd=8, rs1=1, shamt=5 (op2的低5位)
        instr_in = {7'h00, 5'h5, 5'h1, `INST_SLLI, 5'h8, `INST_TYPE_I};
        test_name_str = "SLLI x8, x1, 5";
        op2 = 32'h5;  // shamt=5
        #DELAY;
        check_result(1'b1, 5'h8, 32'h12345678 << 5);

        // Test 8: SRLI 指令 (I-type)
        $display("\n--- Test 8: SRLI Instruction (I-type) ---");
        // SRLI: rd=9, rs1=1, shamt=5, funct7=0
        instr_in = {7'h00, 5'h5, 5'h1, `INST_SRI, 5'h9, `INST_TYPE_I};
        test_name_str = "SRLI x9, x1, 5";
        op2 = 32'h5;
        #DELAY;
        check_result(1'b1, 5'h9, 32'h12345678 >> 5);

        // Test 9: SRAI 指令 (I-type)
        $display("\n--- Test 9: SRAI Instruction (I-type) ---");
        // SRAI: rd=10, rs1=1, shamt=5, funct7=0x20
        instr_in = {7'h20, 5'h5, 5'h1, `INST_SRI, 5'h10, `INST_TYPE_I};
        test_name_str = "SRAI x10, x1, 5";
        op2 = 32'h5;
        #DELAY;
        check_result(1'b1, 5'h10, 32'h12345678 >>> 5);

        // Test 10: ADD 指令 (R-type)
        $display("\n--- Test 10: ADD Instruction (R-type) ---");
        // ADD: rd=11, rs1=1, rs2=6, funct7=0
        instr_in = {7'h00, 5'h6, 5'h1, `INST_ADD_SUB, 5'h11, `INST_TYPE_R_M};
        test_name_str = "ADD x11, x1, x6";
        op1 = 32'h12345678;
        op2 = 32'h87654321;
        #DELAY;
        check_result(1'b1, 5'h11, 32'h12345678 + 32'h87654321);

        // Test 11: SUB 指令 (R-type)
        $display("\n--- Test 11: SUB Instruction (R-type) ---");
        // SUB: rd=12, rs1=1, rs2=6, funct7=0x20
        instr_in = {7'h20, 5'h6, 5'h1, `INST_ADD_SUB, 5'h12, `INST_TYPE_R_M};
        test_name_str = "SUB x12, x1, x6";
        #DELAY;
        check_result(1'b1, 5'h12, 32'h12345678 - 32'h87654321);

        // Test 12: SLL 指令 (R-type)
        $display("\n--- Test 12: SLL Instruction (R-type) ---");
        // SLL: rd=13, rs1=1, rs2=7, funct7=0
        instr_in = {7'h00, 5'h7, 5'h1, `INST_SLL, 5'h13, `INST_TYPE_R_M};
        test_name_str = "SLL x13, x1, x7";
        op2 = 32'h4;  // shift amount
        #DELAY;
        check_result(1'b1, 5'h13, 32'h12345678 << 4);

        // Test 13: SLT 指令 (R-type)
        $display("\n--- Test 13: SLT Instruction (R-type) ---");
        // SLT: rd=14, rs1=1, rs2=8, funct7=0
        instr_in = {7'h00, 5'h8, 5'h1, `INST_SLT, 5'h14, `INST_TYPE_R_M};
        test_name_str = "SLT x14, x1, x8";
        op2 = 32'hffffffff;  // -1 有符号
        #DELAY;
        // op1=0x12345678 (正数) < op2=0xffffffff (负数) ? 0 (正数 > 负数)
        check_result(1'b1, 5'h14, 32'h0);

        // Test 14: SLTU 指令 (R-type)
        $display("\n--- Test 14: SLTU Instruction (R-type) ---");
        // SLTU: rd=15, rs1=1, rs2=9, funct7=0
        instr_in = {7'h00, 5'h9, 5'h1, `INST_SLTU, 5'h15, `INST_TYPE_R_M};
        test_name_str = "SLTU x15, x1, x9";
        op2 = 32'hffffffff;  // 很大的无符号数
        #DELAY;
        // op1=0x12345678 < op2=0xffffffff ? 1
        check_result(1'b1, 5'h15, 32'h1);

        // Test 15: XOR 指令 (R-type)
        $display("\n--- Test 15: XOR Instruction (R-type) ---");
        // XOR: rd=16, rs1=1, rs2=10, funct7=0
        instr_in = {7'h00, 5'h10, 5'h1, `INST_XOR, 5'h16, `INST_TYPE_R_M};
        test_name_str = "XOR x16, x1, x10";
        op2 = 32'hffff0000;
        #DELAY;
        check_result(1'b1, 5'h16, 32'h12345678 ^ 32'hffff0000);

        // Test 16: SRL 指令 (R-type)
        $display("\n--- Test 16: SRL Instruction (R-type) ---");
        // SRL: rd=17, rs1=1, rs2=11, funct7=0
        instr_in = {7'h00, 5'h11, 5'h1, `INST_SR, 5'h17, `INST_TYPE_R_M};
        test_name_str = "SRL x17, x1, x11";
        op2 = 32'h8;
        #DELAY;
        check_result(1'b1, 5'h17, 32'h12345678 >> 8);

        // Test 17: SRA 指令 (R-type)
        $display("\n--- Test 17: SRA Instruction (R-type) ---");
        // SRA: rd=18, rs1=1, rs2=12, funct7=0x20
        instr_in = {7'h20, 5'h12, 5'h1, `INST_SR, 5'h18, `INST_TYPE_R_M};
        test_name_str = "SRA x18, x1, x12";
        op2 = 32'h8;
        #DELAY;
        check_result(1'b1, 5'h18, 32'h12345678 >>> 8);

        // Test 18: OR 指令 (R-type)
        $display("\n--- Test 18: OR Instruction (R-type) ---");
        // OR: rd=19, rs1=1, rs2=13, funct7=0
        instr_in = {7'h00, 5'h13, 5'h1, `INST_OR, 5'h19, `INST_TYPE_R_M};
        test_name_str = "OR x19, x1, x13";
        op2 = 32'h00ff00ff;
        #DELAY;
        check_result(1'b1, 5'h19, 32'h12345678 | 32'h00ff00ff);

        // Test 19: AND 指令 (R-type)
        $display("\n--- Test 19: AND Instruction (R-type) ---");
        // AND: rd=20, rs1=1, rs2=14, funct7=0
        instr_in = {7'h00, 5'h0E, 5'h1, `INST_AND, 5'h14, `INST_TYPE_R_M}; // rs2=14 (0x0E), rd=20 (0x14)
        test_name_str = "AND x20, x1, x14";
        op2 = 32'h00ff00ff;
        #DELAY;
        check_result(1'b1, 5'h14, 32'h12345678 & 32'h00ff00ff);

        // Test 20: M-type指令未实现 (应进入default)
        $display("\n--- Test 20: M-type Instruction (unimplemented) ---");
        // MUL指令: funct3=000, funct7=1 (无效funct7)
        instr_in = {7'h01, 5'h0, 5'h0, `INST_MUL, 5'h0, `INST_TYPE_R_M}; // MUL x0, x0, x0
        test_name_str = "MUL x0, x0, x0 (unimplemented M-type)";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test 21: 未知funct7 (SRI指令)
        $display("\n--- Test 21: Unknown funct7 in SRI ---");
        instr_in = {7'h40, 5'h5, 5'h1, `INST_SRI, 5'h2, `INST_TYPE_I}; // funct7=0x40 无效
        test_name_str = "Unknown funct7 in SRI";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test 22: 未知opcode
        $display("\n--- Test 22: Unknown opcode ---");
        instr_in = {12'h0, 5'h0, 3'b000, 5'h0, 7'b1111111}; // 无效opcode
        test_name_str = "Unknown opcode";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test 23: LUI指令 (未实现，应返回默认值)
        $display("\n--- Test 23: LUI Instruction (unimplemented) ---");
        instr_in = {20'h54321, 5'h10, `INST_LUI};
        test_name_str = "LUI x10, 0x54321";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test 24: AUIPC指令 (未实现)
        $display("\n--- Test 24: AUIPC Instruction (unimplemented) ---");
        instr_in = {20'h67890, 5'h11, `INST_AUIPC};
        test_name_str = "AUIPC x11, 0x67890";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test 25: JAL指令 (未实现)
        $display("\n--- Test 25: JAL Instruction (unimplemented) ---");
        instr_in = {20'h0, 5'h8, `INST_JAL};
        test_name_str = "JAL x8, 0";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test 26: JALR指令 (未实现)
        $display("\n--- Test 26: JALR Instruction (unimplemented) ---");
        instr_in = {12'h321, 5'h2, 3'b000, 5'h9, `INST_JALR};
        test_name_str = "JALR x9, x2, 0x321";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test 27: LW指令 (L-type, 未实现)
        $display("\n--- Test 27: LW Instruction (L-type, unimplemented) ---");
        instr_in = {12'h456, 5'h3, `INST_LW, 5'h4, `INST_TYPE_L};
        test_name_str = "LW x4, 0x456(x3)";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test 28: SW指令 (S-type, 未实现)
        $display("\n--- Test 28: SW Instruction (S-type, unimplemented) ---");
        // SW: rs2=5, rs1=3, imm=0x789
        instr_in = {7'h3c, 5'h5, 5'h3, `INST_SW, 5'h9, `INST_TYPE_S};
        test_name_str = "SW x5, 0x789(x3)";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test 29: BEQ指令 (B-type, 未实现)
        $display("\n--- Test 29: BEQ Instruction (B-type, unimplemented) ---");
        instr_in = {1'b0, 6'h0, 5'h13, 5'h12, `INST_BEQ, 4'h0, 1'b0, `INST_TYPE_B};
        test_name_str = "BEQ x12, x13, 0";
        #DELAY;
        check_result(1'b0, 5'h0, 32'h0);

        // Test summary
        $display("\n=== Test Summary ===");
        if (test_pass) begin
            $display("All %0d tests passed!", test_num);
            $display("EX module functions correctly.");
        end else begin
            $display("Test failed! Please check the design.");
        end

        $display("Test completion time: %t", $time);
        $finish;
    end

    // 信号监控 (可选)
    initial begin
        $monitor("Time: %t ns | instr_in=%h | op1=%h | op2=%h | reg_en=%b | reg_addr=%h | reg_data=%h",
                 $time, instr_in, op1, op2, reg_en, reg_addr, reg_data);
    end

    // 仿真超时保护
    initial begin
        #(DELAY * 100); // 100倍延迟超时
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

endmodule