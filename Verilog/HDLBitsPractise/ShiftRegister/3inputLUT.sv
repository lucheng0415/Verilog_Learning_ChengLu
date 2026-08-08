/*
In this question, you will design a circuit for an 8x1 memory, where writing to the memory is accomplished by shifting-in bits, and reading is "random access", as in a typical RAM. You will then use the circuit to realize a 3-input logic function.

First, create an 8-bit shift register with 8 D-type flip-flops. Label the flip-flop outputs from Q[0]...Q[7]. The shift register input should be called S, which feeds the input of Q[0] (MSB is shifted in first). The enable input controls whether to shift. Then, extend the circuit to have 3 additional inputs A,B,C and an output Z. The circuit's behaviour should be as follows: when ABC is 000, Z=Q[0], when ABC is 001, Z=Q[1], and so on. Your circuit should contain ONLY the 8-bit shift register, and multiplexers. (Aside: this circuit is called a 3-input look-up-table (LUT)).

Module Declaration
module top_module (
    input clk,
    input enable,
    input S,
    input A, B, C,
    output Z ); 
*/

/*
两个要点：

移位方向。 题目说 S 喂给 Q[0]，所以 Q[0] <= S、Q[1] <= Q[0] …… Q[7] <= Q[6]，拼接写法就是 {Q[6:0], S}——S 在最低位，原来的 Q[6:0] 整体上移一格，Q[7] 被挤出去丢弃。"MSB is shifted in first" 是说你先送进去的那一位最终会走到 Q[7]，这跟代码无关，只是说明使用方式。

变址选择。 Q[{A,B,C}] 是 Verilog 的变量索引，综合出来正好是一个 8 选 1 MUX——符合题目"只能用移位寄存器和多路选择器"的限制。{A,B,C} 里 A 在最左边即最高位，所以 ABC=000→Q[0]、ABC=001→Q[1]、ABC=111→Q[7]，跟题意一致。

为什么这叫 LUT： 你通过 8 次移位把某个三输入布尔函数的真值表写进 Q[7:0]，之后 ABC 作为地址查表输出 Z。FPGA 里的逻辑单元就是这么工作的——任意三输入函数都能用同一个硬件实现，区别只在装载的 8 bit 配置数据。实际 FPGA 常用 4 输入或 6 输入 LUT，原理完全相同，只是表变成 16 bit 或 64 bit。
*/

module top_module (
    input clk,
    input enable,
    input S,
    input A, B, C,
    output Z );

    reg [7:0] Q;

    always @(posedge clk)
        if (enable)
            Q <= {Q[6:0], S};   // S 移入 Q[0]，其余依次左移

    assign Z = Q[{A,B,C}];      // 8选1 MUX，A 是地址最高位
endmodule