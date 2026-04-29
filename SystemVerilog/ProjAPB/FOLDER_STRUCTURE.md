# APB SystemVerilog Project - Folder Structure

## 📁 Directory Organization

```
ProjAPB/
├── src/                          # Source code
│   ├── rtl/                      # RTL design files
│   │   ├── apb_if.sv            # APB interface with modports
│   │   ├── apb_master.sv        # APB master module
│   │   ├── apb_slave.sv         # APB slave with register file
│   │   └── top.sv               # Top module
│   │
│   └── tb/                       # Testbench and verification
│       ├── transaction.sv        # Transaction class
│       ├── driver.sv            # APB driver class
│       ├── monitor.sv           # APB monitor class
│       ├── scoreboard.sv        # Verification scoreboard
│       ├── tb.sv                # Testbench module
│       └── test.sv              # Test program/module
│
├── sim/                          # Simulation files
│   ├── waveforms/               # VCD waveform dumps
│   │   ├── waveform.vcd         # Complete signal dump
│   │   └── waveform_detailed.vcd # Filtered APB signals
│   │
│   ├── results/                 # Simulation output
│   │   ├── simulation_results.log # Test execution log
│   │   └── transcript           # ModelSim transcript
│   │
│   └── scripts/                 # Simulation tools
│       ├── sim.do               # ModelSim script
│       └── view_waveform.sh     # Waveform viewer launcher
│
├── doc/                          # Documentation
│   ├── BUG_REPORT.md            # Bug analysis and fixes
│   ├── TEST_RESULTS.md          # Test execution summary
│   ├── WAVEFORM_README.md       # Waveform quick start
│   ├── WAVEFORM_GUIDE.md        # Detailed waveform guide
│   └── WAVEFORM_ASCII.md        # ASCII timing diagrams
│
├── work/                         # ModelSim work directory
│   └── (generated during simulation - not tracked)
│
├── README.md                     # Project overview
└── ProjAPB.md                    # Original requirements
```

---

## 📂 Directory Purpose

### `src/rtl/` - RTL Design
Contains the synthesizable hardware design:
- **apb_if.sv** - SystemVerilog interface defining APB protocol
- **apb_master.sv** - APB master that generates transactions
- **apb_slave.sv** - APB slave with 8×32-bit register file
- **top.sv** - Top module instantiating master and slave

### `src/tb/` - Testbench
Contains the verification infrastructure:
- **transaction.sv** - Data class for APB transactions
- **driver.sv** - Drives APB transactions from master
- **monitor.sv** - Observes bus activity
- **scoreboard.sv** - Compares actual vs expected
- **tb.sv** - Testbench top module
- **test.sv** - Test cases (write/read/random/byte-write)

### `sim/waveforms/` - Waveforms
VCD (Value Change Dump) files for waveform viewing:
- **waveform.vcd** - Complete signal trace (7.6 KB)
- **waveform_detailed.vcd** - APB signals only (4.4 KB)

### `sim/results/` - Results
Simulation output files:
- **simulation_results.log** - Test execution transcript
- **transcript** - ModelSim command history

### `sim/scripts/` - Scripts
Tools for running simulations:
- **sim.do** - ModelSim TCL script for automation
- **view_waveform.sh** - Opens waveforms in GTKWave

### `doc/` - Documentation
Comprehensive guides and analysis:
- **BUG_REPORT.md** - Detailed bug analysis
- **TEST_RESULTS.md** - Test execution summary
- **WAVEFORM_README.md** - Quick start guide
- **WAVEFORM_GUIDE.md** - Detailed waveform analysis
- **WAVEFORM_ASCII.md** - ASCII timing diagrams

---

## 🔄 Workflow

### Compilation & Simulation
```bash
# From ProjAPB directory
cd sim/scripts
vsim -c tb -do sim.do

# Or use the compiled work directory
cd ../..
vsim -c tb
```

### View Waveforms
```bash
# From ProjAPB/sim/scripts directory
./view_waveform.sh

# Or manually
cd sim/waveforms
gtkwave waveform_detailed.vcd
```

### Read Documentation
```bash
# From ProjAPB directory
cat doc/WAVEFORM_README.md     # Quick start
cat doc/WAVEFORM_ASCII.md      # Timing diagrams
cat doc/BUG_REPORT.md          # Bug analysis
cat doc/TEST_RESULTS.md        # Test results
```

---

## 📊 File Relationships

```
Source Files (src/)
├── RTL Design (src/rtl/)
│   └── Used by Testbench
│       └── Compiled into work/
│           └── Used by Simulation
│               └── Generates Waveforms (sim/waveforms/)
│                   └── Viewed in GTKWave
│                       └── Analyzed with Guides (doc/)
│
└── Testbench (src/tb/)
    └── Defines Test Cases
        └── Executed in Simulation
            └── Produces Results (sim/results/)
                └── Summarized in Documentation
```

