# Sample testbench for a Tiny Tapeout project

This is a sample testbench for a Tiny Tapeout project. It uses [cocotb](https://docs.cocotb.org/en/stable/) to drive the DUT and check the outputs.
See below to get started or for more information, check the [website](https://tinytapeout.com/hdl/testing/).

## Setting up

1. Edit [Makefile](Makefile) and modify `PROJECT_SOURCES` to point to your Verilog files.
2. Edit [tb.v](tb.v) and replace `tt_um_example` with your module name.

## How to run

To run the RTL simulation:

```sh
make -B
```

To run gatelevel simulation, first harden your project and copy `../runs/wokwi/results/final/verilog/gl/{your_module_name}.v` to `gate_level_netlist.v`.

Then run:

```sh
make -B GATES=yes
```

If you wish to save the waveform in VCD format instead of FST format, edit tb.v to use `$dumpfile("tb.vcd");` and then run:

```sh
make -B FST=
```

This will generate `tb.vcd` instead of `tb.fst`.

## How to view the waveform file

Using GTKWave

```sh
gtkwave tb.fst tb.gtkw
```

Using Surfer

```sh
surfer tb.fst
```

## DFC64 suites

`make` runs both suites (`COCOTB_TEST_MODULES=test_assembly,test_interrupts`); run one with
e.g. `make COCOTB_TEST_MODULES=test_interrupts`. Both share the runner in `asm_harness.py`:
each `.asm` is assembled with vasm, run until the second read of its `; Done:` address, and
RAM `$0000-$BFFF` must then match its `.json` exactly.

- `test_assembly.py` runs `asm_tests/*.asm` (instructions).
- `test_interrupts.py` runs `irq_tests/*.asm` (IRQ/NMI). Results go to `irq_results.json`.

### Interrupt markers

Interrupt tests mark when the interrupt pins change with a comment on an instruction line
(pins are active low: `ui_in[0]` = IRQ_n, `ui_in[1]` = NMI_n):

| Marker      | Effect                                               |
| :---------- | :--------------------------------------------------- |
| `@irq`      | IRQ_n low (held until `@irq_off`)                    |
| `@irq_off`  | IRQ_n high                                           |
| `@nmi`      | NMI_n low for `IRQ_NMI_PULSE_CLOCKS` (default 2) clocks |
| `@nmi_low`  | NMI_n low (held)                                     |
| `@nmi_high` | NMI_n high                                           |

```
wait:   jmp wait        ; @irq
irq:    php             ; @irq_off
```

- A marker fires once, on the **first bus read** of its instruction's address; the pin
  changes on the next falling clock edge. `@irq +3` delays the change by 3 DUT clocks.
- First read includes dummy reads: a 1-byte instruction or a taken branch may read the
  next address early. Don't put a marker straight after one unless the result is the same
  either way (enter a marked wait loop with `jmp wait`).
- The DFC64 and the 6502 differ in clocks per instruction, so write tests whose result
  doesn't depend on exactly which instruction boundary takes the interrupt: raise it on a
  `jmp wait` loop (the pushed PC is then always `wait`) and leave the loop by patching the
  stacked return address in the handler.
- On a failure the message lists each marker and the clock it fired at, or NEVER FIRED.

The expected `.json` and the `; Cycles:` / `; Done:` lines come from the reference model,
which reads the same markers (it ignores `+N` delays):

```sh
python3 asm_tests/tools/sim6502.py --stamp --write-json irq_tests/*.asm
```
