/*
https://hdlbits.01xz.net/wiki/Lfsr5
A linear feedback shift register is a shift register usually with a few XOR gates to produce the next state of the shift register. A Galois LFSR is one particular arrangement where bit positions with a "tap" are XORed with the output bit to produce its next value, while bit positions without a tap shift. If the taps positions are carefully chosen, the LFSR can be made to be "maximum-length". A maximum-length LFSR of n bits cycles through 2n-1 states before repeating (the all-zero state is never reached).

The following diagram shows a 5-bit maximal-length Galois LFSR with taps at bit positions 5 and 3. (Tap positions are usually numbered starting from 1). Note that I drew the XOR gate at position 5 for consistency, but one of the XOR gate inputs is 0.

Build this LFSR. The reset should reset the LFSR to 1.

Module Declaration
module top_module(
    input clk,
    input reset,    // Active-high synchronous reset to 5'h1
    output [4:0] q
); 
Hint...
The first few states starting at 1 are 00001, 10100, 01010, 00101, ... The LFSR should cycle through 31 states before returning to 00001.

*/

module top_module(
    input clk,
    input reset,    // Active-high synchronous reset to 5'h1
    output [4:0] q
); 

    always @ (posedge clk) begin
        if (reset)
            q <= 5'b00001;
        else begin
            q[4] <= q[0] ^ 1'b0;  // tap位置做XOR
            q[3] <= q[4];
            q[2] <= q[3] ^ q[0];  // tap位置做XOR
            q[1] <= q[2];
            q[0] <= q[1];
        end      
    end
endmodule