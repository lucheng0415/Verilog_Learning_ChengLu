# ProjAPB — APB Master / Slave with UVM Verification

A small AMBA APB design plus a UVM testbench that targets the slave register file.

## Directory layout

```
ProjAPB/
├── README.md              # this file
├── src/
│   └── rtl/
│       ├── apb_master.v   # APB master (procedural, with apb_write / apb_read tasks)
│       ├── apb_slave.v    # APB slave with 8 x 32-bit register file + byte strobes
│       └── top.v          # Wires master + slave together (used for sanity sims)
└── tb/
    └── uvm/
        ├── apb_if.sv      # APB SystemVerilog interface (DRV / MON modports)
        ├── apb_pkg.sv     # UVM package: txn, drv, mon, agt, scb, env, seqs, tests
        ├── tb_top.sv      # Top module: clock/reset, DUT instance, run_test()
        ├── Makefile       # VCS / Questa / Xcelium build & run targets
        └── README.md      # UVM testbench usage notes
```

## RTL summary

### `apb_slave.v`
- 8 × 32-bit register file at word offsets `0x00`, `0x04`, ... `0x1C`.
- Zero-wait-state response: `PREADY` is held high combinationally.
- Byte-strobe writes via `PSTRB[3:0]`.
- `PSLVERR` asserted on out-of-range address (any access with `PADDR[31:5] != 0`
  or with `PADDR[1:0] != 0`).

### `apb_master.v`
- Provides procedural `apb_write(addr, data, strb)` and `apb_read(addr, data)` tasks.
- Useful for directed sanity sims at the gate of `top.v`.
- **Not** used by the UVM testbench — the UVM driver acts as the master.

## UVM testbench

The UVM testbench (`tb/uvm/`) verifies the APB slave. The UVM driver
plays the role of the master, the monitor passively samples the bus, and a
scoreboard maintains a behavioural model of the 8×32 register file with the
same byte-strobe semantics as the RTL.

### Test cases

| Test                       | Purpose                                                                 |
|----------------------------|-------------------------------------------------------------------------|
| `apb_write_read_test`      | Walks 8 unique patterns through all 8 registers, then reads them back.  |
| `apb_write_all_test`       | Writes incrementing pattern to every register, then reads every reg.    |
| `apb_strobe_test`          | Exercises every `PSTRB` bit to verify byte-lane write enables.          |
| `apb_error_test`           | Drives out-of-range addresses and checks that `PSLVERR` asserts.        |
| `apb_random_test`          | 20–50 fully randomised transactions, scored against the reference RF.   |
| `apb_regression_test`      | Runs write/read + strobe + error + random sequences back-to-back.       |

### Running

From `tb/uvm/`:

```bash
make TEST=apb_write_read_test         # default VCS flow
make TEST=apb_regression_test SEED=42
make regress                          # runs every test sequentially
make SIMULATOR=questa   TEST=...      # switch toolchain
make SIMULATOR=xcelium  TEST=...
make clean
```

Pass `+dumpvcd` on the simv command to dump waves (`tb_top.vcd`).

## Design verification flow

1. **Stimulus** — sequences create `apb_transaction` objects and hand them to
   the sequencer.
2. **Driver** — pulls items off the sequencer and toggles the APB bus through
   the setup → access → idle phases, waiting for `PREADY`.
3. **Monitor** — passively reconstructs the same transaction from the bus and
   publishes it on its analysis port.
4. **Scoreboard** — receives monitor transactions, updates its golden
   register file for writes (honoring `PSTRB`), and checks every read against
   the model. Out-of-range accesses are expected to set `PSLVERR`.
5. **Report** — `report_phase` prints a pass/fail summary with mismatch count.

## Roadmap

- Wait-state slave variant + driver back-pressure handling.
- Functional coverage (address × write/read × strobe pattern).
- Constrained-random sequence with weights for OOR vs in-range traffic.
