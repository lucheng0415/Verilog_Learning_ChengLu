// =============================================================
//  fifo_uvm_tb.sv — 完整 UVM 验证环境（面向同步 FIFO）
//
//  层次结构：
//    uvm_test
//      └─ fifo_env
//           ├─ fifo_agent (write)
//           │    ├─ fifo_driver
//           │    ├─ fifo_monitor (write side)
//           │    └─ fifo_sequencer
//           ├─ fifo_agent (read)
//           │    ├─ fifo_driver  (read)
//           │    ├─ fifo_monitor (read side)
//           │    └─ fifo_sequencer
//           └─ fifo_scoreboard
//
//  验证点：
//    • 正常写入 / 读取数据完整性
//    • FIFO 满时写使能无效（数据不丢不覆盖）
//    • FIFO 空时读使能无效
//    • 同时读写（back-to-back）
//    • 随机激励 + 功能覆盖率
// =============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

// -----------------------------------------------------------
// 0. Interface
// -----------------------------------------------------------
interface fifo_if #(
    parameter DATA_WIDTH = 8
)(input logic clk, input logic rst_n);

    logic                  wr_en;
    logic [DATA_WIDTH-1:0] wr_data;
    logic                  full;

    logic                  rd_en;
    logic [DATA_WIDTH-1:0] rd_data;
    logic                  empty;

    // 时序断言：写满不能继续写
    property no_write_when_full;
        @(posedge clk) (full && wr_en) |=> (full);  // 满时写后仍然满（数据没溢出）
    endproperty
    assert property (no_write_when_full)
        else `uvm_error("FIFO_ASSERT", "Wrote to full FIFO — overflow!");

    // 时序断言：读空不能继续读
    property no_read_when_empty;
        @(posedge clk) disable iff (!rst_n)
        (empty && rd_en) |=> (empty);
    endproperty
    assert property (no_read_when_empty)
        else `uvm_error("FIFO_ASSERT", "Read from empty FIFO — underflow!");

endinterface

// -----------------------------------------------------------
// 1. Transaction（sequence_item）
// -----------------------------------------------------------
class fifo_transaction extends uvm_sequence_item;
    `uvm_object_utils_begin(fifo_transaction)
        `uvm_field_int(wr_en,   UVM_ALL_ON)
        `uvm_field_int(wr_data, UVM_ALL_ON)
        `uvm_field_int(rd_en,   UVM_ALL_ON)
        `uvm_field_int(rd_data, UVM_ALL_ON)
        `uvm_field_int(full,    UVM_ALL_ON)
        `uvm_field_int(empty,   UVM_ALL_ON)
    `uvm_object_utils_end

    rand logic        wr_en;
    rand logic [7:0]  wr_data;
    rand logic        rd_en;
         logic [7:0]  rd_data;   // DUT 输出，不随机化
         logic        full;
         logic        empty;

    // 约束：不在空时读，不在满时写（可在测试中覆盖）
    constraint c_safe {
        if (full)  wr_en == 0;
        if (empty) rd_en == 0;
    }

    // 同时读写的约束（覆盖率 corner）
    constraint c_rw_dist {
        wr_en dist { 1 := 70, 0 := 30 };
        rd_en dist { 1 := 50, 0 := 50 };
    }

    function new(string name = "fifo_transaction");
        super.new(name);
    endfunction
endclass

