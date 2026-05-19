// APB Slave (Verilog rewrite of apb_slave.sv)
// 8 x 32-bit register file with byte-strobe writes.
module apb_slave (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    output reg         PREADY,
    output reg         PSLVERR,
    input  wire [3:0]  PSTRB
);

    reg [31:0] registers [0:7];
    integer    i;
    integer    j;

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            registers[i] = 32'h0;
        end
    end

    // Combinational response: zero wait state, read mux, error flag
    always @(*) begin
        PREADY  = 1'b1;
        PSLVERR = 1'b0;
        PRDATA  = 32'h0;

        if (PSEL && PENABLE) begin
            if (PWRITE) begin
                // Write address bounds check (PADDR[4:2] is 3 bits => always in range)
                if (PADDR[4:2] >= 4'd8) begin
                    PSLVERR = 1'b1;
                end
            end else begin
                // Read mux
                if (PADDR[4:2] < 4'd8) begin
                    PRDATA = registers[PADDR[4:2]];
                end else begin
                    PSLVERR = 1'b1;
                end
            end
        end
    end

    // Synchronous write with byte strobes, async active-low reset
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            for (j = 0; j < 8; j = j + 1) begin
                registers[j] <= 32'h0;
            end
        end else if (PSEL && PENABLE && PWRITE && PREADY) begin
            if (PADDR[4:2] < 4'd8) begin
                for (j = 0; j < 4; j = j + 1) begin
                    if (PSTRB[j]) begin
                        registers[PADDR[4:2]][j*8 +: 8] <= PWDATA[j*8 +: 8];
                    end
                end
            end
        end
    end
endmodule
