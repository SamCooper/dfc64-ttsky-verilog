"""Async model of a generic byte-addressable SRAM.

Wired the way the PCB wires a real chip: address comes from a pair of
Latch573 mocks (holding A0-A7 / A8-A15), data is exchanged over the
ASIC's uio bus, and WE_n / OE_n are active-low control bits carried on
the ASIC's control bus (uo_out). Writes are captured continuously while
WE_n is low (so the byte present on the bus when WE_n rises is what
"sticks", matching a real SRAM's write-cycle timing). Reads drive the
bus continuously while OE_n is low.

Note: triggers are registered on the whole control bus signal, not
bit-selects -- Icarus Verilog's VPI cannot register value-change
callbacks on part-selects of a vector, only on the vector itself.
"""

import cocotb
from cocotb.triggers import Edge, First, ReadOnly


class SRAM:
    def __init__(self, low_latch, high_latch, data_out_signal, data_in_signal,
                 control_signal, we_n_bit, oe_n_bit, size=0x10000):
        self._low_latch = low_latch
        self._high_latch = high_latch
        self._data_out = data_out_signal
        self._data_in = data_in_signal
        self._control = control_signal
        self._we_n_bit = we_n_bit
        self._oe_n_bit = oe_n_bit
        self.memory = bytearray(size)
        self._task = cocotb.start_soon(self._run())

    @property
    def address(self):
        return (self._high_latch.value << 8) | self._low_latch.value

    def _we_n(self):
        return (int(self._control.value) >> self._we_n_bit) & 1

    def _oe_n(self):
        return (int(self._control.value) >> self._oe_n_bit) & 1

    async def _run(self):
        while True:
            await First(Edge(self._control), Edge(self._data_out))
            await ReadOnly()

            if self._we_n() == 0:
                self.memory[self.address] = int(self._data_out.value) & 0xFF

            if self._oe_n() == 0:
                self._data_in.value = self.memory[self.address]

    def stop(self):
        self._task.kill()
