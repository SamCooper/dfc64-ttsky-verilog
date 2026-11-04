### Physical Setup and PCB Routing

The ASIC interfaces with external memory through a shared 8-bit bidirectional bus and dedicated control lines. The physical PCB requires some primary support logic chips alongside the actual RAM/ROM chips.

Instead of basic transparent latches, the PCB utilizes fully synchronous presettable counters (74HC163s). This allows the ASIC to perform 1-cycle burst sequential reads (by pulsing an increment pin). 1-cycle Zero Page fetches are possible by clearing the upper address hardware synchronously (through the upper counters' `SR_n` pins). The ASIC and the PCB logic share a single external free-running clock, ensuring perfect cycle synchronization.

**ASIC Pin Assignments**
*   **System Clock (`clk`):** Driven by the external PCB oscillator.
*   **Bidirectional (`uio[7:0]`):** The time-multiplexed bus. Sequentially pushes the lower address, upper address, and finally reads/writes data. An enhancement exists where the addresses being read/written are sequential and therefore the address in the latch can be incremented in a single cycle rather than needing to be completely overwritten.
*   **Outputs (`uo_out[7:0]`):** The synchronized bus control signals. They are wired straight to the 74HC163 counters and the memory, so each pin has the polarity of the chip pin it drives (the CPU logic itself is active-high; the inversion is done at the top level):
    *   `uo_out[0]` - `LOAD_L_n`: Active-low parallel load for the lower address byte (`PE_n` of the lower counters).
    *   `uo_out[1]` - `LOAD_H_n`: Active-low parallel load for the upper address byte (`PE_n` of the upper counters).
    *   `uo_out[2]` - `ADDR_INC`: Active-high count enable to increment the full 16-bit address (`CEP` of all four counters).
    *   `uo_out[3]` - `MEM_WE_n`: Active-low Memory Write Enable.
    *   `uo_out[4]` - `MEM_OE_n`: Active-low Memory Output Enable.
    *   `uo_out[5]` - `ZP_CLR_n`: Active-low synchronous clear for the upper address byte (`SR_n` of the upper counters; Zero Page optimization).
    *   `uo_out[6:7]` - Unused (Available for future interrupts, NMI, or dedicated Chip Selects).
