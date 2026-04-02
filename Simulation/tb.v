module tb;

reg clk;
reg rstn;
reg wr;
reg sel;
wire flag;
reg [15:0] wdata;
wire [15:0] rdata;

des dut (
 .clk(clk),
 .rstn(rstn),
 .wr(wr),
 .sel(sel),
 .wdata(wdata),
 .rdata(rdata),
 .flag(flag)
);

initial begin
$dumpfile("RegisterVector.vcd");
$dumpvars(0, tb.dut);
end

// clock generation
initial begin
 clk = 0;
 forever #5 clk = ~clk;
end

// stimulus
initial begin
 rstn = 0;
 wr = 0;
 sel = 0;
 wdata = 0;

 #10 rstn = 1;

 #10 sel = 1;
 wr = 1;
 wdata = 16'h1234;

 #10 wr = 0;

 #20 $finish;
end

endmodule