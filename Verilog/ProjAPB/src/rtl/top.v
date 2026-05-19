// Top-level wrapper (Verilog rewrite of top.sv)
// Wires the APB master to the APB slave; no SystemVerilog interface.
module top (
    input wire PCLK,
    input wire PRESETn
);

    wire [31:0] PADDR;
    wire [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire        PSEL;
    wire        PENABLE;
    wire        PWRITE;
    wire        PREADY;
    wire        PSLVERR;
    wire [3:0]  PSTRB;

    apb_master u_master (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR),
        .PSTRB   (PSTRB)
    );

    apb_slave u_slave (
        .PCLK    (PCLK),
        .PRESETn (PRESETn),
        .PADDR   (PADDR),
        .PWDATA  (PWDATA),
        .PRDATA  (PRDATA),
        .PSEL    (PSEL),
        .PENABLE (PENABLE),
        .PWRITE  (PWRITE),
        .PREADY  (PREADY),
        .PSLVERR (PSLVERR),
        .PSTRB   (PSTRB)
    );
endmodule
