// =============================================================
//  sync_fifo.v — 同步 FIFO（单时钟域）
//  深度 = 2^ADDR_WIDTH，数据宽度 = DATA_WIDTH
//  满/空标志通过比较读写指针的"多出一位"实现（无需额外状态）
// =============================================================
module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4         // 深度 = 2^4 = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    // 写端口
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,
    // 读端口
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire                  empty,
    // 调试
    output wire [ADDR_WIDTH:0]   fifo_count   // 当前存储数量
);

    // -------------------------------------------------------
    // 内部存储：2^ADDR_WIDTH 深度的寄存器阵列
    // -------------------------------------------------------
    localparam DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // -------------------------------------------------------
    // 读写指针：多一位用于区分"满"和"空"
    //   写指针 wr_ptr 和读指针 rd_ptr 均为 ADDR_WIDTH+1 位
    //   低 ADDR_WIDTH 位是真实地址，最高位是"绕圈"标志
    //   全等 → 空；最高位不同且低位相等 → 满
    // -------------------------------------------------------
    reg [ADDR_WIDTH:0] wr_ptr;   // 写指针（含回绕位）
    reg [ADDR_WIDTH:0] rd_ptr;   // 读指针（含回绕位）

    wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // -------------------------------------------------------
    // 满/空/数量判断
    // -------------------------------------------------------
    assign empty      = (wr_ptr == rd_ptr);
    assign full       = (wr_ptr[ADDR_WIDTH]   != rd_ptr[ADDR_WIDTH])   // 绕圈不同
                      & (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]); // 地址相同
    assign fifo_count = wr_ptr - rd_ptr;   // 自然溢出处理绕圈

    // -------------------------------------------------------
    // 写操作
    // -------------------------------------------------------
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] <= 0;
        end else if (wr_en && !full) begin
            mem[wr_addr] <= wr_data;
            wr_ptr       <= wr_ptr + 1;
        end
    end

    // -------------------------------------------------------
    // 读操作（同步输出）
    // -------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr  <= 0;
            rd_data <= 0;
        end else if (rd_en && !empty) begin
            rd_data <= mem[rd_addr];
            rd_ptr  <= rd_ptr + 1;
        end
    end

endmodule
