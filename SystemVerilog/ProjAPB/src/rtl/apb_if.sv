interface apb_if(input logic PCLK, input logic PRESETn);
    // APB signals
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic        PREADY;
    logic        PSLVERR;
    logic [3:0]  PSTRB;  // For byte enables

    // Modports
    modport master (
        input  PCLK, PRESETn, PRDATA, PREADY, PSLVERR,
        output PADDR, PWDATA, PSEL, PENABLE, PWRITE, PSTRB
    );

    modport slave (
        input  PCLK, PRESETn, PADDR, PWDATA, PSEL, PENABLE, PWRITE, PSTRB,
        output PRDATA, PREADY, PSLVERR
    );
endinterface