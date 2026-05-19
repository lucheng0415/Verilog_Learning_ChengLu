# ProjAPB UVM Testbench

UVM-1.2 testbench for the Verilog APB slave under `../../src/rtl/apb_slave.v`.

## Files

| File           | Role                                                              |
|----------------|-------------------------------------------------------------------|
| `apb_if.sv`    | APB SystemVerilog interface, with `DRV` and `MON` modports.       |
| `apb_pkg.sv`   | UVM transaction, driver, monitor, agent, env, scoreboard, tests.  |
| `tb_top.sv`    | Top: clock/reset, DUT instance, interface wiring, `run_test()`.   |
| `Makefile`     | VCS / Questa / Xcelium build & run targets.                       |

## Architecture

```
      +---------- apb_pkg ----------+
      |                             |
   +--+---+    +----+    +-------+  |
   | seq  |--->|sqr |--->|driver |--+----.
   +------+    +----+    +-------+  |    | drv_cb
                                    |    v
                                +---+----+-------+
                                |  apb_if (DRV) |
                                +-----+----------+
                                      |
                            +---------v----------+
                            |  DUT: apb_slave.v |
                            +---------+----------+
                                      |
                                +-----v----------+
                                |  apb_if (MON) |
                                +-----+----------+
                                      |
                                  +---v----+    +------------+
                                  |monitor |--->|scoreboard  |
                                  +--------+    +------------+
```

## Test cases

| Test                  | Sequence(s)                                | What it checks                                  |
|-----------------------|--------------------------------------------|-------------------------------------------------|
| `apb_write_read_test` | `apb_write_read_seq`                       | Each register holds the byte pattern written.   |
| `apb_write_all_test`  | `apb_write_all_seq` → `apb_read_all_seq`   | Full-RF write-then-read.                        |
| `apb_strobe_test`     | `apb_strobe_seq`                           | Byte strobes mask individual lanes correctly.   |
| `apb_error_test`      | `apb_error_seq`                            | OOR addresses produce `PSLVERR`.                |
| `apb_random_test`     | `apb_random_seq` (20–50 txns, randomised)  | Stress + scoreboard parity under random stim.   |
| `apb_regression_test` | All of the above, back-to-back             | Catches state leakage between sequences.        |

## Running

```bash
# Default test (VCS)
make
# Specific test + seed
make TEST=apb_regression_test SEED=42
# Switch simulator
make SIMULATOR=questa TEST=apb_random_test
# Regression — every test sequentially
make regress
# Cleanup
make clean
```

Add `+dumpvcd` to the run command (or to `RUN_CMD` in the Makefile) to dump
`tb_top.vcd`.

## How the scoreboard works

`apb_scoreboard` maintains an 8-entry `bit [31:0] ref_regs` model.
For every monitored transaction it:

1. Decodes `paddr[4:2]` as the register index and checks the address is in
   range (upper bits zero, word aligned).
2. On a write: applies the same per-byte `PSTRB` update the RTL does.
3. On a read: compares `PRDATA` against `ref_regs[idx]`.
4. On an OOR access: asserts `PSLVERR` is set; flags a mismatch otherwise.

Pass/fail is reported in `report_phase`, with mismatch and error counts.

## Extending

- **New directed test**: derive from `apb_base_test`, instantiate a sequence,
  start it on `env.agent.sequencer`. Register via `uvm_component_utils`.
- **New sequence**: derive from `apb_base_seq`, call `do_write` / `do_read`
  helpers or create raw `apb_transaction`s.
- **Wait-state coverage**: parameterize the slave to inject `PREADY` low for
  N cycles, then verify the driver's wait loop still functions.
- **Functional coverage**: add a `covergroup` in the monitor on
  `{paddr[4:2], pwrite, pstrb}`.
