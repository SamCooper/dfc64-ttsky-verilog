**External Support ICs**
1.  **Lower Address Counters (2× 74HC163):**
    *   *Inputs:* Wired to the ASIC's `uio[7:0]` bus.
    *   *Clock:* Tied to the main external system oscillator.
    *   *Control:* `PE_n` (Load, active low) driven directly by `LOAD_L_n`. `CEP` (Count enable) driven by `ADDR_INC`. `CET` of the lowest chip tied HIGH; each following chip's `CET` driven by the `TC` of the chip below. `SR_n` (Clear) tied HIGH (disabled). 
    *   *Outputs:* Drives physical `A0-A7`. The `TC` (Terminal Count) of the top lower chip feeds `CET` of the upper counters, so an increment carries across all four chips and rolls over the full 16 bits.
2.  **Upper Address Counters (2× 74HC163):**
    *   *Inputs:* Wired to the ASIC's `uio[7:0]` bus.
    *   *Clock:* Tied to the main external system oscillator.
    *   *Control:* `PE_n` driven directly by `LOAD_H_n`. `CEP` driven by `ADDR_INC`. `CET` chained from the `TC` of the chip below. `SR_n` (Clear) driven by `ZP_CLR_n`, allowing instant Zero Page access.
    *   *Outputs:* Drives physical `A8-A15`. 
3.  **Address Decoder (1× 74HC138 & 1x 74HC08 AND Gate):**
    *   *Inputs:* Reads `A13`, `A14`, and `A15` directly from the Upper Address Counters.
    *   *Outputs:* Asserts one of eight active-low `Y` pins, combined via AND gates to drive the `CS_n` pins on physical memory chips.
4.  **Memory Chips (3.3V SRAM / EEPROM):**
    *   *Address Lines:* Driven continuously by the 74HC163 arrays.
    *   *Data Lines:* Wired back to the ASIC's `uio[7:0]` bus.
    *   *Control Lines:* `WE_n` and `OE_n` driven directly by `MEM_WE_n` and `MEM_OE_n`. `CS_n` driven by the 74HC138 logic.
