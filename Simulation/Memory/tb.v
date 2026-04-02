module tb;

reg clk;
reg rstn;
reg [1:0] addr;
reg wr;
reg sel;
reg [15:0] wdata;
wire [15:0] rdata;

mem dut (
 .clk(clk),
 .rstn(rstn),
 .addr(addr),
 .wr(wr),
 .sel(sel),
 .wdata(wdata),
 .rdata(rdata)
);

initial begin
$dumpfile("Memory.vcd");
$dumpvars(0, tb);
end



// clock generation
initial begin
 clk = 0;
 forever #10 clk = ~clk;
end

initial begin
 rstn = 0;
 wr = 0;
 sel = 0;
 wdata = 0;
 addr = 0;

repeat(2)@(posedge clk);
 rstn = 1; // keeps two cycles to avoid the race condition


 // write addr 0
 @(posedge clk);
 addr = 2'b00;
 wdata = 16'h1234;
 sel = 1;
 wr = 1;

 // write addr 1
 @(posedge clk);
 addr = 2'b01;
 wdata = 16'h5678;

 @(posedge clk); // Keeps 1 cycle to make sure addr 1 writes ok
 wr = 1;
 
 // read addr 0
 @(posedge clk);
 addr = 2'b00;
 wr = 0;

 // read addr 1
 @(posedge clk);
 addr = 2'b01;


 repeat(2)@(posedge clk);
 $finish;
end

endmodule