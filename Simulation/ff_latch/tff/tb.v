module tb;

reg clk;
reg rstn;
reg t;
wire q;   // ✅ 补上

tff u0 (
    .clk(clk),
    .rstn(rstn),
    .t(t),
    .q(q)
);

// clock
always #5 clk = ~clk;

// waveform
initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
end

// stimulus
initial begin
    clk = 0;
    rstn = 0;
    t = 0;

    $monitor ("T=%0t rstn=%0b t=%0b q=%0b", $time, rstn, t, q);

    #10 rstn = 1;   // ✅ 正确复位释放

    #10 t = 1;
    #20 t = 0;
    #30 t = 1;
    #40 t = 0;

    #20;
    $finish;
end

endmodule