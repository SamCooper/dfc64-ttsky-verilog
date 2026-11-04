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
