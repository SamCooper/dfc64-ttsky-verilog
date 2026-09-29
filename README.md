# DFC64: DIY Fabricated Computer 64

## Project Architecture and Technical Choices

This project targets the manufacturing of a custom ASIC via the Tiny Tapeout open-source silicon pipeline.
The design implements a 6502 instruction level compatible 8-bit CPU  featuring a 16-bit address space and an 8-bit data bus, heavily relying on external off-chip decoding to fit within the physical I/O constraints of a single ASIC tile.
The CPU uses the IO pins of the Tiny Tapeout footprint as follows:

* 8 input pins
  * These are used to control aspects of the CPU such as reset, NMIs, halts, etc
* 8 output pins
  * These are used by the CPU to signal reading and writing of address and data words to the support ICs
* 8 bidirectional pins
  * This forms the data bus of the CPU and is used for all inputs and outs including both hi and low bytes of addresses as well as any data words in and out

**Core Toolchain and Design Decisions**
*   **Design Entry (H. Neemann's Digital):** To balance visual schematic capture with hierarchical organization, the core logic and Finite State Machines (FSM) will be designed manually in *Digital*. This allows for drag-and-drop logic gate placement while automatically exporting standard, synthesizable Verilog for the ASIC toolchain.
*   **Test-Driven Development (Claude Code):** Development will follow a strict BDD (Behavior-Driven Development) methodology. Claude Code will act as an automated test engineer, generating Python-based hardware mocks and test vectors based on plain-language specifications before the hardware is drawn.
*   **Assembly Verification (vasm6502):** To verify the 6502 instruction set, standard assembly files will be compiled using `vasm`. The resulting binaries will be injected into the simulated ROM to verify full software execution against the hardware.
*   **I/O Strategy (Time-Multiplexed Bus):** Because Tiny Tapeout provides limited I/O (8 bidirectional, 8 inputs, 8 outputs), the ASIC will output a multiplexed 16-bit address over two clock cycles using the bidirectional pins.
*   **External PCB Decoding:** 
    * The multiplexed signals will be captured by two external 8-bit latches. It is TBD on how this will be built currently as it will use an enhancement that allows the stored 16-bit address to increment in a single cycle.
    * A 74HC138 3-to-8 line decoder on the PCB will manage the physical memory map, dividing the 64KB space into discrete blocks for System RAM, Video RAM (framebuffer), I/O peripherals, and ROM.
---

## Memory Architecture and Physical Layout

To support a full 64KB address space within the pin constraints of a standard Tiny Tapeout tile, the DFC64 utilizes a time-multiplexed bus paired with external PCB-level decoding. This splits the architecture into a strict logical memory map for the 6502 CPU and a coordinated physical layout of support ICs on the host board.

### Logical Memory Map

The 64KB address space is divided into eight discrete 8KB chunks using a 74HC138 3-to-8 line decoder reading the top three address bits (`A13`, `A14`, `A15`). Because 6502 architecture requires RAM at the bottom (for Zero Page and Stack) and ROM at the top (for reset vectors), the blocks are allocated as follows:

| Address Range | Size | Hardware Target | Decoder Output | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0xC000 - 0xFFFF` | 16KB | ROM | `Y6`, `Y7` (ANDed) | Boot ROM. Contains reset vectors at `0xFFFC/D`. |
| `0x8000 - 0xBFFF` | 16KB | Video RAM | `Y4`, `Y5` (ANDed) | Graphical framebuffer memory for display output. |
| `0x6000 - 0x7FFF` | 8KB | I/O Peripherals | `Y3` | Memory-mapped I/O (UART, Timers, SPI). Can be subdivided via ASIC pins or cascaded decoders. |
| `0x0000 - 0x5FFF` | 24KB | System RAM | `Y0`, `Y1`, `Y2` (ANDed) | General memory. Includes Zero Page (`0x0000-0x00FF`) and Hardware Stack (`0x0100-0x01FF`). |

### Physical Setup and PCB Routing

The ASIC interfaces with external memory through a shared 8-bit bidirectional bus and dedicated control lines. The physical PCB requires some primary support logic chips alongside the actual RAM/ROM chips.

Instead of basic transparent latches, the PCB utilizes fully synchronous presettable counters (74HC163s). This allows the ASIC to perform 1-cycle burst sequential reads (by pulsing an increment pin) and 1-cycle Zero Page fetches (by clearing the upper address hardware synchronously). The ASIC and the PCB logic share a single external free-running clock, ensuring perfect cycle synchronization.

**ASIC Pin Assignments**
*   **System Clock (`clk`):** Driven by the external PCB oscillator.
*   **Bidirectional (`uio[7:0]`):** The time-multiplexed bus. Sequentially pushes the lower address, upper address, and finally reads/writes data. An enhancement exists where the addresses being read/written are sequential and therefore the address in the latch can be incremented in a single cycle rather than needing to be completely overwritten.
*   **Outputs (`uo_out[7:0]`):** The synchronized bus control signals:
    *   `uo_out[0]` - `LOAD_L_n`: Active-low parallel load for the lower address byte.
    *   `uo_out[1]` - `LOAD_H_n`: Active-low parallel load for the upper address byte.
    *   `uo_out[2]` - `ZP_CLR_n`: Active-low synchronous clear for the upper address byte (Zero Page optimization).
    *   `uo_out[3]` - `ADDR_INC`: Active-high count enable to increment the full 16-bit address.
    *   `uo_out[4]` - `MEM_WE_n`: Active-low Memory Write Enable.
    *   `uo_out[5]` - `MEM_OE_n`: Active-low Memory Output Enable.
    *   `uo_out[6:7]` - Unused (Available for future interrupts, NMI, or dedicated Chip Selects).

**External Support ICs**
1.  **Lower Address Counters (2× 74HC163):**
    *   *Inputs:* Wired to the ASIC's `uio[7:0]` bus.
    *   *Clock:* Tied to the main external system oscillator.
    *   *Control:* `PE_n` (Load) driven by `LOAD_L_n`. `CEP` (Count) driven by `ADDR_INC`. `SR_n` (Clear) tied HIGH (disabled). 
    *   *Outputs:* Drives physical `A0-A7`. `TC` (Terminal Count) cascades to the upper counters for 16-bit rollover.
2.  **Upper Address Counters (2× 74HC163):**
    *   *Inputs:* Wired to the ASIC's `uio[7:0]` bus.
    *   *Clock:* Tied to the main external system oscillator.
    *   *Control:* `PE_n` driven by `LOAD_H_n`. `SR_n` (Clear) driven by `ZP_CLR_n` allowing instant Zero Page access.
    *   *Outputs:* Drives physical `A8-A15`. 
3.  **Address Decoder (1× 74HC138 & 1x 74HC08 AND Gate):**
    *   *Inputs:* Reads `A13`, `A14`, and `A15` directly from the Upper Address Counters.
    *   *Outputs:* Asserts one of eight active-low `Y` pins, combined via AND gates to drive the `CS_n` pins on physical memory chips.
4.  **Memory Chips (3.3V SRAM / EEPROM):**
    *   *Address Lines:* Driven continuously by the 74HC163 arrays.
    *   *Data Lines:* Wired back to the ASIC's `uio[7:0]` bus.
    *   *Control Lines:* `WE_n` and `OE_n` driven by the ASIC. `CS_n` driven by the 74HC138 logic.

---

## Verification and Testing Strategy

Relying solely on behavioral simulation leaves the project vulnerable to physical timing failures. The verification pipeline orchestrated by Claude Code will progress through six escalating steps of strictness.

*   **Step 1. Behavioral Mocking and Simulation (Cocotb & Python)**
    *   *Approach:* Claude Code will generate asynchronous Python coroutines simulating the external latches, the 74HC138 decoder, and the physical SRAM/ROM/IO chips.
    *   *Goal:* Verify the logical timing of the multiplexed bus FSM and ensure the ASIC correctly executes multi-cycle read/write transactions against the mocked memory map.
*   **Step 2. ISA Compliance Testing (Software-in-the-Loop)**
    *   *Approach:* Small 6502 assembly files are written for every opcode and addressing mode. These are compiled via `vasm`, loaded into the Cocotb Python ROM mock at `0xC000`, and executed by the simulated Verilog ASIC.
    *   *Goal:* Assert that the CPU's internal registers, ALU operations, and final memory writes match the exact expected behavior of a real 6502 processor executing the same code.
*   **Step 3. Static Linting (Verilator)**
    *   *Approach:* The Verilog exported from *Digital* is processed via Verilator (`--lint-only`).
    *   *Goal:* Catch floating nets, width mismatches, and accidentally inferred latches.
*   **Step 4. Formal Verification (SymbiYosys)**
    *   *Approach:* Claude Code generates SystemVerilog assertions defining the absolute rules of the multiplexed bus.
    *   *Goal:* Use mathematical solvers to definitively prove the FSM cannot enter a deadlock or illegal state, regardless of external inputs.
*   **Step 5. Gate-Level Simulation (GLS)**
    *   *Approach:* Re-running the original Cocotb BDD suite against the OpenLane-synthesized netlist and SDF (Standard Delay Format) file.
    *   *Goal:* Prove that the microscopic propagation delays of the physical standard cells do not violate the required setup and hold times of the memory bus.
*   **Step 6. Hardware Prototyping (iCE40 FPGA)**
    *   *Approach:* Synthesizing the *Digital*-exported Verilog through Project IceStorm and flashing it to a Lattice iCE40 FPGA.
    *   *Goal:* Interface the physical FPGA with a breadboard containing the actual latches and SRAM to validate real-world electrical timing before ASIC fabrication.

---

## Implementation and Submission Roadmap

| Phase       | Milestone                        | Execution Steps                                                                                                                                                                                                                                                                                                        | State |
|:------------|:---------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:----|
| **Phase 1** | **Environment & Infrastructure** | 1. Fork the official `TinyTapeout/ttsky-verilog-template` (Sky130 shuttle) GitHub repository.<br>2. Install OSS CAD Suite (Yosys, nextpnr, Verilator) and H. Neemann's *Digital*.<br>3. Configure Claude Code (`CLAUDE.md`) to output Cocotb Python test scripts directly to the project's `test/` directory.                                                          | Complete |
| **Phase 2** | **Scope Exploration**            | 1. Generate a markdown document that details all Opcodes for a 6502, including the various addressing modes, <br> 2. Create a ToDo list and ordering of OpCodes and modes to implement through discussion with the user<br> 3. Setup a toolchain to take 6502 ASM files and be able to compile them into 6502 machine code for later verification tests | Complete |
| **Phase 3** | **Bus Test Generation (TDD)** | 1. Prompt Claude Code to generate the Python mock objects for the latches and SRAM.<br>2. Generate the BDD Given/When/Then test suite checking address latching and data transfer.<br>3. Verify the test suite fails. | Complete |
| **Phase 4** | **ISA Test Campaign Setup** | 1. Write atomic `.asm` files for targeted 6502 opcodes (e.g., `LDA`, `STA`, `ADC`).<br>2. Write a Python Cocotb script that compiles the `.asm`, loads the binary into the ROM mock, pulses the reset vector, and asserts the final RAM state.<br>3. Verify these higher-level tests fail. | |
| **Phase 5** | **Logic Design** | 1. Open *Digital* and build the hierarchical FSM and 6502 subset ALU/Registers.<br>2. Export the design as a Verilog module.<br>3. Instantiate the exported Verilog inside the `tt_um_template.v` top-level file. | |
| **Phase 6** | **Simulation & Hardening** | 1. Run the Cocotb BDD suite (both Bus tests and ISA Assembly tests) against the exported Verilog.<br>2. Generate VCD files and inspect failing transitions in GTKWave.<br>3. Iterate the *Digital* schematic until all ISA compliance tests pass.<br>4. Run SymbiYosys formal proofs to guarantee FSM stability. | |
| **Phase 7** | **Physical Prototyping** | 1. Write the `pins.pcf` mapping file for the iCE40 FPGA board.<br>2. Breadboard the latches, 74HC138 decoder, and memory chips.<br>3. Flash the FPGA via `iceprog` and run physical logic analyzer tests on the memory bus. | |
| **Phase 8** | **ASIC Compilation** | 1. Push the final *Digital*-exported Verilog to the GitHub repository.<br>2. Monitor the automated OpenLane GitHub Action as it performs Logic Synthesis, Floorplanning, and Routing.<br>3. Verify Area and Gate Count limits. | |
| **Phase 9** | **Tapeout Submission** | 1. Review the automated Gate-Level Simulation (GLS) logs to ensure no timing violations occurred during layout.<br>2. Navigate to the Tiny Tapeout portal and paste the GitHub repository URL.<br>3. Finalize pin descriptions, select the target shuttle run, and complete checkout. | |