Challenge: Build a Data Type Testbench Demonstrating All Types
Create a comprehensive testbench that demonstrates proper usage of all Verilog data types: wire, reg, integer, time, real, and strings. The testbench should showcase common operations, value assignments, and format specifiers.

Requirements:

Demonstrate wire vs reg with a simple combinational and sequential circuit
Use integer for a loop counter that iterates 10 times
Use time to measure elapsed simulation time between two events
Use real to calculate average of three values with fractional precision
Demonstrate string truncation and padding with three different sizes
Show proper format specifiers for each data type in $display
Include comments explaining when each type is appropriate


Start with wire and reg to model a simple flip-flop (wire for input/output ports, reg for sequential storage). Use integer in a for loop to generate test patterns. Capture $time at start and end to measure duration. Calculate an average with real division. Create three string variables sized at exactly 10, less than 10, and more than 10 characters to see truncation and padding behavior.


Simulation result:

═══════════════════════════════════════════
  COMPILATION (Icarus Verilog)
═══════════════════════════════════════════

$ /usr/bin/iverilog -o simulation _timescale.v testbench.v
✓ Compilation successful

═══════════════════════════════════════════
  SIMULATION (VVP Runtime)
═══════════════════════════════════════════

$ /usr/bin/vvp simulation
========================================
  Verilog Data Types Demonstration
========================================

--- WIRE (Nets) vs REG (Variables) ---
VCD info: dumpfile dump.vcd opened for output.
D flip-flop: d=1, q=1 (q is reg, stores d on clk edge)
Combinational: a=1, b=0, and_out=0, or_out=1
  -> wire and_out/or_out change immediately with inputs

--- INTEGER (32-bit signed) ---
Loop counter i (integer): 1 to 10
Sum = 55 (calculated using integer arithmetic)
  -> integer ideal for loop counters and arithmetic

--- TIME (64-bit unsigned) ---
Start time: 30
End time: 130
Elapsed time: 100 (time type stores simulation time)

--- REAL (64-bit floating point) ---
Values: 10.50, 20.75, 15.25
Average: 15.5000 (real allows fractional precision)
  -> real essential for non-integer calculations

--- STRING STORAGE ---
Original string: "HelloWorld" (10 characters)
str_exact [8*10:1] = "HelloWorld" (exact fit)
str_small [8*5:1]  = "World" (truncated to rightmost 5 chars)
str_large [8*20:1] = "          HelloWorld" (padded with 10 leading spaces)
  -> String size must be [8*N:1] for N characters

--- FORMAT SPECIFIERS ---
%b (binary):      q = 1
%d (decimal):     sum =          55
%0d (decimal):    sum = 55 (no leading spaces)
%h (hex):         sum = 00000037
%0h (hex):        sum = 0x37 (common hex format)
%t (time):        elapsed = 100
%f (real):        average = 15.500000
%0.2f (real):     average = 15.50 (2 decimal places)
%s (string):      str = HelloWorld

========================================
  Summary: When to Use Each Type
========================================
wire:    Connecting modules, combinational logic outputs
reg:     Sequential logic (clocked), procedural assignments
integer: Loop counters, testbench arithmetic (non-synthesizable)
time:    Measuring simulation time, performance analysis
real:    Floating point math, delays, testbench calculations
string:  Messages, file names, debug output
testbench.v:138: $finish called at 130 (1ns)

✓ VCD waveform captured (1409 bytes)
✓ Simulation completed successfully in 0.10s


✅ Simulation Successful!
⏱️ Total time: 5.0s

