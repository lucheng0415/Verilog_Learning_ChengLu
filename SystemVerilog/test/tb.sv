module tb;
    logic [3:0] my_data;
    logic en;
    logic clk;

    assign en = my_data[0];

    initial clk = 0;
    always #5 clk <= ~clk; // 10 time units clock

    initial begin
        $display("my_data=%0h en=%0b", my_data, en);
        my_data = 4'hF;
        $display("my_data=%0h en=%0b", my_data, en);
	#0;
        $display("my_data=%0h en=%0b", my_data, en);
    end
endmodule