// -----------------------------------------------------------
// 2. Sequences
// -----------------------------------------------------------
// 基础：随机读写
class fifo_rand_seq extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(fifo_rand_seq)

    int unsigned num_trans = 200;

    function new(string name = "fifo_rand_seq");
        super.new(name);
    endfunction

    task body();
        fifo_transaction tr;
        repeat (num_trans) begin
            tr = fifo_transaction::type_id::create("tr");
            start_item(tr);
            if (!tr.randomize())
                `uvm_fatal("RAND", "Randomization failed")
            finish_item(tr);
        end
    endtask
endclass

// 压力：写满后读空
class fifo_fill_drain_seq extends uvm_sequence #(fifo_transaction);
    `uvm_object_utils(fifo_fill_drain_seq)

    function new(string name = "fifo_fill_drain_seq");
        super.new(name);
    endfunction

    task body();
        fifo_transaction tr;
        // 写 32 次（超过 FIFO 深度，测满标志）
        repeat (32) begin
            tr = fifo_transaction::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize() with { wr_en == 1; rd_en == 0; });
            finish_item(tr);
        end
        // 读 32 次
        repeat (32) begin
            tr = fifo_transaction::type_id::create("tr");
            start_item(tr);
            assert(tr.randomize() with { wr_en == 0; rd_en == 1; });
            finish_item(tr);
        end
    endtask
endclass

// -----------------------------------------------------------
// 3. Driver
// -----------------------------------------------------------
class fifo_driver extends uvm_driver #(fifo_transaction);
    `uvm_component_utils(fifo_driver)

    virtual fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG", "fifo_if not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_transaction tr;
        // 复位等待
        @(posedge vif.clk iff vif.rst_n);
        forever begin
            seq_item_port.get_next_item(tr);
            drive_item(tr);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(fifo_transaction tr);
        @(posedge vif.clk);
        #1; // 非零延迟，对齐时序
        vif.wr_en   <= tr.wr_en;
        vif.wr_data <= tr.wr_data;
        vif.rd_en   <= tr.rd_en;
        // 回采 DUT 状态
        @(posedge vif.clk);
        tr.full   = vif.full;
        tr.empty  = vif.empty;
        tr.rd_data = vif.rd_data;
    endtask
endclass

// -----------------------------------------------------------
// 4. Monitor
// -----------------------------------------------------------
class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)

    virtual fifo_if                 vif;
    uvm_analysis_port #(fifo_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG", "fifo_if not found")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_transaction tr;
        forever begin
            @(posedge vif.clk);
            #1;
            tr = fifo_transaction::type_id::create("tr");
            tr.wr_en   = vif.wr_en;
            tr.wr_data = vif.wr_data;
            tr.rd_en   = vif.rd_en;
            tr.rd_data = vif.rd_data;
            tr.full    = vif.full;
            tr.empty   = vif.empty;
            ap.write(tr);
        end
    endtask
endclass

// -----------------------------------------------------------
// 5. Scoreboard（参考模型：一个 SystemVerilog queue）
// -----------------------------------------------------------
class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)

    uvm_analysis_imp #(fifo_transaction, fifo_scoreboard) analysis_export;

    // 黄金参考模型
    logic [7:0] ref_fifo [$];
    int         pass_cnt, fail_cnt;

    // 功能覆盖率组
    covergroup fifo_cg;
        cp_full  : coverpoint (ref_fifo.size() == 16);  // 满
        cp_empty : coverpoint (ref_fifo.size() == 0);   // 空
        cp_wr    : coverpoint (1'b1);                   // 写操作
        cp_rd    : coverpoint (1'b1);                   // 读操作
        cr_rw    : cross cp_wr, cp_rd;                  // 同时读写
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        fifo_cg = new();
        pass_cnt = 0;
        fail_cnt = 0;
    endfunction

    // 写入参考模型并比对
    function void write(fifo_transaction tr);
        logic [7:0] expected;

        // 写操作：DUT 满时丢弃
        if (tr.wr_en && (ref_fifo.size() < 16))
            ref_fifo.push_back(tr.wr_data);

        // 读操作：比对读出数据
        if (tr.rd_en && (ref_fifo.size() > 0)) begin
            expected = ref_fifo.pop_front();
            if (tr.rd_data === expected) begin
                pass_cnt++;
                `uvm_info("SCB", $sformatf("PASS: expected=0x%0h got=0x%0h",
                    expected, tr.rd_data), UVM_HIGH)
            end else begin
                fail_cnt++;
                `uvm_error("SCB", $sformatf("FAIL: expected=0x%0h got=0x%0h",
                    expected, tr.rd_data))
            end
        end

        // 满/空标志比对
        if (tr.full !== (ref_fifo.size() == 16))
            `uvm_error("SCB", $sformatf("Full flag mismatch! DUT=%0b REF=%0b",
                tr.full, ref_fifo.size() == 16))
        if (tr.empty !== (ref_fifo.size() == 0))
            `uvm_error("SCB", $sformatf("Empty flag mismatch! DUT=%0b REF=%0b",
                tr.empty, ref_fifo.size() == 0))

        fifo_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf(
            "\n========= Scoreboard Summary =========\n  PASS: %0d\n  FAIL: %0d\n======================================",
            pass_cnt, fail_cnt), UVM_NONE)
        if (fail_cnt > 0)
            `uvm_error("SCB", "TEST FAILED")
        else
            `uvm_info("SCB", "TEST PASSED", UVM_NONE)
    endfunction
endclass

// -----------------------------------------------------------
// 6. Agent
// -----------------------------------------------------------
class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)

    fifo_driver    drv;
    fifo_monitor   mon;
    uvm_sequencer #(fifo_transaction) seqr;

    uvm_analysis_port #(fifo_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv  = fifo_driver  ::type_id::create("drv",  this);
        mon  = fifo_monitor ::type_id::create("mon",  this);
        seqr = uvm_sequencer#(fifo_transaction)::type_id::create("seqr", this);
        ap   = new("ap", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        mon.ap.connect(ap);
    endfunction
endclass

// -----------------------------------------------------------
// 7. Environment
// -----------------------------------------------------------
class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)

    fifo_agent      agent;
    fifo_scoreboard sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = fifo_agent     ::type_id::create("agent", this);
        sb    = fifo_scoreboard::type_id::create("sb",    this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.ap.connect(sb.analysis_export);
    endfunction
endclass

// -----------------------------------------------------------
// 8. Tests
// -----------------------------------------------------------
// 8a. 随机测试
class fifo_rand_test extends uvm_test;
    `uvm_component_utils(fifo_rand_test)

    fifo_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_rand_seq seq;
        phase.raise_objection(this);
        seq = fifo_rand_seq::type_id::create("seq");
        seq.num_trans = 500;
        seq.start(env.agent.seqr);
        #100;
        phase.drop_objection(this);
    endtask
