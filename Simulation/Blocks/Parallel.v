module tb_parallel;
 reg clk = 0;
 reg [7:0] data;

 // Initial block 1: Generate clock (runs for 100 time units)
 initial begin
 repeat (10) begin
 #5 clk = ~clk; // Toggle clock every 5 units
 end
 $display("Block 1 finished at time %0t", $time); // Time 50
 end

 // Initial block 2: Apply test data (runs for 30 time units)
 initial begin
 data = 8'h00;
 #10 data = 8'hAA; // Time 10
 #10 data = 8'h55; // Time 20
 #10 data = 8'hFF; // Time 30
 $display("Block 2 finished at time %0t", $time); // Time 30
 end

 // Initial block 3: Monitor and finish (controls simulation end)
 initial begin
 $monitor("Time=%0t clk=%b data=%h", $time, clk, data);
 #60 $finish; // End simulation at time 60
 end
endmodule