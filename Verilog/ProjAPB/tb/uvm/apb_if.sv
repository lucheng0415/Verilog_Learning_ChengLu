// APB Interface for UVM testbench
// Bundles APB signals; used by driver/monitor to connect to the Verilog DUT.
interface apb_if (input logic PCLK, input logic PRESETn);
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic        PREADY;
    logic        PSLVERR;
    logic [3:0]  PSTRB;

    clocking drv_cb @(posedge PCLK);
        default input #1step output #1;
        output PADDR, PWDATA, PSEL, PENABLE, PWRITE, PSTRB;
        input  PRDATA, PREADY, PSLVERR;
    endclocking

    clocking mon_cb @(posedge PCLK);
        default input #1step;
        input PADDR, PWDATA, PRDATA, PSEL, PENABLE, PWRITE, PREADY, PSLVERR, PSTRB;
    endclocking

    modport DRV (clocking drv_cb, input PCLK, PRESETn);
    modport MON (clocking mon_cb, input PCLK, PRESETn);
endinterface
