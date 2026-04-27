# APB SystemVerilog Project

This project implements a complete AMBA APB (Advanced Peripheral Bus) system in SystemVerilog, including design and verification components.

## Project Structure

```
ProjAPB/
├── rtl/
│   ├── apb_if.sv       # APB interface with modports
│   ├── apb_master.sv   # APB master module
│   ├── apb_slave.sv    # APB slave with register block
│   └── top.sv          # Top module connecting master and slave
├── tb/
│   ├── tb.sv           # Testbench module
│   ├── test.sv         # Test program with test cases
│   ├── driver.sv       # APB driver class
│   ├── monitor.sv      # APB monitor class
│   ├── scoreboard.sv   # Scoreboard for checking
│   └── transaction.sv  # Transaction class
└── ProjAPB.md          # Project requirements
```

## Features

### Design
- APB Master: Generates read/write transactions following APB protocol
- APB Slave: Implements 8x32-bit register block with byte enable support
- APB Interface: Defines all signals and modports
- Top Module: Connects master and slave via interface

### Verification
- Driver: Drives APB transactions
- Monitor: Observes bus activity
- Scoreboard: Compares expected vs actual data
- Test Cases: Basic read/write, back-to-back, random, byte writes

## Simulation

To run the simulation, use a SystemVerilog simulator like ModelSim, Questa, or VCS.

Example command (assuming ModelSim):
```
vlib work
vlog rtl/*.sv tb/*.sv
vsim -c tb -do "run -all; quit"
```

## Requirements Met
- APB protocol compliance (IDLE -> SETUP -> ACCESS)
- Support for PREADY wait states
- Byte enable using PSTRB
- Register read/write operations
- Comprehensive testbench with self-checking scoreboard