/*
This is a Moore state machine with two states, one input, and one output. Implement this state machine. Notice that the reset state is B.

This exercise is the same as fsm1s, but using asynchronous reset.

link: https://hdlbits.01xz.net/wiki/Fsm1

Module Declaration
module top_module(
    input clk,
    input areset,    // Asynchronous reset to state B
    input in,
    output out);
*/

/*
三段式的分工：

组合块算 next_state——纯粹的状态转移表，不含时钟
时序块负责状态寄存 + 复位——posedge areset 进敏感列表才是异步复位，这是和 fsm1s 唯一的区别
assign out 只看 state，不看 in——这就是 Moore 的定义。如果写成 out = (state==B) && in 就变 Mealy 了

验证一下 hint 说的 TFF：

转移表读出来是"in=0 翻转，in=1 保持"，正好是 T 触发器的 T = ~in。所以整个题也可以写成一行：

systemverilog
always @(posedge clk or posedge areset)
    if (areset) out_r <= 1'b1;
    else        out_r <= in ? out_r : ~out_r;

功能完全一样，综合结果也一样。不过题目的目的是练 FSM 的写法，所以面试或作业里还是用上面的三段式——结构清晰、状态多了以后可扩展、综合工具也更容易识别成状态机并做状态编码优化。

一个容易踩的坑： 组合块的 case 如果漏了某个分支，next_state 会被推断成锁存器。这里两个状态都写全了所以没事；状态一多，习惯上要么加 default:，要么在 always @(*) 开头先写一句 next_state = state; 兜底。
*/

module top_module(
    input clk,
    input areset,    // Asynchronous reset to state B
    input in,
    output out);//  

    localparam A = 1'b0, B = 1'b1;
    reg state, next_state;

    always @(*) begin
        case (state)
            A: next_state = in ? A : B;
            B: next_state = in ? B : A;
        endcase
    end

    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= B;
        else
            state <= next_state;
    end

    assign out = (state == B);

endmodule
