/*
https://hdlbits.01xz.net/wiki/Shift4

Build a 4-bit shift register (right shift), with asynchronous reset, synchronous load, and enable.

areset: Resets shift register to zero.
load: Loads shift register with data[3:0] instead of shifting.
ena: Shift right (q[3] becomes zero, q[0] is shifted out and disappears).
q: The contents of the shift register.
If both the load and ena inputs are asserted (1), the load input has higher priority.

Module Declaration
module top_module(
    input clk,
    input areset,  // async active-high reset to zero
    input load,
    input ena,
    input [3:0] data,
    output reg [3:0] q); 
*/

/*
关于右移的理解：
假设 q = 4'b1011，用二进制位来看：

位置:   q[3] q[2] q[1] q[0]
移前:     1    0    1    1
移后:     0    1    0    1   ← q[0]的1消失了，q[3]补0

{1'b0, q[3:1]} 拆开就是：

{ 1'b0,  q[3], q[2], q[1] }
=  0      1     0     1
q[3:1] 整体往右移一位（原来在 q[3] 的跑到 q[2]，以此类推）
最高位 q[3] 空出来，补 0
原来的 q[0] 被挤出去丢掉

本质就是除以 2 的操作（无符号数）。
*/

/*
这里if case中没有else收尾不会综合成latch， latch 只在组合逻辑（always @(*)）里 if-else 不完整时才产生。
这里是时序逻辑（always @(posedge clk)），没有 else 的意思是"保持原值"，综合出来是寄存器的保持状态，不是 latch。
*/

module top_module(
    input clk,
    input areset,  // async active-high reset to zero
    input load,
    input ena,
    input [3:0] data,
    output reg [3:0] q); 

    always @ (posedge areset or posedge clk) begin //areset 在 sensitivity list 里用 posedge，因为是异步高电平复位
        if (areset)
            q <= 4'b0000;
        else if (load) //load 优先级高于 ena，所以放在前面的 else if
            q <= data; 
        else if (ena)
            q <= {1'b0, q[3:1]}; //右移：{1'b0, q[3:1]} — 最高位补 0，q[0] 丢弃, 拼接符号中左边为高位
    end

endmodule