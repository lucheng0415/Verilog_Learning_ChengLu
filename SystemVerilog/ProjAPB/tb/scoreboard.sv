class apb_scoreboard;
    mailbox mon2scb;
    logic [31:0] expected_mem [logic [31:0]];  // Associative array for expected memory

    function new(mailbox mon2scb);
        this.mon2scb = mon2scb;
    endfunction

    task run();
        apb_transaction trans;
        forever begin
            mon2scb.get(trans);
            if (trans.write) begin
                // For write, update expected memory
                // Initialize entry if it doesn't exist
                if (!expected_mem.exists(trans.addr)) begin
                    expected_mem[trans.addr] = 32'h0;
                end
                for (int i = 0; i < 4; i++) begin
                    if (trans.strb[i]) begin
                        expected_mem[trans.addr][i*8 +: 8] = trans.data[i*8 +: 8];
                    end
                end
                $display("Write recorded: addr=0x%h, data=0x%h, strb=0x%h, expected=0x%h", trans.addr, trans.data, trans.strb, expected_mem[trans.addr]);
            end else begin
                // For read, check against expected
                if (expected_mem.exists(trans.addr)) begin
                    if (trans.data == expected_mem[trans.addr]) begin
                        $display("✓ Read match: addr=0x%h, data=0x%h", trans.addr, trans.data);
                    end else begin
                        $display("✗ Read MISMATCH: addr=0x%h, expected=0x%h, actual=0x%h", trans.addr, expected_mem[trans.addr], trans.data);
                    end
                end else begin
                    // Unwritten address - should read as 0x0
                    if (trans.data == 32'h0) begin
                        $display("✓ Read match (unwritten): addr=0x%h, data=0x%h", trans.addr, trans.data);
                    end else begin
                        $display("✗ Read MISMATCH (unwritten): addr=0x%h, expected=0x%h, actual=0x%h", trans.addr, 32'h0, trans.data);
                    end
                end
            end
        end
    endtask
endclass