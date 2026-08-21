# Verilog_Learning_ChengLu

Self-directed RTL design and functional verification work — SystemVerilog/UVM testbenches,
Verilog RTL, simulation exercises, ASIC flow notes, and storage protocol study material.

Maintained by **Cheng Lu** as a structured route from a post-silicon validation and
embedded software background into front-end design verification.

---

## What's here

| Area | Directory | Contents |
|---|---|---|
| **Verification projects** | [`Verilog/ProjAPB`](Verilog/ProjAPB) · [`Verilog/ProjFIFO`](Verilog/ProjFIFO) | Complete UVM environments built against Verilog RTL |
| **Language & exercises** | [`Verilog/`](Verilog) | HDLBits solutions, reusable building blocks, language notes |
| **Simulation practice** | [`Simulation/`](Simulation) | Small designs with testbenches and captured waveforms |
| **ASIC flow** | [`ASIC_Flow/`](ASIC_Flow) | Design flow and abstraction-layer notes |
| **Storage protocols** | [`NVMe/`](NVMe) | NVMe specification study notes and interview question set |

---

## Verification projects

### ProjAPB — AMBA APB master/slave with a UVM testbench

An APB slave with an 8 × 32-bit register file, byte-strobe writes, zero-wait-state
responses and `PSLVERR` on out-of-range access, verified by a UVM-1.2 environment.

The testbench (`apb_pkg.sv`, ~600 lines) implements the full UVM component stack —
transaction, sequencer, driver, monitor, agent, scoreboard, environment, sequence
library and tests — driving the DUT through a SystemVerilog interface with separate
`DRV` and `MON` modports. A Makefile provides VCS, Questa and Xcelium targets.

→ [`Verilog/ProjAPB/README.md`](Verilog/ProjAPB/README.md) ·
[testbench notes](Verilog/ProjAPB/tb/uvm/README.md)

### ProjFIFO — synchronous and asynchronous FIFOs

`sync_fifo.v` and a clock-domain-crossing `async_fifo.v` using Gray-coded pointers
and two-flop synchronisers, with a UVM testbench (`fifo_uvm_tb.sv`) exercising
fill/drain behaviour and the full/empty boundary conditions.

---

## Language and exercises

- **[`Verilog/HDLBitsPractise/`](Verilog/HDLBitsPractise)** — worked HDLBits solutions
  covering shift registers, LFSRs, cellular automata (Rule 90), BCD counters and finite
  state machines. Each file carries the problem statement and reasoning, not just the
  answer. Profile: [HDLBits statistics for CLU34](https://hdlbits.01xz.net/wiki/Special:VlgStats/54A0EB5657B8A7F2)
- **[`Verilog/BasicVerilogCodeBlocks/`](Verilog/BasicVerilogCodeBlocks)** — reusable
  primitives: parameterised flip-flops with synchronous and asynchronous reset, and a
  reset synchroniser (asynchronous assert, synchronous release).
- **[`Verilog/UVMPractise/`](Verilog/UVMPractise)** — minimal driver-only UVM examples
  used to work through the phasing and factory mechanics in isolation.
- **Notes** — [`Verilog.md`](Verilog/Verilog.md),
  [`Verilog_Intro.md`](Verilog/Verilog_Intro.md),
  [`VerilogDataTypes.md`](Verilog/VerilogDataTypes.md)

## Simulation practice

[`Simulation/`](Simulation) holds small designs paired with testbenches — adders,
multiplexers, memories, register vectors, and a set of flip-flop and latch variants
(D latch, DFF with synchronous and asynchronous reset, T flip-flop) — each with its
`.vcd` waveform committed so the results can be inspected without re-running a simulator.

## ASIC flow

[`ASIC_Flow/`](ASIC_Flow) collects notes on the ASIC design flow and on the abstraction
layers between behavioural RTL and the transistor view.

## Storage protocols

[`NVMe/`](NVMe) contains a study reference on the NVMe specification — queue mechanism
and command lifecycle, SQE/CQE formats and status codes, PRP versus SGL addressing,
controller registers and initialisation, Admin and NVM command sets, SMART log fields,
power management, end-to-end data protection, and protocol compliance testing practice —
together with a tiered interview question set.

→ [`NVMe/README.md`](NVMe/README.md)

---

## Tooling

| Purpose | Tools |
|---|---|
| Simulation | Icarus Verilog, VCS, Questa, Xcelium |
| Waveform viewing | GTKWave |
| Methodology | UVM 1.2 |
| Languages | Verilog-2001, SystemVerilog |

Line endings are normalised to LF via [`.gitattributes`](.gitattributes); build products
and waveform-viewer state are excluded in [`.gitignore`](.gitignore).

---

## Background

Five years of post-silicon validation at Intel (camera IP and LTE sub-memory domains,
MIPI CSI-2 characterisation, silicon bring-up and debug), followed by FPGA-based feature
verification and embedded software work. This repository is the practical half of moving
that validation experience toward pre-silicon functional verification.
