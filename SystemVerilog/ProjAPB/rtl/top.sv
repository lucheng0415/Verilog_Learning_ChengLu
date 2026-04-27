module top(apb_if apb_bus);
    // Instantiate master
    apb_master master(.apb(apb_bus.master));

    // Instantiate slave
    apb_slave slave(.apb(apb_bus.slave));
endmodule