"""Async model of a generic byte-addressable SRAM.

Wired the way the PCB wires a real chip: address comes from a pair of
Latch573 mocks (holding A0-A7 / A8-A15), data is exchanged over the
ASIC's uio bus, and WE/OE are active-HIGH strobe bits carried on the
ASIC's control bus (uo_out) -- matching this design's "_set" convention
(ale_set, ahe_set, mwe_set, mre_set, ...: asserted when the bit is 1).
Writes are captured continuously while WE is high (so the byte present
on the bus when WE falls is what "sticks", matching a real SRAM's
write-cycle timing). Reads drive the bus continuously while OE is high.

Note: triggers are registered on the whole control bus signal, not
bit-selects -- Icarus Verilog's VPI cannot register value-change
callbacks on part-selects of a vector, only on the vector itself.
"""

import cocotb
from cocotb.triggers import Edge, First, NextTimeStep, ReadOnly

from mocks.bitutil import bit, byte


class SRAM:
    def __init__(self, low_latch, high_latch, data_out_signal, data_in_signal,
                 control_signal, we_bit, oe_bit, size=0x10000):
        self._low_latch = low_latch
        self._high_latch = high_latch
        self._data_out = data_out_signal
        self._data_in = data_in_signal
        self._control = control_signal
        self._we_bit = we_bit
        self._oe_bit = oe_bit
        self.memory = bytearray(size)
        self._task = cocotb.start_soon(self._run())

    @property
    def address(self):
        return (self._high_latch.value << 8) | self._low_latch.value

    def _we(self):
        return bit(self._control, self._we_bit)

    def _oe(self):
        return bit(self._control, self._oe_bit)

    async def _run(self):
        while True:
            await First(Edge(self._control), Edge(self._data_out))
            await ReadOnly()

            if self._we() == 1:
                self.memory[self.address] = byte(self._data_out)

            if self._oe() == 1:
                # Signals can't be written during ReadOnly, and this
                # simulator won't transition ReadOnly -> ReadWrite within
                # the same time step, so defer the write to the start of
                # the next time step instead.
                read_value = self.memory[self.address]
                await NextTimeStep()
                self._data_in.value = read_value

    def stop(self):
        self._task.kill()
