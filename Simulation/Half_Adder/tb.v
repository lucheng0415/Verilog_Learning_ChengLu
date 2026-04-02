module tb;
	// Declare testbench variables
	reg a, b; // Input drivers
	wire sum, cout; // Outputs from design under test
	integer i;

	// Instantiate the design and connect design inputs/outputs with
	// testbench variables
	ha u0 ( .a(a), .b(b), .sum(sum), .cout(cout));
initial begin
$dumpfile("ha.vcd");
$dumpvars(0, tb);
end
	initial begin
		// At the beginning of time, initialize all inputs of the design
		// to a known value, in this case we have chosen it to be 0.
		a <= 0;
		b <= 0;

		// Use a $monitor task to print any change in the signal to
		// simulation console
		$monitor("a=%0b b=%0b sum=%0b cout=%0b", a, b, sum, cout);

		// Because there are only 2 inputs, there can be 4 different input combinations
		// So use an iterator "i" to increment from 0 to 4 and assign the value
		// to testbench variables so that it drives the design inputs
		for (i = 0; i < 4; i = i + 1) begin
			{a, b} = i;
			#10;
		end
	end
endmodule