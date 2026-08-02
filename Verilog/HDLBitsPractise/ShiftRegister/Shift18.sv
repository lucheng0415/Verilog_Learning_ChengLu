/*
Build a 64-bit arithmetic shift register, with synchronous load. The shifter can shift both left and right, and by 1 or 8 bit positions, selected by amount.

An arithmetic right shift shifts in the sign bit of the number in the shift register (q[63] in this case) instead of zero as done by a logical right shift. Another way of thinking about an arithmetic right shift is that it assumes the number being shifted is signed and preserves the sign, so that arithmetic right shift divides a signed number by a power of two.

There is no difference between logical and arithmetic left shifts.

load: Loads shift register with data[63:0] instead of shifting.
ena: Chooses whether to shift.
amount: Chooses which direction and how much to shift.
2'b00: shift left by 1 bit.
2'b01: shift left by 8 bits.
2'b10: shift right by 1 bit.
2'b11: shift right by 8 bits.
q: The contents of the shifter.
Module Declaration
module top_module(
    input clk,
    input load,
    input ena,
    input [1:0] amount,
    input [63:0] data,
    output reg [63:0] q);

A 5-bit number 11000 arithmetic right-shifted by 1 is 11100, while a logical right shift would produce 01100.
Similarly, a 5-bit number 01000 arithmetic right-shifted by 1 is 00100, and a logical right shift would produce the same result, because the original number was non-negative. 
*/

/*
    算术移位寄存器（Arithmetic Shift Register）是一种移位寄存器，与普通逻辑移位的区别在于右移时保留符号位。
    
    逻辑右移 vs 算术右移
    
    逻辑右移：左侧补 0
    1110 >> 1 → 0111
    算术右移：左侧补符号位（最高位）
    1110 >> 1 → 1111
    0110 >> 1 → 0011
    
    为什么要保留符号位？
    
    算术右移等价于对有符号数除以2的幂次。例如：
    
    1110（补码表示 -2）算术右移1位 → 1111（补码表示 -1），即 -2 ÷ 2 = -1 ✓
    如果用逻辑右移，1110 → 0111（表示 +7），结果就错了
    
    左移没有区别
    
    算术左移和逻辑左移完全一样，右侧都补 0。
    
    简单说：算术移位寄存器就是为了让右移操作对有符号数仍然有意义而设计的。
*/

module top_module(
    input clk,
    input load,
    input ena,
    input [1:0] amount,
    input [63:0] data,
    output reg [63:0] q); 
 
    always @(posedge clk) begin
        if (load)
            q <= data;
        else if (ena && amount == 2'b00)  // shift left by 1 bit.
            q <= {q[62:0], 1'b0};
        else if (ena && amount == 2'b01)  // shift left by 8 bit.
            q <= {q[55:0], 8'b0};
        else if (ena && amount == 2'b10)  // shift right by 1 bit.
            q <= {{q[63]}, q[63:1]};
        else if (ena && amount == 2'b11)  // shift right by 8 bit.
            q <= {{8{q[63]}}, q[63:8]};
    end

endmodule
