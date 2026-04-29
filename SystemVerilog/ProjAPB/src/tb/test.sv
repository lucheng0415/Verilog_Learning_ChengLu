import transaction_sv_unit::*;
import driver_sv_unit::*;
import monitor_sv_unit::*;
import scoreboard_sv_unit::*;

module test(apb_if.master master_vif, apb_if.slave slave_vif);
    apb_driver driver;
    apb_monitor mon;
    apb_scoreboard scb;
    mailbox mon2scb;

    initial begin
        mon2scb = new();
        driver = new(master_vif);
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
        driver.apb_write(32'h0, 32'h12345678);
        driver.apb_read(32'h0, read_data);
    endtask

    task back_to_back();
        logic [31:0] data1, data2;
        driver.apb_write(32'h4, 32'hAAAAAAAA);
        driver.apb_write(32'h8, 32'hBBBBBBBB);
        driver.apb_read(32'h4, data1);
        driver.apb_read(32'h8, data2);
    endtask

    task random_transactions();
        logic [31:0] addr, data, read_data;
        int i;
        for (i = 0; i < 10; i++) begin
            addr = ($random % 8) * 4;  // Random word-aligned address 0,4,8,...,28
            data = $random;
            driver.apb_write(addr, data);
            driver.apb_read(addr, read_data);
        end
    endtask

    task byte_write();
        logic [31:0] read_data;
        // Write byte 0 with 0xFF
        driver.apb_write(32'h10, 32'hFF, 4'b0001);
        // Write byte 1 with 0xFF (data needs byte 1 = 0xFF, so use 0xFF00)
        driver.apb_write(32'h10, 32'hFF00, 4'b0010);
        driver.apb_read(32'h10, read_data);
        // Expected: 0x0000FFFF (byte 0 = 0xFF, byte 1 = 0xFF)
    endtask
endmodule