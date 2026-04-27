program test(apb_if.master master_vif, apb_if.slave slave_vif);
    apb_driver drv;
    apb_monitor mon;
    apb_scoreboard scb;
    mailbox mon2scb;

    initial begin
        mon2scb = new();
        drv = new(master_vif);
        mon = new(slave_vif, mon2scb);
        scb = new(mon2scb);

        // Start monitor and scoreboard
        fork
            mon.run();
            scb.run();
        join_none

        // Wait for reset
        #30;

        // Test cases
        basic_write_read();
        back_to_back();
        random_transactions();
        byte_write();

        #100 $finish;
    end

    task basic_write_read();
        logic [31:0] read_data;
        drv.apb_write(32'h0, 32'h12345678);
        drv.apb_read(32'h0, read_data);
    endtask

    task back_to_back();
        drv.apb_write(32'h4, 32'hAAAAAAAA);
        drv.apb_write(32'h8, 32'hBBBBBBBB);
        logic [31:0] data1, data2;
        drv.apb_read(32'h4, data1);
        drv.apb_read(32'h8, data2);
    endtask

    task random_transactions();
        for (int i = 0; i < 10; i++) begin
            logic [31:0] addr = $random % 32;  // Random address 0-31
            logic [31:0] data = $random;
            drv.apb_write(addr, data);
            logic [31:0] read_data;
            drv.apb_read(addr, read_data);
        end
    endtask

    task byte_write();
        // Write byte 0
        drv.apb_write(32'h10, 32'hFF, 4'b0001);
        // Write byte 1
        drv.apb_write(32'h10, 32'h00FF, 4'b0010);
        logic [31:0] read_data;
        drv.apb_read(32'h10, read_data);
        // Expected: 0x00FF00FF
    endtask
endprogram