![DFC64 logo](../logo.svg "DFC64")

This project implements a 6502 instruction level compatible 8-bit CPU featuring a 16-bit address space and an 8-bit data bus, heavily relying on external off-chip decoding to fit within the physical I/O constraints of a single ASIC tile.
The CPU uses the IO pins of the Tiny Tapeout footprint as follows:

* 8 input pins
  * These are used to control aspects of the CPU such as reset, NMIs, halts, etc
* 8 output pins
  * These are used by the CPU to signal reading and writing of address and data words to the support ICs
* 8 bidirectional pins
  * This forms the data bus of the CPU and is used for all inputs and outs including both hi and low bytes of addresses as well as any data words in and out

**Not supported:** decimal (BCD) mode. `SED` and `CLD` set and clear the D flag, and the flag is saved and restored by `PHP`/`PLP`/`BRK`/`RTI`, but `ADC` and `SBC` ignore it and always do binary arithmetic. There are no decimal-mode tests.
