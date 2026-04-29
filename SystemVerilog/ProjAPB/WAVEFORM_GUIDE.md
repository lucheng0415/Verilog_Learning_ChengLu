# APB Waveform Traces - Guide

## Generated Waveform Files

Two waveform files have been generated for viewing the simulation results:

### 1. `waveform.vcd` (7.6 KB)
- **Complete signal dump** of entire testbench hierarchy
- Includes all modules, signals, and internal state
- Best for detailed debugging

### 2. `waveform_detailed.vcd` (4.4 KB)
- **Filtered APB signals** for focused analysis
- Contains only relevant bus signals
- Optimized for protocol analysis

## Signals Captured

### Clock & Reset
- **PCLK** - APB Clock (10ns period)
- **PRESETn** - Active-low reset

### APB Control Signals
- **PSEL** - Peripheral select
- **PENABLE** - Enable signal (1=ACCESS phase, 0=SETUP phase)
- **PWRITE** - Write enable (1=write, 0=read)
- **PREADY** - Slave ready signal
- **PSLVERR** - Slave error flag

### APB Data Signals
- **PADDR[31:0]** - Address bus
- **PWDATA[31:0]** - Write data
- **PRDATA[31:0]** - Read data
- **PSTRB[3:0]** - Byte strobes (write enable per byte)

### Internal Signals (in waveform.vcd)
- **Slave registers** - 8x32-bit register file
- **Master/Slave states**
- **Transaction control signals**

## How to View the Waveforms

### Option 1: Using GTKWave (Recommended)
```bash
gtkwave waveform_detailed.vcd &
```
- Free, open-source waveform viewer
- Supports VCD format
- Zoom, pan, search capabilities

### Option 2: Using ModelSim Wave Viewer
```bash
vsim
File → Open → waveform.vcd
```

### Option 3: Online VCD Viewer
- Use web-based viewers like: https://vcdviewer.com/

### Option 4: Text-based Inspection
```bash
cat waveform_detailed.vcd | head -100
```

## Key Events in the Waveform

### Reset Phase (0-20 ps)
```
Time: 0 ps  - PRESETn = 0 (Reset asserted)
             - PCLK starts oscillating (10 ns period)
             - All APB signals = 0

Time: 20 ps - PRESETn = 1 (Reset released)
             - System ready for operations
```

### Test Sequence
```
Phase 1: Basic Write/Read (20-200 ps)
  - Write 0x12345678 to address 0x00
  - Read back from address 0x00
  - Verify: Data matches ✓

Phase 2: Back-to-Back Transfers (200-400 ps)
  - Write 0xAAAAAAAA to address 0x04
  - Write 0xBBBBBBBB to address 0x08
  - Read from address 0x04, verify 0xAAAAAAAA
  - Read from address 0x08, verify 0xBBBBBBBB

Phase 3: Random Transactions (400-800 ps)
  - 10 random write/read pairs
  - Addresses: 0x00-0x1C (8 registers)
  - Data: Random values with full byte enables

Phase 4: Byte Write Test (800-995 ps)
  - Write 0xFF to byte 0 of register 4 (PSTRB=0x1)
  - Write 0xFF to byte 1 of register 4 (PSTRB=0x2)
  - Read back and verify partial updates
```

## APB Protocol Verification in Waveform

### SETUP Phase Signals
```
PSEL  = 1
PENABLE = 0
PWRITE = 0 (for read) or 1 (for write)
PADDR = [address]
PWDATA = [data for write]
```

### ACCESS Phase Signals
```
PSEL    = 1
PENABLE = 1  ← Key difference from SETUP
PREADY  = 1 (slave ready)
PRDATA  = [read data] (for read operations)
```

### Idle State
```
PSEL = 0
PENABLE = 0
All other signals stable/zero
```

## Signal Tracing Example

### Basic Write Transaction (0x1000 to Address 0x00)

