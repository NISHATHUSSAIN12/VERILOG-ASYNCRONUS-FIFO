# VERILOG-ASYNCHRONOUS-FIFO

A complete Verilog/SystemVerilog implementation of an **Asynchronous FIFO (First-In-First-Out)** for safe data transfer across independent clock domains. This design ensures metastability-free synchronization using Gray-coded pointers and dual flip-flop synchronizers.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Modules](#modules)
  - [Memory Module](#memory-module)
  - [Gray Code Converter](#gray-code-converter)
  - [Synchronizer Module](#synchronizer-module)
  - [Read Pointer](#read-pointer)
  - [Write Pointer](#write-pointer)
  - [Async FIFO Top Module](#async-fifo-top-module)
- [Testbench](#testbench)
- [Waveform Analysis](#waveform-analysis)
- [Simulation Results](#simulation-results)

---

## Overview

### What is an Asynchronous FIFO?

An Asynchronous FIFO is a memory buffer that allows safe data transfer between two independent clock domains:
- **Write Clock Domain**: Data is written at the writer's clock frequency
- **Read Clock Domain**: Data is read at the reader's clock frequency

### Key Challenges Solved

1. **Metastability**: When crossing clock domains, multi-bit signals can experience metastability issues
2. **Synchronization**: Ensures read/write pointers are safely synchronized across clock domains
3. **Gray Code**: Uses Gray code (only one bit changes per increment) for safe multi-bit comparison

---

## Architecture

### Block Diagram

The following block diagram shows the complete module hierarchy and signal connections:

![Async FIFO Block Diagram](waveforms/async_fifo_block_diagram.png)

**Block Diagram Components:**
- **sync_wr / sync_rd**: Dual flip-flop CDC synchronizers for pointer crossing
- **status / status1**: Empty and Full flag checkers
- **fifo_mem**: Dual-port RAM for data storage
- **Bidirectional CDC**: Write pointers flow to read domain, read pointers flow to write domain

### ASCII Architecture

```
┌─────────────────────────────────────────────────────┐
│           Asynchronous FIFO Architecture            │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Write Clock Domain       │    Read Clock Domain    │
│  ─────────────────────    │    ────────────────     │
│                           │                         │
│  Write Pointer     ──────►Sync──►  Read Domain     │
│                           │      Write Ptr        │
│                           │                         │
│  ┌──────────────────────┐ │                         │
│  │   Dual-Port RAM      │ │                         │
│  │   (FIFO Memory)      │ │                         │
│  └──────────────────────┘ │                         │
│         ▲      │           │                         │
│         │      │           │                         │
│  Write  │      │ Read      │                         │
│  Ptr    │      │ Ptr       │                         │
│         │      ▼           │                         │
│  Read Pointer      ──────►Sync──►  Write Domain    │
│                           │       Read Ptr         │
│  Empty/Full Flags◄────────┘                         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Modules

### 1. FIFO Memory Module

#### Description

The FIFO memory module (`FIFO_memory.v`) is the core storage element that holds data being transferred across clock domains. It implements a dual-port RAM with independent read and write ports operating on different clock domains.

**Key Features:**
- **Dual-Port RAM**: Separate read and write ports allow simultaneous operations
- **Configurable Parameters**: 
  - `DATA_SIZE`: Width of data (default: 8-bit)
  - `ADDR_SIZE`: Address width determining FIFO depth (depth = 2^ADDR_SIZE)
- **Synchronous Write**: Data writes on positive edge of `wr_clk`
- **Combinational Read**: Data reads are available immediately based on `rd_addr`
- **Full/Empty Protection**: Respects full and empty flags from pointer logic

**Port Details:**
```
Inputs:
  - wr_clk, rd_clk    : Independent write and read clock signals
  - rest_n            : Active-low asynchronous reset
  - wr_enb            : Write enable signal
  - rd_enb            : Read enable signal
  - full, empty       : Status flags from pointer generators
  - wr_data[7:0]      : Input data to be stored
  
Outputs:
  - rd_data[7:0]      : Output data from memory
  - b_rd_addr[2:0]    : Current read address
  - b_wr_addr[2:0]    : Current write address
```

**Operation:**
- On `wr_clk` rising edge: If `wr_enb=1` and `full=0`, write `wr_data` to memory at `b_wr_addr`, then increment address
- On `rd_clk` rising edge: If `rd_enb=1` and `empty=0`, read from memory at `b_rd_addr`, then increment address

**File Reference:** [fifo_memory.v](fifo_memory.v)

---

### 2. Flip-Flop Synchronizer Module

#### Description

The flip-flop synchronizer module (`ff_sync.v`) implements a dual flip-flop cascade for safe clock domain crossing (CDC). This is critical to prevent metastability when Gray-coded pointers cross from one clock domain to another.

**Key Features:**
- **2-Stage Pipeline**: Two cascaded flip-flops reduce metastability to acceptable levels
- **Generic Size**: Supports any bit-width via `size` parameter
- **Asynchronous Reset**: Each flip-flop resets independently
- **Minimal Latency**: Only adds 2-3 clock cycles of delay

**How It Works:**
The input signal passes through two flip-flop stages:
1. First stage (`q1`): Samples the input on clock edge (metastability may occur here)
2. Second stage (`q2`): Samples the stabilized output from stage 1
3. Output (`q2`): Now stable with very low metastability probability

This dual-stage approach ensures:
- Input signal may become metastable at `q1`
- By the time `q2` samples `q1`, most metastability has settled
- Output `q2` is clean and safe to use in the target clock domain

**Port Details:**
```
Inputs:
  - clk           : Target clock domain clock signal
  - rest_n        : Active-low asynchronous reset
  - din[3:0]      : Gray-coded pointer from source domain
  
Outputs:
  - q2[3:0]       : Synchronized output (delayed by 2-3 cycles)
```

**Timing Considerations:**
- Synchronization latency: 2-3 cycles of target clock
- Write pointer needs 2-3 read-clock cycles to appear as empty flag
- Read pointer needs 2-3 write-clock cycles to appear as full flag

**File Reference:** [ff_sync.v](ff_sync.v)

---

### 3. Empty Checker Module

#### Description

The empty checker module (`empty_checker.v`) generates the read pointer and the empty flag in the read clock domain. It maintains a binary read address for memory access and converts it to Gray code for safe synchronization to the write domain.

**Key Features:**
- **Gray-Code Conversion**: Converts binary read pointer to Gray code for CDC
- **Address Generation**: Provides binary read address directly to FIFO memory
- **Empty Flag Logic**: Asserts when Gray-coded read pointer equals synchronized write pointer
- **Controlled Increment**: Read pointer only increments when `rd_enb=1` and `empty=0`

**How Empty Flag Works:**
- The `empty` flag compares Gray-coded pointers between domains
- When `g_rd_ptr_next == syn_g_wr_ptr`, it means no more data to read
- Flag is set combinationally for immediate response
- Read operations cannot occur when `empty=1`

**Gray Code Formula:**
```
b_rd_ptr_next = b_rd_ptr + (rd_enb && !empty)
g_rd_ptr_next = (b_rd_ptr_next >> 1) ^ b_rd_ptr_next
```

This generates valid Gray code where only one bit changes per increment.

**Port Details:**
```
Inputs:
  - rd_clk              : Read clock domain clock
  - rest_n              : Active-low reset
  - rd_enb              : Read enable signal
  - syn_g_wr_ptr[3:0]   : Synchronized write pointer (Gray code)
  
Outputs:
  - b_rd_ptr[3:0]       : Binary read pointer (for potential use)
  - g_rd_ptr[3:0]       : Gray-coded read pointer (to synchronizer)
  - empty               : FIFO empty flag (asserted when no data)
```

**Address Assignment:**
The lower bits of the binary pointer form the actual read address:
```
rd_addr = b_rd_ptr[2:0]  // Actual address to memory
```

**File Reference:** [empty_checker.v](empty_checker.v)

---

### 4. Full Checker Module

#### Description

The full checker module (`full_checker.v`) generates the write pointer and the full flag in the write clock domain. It maintains a binary write address for memory access and converts it to Gray code for safe synchronization to the read domain.

**Key Features:**
- **Gray-Code Conversion**: Converts binary write pointer to Gray code for CDC
- **Address Generation**: Provides binary write address directly to FIFO memory
- **Full Flag Logic**: Asserts when wrapped-around write pointer collides with read pointer
- **Controlled Increment**: Write pointer only increments when `wr_enb=1` and `full=0`

**How Full Flag Works:**

The full flag detection is more complex than empty flag because a full FIFO and empty FIFO both have the same binary pointer values when wrapped around.

**Solution**: Use MSB (Most Significant Bit) inversion:
```
Full condition: When all bits except MSBs are equal, but MSBs are inverted
  {~syn_g_rd_ptr[3:2], syn_g_rd_ptr[1:0]} == g_wr_ptr_next
```

This means:
- Write pointer has wrapped around one more time than read pointer
- No more write space available
- FIFO is completely full with N elements (where N = buffer depth)

**Gray Code and Full Detection:**
```
b_wr_ptr_next = b_wr_ptr + (wr_enb && !full)
g_wr_ptr_next = (b_wr_ptr_next >> 1) ^ b_wr_ptr_next

Full = (g_wr_ptr_next == {~syn_g_rd_ptr[addr_size-1:addr_size-2], 
                           syn_g_rd_ptr[addr_size-3:0]})
```

**Port Details:**
```
Inputs:
  - wr_clk              : Write clock domain clock
  - rest_n              : Active-low reset
  - wr_enb              : Write enable signal
  - syn_g_rd_ptr[3:0]   : Synchronized read pointer (Gray code)
  
Outputs:
  - b_wr_ptr[3:0]       : Binary write pointer (for potential use)
  - g_wr_ptr[3:0]       : Gray-coded write pointer (to synchronizer)
  - full                : FIFO full flag (asserted when no space)
```

**Address Assignment:**
The lower bits of the binary pointer form the actual write address:
```
wr_addr = b_wr_ptr[2:0]  // Actual address to memory
```

**File Reference:** [full_checker.v](full_checker.v)

---

### 5. Asynchronous FIFO Top Module

#### Description

The top-level async FIFO module (`async_fifo_top.v`) integrates all components together: FIFO memory, clock domain synchronizers, pointer generators, and empty/full flag checkers. This module provides the complete FIFO interface to the user.

**Architecture Overview:**

```
┌─────────────────────────────────────────────────────────────┐
│                   async_fifo_top Module                      │
├──────────────────────┬──────────────────────────────────────┤
│   WRITE DOMAIN       │      READ DOMAIN                     │
│   (wr_clk)           │      (rd_clk)                        │
│                      │                                      │
│  ┌─────────────┐     │  ┌─────────────┐                    │
│  │full_checker │◄────┼──┤empty_checker│                    │
│  └──────┬──────┘     │  └──────┬──────┘                    │
│         │            │         │                           │
│    g_wr_ptr          │    g_rd_ptr                         │
│         │            │         │                           │
│  ┌──────▼─────┐      │  ┌──────▼─────┐                    │
│  │ff_sync_rd  │      │  │ff_sync_wr  │                    │
│  └──────┬─────┘      │  └──────┬─────┘                    │
│         │            │         │                           │
│    syn_g_rd_ptr      │    syn_g_wr_ptr                    │
│         │            │         │                           │
│         │            ▼         │                           │
│         │       ┌─────────────┐│                           │
│         │       │FIFO_memory  ││                           │
│         │       │    (Dual-   ││                           │
│         └──────►│   Port RAM) ◄┘                           │
│                 └─────────────┘                            │
│                      │                                      │
│                 wr_data ──► rd_data                        │
└──────────────────────┴──────────────────────────────────────┘
```

**Key Integration Features:**

1. **Dual Clock Domains**: Independent `wr_clk` and `rd_clk`
2. **Cross-Domain Synchronization**: Gray-coded pointers synchronized via `ff_sync`
3. **Empty/Full Flags**: Generated in respective clock domains
4. **Safe Memory Access**: Respects full and empty flags to prevent overflow/underflow

**Signal Flow:**

**Write Domain Path:**
1. `full_checker` maintains `b_wr_ptr` and generates `g_wr_ptr` (Gray code)
2. `g_wr_ptr` is sent through `ff_sync_rd` to read domain as `syn_g_wr_ptr`
3. `b_wr_ptr` lower bits address the memory for writes
4. `full` flag prevents writes when FIFO is full

**Read Domain Path:**
1. `empty_checker` maintains `b_rd_ptr` and generates `g_rd_ptr` (Gray code)
2. `g_rd_ptr` is sent through `ff_sync_wr` to write domain as `syn_g_rd_ptr`
3. `b_rd_ptr` lower bits address the memory for reads
4. `empty` flag prevents reads when FIFO is empty

**Port Details:**

```
Write Domain Inputs:
  - wr_clk          : Write clock (e.g., 100 MHz)
  - rest_n          : Asynchronous reset (active-low)
  - wr_enb          : Write enable
  - wr_data[7:0]    : Data to write (8-bit)
  
Write Domain Outputs:
  - full            : Write prevented when asserted

Read Domain Inputs:
  - rd_clk          : Read clock (e.g., 66.67 MHz)
  - rd_enb          : Read enable
  
Read Domain Outputs:
  - rd_data[7:0]    : Data read (8-bit)
  - empty           : Read prevented when asserted
```

**Configurable Parameters:**
```verilog
parameter DATA_SIZE = 8    // Width of data bus
parameter ADDR_SIZE = 3    // Address width (depth = 2^3 = 8)
```

**Key Benefits:**

1. **Metastability Prevention**: Gray-coded pointers + dual flip-flop synchronizers
2. **Independent Clocks**: No timing constraints between write and read clocks
3. **Simple Interface**: Standard FIFO read/write operations
4. **Asynchronous Reset**: Both domains have independent reset capability
5. **Flag-Based Flow Control**: `full` and `empty` flags for easy integration

**Typical Usage:**
```verilog
// Write Side (100 MHz)
if (!full) begin
    wr_data <= data_to_send;
    wr_enb <= 1;
end

// Read Side (66.67 MHz - different frequency!)
if (!empty) begin
    rd_enb <= 1;
    received_data <= rd_data;
end
```

**File Reference:** [async_fifo_top.v](async_fifo_top.v)

---

## Testbench

### Description

The testbench module validates the complete async FIFO functionality through multiple test scenarios. It instantiates the `async_fifo_top` module and exercises all features including different clock frequencies, simultaneous read/write operations, and flag generation.

### Key Test Features

**Independent Clocks:**
- Write clock: 10 ns period (100 MHz)
- Read clock: 15 ns period (66.67 MHz)
- Different frequencies stress-test the clock domain crossing logic

**Test Scenarios:**

1. **Test 1 - Fill FIFO**
   - Writes 8 data values sequentially
   - Monitors `full` flag assertion
   - Verifies write pointer increments correctly
   - Write address cycles through memory locations

2. **Test 2 - Read FIFO** 
   - Reads 8 previously written values
   - Verifies data integrity (read data matches written data)
   - Monitors `empty` flag assertion
   - Tests proper FIFO FIFO behavior (first-in, first-out)

3. **Test 3 - Simultaneous Read/Write**
   - Performs overlapping read and write operations
   - Tests clock domain crossing during active data flow
   - Verifies pointer synchronization under concurrent load

4. **Test 4 - Empty Flag Verification**
   - Confirms `empty` flag asserts correctly
   - Validates that no more data can be read

### Testbench Parameters

```verilog
parameter DATA_SIZE = 8       // 8-bit data width
parameter ADDR_SIZE = 3       // 3-bit address (8 FIFO locations)
parameter CLK_WR_PERIOD = 10  // 10 ns write clock period
parameter CLK_RD_PERIOD = 15  // 15 ns read clock period
```

### Port Connections

**Write Clock Domain:**
```
wr_clk       : Write clock signal (toggled every CLK_WR_PERIOD/2)
wr_rst_n     : Reset released after 50ns, then again at 100ns
wr_en        : Generated based on test scenarios
wr_data[7:0] : Test data patterns (0x00, 0x01, ..., 0x0F, 0xAA, etc.)
full         : Monitored for flag correctness
```

**Read Clock Domain:**
```
rd_clk       : Read clock signal (toggled every CLK_RD_PERIOD/2)
rd_rst_n     : Reset released after 100ns (150ns total)
rd_en        : Generated based on test scenarios
rd_data[7:0] : Captured and compared against expected values
empty        : Monitored for flag correctness
```

### Test Execution Flow

```
Time 0-50ns:     Both resets held LOW
Time 50-100ns:   wr_rst_n released, wr_clk active
Time 100-150ns:  rd_rst_n released, both clocks running
Time 150-250ns:  Test 1 - Fill FIFO with 8 values
Time 250-450ns:  Synchronizers propagate (3 clock cycle delay)
Time 450-600ns:  Test 2 - Read back 8 values and verify
Time 600-900ns:  Test 3 - Simultaneous read/write (20 items)
Time 900-1000ns: Test 4 - Verify empty flag
Time 1000ns+:    $finish - Testbench complete
```

### Expected Outputs

The testbench prints comprehensive test results:
```
============================================
  Asynchronous FIFO Testbench Started
============================================
Data Width: 8, FIFO Depth: 8
Write Clock Period: 10 ns
Read Clock Period: 15 ns
============================================

[TEST 1] Filling FIFO...
  Written: 0x00 (location 0)
  Written: 0x01 (location 1)
  ...
  Total Written: 8

[TEST 2] Reading FIFO...
  Read: 0x00 (expected: 0x00) - PASS
  Read: 0x01 (expected: 0x01) - PASS
  ...
  Total Read: 8

[TEST 3] Simultaneous Read and Write...
  Simultaneous operations completed

[TEST 4] Empty Flag Test...
  FIFO is EMPTY - Flag correctly asserted

============================================
  All Tests Completed Successfully!
============================================
```

### How to Run the Testbench

**Using ModelSim/QuestaSim:**
```bash
# Compile all modules
vlog fifo_memory.v ff_sync.v empty_checker.v full_checker.v async_fifo_top.v

# Compile testbench
vlog async_fifo_tb.v

# Run simulation
vsim -gui work.async_fifo_tb

# In ModelSim command line:
run -all

# View waveforms (optional)
add wave -r /async_fifo_tb/*
```

**Using Vivado:**
```tcl
# Create project
create_project async_fifo_sim ./sim -part xc7k70tfbg484-1

# Add source files
add_files {fifo_memory.v ff_sync.v empty_checker.v full_checker.v async_fifo_top.v async_fifo_tb.v}

# Run simulation
launch_simulation -simset sim_1
run -all
```

**Using IVerilog (Open Source):**
```bash
# Compile and link
iverilog -o fifo_sim \
  fifo_memory.v \
  ff_sync.v \
  empty_checker.v \
  full_checker.v \
  async_fifo_top.v \
  async_fifo_tb.v

# Run simulation
vvp fifo_sim
```

**File Reference:** See [async_fifo_tb.v](async_fifo_tb.v) for the complete testbench implementation.

---

## Waveform Analysis

### Actual Simulation Waveform

The following waveform screenshot captures the complete FIFO operation from the ModelSim simulation:

![Async FIFO Waveform - Complete 500ns Simulation](waveforms/async_fifo_waveform_simulation.png)

**Waveform Shows (0-500ns):**
- **wr_clk**: Write clock @ 100 MHz (10ns period) - green
- **rd_clk**: Read clock @ 66.67 MHz (15ns period) - green (slower)
- **rest_n**: Active-low reset - released at ~50ns
- **wr_enb**: Write enable - active during write phase (~150-250ns)
- **rd_enb**: Read enable - active during read phase (~350-450ns)
- **wr_data[7:0]**: Write data bus showing 0x00, 0x01, 0x02... 0x07
- **rd_data[7:0]**: Read data bus showing same values with CDC delay
- **full**: FIFO full flag - HIGH when buffer is full
- **empty**: FIFO empty flag - HIGH when no data available
- **Internal pointers**: Write/Read pointer progression in binary and gray code
- **Synchronization signals**: Shows CDC (Clock Domain Crossing) latency

**Key Observations from Waveform:**
1. **Independent Clocks**: Different clock frequencies run simultaneously
2. **Data Path**: 8 values (0-7) written, then read back in same order
3. **Pointer Sync**: Gray-coded pointers visible with 2-3 clock cycle CDC delay
4. **Flag Timing**: Empty and Full flags update after pointer synchronization
5. **Data Integrity**: No data corruption despite clock domain crossing

### Complete ASCII Waveform Document

A detailed text-based waveform with all 5 phases annotated is available in [waveforms/async_fifo_waveform.txt](waveforms/async_fifo_waveform.txt)

### Key Signals to Observe

#### Write Clock Domain Signals
```
wr_clk       : Write clock signal (100 MHz - 10ns period)
wr_rst_n     : Write domain reset (active low)
wr_en        : Write enable signal
wr_data[7:0] : Data to be written (8-bit)
full         : FIFO full flag (write prevented when asserted)
```

#### Read Clock Domain Signals
```
rd_clk       : Read clock signal (66.67 MHz - 15ns period)
rd_rst_n     : Read domain reset (active low)
rd_en        : Read enable signal
rd_data[7:0] : Data read from FIFO (8-bit)
empty        : FIFO empty flag (read prevented when asserted)
```

#### Internal Synchronization Signals
```
wr_ptr_gray[4:0]      : Write pointer in Gray code
rd_ptr_gray[4:0]      : Read pointer in Gray code
wr_ptr_gray_sync[4:0] : Synchronized write pointer in read clock domain
rd_ptr_gray_sync[4:0] : Synchronized read pointer in write clock domain
```

### Expected Waveform Behavior

#### Phase 1: Reset (0-100ns)
- Both `wr_rst_n` and `rd_rst_n` are held LOW
- Pointers reset to 0
- Both `full` and `empty` flags are HIGH (FIFO is empty)
- No data transfer

#### Phase 2: FIFO Filling (100-260ns)
```
Timeline:
- Write operations occur on every wr_clk rising edge
- Data increments from 0x00 to 0x0F (16 items)
- Write pointer advances: 0→1→2→3...→15→16
- full flag asserts when write pointer equals read pointer (wrapped)
- Synchronized signals show ~2-3 cycle delay
```

#### Phase 3: Synchronization Delay (260-340ns)
```
- After write operations stop, synchronizers need time to propagate
- Gray-coded write pointer crosses from write to read domain
- Shows CDC (Clock Domain Crossing) latency (~3 clock cycles)
- Read clock continues running independently
```

#### Phase 4: FIFO Reading (340-520ns)
```
- Read operations begin after synchronization
- Data reads: 0x00→0x01→0x02...→0x0F
- rd_data should match written data (in order)
- Read pointer advances
- empty flag asserts when all data is read
```

### Waveform Diagram Example

```
            ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐
wr_clk      │ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘ └─
            ├─────────────────────────────────────────────────────
wr_rst_n    ┤0         ┐
            │          └────────────────────────────────────────
            ├─────────────────────────────────────────────────────
wr_en       ┤0         ┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐
            │          └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘
            ├─────────────────────────────────────────────────────
wr_data     ├ 00h  01h  02h  03h  04h  05h  06h  07h  08h  09h
            │
            ├─────────────────────────────────────────────────────
full        ┤1         ┐
            │          └─────────────────────────────┐
            │                                        └─────────
            ├─────────────────────────────────────────────────────
empty       ┤1         ┐
            │          └────────────────────────────────────────
            └─────────────────────────────────────────────────────
```

### How to Generate Waveforms

#### Using ModelSim/QuestaSim
```bash
# Compile
vlog async_fifo.v
vlog async_fifo_tb.v

# Simulate
vsim -gui work.async_fifo_tb

# In ModelSim console:
run -all

# View waveforms
add wave -r /*
```

#### Using Vivado
```tcl
# Create project and add files
create_project async_fifo_proj ./async_fifo_proj -part xc7k70tfbg484-1

# Add source files
add_files {async_fifo.v async_fifo_tb.v}

# Run simulation
launch_simulation -simset sim_1
run -all
```

#### Using IVerilog
```bash
iverilog -o async_fifo_sim async_fifo.v async_fifo_tb.v
vvp async_fifo_sim
```

---

## Simulation Results

### Expected Test Output

```
============================================
  Asynchronous FIFO Testbench Started
============================================
Data Width: 8, FIFO Depth: 16
Write Clock Period: 10 ns
Read Clock Period: 15 ns
============================================

[TEST 1] Filling FIFO...
  Written: 0x00 (location 0)
  Written: 0x01 (location 1)
  Written: 0x02 (location 2)
  ...
  Written: 0x0f (location 15)
  FIFO FULL - Cannot write
  Total Written: 16

[TEST 2] Reading FIFO...
  Read: 0x00 (expected: 0x00) - PASS
  Read: 0x01 (expected: 0x01) - PASS
  Read: 0x02 (expected: 0x02) - PASS
  ...
  Read: 0x0f (expected: 0x0f) - PASS
  FIFO EMPTY - Cannot read
  Total Read: 16

[TEST 3] Simultaneous Read and Write...
  Simultaneous operations completed

[TEST 4] Empty Flag Test...
  FIFO is EMPTY - Flag correctly asserted

============================================
  All Tests Completed Successfully!
============================================
```

### Performance Metrics

| Metric | Value |
|--------|-------|
| FIFO Depth | 16 locations |
| Data Width | 8 bits |
| Write Clock | 100 MHz (10ns period) |
| Read Clock | 66.67 MHz (15ns period) |
| Synchronization Latency | 2-3 read clock cycles |
| Full Flag Setup | 2-3 write clock cycles |
| Empty Flag Setup | 2-3 read clock cycles |
| Max Write Throughput | 100 Mbyte/s |
| Max Read Throughput | 66.67 Mbyte/s |

---

## Key Design Considerations

### 1. Gray Code Advantage
- **Traditional Binary**: Multiple bits change simultaneously (e.g., 0111 → 1000)
- **Gray Code**: Only one bit changes per step (e.g., 0100 → 1100)
- **Benefit**: Prevents metastability when crossing clock domains

### 2. Pointer Width
- Pointers use `ADDR_WIDTH + 1` bits
- Extra bit distinguishes full from empty
- Full: MSBs different, lower bits equal
- Empty: Pointers exactly equal

### 3. Synchronization Latency
- 2-3 cycle delay for pointer synchronization
- Empty/Full flags may not respond immediately
- Must manage underflow/overflow carefully

### 4. Clock Domain Isolation
- Separate reset for each clock domain
- Each domain operates independently
- Only Gray-coded pointers cross domains

---

## File Structure

```
VERILOG-ASYNCRONUS-FIFO/
│
├── README.md                           # Main project documentation
│
├── Core Modules:
├── async_fifo_top.v                    # Top-level module integrating all components
├── fifo_memory.v                       # Dual-port RAM for data storage
├── ff_sync.v                           # Flip-flop CDC synchronizer (2-stage)
├── empty_checker.v                     # Empty flag generator (read domain)
├── full_checker.v                      # Full flag generator (write domain)
│
├── Verification:
├── async_fifo_tb.v                     # Testbench with 4 test scenarios
│
└── Waveforms & Simulation Documentation:
    └── waveforms/
        ├── README.md                               # Waveform analysis guide
        ├── async_fifo_waveform_simulation.png      # ModelSim waveform screenshot
        ├── async_fifo_block_diagram.png            # Module block diagram
        └── async_fifo_waveform.txt                 # ASCII waveform (detailed timing)
```

### Waveforms Directory Details

| File | Purpose | Content |
|------|---------|---------|
| `waveforms/README.md` | Waveform documentation | Detailed explanation of signals and results |
| `waveforms/async_fifo_waveform_simulation.png` | Actual simulation results | ModelSim screenshot (0-500ns) showing all signals |
| `waveforms/async_fifo_block_diagram.png` | Architecture diagram | Module connections and signal routing |
| `waveforms/async_fifo_waveform.txt` | Text-based waveform | 5-phase timing diagram with annotations |

### Module Dependencies

```
async_fifo_top.v
├── Instantiates: fifo_memory.v
├── Instantiates: ff_sync.v (x2 for bidirectional CDC)
├── Instantiates: empty_checker.v
└── Instantiates: full_checker.v

empty_checker.v
└── Uses: Gray code conversion logic (inline)

full_checker.v
└── Uses: Gray code conversion logic (inline)
```

### File Descriptions

| File | Purpose | Lines | Key Signals |
|------|---------|-------|-------------|
| `async_fifo_top.v` | Top-level integration | ~70 | wr_clk, rd_clk, wr_data, rd_data, full, empty |
| `fifo_memory.v` | Dual-port RAM storage | ~30 | wr_clk, rd_clk, wr_en, rd_en, mem[8][8] |
| `ff_sync.v` | CDC synchronizer | ~20 | clk, din, q1, q2 |
| `empty_checker.v` | Empty flag logic | ~25 | rd_clk, b_rd_ptr, g_rd_ptr, empty |
| `full_checker.v` | Full flag logic | ~25 | wr_clk, b_wr_ptr, g_wr_ptr, full |
| `async_fifo_tb.v` | Test harness | ~80 | Test stimuli and monitoring |
| `README.md` | Documentation | ~800 | This comprehensive guide |

---

## References & Further Reading

1. **Clock Domain Crossing (CDC)**
   - Xilinx Application Note: [Synchronization Strategies for Clock Domain Crossing](https://www.xilinx.com)

2. **Gray Code Benefits**
   - Paper: "Gray Code and Binary Conversion"
   - https://en.wikipedia.org/wiki/Gray_code

3. **FIFO Design Standards**
   - Altera/Intel Application Note: Asynchronous FIFO Design
   - Synopsys: Clock Domain Crossing Best Practices

---

## Contributing & Support

For bugs, improvements, or questions about this FIFO implementation, please refer to the project repository or contact the maintainers.

---

**Last Updated**: 2026
**Version**: 1.0
**License**: MIT