endclass

// 8b. 压力测试：写满 → 读空
class fifo_stress_test extends uvm_test;
    `uvm_component_utils(fifo_stress_test)

    fifo_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_fill_drain_seq seq;
        phase.raise_objection(this);
        // 多轮 fill-drain
        repeat (5) begin
            seq = fifo_fill_drain_seq::type_id::create("seq");
            seq.start(env.agent.seqr);
        end
        #100;
        phase.drop_objection(this);
    endtask
endclass

// -----------------------------------------------------------
// 9. 顶层 Testbench
// -----------------------------------------------------------
module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    // 时钟 & 复位
    logic clk, rst_n;
    initial clk = 0;
    always #5 clk = ~clk;   // 100 MHz

    initial begin
        rst_n = 0;
        repeat (4) @(posedge clk);
        rst_n = 1;
    end

    // Interface 实例化
    fifo_if #(.DATA_WIDTH(DATA_WIDTH)) dut_if(.clk(clk), .rst_n(rst_n));

    // DUT：同步 FIFO
    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .wr_en     (dut_if.wr_en),
        .wr_data   (dut_if.wr_data),
        .full      (dut_if.full),
        .rd_en     (dut_if.rd_en),
        .rd_data   (dut_if.rd_data),
        .empty     (dut_if.empty),
        .fifo_count()
    );

    // 注册 interface
    initial begin
        uvm_config_db #(virtual fifo_if)::set(null, "uvm_test_top.*", "vif", dut_if);
    end

    // 启动 UVM
    initial begin
        // 通过 +UVM_TESTNAME=<test_name> 在命令行选择测试
        // 例：vsim -do "vsim tb_top +UVM_TESTNAME=fifo_stress_test"
        run_test();
    end

    // 波形
    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
