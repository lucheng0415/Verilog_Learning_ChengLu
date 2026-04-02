module ha ( input 	a, b,
						output	sum, cout);

	// Sum bit: XOR gives 1 when inputs differ (1+0=1, 0+1=1)
	assign sum = a ^ b;

	// Carry bit: AND gives 1 only when both inputs are 1 (1+1=10 in binary)
	assign cout = a & b;
endmodule