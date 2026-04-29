module tb;
    // Clock and reset
    logic PCLK;
    logic PRESETn;

    // Interface
    apb_if apb_bus(.PCLK(PCLK), .PRESETn(PRESETn));

    // DUT
    top dut(.apb_bus(apb_bus));

    // Test module
    test t(.master_vif(apb_bus.master), .slave_vif(apb_bus.slave));

    // Clock generation
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end

    // Reset
    initial begin
        PRESETn = 0;
        #20 PRESETn = 1;
    end
endmodule