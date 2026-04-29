# APB Protocol Waveform - ASCII Visualization

## Basic Write Transaction (Write 0x12345678 to Address 0x00)

```
Time(ps):     0      10     20     30     40     50     60     70     80     90     100
            |------|------|------|------|------|------|------|------|------|------|

PCLK         ---|___|-----|___||-----|___|-----|___||-----|___|-----|___||-----|___|---
             ___           ___           ___           ___           ___

PRESETn      ___[=================|======================================================
             (held low 20ps, then released)

PSEL         _________[========================|_____________________________________________
             (asserted at 30ps for SETUP phase)

PENABLE      _____________________[=================|_______________________
             (asserted at 50ps for ACCESS phase)  (held until 70ps)

PWRITE       _____________________[=================|_______________________
             (1 = Write operation)

PADDR[31:0]  XXXXXXX[==================0x00000000=================]XXXXXXX
             (set to 0x00 during SETUP, held through ACCESS)

PWDATA[31:0] XXXXXXX[==================0x12345678=================]XXXXXXX
             (write data set during SETUP)

PREADY       HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
             (slave always ready, asserts immediately)

PRDATA[31:0] XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
             (not used in write operation)

PSTRB[3:0]   XXXXXXX[==================0xF=================]XXXXXXX
             (all bytes enabled for full 32-bit write)
```

**Key Timing:**
- T=0ps: Reset asserted, PCLK starts
- T=20ps: Reset released
- T=30ps: SETUP phase begins (PSEL=1, PENABLE=0)
- T=50ps: ACCESS phase begins (PENABLE=1)
- T=70ps: IDLE phase (PSEL=0, PENABLE=0)

---

## Basic Read Transaction (Read from Address 0x00 after write)

```
Time(ps):     200    210    220    230    240    250    260    270    280    290
            |------|------|------|------|------|------|------|------|------|------|

PCLK         ___|-----|___|-----|___||-----|___|-----|___||-----|___|-----|___||---
             ___           ___           ___           ___           ___

PSEL         [========================|_____________________________________________
             (already high from previous transaction, remains asserted)

PENABLE      _____[=================|_______________________
             (SETUP phase)             (transitions to ACCESS)

PWRITE       _____[=================|_______________________
             (0 = Read operation)

PADDR[31:0]  XXXXXXX[==================0x00000000=================]XXXXXXX
             (read address set)

PWDATA[31:0] XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
             (not used in read operation)

PREADY       HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
             (slave indicates ready)

PRDATA[31:0] XXXXXXX[==================0x12345678=================]XXXXXXX
             (slave returns previously written data)   ↑
                                                   (read at this point)
```

---

## Back-to-Back Write Transactions

```
Time(ps):     300    320    340    360    380    400    420
            |------|------|------|------|------|------|------|

PCLK         ___|-----|___|-----|___|-----|___|-----|___|-----|___

PSEL         [========|=========|=========|=========|=========|---
             (continuously asserted for back-to-back)

PENABLE      ____[===|___|[===|___|[===|___|[===|____
             (SETUP)  (ACCESS) (SETUP)(ACCESS) pattern repeats

PADDR        [0x04][0x04][0x08][0x08][0x04][0x04]...
             Write  Write  Write  Write  Read   Read
             to     confirm  to    confirm  from  from
             0x04  0x04    0x08   0x08   0x04   0x08

PWDATA       [0xAAAAAAAA][0xBBBBBBBB][0x06D7CD0D]...
             Write1      Write2     Random

PRDATA       [0xAAAAAAAA][0xBBBBBBBB][0x06D7CD0D]...
             (confirmed)
```

---

## Byte Write Transaction (PSTRB Demonstration)

```
Time(ps):     800    820    840    860    880    900    920
            |------|------|------|------|------|------|------|

PSEL         [====|___|[====|___|[====|________
             Write Byte0  Write Byte1  Read

PENABLE      __[=|___[=|___[=|___
             (ACCESS phase)

PADDR        [0x10][0x10][0x10]
             (same register, different bytes)

PWDATA       [0x000000FF][0x0000FF00][XXXX]
             byte0 only   byte1 only

PSTRB        [0x1][0x1][0x2][0x2][0xF][0xF]
             byte0      byte1     all bytes (read)

Register[4]: [0xC0895E81]
             ↓ (write 0xFF to byte 0, PSTRB=0x1)
             [0xC0895EFF]
             ↓ (write 0xFF to byte 1, PSTRB=0x2)
             [0xC089FFFF]
             ↓ (read)
             PRDATA = 0xC089FFFF ✓ MATCH

Binary representation of register changes:
Before:  1100 0000 1000 1001 0101 1110 1000 0001
         |Byte3|Byte2|Byte1|Byte0|
         
After W1:1100 0000 1000 1001 0101 1110 1111 1111  (byte0 = 0xFF)
         
After W2:1100 0000 1000 1001 1111 1111 1111 1111  (byte1 = 0xFF)
```

