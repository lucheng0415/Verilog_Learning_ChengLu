// Top-level UVM testbench
// - Instantiates the Verilog apb_slave (DUT)
// - Drives APB signals through apb_if from the UVM driver
// - Generates clock and reset
`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    import apb_pkg::*;
    `include "uvm_macros.svh"

    // Clock & reset
    logic PCLK;
    logic PRESETn;

    initial PCLK = 1'b0;
    always #5 PCLK = ~PCLK;  // 100 MHz

    initial begin
        PRESETn = 1'b0;
        repeat (5) @(posedge PCLK);
        PRESETn = 1'b1;
    end

    // Interface
    apb_if vif (.PCLK(PCLK), .PRESETn(PRESETn));

    // DUT: APB slave (Verilog)
    apb_slave dut (
        .PCLK    (vif.PCLK),
        .PRESETn (vif.PRESETn),
        .PADDR   (vif.PADDR),
        .PWDATA  (vif.PWDATA),
        .PRDATA  (vif.PRDATA),
        .PSEL    (vif.PSEL),
        .PENABLE (vif.PENABLE),
        .PWRITE  (vif.PWRITE),
        .PREADY  (vif.PREADY),
        .PSLVERR (vif.PSLVERR),
        .PSTRB   (vif.PSTRB)
    );

    // Waveform dump (optional, controlled by +dumpvcd)
    initial begin
        if ($test$plusargs("dumpvcd")) begin
            $dumpfile("tb_top.vcd");
            $dumpvars(0, tb_top);
        end
    end

    // Hand the interface to UVM and start the test
    initial begin
        uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.agent.*", "vif", vif);
        run_test();
    end

    // Watchdog
    initial begin
        #100us;
        `uvm_fatal("TB_TOP", "Simulation watchdog timeout — test hung")
    end
endmodule
