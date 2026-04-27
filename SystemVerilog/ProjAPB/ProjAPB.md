# APB SystemVerilog Project

## 🎯 Project Goal
Generate a complete SystemVerilog project implementing an AMBA APB (Advanced Peripheral Bus) system, including both design and verification components.

---

## 🧱 Design Requirements

### 1. APB Master
- Generate APB transactions (read/write)
- Follow APB protocol:
  - IDLE → SETUP → ACCESS
- Support:
  - Address (`PADDR`)
  - Write data (`PWDATA`)
  - Read data (`PRDATA`)
  - Control signals (`PSEL`, `PENABLE`, `PWRITE`)
- Optional:
  - Support wait states via `PREADY`

---

### 2. APB Slave
- Implement a simple register block (e.g., 4–8 registers)
- Support:
  - Read and write operations
  - Byte enable using `PSTRB` (APB4)
- Correct write condition:PSEL && PENABLE && PWRITE && PREADY
- Return:
- `PRDATA`
- `PREADY`
- Optional `PSLVERR`

---

### 3. APB Interface
- Create a SystemVerilog `interface`
- Include:
- All APB signals
- Modports for master/slave

---

### 4. Top Module
- Instantiate:
- APB master
- APB slave
- Connect via interface

## 🧪 Verification Requirements

### 1. Testbench
- Clock and reset generation
- Instantiate DUT (top module)

---

### 2. Driver
- Generate APB transactions:
- Write
- Read
- Tasks:
- `apb_write(addr, data)`
- `apb_read(addr, data_out)`

---

### 3. Monitor
- Observe APB bus activity
- Capture transactions

---

### 4. Scoreboard
- Compare expected vs actual data
- Check correctness of read/write

---

### 5. Test Cases
Include:
- Basic write/read
- Back-to-back transfers
- Random transactions
- Wait state insertion (`PREADY=0`)
- Byte write using `PSTRB`

---

## 🗂️ Suggested File Structure

apb_project/
├── rtl/
│ ├── apb_master.sv
│ ├── apb_slave.sv
│ ├── apb_if.sv
│ └── top.sv
│
├── tb/
│ ├── tb_top.sv
│ ├── driver.sv
│ ├── monitor.sv
│ ├── scoreboard.sv
│ └── test.sv
│
├── sim/
│ └── run.do / Makefile
│
└── README.md

---

## ⚙️ Coding Style Requirements

- Use SystemVerilog (not pure Verilog)
- Use:
  - `logic` instead of `reg/wire`
  - `always_ff` / `always_comb`
- Follow synchronous design:
  - All registers on `posedge PCLK`
- Use non-blocking assignment (`<=`) in sequential logic

---

## 🚀 Extra (Optional but Preferred)

- Add assertions for APB protocol:
  - SETUP → ACCESS transition
  - `PENABLE` timing check
- Add coverage (functional coverage)
- Add parameterization:
  - Address width
  - Data width

---

## 📌 Expected Output

Generate:
1. Full SystemVerilog source code
2. Testbench with multiple test cases
3. Simulation-ready project
4. Comments explaining key logic

---

## 🧠 Notes

- Keep the design simple but correct
- Focus on protocol correctness
- Make code clean and readable
- Ensure no “write glitch” (multiple writes per transaction)

---

## ✅ Deliverables

- Complete working APB RTL + TB
- Ready to run in simulator (e.g., VCS / Questa / Verilator)

