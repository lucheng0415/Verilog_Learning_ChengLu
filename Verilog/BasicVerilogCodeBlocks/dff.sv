/*1.1 D触发器 同步复位*/
module dff_sync_reset #(parameter W = 8) (
    input          clk,
    input          reset, // Active-high synchronous reset to 0
    input  [W-1:0] d,
    output [W-1:0] reg q
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
    input          clk,
    input          areset, // Asynchronous reset to 0
    input  [W-1:0] d,
    output [W-1:0] reg q
);
    always @(posedge clk or posedge areset) begin
        if (areset)
            q <= {W{1'b0}};
        else
            q <= d;
    end
endmodule

/*1.3 复位同步器 异步复位 同步释放*/
module reset_synchronizer (
    input clk,
    input rst_n_async, // Asynchronous reset to 0
    output reg rst_n_sync // Synchronized reset output
);
    reg [1:0] sync_ff; // Two flip-flops for synchronization

    always @(posedge clk or posedge rst_n_async) begin
        if (rst_n_async)
            sync_ff <= 2'b11; // Set both flip-flops to 1 on asynchronous reset
        else
            sync_ff <= {sync_ff[0], 1'b0}; // Shift in 0 on each clock cycle
    end

    assign rst_n_sync = sync_ff[1]; // Output the synchronized reset signal
endmodule