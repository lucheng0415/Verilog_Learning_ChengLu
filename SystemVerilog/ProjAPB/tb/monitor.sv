class apb_monitor;
    virtual apb_if.slave vif;
    mailbox mon2scb;

    function new(virtual apb_if.slave vif, mailbox mon2scb);
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        forever begin
            // Wait for transaction
            @(posedge vif.PCLK);
            if (vif.PSEL && vif.PENABLE && vif.PREADY) begin
                apb_transaction trans = new();
                trans.addr = vif.PADDR;
                trans.data = vif.PWRITE ? vif.PWDATA : vif.PRDATA;
                trans.write = vif.PWRITE;
                trans.strb = vif.PSTRB;
                mon2scb.put(trans);
            end
        end
    endtask
endclass