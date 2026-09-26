"""Async model of a 74HC573 octal transparent latch.

Real part behavior: while LE is high the Q outputs follow D (transparent);
the instant LE falls, Q freezes at whatever D held at that moment. This
model reproduces that by re-sampling the data bus on every change of
either the control bus (which carries LE) or the data bus, so it also
catches data changing while LE is still high (as a real transparent latch
would).

Note: triggers are registered on whole vector signals (e.g. uo_out), not
bit-selects -- Icarus Verilog's VPI cannot register value-change callbacks
on part-selects of a vector, only on the vector itself.
"""

import cocotb
from cocotb.triggers import Edge, First, ReadOnly


class Latch573:
    def __init__(self, control_signal, le_bit, data_signal):
        self._control = control_signal
        self._le_bit = le_bit
        self._data = data_signal
        self.value = 0
        self._task = cocotb.start_soon(self._run())

    def _le(self):
        return (int(self._control.value) >> self._le_bit) & 1

    async def _run(self):
        while True:
            await First(Edge(self._control), Edge(self._data))
            await ReadOnly()
            if self._le() == 1:
                self.value = int(self._data.value)

    def stop(self):
        self._task.kill()
