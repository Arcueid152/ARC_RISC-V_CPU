`timescale 1ns / 1ps

module pc_cnt_tb;

    // 测试参数
    parameter CLK_PERIOD = 10;      // 时钟周期 10ns (100MHz)
    parameter TEST_CYCLES = 20;     // 测试周期数

    // 信号声明
    reg clk;
    reg rstn;
    reg jump_en;
    reg [31:0] jump_addr;
    wire [31:0] pc_pointer;

    integer test_pass;          // 测试通过标志
    integer test_num;           // 测试编号

    // 实例化被测试模块
    pc_cnt u_pc_cnt (
        .clk(clk),
        .rstn(rstn),
        .jump_en(jump_en),
        .jump_addr(jump_addr),
        .pc_pointer(pc_pointer)
    );

    // 时钟生成
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // 复位生成
    task apply_reset;
        begin
            rstn = 0;
            jump_en = 0;
            jump_addr = 0;
            #(CLK_PERIOD * 2);
            rstn = 1;
            @(negedge clk); // Wait for clock falling edge to avoid clock edge
            #1; // Small delay after clock edge
        end
    endtask

    // 字符串寄存器用于测试名称
    reg [639:0] test_name_str; // 80字符 * 8位

    // 检查结果任务
    task check_result;
        input [31:0] expected;
        begin
            test_num = test_num + 1;
            if (pc_pointer !== expected) begin
                $display("[TEST %0d FAIL] %s: expected = %h, actual = %h",
                         test_num, test_name_str, expected, pc_pointer);
                test_pass = 0;
            end else begin
                $display("[TEST %0d PASS] %s: PC = %h",
                         test_num, test_name_str, pc_pointer);
            end
        end
    endtask

    // 主测试过程
    initial begin
        // 初始化测试变量
        test_pass = 1;
        test_num = 0;

        $display("=== PC Counter Module Test Start ===");
        $display("Time: %t", $time);

        // Test 1: Reset function
        $display("\n--- Test 1: Reset Function ---");
        apply_reset;
        test_name_str = "After reset, PC should be 0";
        check_result(32'h0);

        // Test 2: Normal increment function
        $display("\n--- Test 2: Normal Increment Function ---");
        @(posedge clk); #1;
        test_name_str = "After 1st cycle, PC should be 4";
        check_result(32'h4);

        @(posedge clk); #1;
        test_name_str = "After 2nd cycle, PC should be 8";
        check_result(32'h8);

        @(posedge clk); #1;
        test_name_str = "After 3rd cycle, PC should be C";
        check_result(32'hc);

        // Test 3: Jump function
        $display("\n--- Test 3: Jump Function ---");
        jump_addr = 32'h1000;
        jump_en = 1;
        @(posedge clk); #1;
        test_name_str = "Jump to address 1000";
        check_result(32'h1000);

        // Disable jump, continue increment
        jump_en = 0;
        @(posedge clk); #1;
        test_name_str = "Continue increment after jump";
        check_result(32'h1004);

        // Test 4: Multiple consecutive jumps
        $display("\n--- Test 4: Multiple Consecutive Jumps ---");
        jump_addr = 32'h2000;
        jump_en = 1;
        @(posedge clk); #1;
        test_name_str = "Jump to address 2000";
        check_result(32'h2000);

        jump_addr = 32'h3000;
        @(posedge clk); #1;
        test_name_str = "Consecutive jump to address 3000";
        check_result(32'h3000);

        // Test 5: Reset during operation
        $display("\n--- Test 5: Reset During Operation ---");
        jump_en = 0;
        #(CLK_PERIOD/2);  // Half cycle later reset
        rstn = 0;
        #1; // Small delay after reset
        test_name_str = "PC should be 0 after reset during operation";
        check_result(32'h0);

        // Resume operation
        rstn = 1;
        @(negedge clk); // Wait for clock falling edge
        #1; // Small delay after clock edge
        test_name_str = "Continue increment after reset recovery";
        check_result(32'h4);

        // Test 6: Boundary cases
        $display("\n--- Test 6: Boundary Cases ---");

        // Jump to address 0
        jump_addr = 32'h0;
        jump_en = 1;
        @(posedge clk); #1;
        test_name_str = "Jump to address 0";
        check_result(32'h0);

        // Jump to near max address
        jump_addr = 32'hfffffffc;  // Multiple of 4
        jump_en = 1;
        @(posedge clk); #1;
        test_name_str = "Jump to near maximum address";
        check_result(32'hfffffffc);

        jump_en = 0;
        @(posedge clk); #1;
        test_name_str = "Address wrap-around to 0 (32-bit overflow)";
        check_result(32'h0);

        // Test summary
        $display("\n=== Test Summary ===");
        if (test_pass) begin
            $display("All %0d tests passed!", test_num);
            $display("Module functions correctly.");
        end else begin
            $display("Test failed! Please check the design.");
        end

        $display("Test completion time: %t", $time);
        $finish;
    end

    // Signal monitoring (optional)
    initial begin
        $monitor("Time: %t ns | rstn=%b | jump_en=%b | jump_addr=%h | pc_pointer=%h",
                 $time, rstn, jump_en, jump_addr, pc_pointer);
    end

    // Simulation timeout protection
    initial begin
        #(CLK_PERIOD * TEST_CYCLES * 3);
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

endmodule