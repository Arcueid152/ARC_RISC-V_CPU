//// ============================================================
// BPU.v — 分支预测单元（Branch Prediction Unit）
// 策略： 计数器（PHT）用于判断（强不跳，弱不跳，弱跳，强跳） + 储存跳转地址（BTB）
//
// 接口说明：
//   预测阶段 - IF
//     pc_in        : 当前 IF 阶段的 PC，用来查表
//     pred_taken   : 预测是否跳转（1=跳，0=不跳）
//     pred_addr    : 预测的目标地址（BTB 查到的）
//
//   更新阶段 - EX
//     update_en    : EX 判断是否是分支指令，需要更新
//     update_pc    : 该分支指令的 PC
//     actual_taken : 实际是否跳转了
//     actual_addr  : 实际跳转目标地址
// ============================================================

module BPU #(
    parameter PHT_BITS = 6,              // PHT 表大小：2^6 = 64 项  目前设定为64项，不一定为最优的大小。太小会导致超出的分支预测互相替换原有的优化后的预测，使其又要重新优化预测；太大会导致出现选择器的级联越深，走线越长，导致组合逻辑延迟显著增加。
    parameter BTB_BITS = 6               // BTB 表大小：2^6 = 64 项
)(
    input  wire        clk,
    input  wire        rst,

    // === 预测接口（IF 阶段查询）===
    input  wire [31:0] pc_in,            // 当前 IF 的 PC
    output wire        pred_taken,       // 预测：是否跳转
    output wire   [31:0] pred_addr,        // 预测：跳转目标地址

    // === 更新接口（EX 阶段反馈）===
    input  wire        update_en,        // EX 判断是否是分支指令
    input  wire [31:0] update_pc,        // 该分支的 PC
    input  wire        actual_taken,     // 实际跳没跳
    input  wire [31:0] actual_addr       // 实际跳转地址
);



    // ========== PHT：计数器表部分 ==========
    //     11/10=预测跳，01/00=预测不跳
    localparam PHT_DEPTH = (1 << PHT_BITS);
    reg [1:0] pht [0:PHT_DEPTH-1];                  //pht就是预测跳与不跳的pht表

    // PHT 索引：取 PC 的低 PHT_BITS 位（跳过最低2位对齐位）
    wire [PHT_BITS-1:0] pht_idx_pred   = pc_in    [PHT_BITS+1:2];      //确定预测的pht是哪个项
    wire [PHT_BITS-1:0] pht_idx_update = update_pc[PHT_BITS+1:2];      //确定更新的pht是哪个项

    // 预测：计数器最高位为 1 → 预测跳
    wire pht_pred = pht[pht_idx_pred][1];

    // PHT更新模块
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < PHT_DEPTH; i = i + 1)
                pht[i] <= 2'b01; // 初始：弱不跳
        end
        else if (update_en) begin
            if (actual_taken) begin
                // 跳了 → +1（最高到 11）
                if (pht[pht_idx_update] != 2'b11)
                    pht[pht_idx_update] <= pht[pht_idx_update] + 2'b01;
            end
            else begin
                // 没跳 → -1（最低到 00）
                if (pht[pht_idx_update] != 2'b00)
                    pht[pht_idx_update] <= pht[pht_idx_update] - 2'b01;
            end
        end
    end

    // ========== BTB：跳转地址储存模块 ==========
    // 每项存：valid(1) + tag[TAG_BITS-1:0] + target_addr[31:0]
    localparam BTB_DEPTH  = (1 << BTB_BITS);
    localparam TAG_BITS   = 30 - BTB_BITS; // PC[31:2] 去掉索引位剩下的

    //每项的三个部分的声明
    reg                 btb_valid  [0:BTB_DEPTH-1];
    reg [TAG_BITS-1:0]  btb_tag    [0:BTB_DEPTH-1];
    reg [31:0]          btb_target [0:BTB_DEPTH-1];

    // BTB 索引：取 PC 的低 BTB_BITS 位（同样跳过对齐位）
    wire [BTB_BITS-1:0] btb_idx_pred   = pc_in    [BTB_BITS+1:2];    //确定预测的btb的地址（即target）是哪个
    wire [BTB_BITS-1:0] btb_idx_update = update_pc[BTB_BITS+1:2];    //确定更新的btb的地址（即target）是哪个

    wire [TAG_BITS-1:0] tag_pred   = pc_in    [31:BTB_BITS+2];       //确定预测的btb的tag是哪个
    wire [TAG_BITS-1:0] tag_update = update_pc[31:BTB_BITS+2];       //确定更新的btb的tag是哪个

    // BTB 命中判断
    wire btb_hit = btb_valid[btb_idx_pred] &&
                   (btb_tag[btb_idx_pred] == tag_pred);

    // BTB更新模块 （只有实际跳转时才写入/更新目标地址）
    integer j;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (j = 0; j < BTB_DEPTH; j = j + 1) begin
                btb_valid[j]  <= 1'b0;
                btb_tag[j]    <= {TAG_BITS{1'b0}};
                btb_target[j] <= 32'h8000_0000;
            end
        end
        else if (update_en && actual_taken) begin
            btb_valid [btb_idx_update] <= 1'b1;
            btb_tag   [btb_idx_update] <= tag_update;
            btb_target[btb_idx_update] <= actual_addr;
        end
    end

    // ========== 输出预测结果 ==========
    // 预测跳转：PHT 说跳 && BTB 有记录这条分支的目标地址
    assign pred_taken = pht_pred && btb_hit;
    assign pred_addr  = btb_hit ? btb_target[btb_idx_pred] : (pc_in + 32'h4);
endmodule
    