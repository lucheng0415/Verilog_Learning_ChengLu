module tb_datatypes;

  // ========== NET DEMONSTRATION (wire) ==========
  // Nets represent physical connections and cannot store values
  wire a;              // Inputs to combinational logic
  wire and_out;           // Output of AND gate (continuous assignment)
  wire or_out;            // Output of OR gate

  // Continuous assignments drive wire nets
  assign and_out = a & b; // Combinational logic: AND gate
  assign or_out = a | b;  // Combinational logic: OR gate

  // ========== VARIABLE DEMONSTRATION (reg) ==========
  // Variables can store values and are used in procedural blocks
  reg clk;                // Clock signal for sequential logic
  reg rst;                // Reset signal
  reg d;                  // D flip-flop input
  reg q;                  // D flip-flop output (sequential storage)
  reg b;

  // Sequential logic: D flip-flop using reg
  always @(posedge clk or posedge rst) begin
    if (rst)
      q <= 1'b0;          // Reset: reg retains 0 until reassigned
    else
      q <= d;             // On clock edge: reg stores new value
  end

  // ========== INTEGER DEMONSTRATION ==========
  // integer: 32-bit signed type for loop counters and arithmetic
  integer i;              // Loop counter
  integer sum;            // Accumulator for sum of iterations

  // ========== TIME DEMONSTRATION ==========
  // time: 64-bit unsigned for storing simulation time
  time start_time;        // Capture time at beginning
  time end_time;          // Capture time at end
  time elapsed_time;      // Calculated difference

  // ========== REAL DEMONSTRATION ==========
  // real: 64-bit floating point for mathematical calculations
  real value1, value2, value3;  // Three values to average
  real average;                 // Calculated average

  // ========== STRING DEMONSTRATION ==========
  // Strings stored in reg with [8*N:1] sizing (N = number of characters)
  reg [8*10:1] str_exact;   // Exactly 10 characters
  reg [8*5:1] str_small;    // Only 5 characters (will truncate)
  reg [8*20:1] str_large;   // 20 characters (will pad with zeros)

  // Clock generation for sequential logic demo
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10 time unit period clock
  end

  // Main testbench procedure
  initial begin
    $display("========================================");
    $display("  Verilog Data Types Demonstration");
    $display("========================================\n");

    // ===== WIRE & REG DEMO =====
    $display("--- WIRE (Nets) vs REG (Variables) ---");
    rst = 1; d = 0;
    #10 rst = 0;
    #10 d = 1;
    #10;
    $display("D flip-flop: d=%b, q=%b (q is reg, stores d on clk edge)", d, q);
    $display("Combinational: a=%b, b=%b, and_out=%b, or_out=%b", a, b, and_out, or_out);
    $display("  -> wire and_out/or_out change immediately with inputs\n");

    // ===== INTEGER DEMO =====
    $display("--- INTEGER (32-bit signed) ---");
    sum = 0;
    for (i = 1; i <= 10; i = i + 1) begin
      sum = sum + i;  // Accumulate 1+2+...+10
    end
    $display("Loop counter i (integer): 1 to 10");
    $display("Sum = %0d (calculated using integer arithmetic)", sum);
    $display("  -> integer ideal for loop counters and arithmetic\n");

    // ===== TIME DEMO =====
    $display("--- TIME (64-bit unsigned) ---");
    start_time = $time;    // Capture current simulation time
    $display("Start time: %0t", start_time);

    #100;                  // Wait 100 time units

    end_time = $time;      // Capture time after delay
    elapsed_time = end_time - start_time;
    $display("End time: %0t", end_time);
    $display("Elapsed time: %0t (time type stores simulation time)\n", elapsed_time);

    // ===== REAL DEMO =====
    $display("--- REAL (64-bit floating point) ---");
    value1 = 10.5;
    value2 = 20.75;
    value3 = 15.25;
    average = (value1 + value2 + value3) / 3.0;  // Floating point division
    $display("Values: %0.2f, %0.2f, %0.2f", value1, value2, value3);
    $display("Average: %0.4f (real allows fractional precision)", average);
    $display("  -> real essential for non-integer calculations\n");

    // ===== STRING DEMO =====
    $display("--- STRING STORAGE ---");
    str_exact = "HelloWorld";  // Exactly 10 chars
    str_small = "HelloWorld";  // Only 5 chars (truncates leftmost)
    str_large = "HelloWorld";  // 20 chars (pads leftmost with spaces)

    $display("Original string: \"HelloWorld\" (10 characters)");
    $display("str_exact [8*10:1] = \"%s\" (exact fit)", str_exact);
    $display("str_small [8*5:1]  = \"%s\" (truncated to rightmost 5 chars)", str_small);
    $display("str_large [8*20:1] = \"%s\" (padded with 10 leading spaces)", str_large);
    $display("  -> String size must be [8*N:1] for N characters\n");

    // ===== FORMAT SPECIFIER SUMMARY =====
    $display("--- FORMAT SPECIFIERS ---");
    $display("%%b (binary):      q = %b", q);
    $display("%%d (decimal):     sum = %d", sum);
    $display("%%0d (decimal):    sum = %0d (no leading spaces)", sum);
    $display("%%h (hex):         sum = %h", sum);
    $display("%%0h (hex):        sum = 0x%0h (common hex format)", sum);
    $display("%%t (time):        elapsed = %0t", elapsed_time);
    $display("%%f (real):        average = %f", average);
    $display("%%0.2f (real):     average = %0.2f (2 decimal places)", average);
    $display("%%s (string):      str = %s", str_exact);

    $display("\n========================================");
    $display("  Summary: When to Use Each Type");
    $display("========================================");
    $display("wire:    Connecting modules, combinational logic outputs");
    $display("reg:     Sequential logic (clocked), procedural assignments");
    $display("integer: Loop counters, testbench arithmetic (non-synthesizable)");
    $display("time:    Measuring simulation time, performance analysis");
    $display("real:    Floating point math, delays, testbench calculations");
    $display("string:  Messages, file names, debug output");

    $finish;
  end

  // Drive wire inputs for combinational demo
  initial begin
    {d, b} = 2'b00;
    #15 {d, b} = 2'b01;
    #10 {d, b} = 2'b10;
    #10 {d, b} = 2'b11;
  end

  // a follows d with delay for wire demo
  assign #1 a = d;

endmodule


