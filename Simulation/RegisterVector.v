//Verilog vectors are declared using a size range on the left side of the variable name and these get realized into flops that match
//the size of the variable. In the code shown below, the design module accepts clock, reset and some control signals to read and write
//into the block. It contains a 16-bit storage element called register which simply gets updated during writes and returns the current
//value during reads. The register is written when sel and wr are high on the same clock edge. It returns the current data when sel is
//high and wr is low.

module des (input         clk,
            input         rstn,
            input         wr,
            input         sel,
            input [15:0]  wdata,
            output [15:0] rdata,
			output        flag);

reg iFlag;
reg[15:0] register;
always @ (posedge clk) begin
	iFlag <= ~iFlag;
    if (~rstn) begin
        register <= 0;
		iFlag <= 0;
	end
    else begin
        if (sel & wr) begin
            register <= wdata;
		end
    end
    $display("time=%0t register=%h", $time, register);
end

	assign rdata = (sel & ~wr) ? register : 0;
	assign flag = iFlag;
endmodule