/*1.1 D触发器 同步复位*/
module dff_sync_reset #(parameter W = 8) (
    input              clk,
    input              reset, // Active-high synchronous reset to 0
    input      [W-1:0] d,
    output reg [W-1:0] q
);
    always @(posedge clk) begin
        if (reset)
            q <= {W{1'b0}};
        else
            q <= d;
    end
endmodule

/*1.2 D触发器 异步复位*/
module dff_async_reset #(parameter W = 8) (
    input              clk,
    input              areset, // Active-high asynchronous reset to 0
    input      [W-1:0] d,
    output reg [W-1:0] q
);
    always @(posedge clk or posedge areset) begin
        if (areset)
            q <= {W{1'b0}};
        else
            q <= d;
    end
endmodule

/*1.3 复位同步器 异步复位 同步释放*/
// 复位到来时立刻生效（异步断言），释放时经两级触发器同步到时钟域（同步释放），
// 避免复位释放的时刻与时钟沿过近而引发亚稳态。
module reset_synchronizer (
    input  clk,
    input  rst_n_async, // Active-low asynchronous reset in
    output rst_n_sync   // Active-low reset, synchronously released
);
    reg [1:0] sync_ff;

    // 低有效复位用 negedge 进敏感列表：拉低的瞬间异步生效
    always @(posedge clk or negedge rst_n_async) begin
        if (!rst_n_async)
            sync_ff <= 2'b00;               // 异步断言：立即清零
        else
            sync_ff <= {sync_ff[0], 1'b1};  // 同步释放：1 逐级移入，两拍后输出拉高
    end

    assign rst_n_sync = sync_ff[1];
endmodule
