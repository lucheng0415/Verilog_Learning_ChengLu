module mem (
    input             clk,
    input             rstn,
    input      [1:0]  addr,
    input             wr,
    input             sel,
    input      [15:0] wdata,
    output     [15:0] rdata
);

reg [15:0] register [0:3];
integer i;

always @(posedge clk) begin
    if (!rstn) begin
        for (i = 0; i < 4; i = i + 1) begin
            register[i] <= 0;
        end
    end else begin          // else begin
        if (sel & wr) begin //   if begin
            register[addr] <= wdata;
        end                 //   if end
    end                     // else end
end                         // always end

assign rdata = (sel & ~wr) ? register[addr] : 16'h0;

endmodule