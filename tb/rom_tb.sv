`timescale 1ns / 1ps

module rom_tb;

    // 测试参数
    parameter CLK_PERIOD = 10;      // 时钟周期 10ns (100MHz)
    parameter TEST_CYCLES = 20;     // 测试周期数

    // 信号声明
    reg [31:0] instr_addr;          // 字节地址输入
    wire [31:0] instr_out;          // 指令输出

    integer test_pass;              // 测试通过标志
    integer test_num;               // 测试编号

    // 参考ROM存储，用于验证
    reg [31:0] ref_mem [0:4095];

    // 字符串寄存器用于测试名称
    string  test_name_str; // 80字符 * 8位

    // 实例化被测试模块 (使用测试ROM文件)
    rom #(
        .FILE("../tests/test_rom.txt")
    ) u_rom (
        .instr_addr(instr_addr),
        .instr_out(instr_out)
    );

    // 初始化：加载参考内存
    initial begin
        $readmemh("../tests/test_rom.txt", ref_mem);
    end

    // 检查结果任务
    task check_result;
        input [31:0] expected;
        begin
            test_num = test_num + 1;
            if (instr_out !== expected) begin
                $display("[TEST %0d FAIL] %s: expected = %h, actual = %h",
                         test_num, test_name_str, expected, instr_out);
                test_pass = 0;
            end else begin
                $display("[TEST %0d PASS] %s: instr_out = %h",
                         test_num, test_name_str, instr_out);
            end
        end
    endtask

    // 测试读取任务
    task test_read;
        input [31:0] byte_addr;
        input integer word_index;
        begin
            instr_addr = byte_addr;
            #1; // 等待组合逻辑稳定
            test_name_str = $sformatf("Read byte_addr=%h (word_index=%0d)", byte_addr, word_index);
            check_result(ref_mem[word_index]);
        end
    endtask

    // 主测试过程
    initial begin
        // 初始化测试变量
        test_pass = 1;
        test_num = 0;
        instr_addr = 32'h0;

        $display("=== ROM Module Test Start ===");
        $display("Time: %t", $time);
        $display("ROM file: test_rom.txt");
        $display("ROM depth: 16 words (32-bit each)");
        $display("Total size: 64 bytes");

        // Test 1: Sequential reads from beginning
        $display("\n--- Test 1: Sequential Reads (4-byte aligned) ---");
        test_read(32'h0, 0);
        test_read(32'h4, 1);
        test_read(32'h8, 2);
        test_read(32'hc, 3);
        test_read(32'h10, 4);

        // Test 2: Random address reads within file range
        $display("\n--- Test 2: Random Address Reads (within 16 words) ---");
        test_read(32'h14, 5);   // 0x14 = 20 bytes, 20/4 = 5 words
        test_read(32'h18, 6);   // 0x18 = 24 bytes, 24/4 = 6 words
        test_read(32'h1c, 7);   // 0x1c = 28 bytes, 28/4 = 7 words
        test_read(32'h20, 8);   // 0x20 = 32 bytes, 32/4 = 8 words

        // Test 3: Non-4-byte aligned addresses (should still work due to address shifting)
        $display("\n--- Test 3: Non-4-byte Aligned Addresses (Testing address shift) ---");
        // ROM模块执行 instr_addr[31:2] 索引，所以低2位被忽略
        // 地址 0x1, 0x2, 0x3 应该都返回 word 0
        instr_addr = 32'h1;
        #1;
        test_name_str = "Byte address 0x1 (should read word 0)";
        check_result(ref_mem[0]);

        instr_addr = 32'h2;
        #1;
        test_name_str = "Byte address 0x2 (should read word 0)";
        check_result(ref_mem[0]);

        instr_addr = 32'h3;
        #1;
        test_name_str = "Byte address 0x3 (should read word 0)";
        check_result(ref_mem[0]);

        // 地址 0x5 应该返回 word 1 (因为 0x5[31:2] = 1)
        instr_addr = 32'h5;
        #1;
        test_name_str = "Byte address 0x5 (should read word 1)";
        check_result(ref_mem[1]);

        // Test 4: Boundary addresses
        $display("\n--- Test 4: Boundary Addresses ---");
        // 最后一个有效字地址: 15 * 4 = 60 (0x3c)
        test_read(32'h3c, 15);
        // 超出范围地址 (可能返回 x)
        instr_addr = 32'h40; // 16 * 4 = 64, 超出范围
        #1;
        test_name_str = "Address beyond ROM range (0x40)";
        if (instr_out === 32'hx || instr_out === 32'hz) begin
            $display("[TEST %0d INFO] %s: Output is %h (expected for out-of-range)",
                     test_num + 1, test_name_str, instr_out);
            test_num = test_num + 1;
        end else begin
            $display("[TEST %0d INFO] %s: Output = %h",
                     test_num + 1, test_name_str, instr_out);
            test_num = test_num + 1;
        end

        // Test 5: Address translation verification
        $display("\n--- Test 5: Address Translation Verification ---");
        // 测试地址转换逻辑：instr_addr[31:2] 作为索引
        // 地址 0x10 (16) -> 索引 4
        instr_addr = 32'h10;
        #1;
        test_name_str = "Address 0x10 should index word 4";
        check_result(ref_mem[4]);

        // 地址 0x14 (20) -> 索引 5
        instr_addr = 32'h14;
        #1;
        test_name_str = "Address 0x14 should index word 5";
        check_result(ref_mem[5]);

        // Test 6: Verify all words in ROM (optional, can be slow)
        $display("\n--- Test 6: Verify First 16 Words ---");
        begin
            integer i;
            for (i = 0; i < 16; i = i + 1) begin
                instr_addr = i * 4;
                #1;
                if (instr_out !== ref_mem[i]) begin
                    $display("[TEST FAIL] Word %0d: expected = %h, actual = %h",
                             i, ref_mem[i], instr_out);
                    test_pass = 0;
                end
            end
            test_num = test_num + 1;
            if (test_pass) begin
                $display("[TEST %0d PASS] First 16 words verified", test_num);
            end
        end

        // Test 7: Back-to-back reads
        $display("\n--- Test 7: Back-to-Back Reads (Fast address changes) ---");
        instr_addr = 32'h0;
        #1;
        if (instr_out !== ref_mem[0]) test_pass = 0;

        instr_addr = 32'h4;
        #0.5; // 更短的延迟
        if (instr_out !== ref_mem[1]) test_pass = 0;

        instr_addr = 32'h8;
        #0.2; // 更短的延迟
        if (instr_out !== ref_mem[2]) test_pass = 0;

        test_num = test_num + 1;
        if (test_pass) begin
            $display("[TEST %0d PASS] Back-to-back reads successful", test_num);
        end else begin
            $display("[TEST %0d FAIL] Back-to-back reads failed", test_num);
        end

        // Test summary
        $display("\n=== Test Summary ===");
        if (test_pass) begin
            $display("All %0d tests passed!", test_num);
            $display("ROM module functions correctly.");
        end else begin
            $display("Test failed! Please check the design.");
        end

        $display("Test completion time: %t", $time);
        $finish;
    end

    // Signal monitoring (optional)
    initial begin
        $monitor("Time: %t ns | instr_addr=%h | instr_out=%h",
                 $time, instr_addr, instr_out);
    end

    // Simulation timeout protection
    initial begin
        #(CLK_PERIOD * TEST_CYCLES * 3);
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

endmodule