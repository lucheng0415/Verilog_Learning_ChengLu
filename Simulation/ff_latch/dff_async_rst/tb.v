module tb_dff;
	reg clk;
	reg d;
	reg rstn;
	reg [2:0] delay;
    integer i;
        wire q;
    // Generate clock
    always #10 clk = ~clk;

    initial begin
    $dumpfile("dump.vcd");   // 波形文件名
    $dumpvars(0, tb_dff);    // tb 是你的 testbench module 名
    end

    // Testcase
    initial begin
    	clk <= 0;
    	d <= 0;
    	rstn <= 0;
        
    	#10 d <= 1;
    	#20 rstn <= 1;
        #25 d <= 0;
        #30 d <= 1;
        #35 rstn <= 0;
        #40
        #45
        $finish;
    end
endmodule