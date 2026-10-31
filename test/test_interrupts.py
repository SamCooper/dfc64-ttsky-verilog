"""Interrupt tests: one cocotb test per test/irq_tests/*.asm (see asm_harness.py).

Each test marks in its source when IRQ_n / NMI_n change, with a comment on an
instruction line (several may share a line):
    ; @irq         drive IRQ_n low (level; held until @irq_off)
    ; @irq_off     release IRQ_n
    ; @nmi         pulse NMI_n low for NMI_PULSE_CLOCKS clocks
    ; @nmi_low     hold NMI_n low        ; @nmi_high  release NMI_n
    ; @irq +3      any marker may be delayed by N DUT clocks
A marker fires once, on the first bus read of its instruction's address, and the pin
changes on the next falling clock edge. The reference model (sim6502.py) reads the same
markers to produce the .json and '; Cycles:' line.

Pins (active LOW, idle high): ui_in[IRQ_N] = IRQ_n, ui_in[NMI_N] = NMI_n.
"""
import os
import sys

import cocotb
from cocotb.triggers import ClockCycles, FallingEdge, ReadOnly, RisingEdge

from asm_harness import register_tests, run_asm_test
from test_bus import IRQ_N, NMI_N, UI_IDLE

_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_HERE, "asm_tests", "tools"))
import sim6502  # noqa: E402  (reference model: marker parser + assembler)

# Directory holding the .asm/.json interrupt test pairs
IRQ_TEST_DIR = os.environ.get("IRQ_TEST_DIR", "irq_tests")
RESULTS_FILE = os.environ.get("IRQ_RESULTS_FILE", os.path.join(_HERE, "irq_results.json"))

# How long '@nmi' holds NMI_n low (DUT clocks)
NMI_PULSE_CLOCKS = int(os.environ.get("IRQ_NMI_PULSE_CLOCKS", "2"))


class InterruptDriver:
    """Drives ui_in from the markers of one test, and records when each one fired."""

    def __init__(self, asm_file):
        self.markers = sim6502.parse_markers(asm_file)
        self.image, _ = sim6502.assemble(asm_file)
        self.pins = UI_IDLE
        self.clock = 0       # clocks since reset was released
        self.fired = {}      # (addr, index) -> clock the pin changed

    async def run(self, dut, sram):
        # vasm and the model must agree on where each marked instruction is
        for addr in self.markers:
            assert sram.memory[addr] == self.image[addr], (
                f"marker address ${addr:04X}: vasm has ${sram.memory[addr]:02X}, "
                f"model has ${self.image[addr]:02X}")
        pending = dict(self.markers)
        seen = 0
        while True:
            await RisingEdge(dut.clk)
            await ReadOnly()
            self.clock += 1
            new_reads = sram.reads[seen:]
            seen += len(new_reads)
            for addr in new_reads:
                for index, (action, delay) in enumerate(pending.pop(addr, ())):
                    cocotb.start_soon(self._apply(dut, addr, index, action, delay))

    async def _apply(self, dut, addr, index, action, delay):
        if delay:
            await ClockCycles(dut.clk, delay)
        await FallingEdge(dut.clk)
        self.fired[(addr, index)] = self.clock
        if action == "nmi":
            self._set(dut, NMI_N, 0, f"@nmi at ${addr:04X}")
            await ClockCycles(dut.clk, NMI_PULSE_CLOCKS)
            await FallingEdge(dut.clk)
            self._set(dut, NMI_N, 1, f"@nmi at ${addr:04X} (end of pulse)")
        else:
            pin, level = {"irq": (IRQ_N, 0), "irq_off": (IRQ_N, 1),
                          "nmi_low": (NMI_N, 0), "nmi_high": (NMI_N, 1)}[action]
            self._set(dut, pin, level, f"@{action} at ${addr:04X}")

    def _set(self, dut, pin, level, why):
        self.pins = (self.pins & ~(1 << pin)) | (level << pin)
        dut.ui_in.value = self.pins
        name = "IRQ_n" if pin == IRQ_N else "NMI_n"
        dut._log.info(f"clock {self.clock}: {name} = {level} ({why})")

    def report(self):
        lines = ["Interrupt markers:"]
        for addr, actions in sorted(self.markers.items()):
            for index, (action, delay) in enumerate(actions):
                when = self.fired.get((addr, index))
                tag = f"@{action}" + (f" +{delay}" if delay else "")
                lines.append(f"  ${addr:04X} {tag:<12} "
                             + (f"fired at clock {when}" if when is not None else "NEVER FIRED"))
        return "\n".join(lines)


async def run_interrupt_test(dut, asm_file, info):
    driver = InterruptDriver(asm_file)
    try:
        await run_asm_test(dut, asm_file, info, stimulus=driver.run)
    except AssertionError as e:
        raise AssertionError(f"{e}\n{driver.report()}") from e
    dut._log.info(driver.report())


register_tests(globals(), IRQ_TEST_DIR, RESULTS_FILE, update_report=False, run=run_interrupt_test)
