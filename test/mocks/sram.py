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
from cocotb.triggers import Edge, Timer, First
from cocotb.types import LogicArray
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
            # 1. TRIGGERING
            # If your address is a calculated property and NOT a physical signal handle, 
            # remove the Edge(self._address_handle) line!
            triggers = [Edge(self._control), Edge(self._data_out)]
            
            # Only add the address trigger if you actually have a handle to the pins
            if hasattr(self, '_address_pins'):
                triggers.append(Edge(self._address_pins))
                
            await First(*triggers)

            # 2. DELAY
            # Simulate physical propagation delay to escape the delta-cycle 
            # without using ReadOnly() or NextTimeStep()
            await Timer(20, unit="ns")

            # 3. WRITE CYCLE
            if self._we() == 1:
                data_val = self._data_out.value
                # Defensive check: Only write if the bus has valid 1s and 0s. 
                # If it's full of 'Z's or 'X's, attempting to cast to int will crash.
                if data_val.is_resolvable:
                    self.memory[self.address] = data_val.integer
                else:
                    self.dut._log.warning(f"Attempted to write unresolved data to RAM: {data_val}")

            # 4. READ CYCLE
            if self._oe() == 1:
                if 0 <= self.address < len(self.memory):
                    read_value = self.memory[self.address]
                else:
                    read_value = 0x00 # Default fallback
                
                print ("Data read: ", hex(self.address))
                self._data_in.value = read_value
            else:
                # 5. HIGH IMPEDANCE
                # Release the bus when not reading so the ASIC can drive it
                self._data_in.value = LogicArray("ZZZZZZZZ")

    def stop(self):
        self._task.kill()