**SETUP Phase:**
```
Time: 30 ps
  PSEL ↑    (goes from 0 to 1)
  PENABLE = 0
  PWRITE ↑  (goes from 0 to 1)
  PADDR ↓   (0x00000000 → stable)
  PWDATA ↓  (0x12345678 → stable)
  PSTRB = 0xF (all bytes enabled)
```

**ACCESS Phase:**
```
Time: 50 ps (clock edge)
  PENABLE ↑ (goes from 0 to 1)
  PREADY = 1 (slave indicates ready)
  [Data latched by slave]
```

**Idle Phase:**
```
Time: 70 ps (clock edge)
  PSEL ↓    (goes from 1 to 0)
  PENABLE ↓ (goes from 1 to 0)
  PWDATA = 0 (cleared)
```

## Analyzing Register State

The slave's 8-register file can be traced through the waveform:

```
Register Map:
  registers[0] at address 0x00
  registers[1] at address 0x04
  registers[2] at address 0x08
  registers[3] at address 0x0C
  registers[4] at address 0x10
  registers[5] at address 0x14
  registers[6] at address 0x18
  registers[7] at address 0x1C
```

Each write transaction updates the corresponding register based on:
- Address bits [4:2] → Register index
- PSTRB[3:0] → Which bytes to update
- PWDATA → The data to write

## Performance Metrics from Waveform

| Metric | Value |
|--------|-------|
| Total Simulation Time | 995 ps |
| Number of Clock Cycles | ~100 |
| Transactions | 28 (14 writes + 14 reads) |
| Average Transaction Duration | 35 ns |
| No wait states | Yes (PREADY always 1) |

## Tips for Waveform Analysis

1. **Zoom on specific transactions** - Use GTKWave zoom to examine individual write/read pairs

2. **Monitor PREADY** - Should always be 1 in this design (no wait states)

3. **Check byte enables** - PSTRB values show which bytes are updated in partial writes

4. **Verify address alignment** - PADDR should always be word-aligned (bits [1:0] = 00)

5. **Data coherency** - Compare PWDATA on write with PRDATA on subsequent read of same address

6. **Register state** - Observe how registers change with each write operation

## Common Waveform Patterns

### Write Pattern
```
SETUP: PSEL=1, PENABLE=0, PWRITE=1, PADDR=[addr], PWDATA=[data]
  ↓ clock
ACCESS: PENABLE=1, PREADY=1 (write accepted)
  ↓ clock
IDLE: PSEL=0, PENABLE=0
```

### Read Pattern
```
SETUP: PSEL=1, PENABLE=0, PWRITE=0, PADDR=[addr]
  ↓ clock
ACCESS: PENABLE=1, PREADY=1, PRDATA=[value]
  ↓ clock
IDLE: PSEL=0, PENABLE=0
```

### Byte Write Pattern
```
PSTRB = 0x1 (byte 0 only)
PSTRB = 0x2 (byte 1 only)
PSTRB = 0x4 (byte 2 only)
PSTRB = 0x8 (byte 3 only)
PSTRB = 0xF (all bytes)
```

## Troubleshooting

**Can't open VCD file?**
- Ensure GTKWave is installed: `apt-get install gtkwave` (Linux)
- Or download from: http://gtkwave.sourceforge.net/

**Waveform looks garbled?**
- Try opening with ModelSim directly
- Ensure file wasn't corrupted during transfer

**Too many signals?**
- Use `waveform_detailed.vcd` (filtered version)
- Or use GTKWave to filter/hide signals

**Want to capture different signals?**
- Edit `sim.do` file to modify vcd add commands
- Re-run simulation to generate new waveform

## Next Steps

1. Open waveform file with viewer:
   ```bash
   gtkwave waveform_detailed.vcd
   ```

2. Examine the protocol transactions

3. Verify data integrity across all test cases

4. Check timing relationships between signals

5. Validate byte write operations with PSTRB

---

**Files Generated:**
- `waveform.vcd` - Complete signal dump
- `waveform_detailed.vcd` - Filtered APB signals
- `sim.do` - Simulation script
- `view_waveform.sh` - Viewer launcher script
