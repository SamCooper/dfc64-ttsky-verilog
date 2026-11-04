Build the support board described under *External hardware*: address counters, the 74HC138 decoder
and RAM/ROM wired to the shared `uio[7:0]` bus, all clocked from the same oscillator as the ASIC.

1. Program a 6502 binary into the ROM at `0xC000-0xFFFF`, with the reset vector at `0xFFFC/D`
   pointing at your code.
2. Hold `IRQ_n` and `NMI_n` (`ui[0]`, `ui[1]`) high so no interrupts are requested.
3. Pulse `rst_n` low, then release it. The CPU fetches the reset vector and starts executing.
4. Watch the bus control outputs on `uo_out[5:0]` and the multiplexed address/data on `uio[7:0]`
   with a logic analyser, or check the results your program writes to RAM or I/O.

In simulation, run the cocotb suite with `make -C test`. It drives only the real Tiny Tapeout pins,
so the same tests run against the RTL and the gate-level netlist.
