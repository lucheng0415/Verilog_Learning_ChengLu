// APB UVM Package
// Contains transaction, sequencer, driver, monitor, agent, scoreboard,
// environment, sequences, and tests for the APB slave DUT.
package apb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // -----------------------------------------------------------------
    // Transaction
    // -----------------------------------------------------------------
    class apb_transaction extends uvm_sequence_item;
        rand bit         pwrite;       // 1 = write, 0 = read
        rand bit [31:0]  paddr;
        rand bit [31:0]  pwdata;
        rand bit [3:0]   pstrb;
             bit [31:0]  prdata;
             bit         pslverr;

        // Default constraint: address bits[4:2] index 8 registers (0..7),
        // bits[1:0] = 0 (word aligned), upper bits zero.
        constraint c_addr_default {
            paddr[1:0]   == 2'b00;
            paddr[31:5]  == 27'b0;
        }
        constraint c_strb_default {
            soft pstrb == 4'b1111;
        }

        `uvm_object_utils_begin(apb_transaction)
            `uvm_field_int(pwrite,  UVM_ALL_ON)
            `uvm_field_int(paddr,   UVM_ALL_ON)
            `uvm_field_int(pwdata,  UVM_ALL_ON)
            `uvm_field_int(pstrb,   UVM_ALL_ON)
            `uvm_field_int(prdata,  UVM_ALL_ON)
            `uvm_field_int(pslverr, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name = "apb_transaction");
            super.new(name);
        endfunction

        virtual function string convert2string();
            return $sformatf("%s addr=0x%08h data=0x%08h strb=0x%01h rdata=0x%08h err=%0b",
                             pwrite ? "WRITE" : "READ ",
                             paddr, pwdata, pstrb, prdata, pslverr);
        endfunction
    endclass

    // -----------------------------------------------------------------
    // Sequencer
    // -----------------------------------------------------------------
    typedef uvm_sequencer #(apb_transaction) apb_sequencer;

    // -----------------------------------------------------------------
    // Driver
    // -----------------------------------------------------------------
    class apb_driver extends uvm_driver #(apb_transaction);
        `uvm_component_utils(apb_driver)

        virtual apb_if vif;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
                `uvm_fatal("DRV", "Virtual interface not set for driver")
        endfunction

        task run_phase(uvm_phase phase);
            // Idle state
            vif.drv_cb.PSEL    <= 1'b0;
            vif.drv_cb.PENABLE <= 1'b0;
            vif.drv_cb.PWRITE  <= 1'b0;
            vif.drv_cb.PADDR   <= 32'h0;
            vif.drv_cb.PWDATA  <= 32'h0;
            vif.drv_cb.PSTRB   <= 4'b1111;

            // Wait out reset
            @(posedge vif.PRESETn);
            @(vif.drv_cb);

            forever begin
                seq_item_port.get_next_item(req);
                drive_transfer(req);
                seq_item_port.item_done();
            end
        endtask

        task drive_transfer(apb_transaction tr);
            // Setup phase
            vif.drv_cb.PSEL    <= 1'b1;
            vif.drv_cb.PENABLE <= 1'b0;
            vif.drv_cb.PWRITE  <= tr.pwrite;
            vif.drv_cb.PADDR   <= tr.paddr;
            vif.drv_cb.PWDATA  <= tr.pwdata;
            vif.drv_cb.PSTRB   <= tr.pstrb;
            @(vif.drv_cb);

            // Access phase
            vif.drv_cb.PENABLE <= 1'b1;
            @(vif.drv_cb);

            // Wait for PREADY
            while (vif.drv_cb.PREADY !== 1'b1) begin
                @(vif.drv_cb);
            end

            // Sample read data and error response
            tr.prdata  = vif.drv_cb.PRDATA;
            tr.pslverr = vif.drv_cb.PSLVERR;

            // Return to idle
            vif.drv_cb.PSEL    <= 1'b0;
            vif.drv_cb.PENABLE <= 1'b0;
            @(vif.drv_cb);

            `uvm_info("DRV", tr.convert2string(), UVM_HIGH)
        endtask
    endclass

    // -----------------------------------------------------------------
    // Monitor
    // -----------------------------------------------------------------
    class apb_monitor extends uvm_monitor;
        `uvm_component_utils(apb_monitor)

        virtual apb_if vif;
        uvm_analysis_port #(apb_transaction) ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
                `uvm_fatal("MON", "Virtual interface not set for monitor")
        endfunction

        task run_phase(uvm_phase phase);
            apb_transaction tr;
            forever begin
                // Wait for setup phase (PSEL && !PENABLE)
                @(vif.mon_cb);
                if (vif.mon_cb.PSEL === 1'b1 && vif.mon_cb.PENABLE === 1'b0) begin
                    tr = apb_transaction::type_id::create("tr");
                    tr.paddr  = vif.mon_cb.PADDR;
                    tr.pwrite = vif.mon_cb.PWRITE;
                    tr.pwdata = vif.mon_cb.PWDATA;
                    tr.pstrb  = vif.mon_cb.PSTRB;

                    // Wait for access phase with PREADY
                    do begin
                        @(vif.mon_cb);
                    end while (!(vif.mon_cb.PSEL === 1'b1 &&
                                 vif.mon_cb.PENABLE === 1'b1 &&
                                 vif.mon_cb.PREADY === 1'b1));

                    tr.prdata  = vif.mon_cb.PRDATA;
                    tr.pslverr = vif.mon_cb.PSLVERR;

                    `uvm_info("MON", tr.convert2string(), UVM_HIGH)
                    ap.write(tr);
                end
            end
        endtask
    endclass

    // -----------------------------------------------------------------
    // Agent
    // -----------------------------------------------------------------
    class apb_agent extends uvm_agent;
        `uvm_component_utils(apb_agent)

        apb_driver    driver;
        apb_sequencer sequencer;
        apb_monitor   monitor;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            monitor = apb_monitor::type_id::create("monitor", this);
            if (get_is_active() == UVM_ACTIVE) begin
                driver    = apb_driver::type_id::create("driver", this);
                sequencer = apb_sequencer::type_id::create("sequencer", this);
            end
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            if (get_is_active() == UVM_ACTIVE) begin
                driver.seq_item_port.connect(sequencer.seq_item_export);
            end
        endfunction
    endclass

    // -----------------------------------------------------------------
    // Scoreboard — reference model of the 8x32 register file
    // -----------------------------------------------------------------
    class apb_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(apb_scoreboard)

        uvm_analysis_imp #(apb_transaction, apb_scoreboard) ap_imp;

        bit [31:0] ref_regs [0:7];
        int        num_writes;
        int        num_reads;
        int        num_errors;
        int        num_mismatches;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap_imp = new("ap_imp", this);
            foreach (ref_regs[i]) ref_regs[i] = 32'h0;
        endfunction

        virtual function void write(apb_transaction tr);
            bit [2:0]  idx     = tr.paddr[4:2];
            bit        in_rng  = (tr.paddr[31:5] == 27'h0) && (tr.paddr[1:0] == 2'h0);
            bit [31:0] exp_data;

            if (tr.pwrite) begin
                num_writes++;
                if (!in_rng) begin
                    // Out-of-range write: expect PSLVERR
                    if (!tr.pslverr) begin
                        num_mismatches++;
                        `uvm_error("SCB", $sformatf("Expected PSLVERR on OOR write addr=0x%08h", tr.paddr))
                    end else begin
                        num_errors++;
                    end
                end else begin
                    // Apply byte-strobe model to reference
                    for (int b = 0; b < 4; b++) begin
                        if (tr.pstrb[b])
                            ref_regs[idx][b*8 +: 8] = tr.pwdata[b*8 +: 8];
                    end
                    if (tr.pslverr) begin
                        num_mismatches++;
                        `uvm_error("SCB", $sformatf("Unexpected PSLVERR on in-range write addr=0x%08h", tr.paddr))
                    end
                end
            end else begin
                num_reads++;
                if (!in_rng) begin
                    if (!tr.pslverr) begin
                        num_mismatches++;
                        `uvm_error("SCB", $sformatf("Expected PSLVERR on OOR read addr=0x%08h", tr.paddr))
                    end else begin
                        num_errors++;
                    end
                end else begin
                    exp_data = ref_regs[idx];
                    if (tr.prdata !== exp_data) begin
                        num_mismatches++;
                        `uvm_error("SCB", $sformatf("Read mismatch addr=0x%08h exp=0x%08h got=0x%08h",
                                                    tr.paddr, exp_data, tr.prdata))
                    end else begin
                        `uvm_info("SCB", $sformatf("Read match  addr=0x%08h data=0x%08h",
                                                    tr.paddr, tr.prdata), UVM_HIGH)
                    end
                end
            end
        endfunction

        function void report_phase(uvm_phase phase);
            `uvm_info("SCB", $sformatf(
                "Scoreboard summary: writes=%0d reads=%0d expected_errors=%0d mismatches=%0d",
                num_writes, num_reads, num_errors, num_mismatches), UVM_LOW)
            if (num_mismatches != 0)
                `uvm_error("SCB", $sformatf("TEST FAILED with %0d mismatches", num_mismatches))
            else
                `uvm_info("SCB", "TEST PASSED — no mismatches", UVM_LOW)
        endfunction
    endclass

    // -----------------------------------------------------------------
    // Environment
    // -----------------------------------------------------------------
    class apb_env extends uvm_env;
        `uvm_component_utils(apb_env)

        apb_agent      agent;
        apb_scoreboard scb;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            agent = apb_agent::type_id::create("agent", this);
            scb   = apb_scoreboard::type_id::create("scb", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agent.monitor.ap.connect(scb.ap_imp);
        endfunction
    endclass

    // -----------------------------------------------------------------
    // Sequences
    // -----------------------------------------------------------------

    // Base sequence — provides helpers
    class apb_base_seq extends uvm_sequence #(apb_transaction);
        `uvm_object_utils(apb_base_seq)

        function new(string name = "apb_base_seq");
            super.new(name);
        endfunction

        task do_write(bit [31:0] addr, bit [31:0] data, bit [3:0] strb = 4'b1111);
            apb_transaction tr = apb_transaction::type_id::create("tr");
            start_item(tr);
            tr.pwrite = 1'b1;
            tr.paddr  = addr;
            tr.pwdata = data;
            tr.pstrb  = strb;
            finish_item(tr);
        endtask

        task do_read(bit [31:0] addr);
            apb_transaction tr = apb_transaction::type_id::create("tr");
            start_item(tr);
            tr.pwrite = 1'b0;
            tr.paddr  = addr;
            tr.pstrb  = 4'b1111;
            finish_item(tr);
        endtask
    endclass

    // Sequence: write all 8 registers with unique patterns
    class apb_write_all_seq extends apb_base_seq;
        `uvm_object_utils(apb_write_all_seq)

        function new(string name = "apb_write_all_seq");
            super.new(name);
        endfunction

        task body();
            `uvm_info("SEQ", "Running apb_write_all_seq", UVM_LOW)
            for (int i = 0; i < 8; i++) begin
                do_write(.addr(i * 4), .data(32'hA0000000 | i));
            end
        endtask
    endclass

    // Sequence: read all 8 registers
    class apb_read_all_seq extends apb_base_seq;
        `uvm_object_utils(apb_read_all_seq)

        function new(string name = "apb_read_all_seq");
            super.new(name);
        endfunction

        task body();
            `uvm_info("SEQ", "Running apb_read_all_seq", UVM_LOW)
            for (int i = 0; i < 8; i++) begin
                do_read(.addr(i * 4));
            end
        endtask
    endclass

    // Sequence: write then read each register, verify scoreboard match
    class apb_write_read_seq extends apb_base_seq;
        `uvm_object_utils(apb_write_read_seq)

        function new(string name = "apb_write_read_seq");
            super.new(name);
        endfunction

        task body();
            bit [31:0] patterns [8] = '{
                32'hDEAD_BEEF, 32'hCAFE_BABE, 32'h1234_5678, 32'hFEED_FACE,
                32'h0F0F_0F0F, 32'hAAAA_AAAA, 32'h5555_5555, 32'hFFFF_FFFF
            };
            `uvm_info("SEQ", "Running apb_write_read_seq", UVM_LOW)
            for (int i = 0; i < 8; i++) begin
                do_write(.addr(i * 4), .data(patterns[i]));
            end
            for (int i = 0; i < 8; i++) begin
                do_read(.addr(i * 4));
            end
        endtask
    endclass

    // Sequence: byte-strobe coverage — partial writes
    class apb_strobe_seq extends apb_base_seq;
        `uvm_object_utils(apb_strobe_seq)

        function new(string name = "apb_strobe_seq");
            super.new(name);
        endfunction

        task body();
            `uvm_info("SEQ", "Running apb_strobe_seq", UVM_LOW)
            // Seed register 0 with all-ones, then knock out one byte at a time
            do_write(.addr(32'h0), .data(32'hFFFF_FFFF), .strb(4'b1111));
            do_write(.addr(32'h0), .data(32'h0000_0000), .strb(4'b0001));
            do_read (.addr(32'h0));
            do_write(.addr(32'h0), .data(32'h0000_0000), .strb(4'b0010));
            do_read (.addr(32'h0));
            do_write(.addr(32'h0), .data(32'h0000_0000), .strb(4'b0100));
            do_read (.addr(32'h0));
            do_write(.addr(32'h0), .data(32'h0000_0000), .strb(4'b1000));
            do_read (.addr(32'h0));
            // Now write a fresh pattern with each strobe individually
            do_write(.addr(32'h4), .data(32'h1122_3344), .strb(4'b0001));
            do_write(.addr(32'h4), .data(32'h1122_3344), .strb(4'b0010));
            do_write(.addr(32'h4), .data(32'h1122_3344), .strb(4'b0100));
            do_write(.addr(32'h4), .data(32'h1122_3344), .strb(4'b1000));
            do_read (.addr(32'h4));
        endtask
    endclass

    // Sequence: out-of-range addresses expecting PSLVERR
    class apb_error_seq extends apb_base_seq;
        `uvm_object_utils(apb_error_seq)

        function new(string name = "apb_error_seq");
            super.new(name);
        endfunction

        task body();
            `uvm_info("SEQ", "Running apb_error_seq", UVM_LOW)
            // Addresses with bit[5]=1 land outside the 8x4-byte register file
            do_write(.addr(32'h20),         .data(32'hBADC_0DE0));
            do_read (.addr(32'h20));
            do_write(.addr(32'h100),        .data(32'hBADC_0DE1));
            do_read (.addr(32'h100));
            do_read (.addr(32'hFFFF_FFE0));
        endtask
    endclass

    // Sequence: randomized transactions within the 8-register window
    class apb_random_seq extends apb_base_seq;
        `uvm_object_utils(apb_random_seq)
        rand int unsigned num_txn;
        constraint c_num { num_txn inside {[20:50]}; }

        function new(string name = "apb_random_seq");
            super.new(name);
        endfunction

        task body();
            apb_transaction tr;
            `uvm_info("SEQ", $sformatf("Running apb_random_seq (%0d txns)", num_txn), UVM_LOW)
            for (int i = 0; i < num_txn; i++) begin
                tr = apb_transaction::type_id::create("tr");
                start_item(tr);
                if (!tr.randomize())
                    `uvm_error("SEQ", "Randomization failed")
                finish_item(tr);
            end
        endtask
    endclass

    // -----------------------------------------------------------------
    // Tests
    // -----------------------------------------------------------------
    class apb_base_test extends uvm_test;
        `uvm_component_utils(apb_base_test)

        apb_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = apb_env::type_id::create("env", this);
        endfunction

        function void end_of_elaboration_phase(uvm_phase phase);
            uvm_top.print_topology();
        endfunction

        task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 100ns);
            `uvm_info(get_type_name(), "Base test — override run_phase in derived test", UVM_LOW)
            phase.drop_objection(this);
        endtask
    endclass

    class apb_write_read_test extends apb_base_test;
        `uvm_component_utils(apb_write_read_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        task run_phase(uvm_phase phase);
            apb_write_read_seq seq;
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 100ns);
            seq = apb_write_read_seq::type_id::create("seq");
            seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    class apb_write_all_test extends apb_base_test;
        `uvm_component_utils(apb_write_all_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        task run_phase(uvm_phase phase);
            apb_write_all_seq wseq;
            apb_read_all_seq  rseq;
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 100ns);
            wseq = apb_write_all_seq::type_id::create("wseq");
            rseq = apb_read_all_seq::type_id::create("rseq");
            wseq.start(env.agent.sequencer);
            rseq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    class apb_strobe_test extends apb_base_test;
        `uvm_component_utils(apb_strobe_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        task run_phase(uvm_phase phase);
            apb_strobe_seq seq;
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 100ns);
            seq = apb_strobe_seq::type_id::create("seq");
            seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    class apb_error_test extends apb_base_test;
        `uvm_component_utils(apb_error_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        task run_phase(uvm_phase phase);
            apb_error_seq seq;
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 100ns);
            seq = apb_error_seq::type_id::create("seq");
            seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    class apb_random_test extends apb_base_test;
        `uvm_component_utils(apb_random_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        task run_phase(uvm_phase phase);
            apb_random_seq seq;
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 100ns);
            seq = apb_random_seq::type_id::create("seq");
            if (!seq.randomize())
                `uvm_error(get_type_name(), "Seq randomize failed")
            seq.start(env.agent.sequencer);
            phase.drop_objection(this);
        endtask
    endclass

    // Regression: run the full battery of sequences in one test
    class apb_regression_test extends apb_base_test;
        `uvm_component_utils(apb_regression_test)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        task run_phase(uvm_phase phase);
            apb_write_read_seq wr_seq;
            apb_strobe_seq     st_seq;
            apb_error_seq      er_seq;
            apb_random_seq     rn_seq;
            phase.raise_objection(this);
            phase.phase_done.set_drain_time(this, 200ns);

            wr_seq = apb_write_read_seq::type_id::create("wr_seq");
            st_seq = apb_strobe_seq    ::type_id::create("st_seq");
            er_seq = apb_error_seq     ::type_id::create("er_seq");
            rn_seq = apb_random_seq    ::type_id::create("rn_seq");

            wr_seq.start(env.agent.sequencer);
            st_seq.start(env.agent.sequencer);
            er_seq.start(env.agent.sequencer);
            if (!rn_seq.randomize())
                `uvm_error(get_type_name(), "rn_seq randomize failed")
            rn_seq.start(env.agent.sequencer);

            phase.drop_objection(this);
        endtask
    endclass

endpackage
