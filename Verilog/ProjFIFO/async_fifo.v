// =============================================================
//  async_fifo.v — 异步 FIFO（双时钟域）
//
//  核心思路（Cliff Cummings 经典方案）：
//  1. 读写指针各用 ADDR_WIDTH+1 位二进制计数器
//  2. 转换为格雷码后跨域同步（2-FF Synchronizer）
//  3. 同步后的格雷码在目标域做满/空判断
//     ▶ empty：读域同步的写指针格雷码 == 读指针格雷码
//     ▶ full ：写域同步的读指针格雷码 MSB 和 MSB-1 均取反后与写指针格雷码相等
// =============================================================

// -----------------------------------------------------------
//  子模块：2-FF 同步器（防亚稳态）
// -----------------------------------------------------------
module sync_2ff #(
    parameter WIDTH = 5
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);
    reg [WIDTH-1:0] stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1 <= 0;
            q      <= 0;
        end else begin
            stage1 <= d;
            q      <= stage1;
        end
    end
endmodule

// -----------------------------------------------------------
//  主模块：async_fifo
// -----------------------------------------------------------
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4     // 深度 = 2^4 = 16
)(
    // 写时钟域
    input  wire                  wclk,
    input  wire                  wrst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    // 读时钟域
    input  wire                  rclk,
    input  wire                  rrst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire                  empty
);

    localparam PTR_WIDTH = ADDR_WIDTH + 1;  // 含回绕位
    localparam DEPTH     = 1 << ADDR_WIDTH;

    // -------------------------------------------------------
    // 双口 RAM（写时钟写，读时钟读，天然异步）
    // -------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // -------------------------------------------------------
    // 写时钟域：写指针（二进制 + 格雷码）
    // -------------------------------------------------------
    reg  [PTR_WIDTH-1:0] wr_ptr_bin;   // 二进制写指针
    wire [PTR_WIDTH-1:0] wr_ptr_gray;  // 格雷码写指针

    assign wr_ptr_gray = (wr_ptr_bin >> 1) ^ wr_ptr_bin;  // bin → gray

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wr_ptr_bin <= 0;
        else if (wr_en && !full)
            wr_ptr_bin <= wr_ptr_bin + 1;
    end

    // 写操作
    always @(posedge wclk) begin
        if (wr_en && !full)
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;
    end

    // -------------------------------------------------------
    // 读时钟域：读指针（二进制 + 格雷码）
    // -------------------------------------------------------
    reg  [PTR_WIDTH-1:0] rd_ptr_bin;
    wire [PTR_WIDTH-1:0] rd_ptr_gray;

    assign rd_ptr_gray = (rd_ptr_bin >> 1) ^ rd_ptr_bin;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rd_ptr_bin <= 0;
        else if (rd_en && !empty)
            rd_ptr_bin <= rd_ptr_bin + 1;
    end

    // 读操作
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rd_data <= 0;
        else if (rd_en && !empty)
            rd_data <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
    end

    // -------------------------------------------------------
    // 跨域同步：写指针格雷码 → 读时钟域
    // -------------------------------------------------------
    wire [PTR_WIDTH-1:0] wr_ptr_gray_sync;  // 在读域中同步好的写指针格雷码

    sync_2ff #(.WIDTH(PTR_WIDTH)) u_sync_wr2rd (
        .clk   (rclk),
        .rst_n (rrst_n),
        .d     (wr_ptr_gray),
        .q     (wr_ptr_gray_sync)
    );

    // -------------------------------------------------------
    // 跨域同步：读指针格雷码 → 写时钟域
    // -------------------------------------------------------
    wire [PTR_WIDTH-1:0] rd_ptr_gray_sync;  // 在写域中同步好的读指针格雷码

    sync_2ff #(.WIDTH(PTR_WIDTH)) u_sync_rd2wr (
        .clk   (wclk),
        .rst_n (wrst_n),
        .d     (rd_ptr_gray),
        .q     (rd_ptr_gray_sync)
    );

    // -------------------------------------------------------
    // Empty 判断（在读时钟域）
    //   条件：同步后的写指针格雷码 == 读指针格雷码
    // -------------------------------------------------------
    assign empty = (wr_ptr_gray_sync == rd_ptr_gray);

    // -------------------------------------------------------
    // Full 判断（在写时钟域）
    //   格雷码满条件（ADDR_WIDTH+1 位格雷码）：
    //     wr_gray[PTR_WIDTH-1]   ≠ rd_gray_sync[PTR_WIDTH-1]   （最高位取反）
    //     wr_gray[PTR_WIDTH-2]   ≠ rd_gray_sync[PTR_WIDTH-2]   （次高位取反）
    //     wr_gray[PTR_WIDTH-3:0] == rd_gray_sync[PTR_WIDTH-3:0] （低位相同）
    //
    //   等价于：
    //     wr_ptr_gray == {~rd_ptr_gray_sync[PTR_WIDTH-1],
    //                     ~rd_ptr_gray_sync[PTR_WIDTH-2],
    //                      rd_ptr_gray_sync[PTR_WIDTH-3:0]}
    // -------------------------------------------------------
    assign full = (wr_ptr_gray == {~rd_ptr_gray_sync[PTR_WIDTH-1],
                                   ~rd_ptr_gray_sync[PTR_WIDTH-2],
                                    rd_ptr_gray_sync[PTR_WIDTH-3:0]});

endmodule
