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
                for (int i = 0; i < 4; i++) begin
                    if (trans.strb[i]) begin
                        expected_mem[trans.addr][i*8 +: 8] = trans.data[i*8 +: 8];
                    end
                end
            end else begin
                // For read, check against expected
                if (expected_mem.exists(trans.addr)) begin
                    if (trans.data == expected_mem[trans.addr]) begin
                        $display("Read match: addr=0x%h, data=0x%h", trans.addr, trans.data);
                    end else begin
                        $display("Read mismatch: addr=0x%h, expected=0x%h, actual=0x%h", trans.addr, expected_mem[trans.addr], trans.data);
                    end
                end else begin
                    if (trans.data == 32'h0) begin
                        $display("Read match (unwritten): addr=0x%h, data=0x%h", trans.addr, trans.data);
                    end else begin
                        $display("Read mismatch (unwritten): addr=0x%h, expected=0x%h, actual=0x%h", trans.addr, 32'h0, trans.data);
                    end
                end
            end
        end
    endtask
endclass