---

## 🛠️ Tools & File Associations

| File Type | Tool | Location |
|-----------|------|----------|
| .sv | ModelSim/Questa | src/rtl/, src/tb/ |
| .vcd | GTKWave, ModelSim | sim/waveforms/ |
| .do | ModelSim | sim/scripts/ |
| .log | Text Editor | sim/results/ |
| .md | Markdown Viewer | doc/, root |

---

## 📝 Configuration Files

### `.gitignore` (Recommended)
```
# Simulation artifacts
work/
*.wdb
*.vcd
*.log
*.o
*.exe

# Backup files
*.bak
*~
```

### Compilation Dependencies
```
src/rtl/apb_if.sv          (no dependencies)
    ↓
src/rtl/apb_master.sv      (depends on apb_if.sv)
src/rtl/apb_slave.sv       (depends on apb_if.sv)
    ↓
src/rtl/top.sv             (depends on master, slave)
    ↓
src/tb/transaction.sv      (no dependencies)
    ↓
src/tb/driver.sv           (depends on transaction.sv, apb_if.sv)
src/tb/monitor.sv          (depends on transaction.sv, apb_if.sv)
src/tb/scoreboard.sv       (depends on transaction.sv)
    ↓
src/tb/tb.sv               (depends on all above)
    ↓
src/tb/test.sv             (depends on driver, monitor, scoreboard)
```

---

## 🔍 Quick File Location Reference

**"Where is..."**

- RTL design → `src/rtl/`
- Testbench → `src/tb/`
- Simulation scripts → `sim/scripts/`
- Waveform files → `sim/waveforms/`
- Test results → `sim/results/`
- Documentation → `doc/`
- Bug analysis → `doc/BUG_REPORT.md`
- Test report → `doc/TEST_RESULTS.md`
- Waveform guide → `doc/WAVEFORM_GUIDE.md`
- Timing diagrams → `doc/WAVEFORM_ASCII.md`
- View waveforms → `sim/scripts/view_waveform.sh`

---

## 📋 File Counts

| Directory | Count | Type |
|-----------|-------|------|
| src/rtl/ | 4 | SystemVerilog RTL |
| src/tb/ | 6 | SystemVerilog TB |
| sim/waveforms/ | 2 | VCD files |
| sim/results/ | 2 | Simulation output |
| sim/scripts/ | 2 | Tools & scripts |
| doc/ | 5 | Documentation |
| **Total** | **23** | **Source + Generated** |

---

## 🚀 Common Tasks

### Run Simulation
```bash
cd SystemVerilog/ProjAPB
rm -rf work && vlib work
vlog -sv src/tb/transaction.sv src/tb/driver.sv \
           src/tb/monitor.sv src/tb/scoreboard.sv \
           src/rtl/*.sv src/tb/tb.sv src/tb/test.sv
vsim -c tb -do "run -all; quit"
```

### Generate Waveforms
```bash
vsim -c tb -do "vcd file sim/waveforms/waveform.vcd; \
                vcd add -r /tb/*; run -all; vcd close; quit"
```

### View Waveforms
```bash
cd sim/waveforms
gtkwave waveform_detailed.vcd
```

### Check Results
```bash
cat sim/results/simulation_results.log
```

### Read Analysis
```bash
# Quick start
cat doc/WAVEFORM_README.md

# Detailed guide
cat doc/WAVEFORM_GUIDE.md

# Timing diagrams
cat doc/WAVEFORM_ASCII.md
```

---

## 📦 Backup & Archive

To backup the project:
```bash
# Exclude generated files
tar --exclude='work' --exclude='*.wdb' \
    -czf ProjAPB_backup.tar.gz \
    src/ doc/ README.md ProjAPB.md
```

---

## 🔧 Customization

To add new features:
1. **New RTL files** → Place in `src/rtl/`
2. **New tests** → Add functions to `src/tb/test.sv`
3. **New analysis** → Create in `doc/`
4. **New waveforms** → Edit `sim/scripts/sim.do`

---

## 📖 Documentation Map

```
README.md (This file) ←─ Project overview and organization
├── ProjAPB.md ←─ Original requirements
├── doc/WAVEFORM_README.md ←─ Quick start guide
├── doc/WAVEFORM_GUIDE.md ←─ Detailed waveform analysis
├── doc/WAVEFORM_ASCII.md ←─ ASCII timing diagrams
├── doc/BUG_REPORT.md ←─ Bug analysis and fixes
└── doc/TEST_RESULTS.md ←─ Test execution summary
```

---

**Project Status:** ✅ Complete and organized  
**Last Updated:** 2026-04-29  
**Structure Version:** 2.0 (Reorganized)
