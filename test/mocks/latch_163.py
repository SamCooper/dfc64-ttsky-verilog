import logging

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly
from mocks.bitutil import bit


class Latch:
    def __init__(self, clk, control_signal, le_bit, data_signal):
        self._clk = clk 
        self._control = control_signal
        self._le_bit = le_bit
        self._data = data_signal
        self.value = 0
        self._log = logging.getLogger(f"cocotb.latch{le_bit}")
        self._task = cocotb.start_soon(self._run())

    def _le(self):
        return bit(self._control, self._le_bit)

    async def _run(self):
        while True:
            # 2. Wait strictly for the clock edge, ignoring data/control glitches
            await RisingEdge(self._clk)
            
            # 3. Yield to the end of the delta-cycle to read the stable setup values
            await ReadOnly()
            
            # 4. Evaluate the active-high load state
            if self._le() == 1:
                val = self._data.value
                # Defensive check for Z or X states
                if val.is_resolvable:
                    self._log.info(f"Latch Load: {hex(val.to_unsigned())}")
                    self.value = val.to_unsigned()

    def stop(self):
        self._task.kill()