---

## Signal Relationships in APB Protocol

### SETUP → ACCESS Transition
```
Before Clock Edge (SETUP):
  PSEL     = 1
  PENABLE  = 0      ← Key difference
  PADDR    = valid
  PWDATA   = valid (for write)

After Clock Edge (ACCESS):
  PSEL     = 1
  PENABLE  = 1      ← Changed to 1
  PADDR    = stable
  PWDATA   = stable
  PRDATA   = valid (for read)
```

### PSTRB Encoding
```
PSTRB[3:0]  Bytes Enabled    Typical Use
   0x1      Byte 0 only      8-bit write to byte 0
   0x2      Byte 1 only      8-bit write to byte 1
   0x3      Bytes 0-1        16-bit write
   0x4      Byte 2 only      8-bit write to byte 2
   0x8      Byte 3 only      8-bit write to byte 3
   0xF      All bytes        32-bit write (full word)
```

---

## Timing Measurements

### Transaction Timing

**Write Duration:** ~30ns (3 clock cycles @ 100MHz)
- Setup phase: 10ns (1 clock)
- Access phase: 10ns (1 clock)
- Idle phase: 10ns (1 clock)

**Read Duration:** ~30ns (same as write)

**Throughput:**
- 1 transaction every 30ns
- Can be reduced to 10ns with pipelined addressing
- Current design: 28 transactions in 995ps = ~35ns average

### Clock Period
- Period: 10ns
- Frequency: 100 MHz
- Rising edges at: 0, 10, 20, 30, 40, 50... ns

---

## State Machine Flow in Waveform

```
┌─────────────────────────────────────────────────────┐
│              APB STATE MACHINE                      │
└─────────────────────────────────────────────────────┘

IDLE STATE:
  PSEL = 0
  PENABLE = 0
  (all control signals inactive)
  
  ↓ Master initiates transaction
  
SETUP STATE:
  PSEL = 1    ← Asserted
  PENABLE = 0 ← Still low
  PADDR, PWDATA set
  
  ↓ Clock edge
  
ACCESS STATE:
  PSEL = 1    ← Remains high
  PENABLE = 1 ← Goes high
  PREADY = 1  ← Slave ready
  PRDATA valid (for read)
  
  ↓ Clock edge (or PREADY low if wait states)
  
IDLE STATE (again):
  PSEL = 0    ← Goes low
  PENABLE = 0 ← Goes low
  
  ↓ Can immediately enter SETUP for next transaction
```

---

## Observing Data Flow

### Write Data Path
```
Master sets: PWDATA[31:0] = 0xAAAAAAAA
             ↓
On ACCESS phase (PENABLE=1, PWRITE=1):
             ↓
Slave samples: registers[addr] = PWDATA (with PSTRB masking)
             ↓
Next read returns updated value
```

### Read Data Path
```
Master sets: PADDR[31:0] = address
             ↓
Slave continuously updates: PRDATA = registers[addr] (combinational)
             ↓
Master samples: read_data = PRDATA (when PENABLE=1, PWRITE=0)
```

---

## Tips for Waveform Analysis

1. **Look for signal transitions** - Changes indicate state machine transitions
2. **Check timing relationships** - Verify SETUP→ACCESS transitions
3. **Monitor PREADY** - Should respond to slave state
4. **Verify data stability** - Data should be stable during transactions
5. **Check byte enables** - Confirm correct PSTRB for each operation
6. **Look for errors** - PSLVERR should remain 0 for valid operations

---

## Common Issues to Look For

❌ **PENABLE doesn't go high after PSEL** - Transaction won't complete
❌ **Data changes during transaction** - Could cause corruption
❌ **PADDR changes during ACCESS** - Slave will see wrong address
❌ **PREADY=0 but no wait cycles** - Timing violation
✓ **Clean state transitions** - Good design
✓ **Data stable throughout** - Reliable operation
✓ **Back-to-back ready** - Good performance

---

## Generating Custom Waveforms

To capture additional signals, edit `sim.do`:

```tcl
vcd file waveform_custom.vcd
vcd add /tb/PCLK
vcd add /tb/PRESETn
vcd add /tb/apb_bus/*        # All APB signals
vcd add /tb/dut/slave/*      # Slave internals
vcd add /tb/dut/master/*     # Master internals
run -all
vcd close
```

Then run:
```bash
vsim -c tb -do @sim.do
gtkwave waveform_custom.vcd
```

---

Generated by APB Testbench - April 29, 2026
