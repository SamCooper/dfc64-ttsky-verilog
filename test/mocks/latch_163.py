"""Model of the external address latches: 74HC163 synchronous presettable counters.

Chip pins (names as in the README): PE_n (parallel load, active LOW), SR_n (synchronous
clear, active LOW), CEP and CET (count enables, active HIGH, both needed to count),
TC (terminal count: CET and Q == 15, used to cascade). Everything happens on the rising
clock edge, with priority clear > load > count.

Each address byte is a pair of 4-bit chips and the two bytes are cascaded so that an
increment carries across all four chips and therefore across the whole 16-bit address:

    chip   A3-A0   A7-A4   A11-A8   A15-A12
    CET    1       TC0     TC1      TC2
    CEP    ADDR_INC strobe on every chip
    PE_n   LOAD_L_n, LOAD_L_n, LOAD_H_n, LOAD_H_n   (low pair, high pair)
    SR_n   high (disabled), or ZP_CLR_n (upper pair only)

The ASIC's output pins (uo_out) are wired straight to the chips: LOAD_L_n / LOAD_H_n to
PE_n and ZP_CLR_n to SR_n (all active LOW), ADDR_INC to CEP (active HIGH). A pin that is X
or Z counts as not asserted. Pins are sampled the way a synchronous part samples them:
what they held *before* the rising clock edge decides what happens at that edge.

`Counter163` and `Counter8` are plain Python (no simulator needed) so the counting logic
can be unit-tested on its own; `Latch` wires a `Counter8` to the DUT's pins.
"""

import logging

import cocotb
from cocotb.triggers import FallingEdge, RisingEdge
from mocks.bitutil import asserted_low, bit


class Counter163:
    """One 74HC163: a 4-bit synchronous counter with parallel load."""

    def __init__(self):
        self.value = 0

    def tc(self, cet=True):
        """Terminal count: high when the count is 15 and CET is high."""
        return bool(cet) and self.value == 0xF

    def clock(self, *, sr_n=True, pe_n=True, data=0, cep=False, cet=True):
        """Apply one rising clock edge (pins as on the chip: SR_n and PE_n active low).

        Priority: synchronous clear, then parallel load, then count (needs CEP and CET).
        """
        if not sr_n:
            self.value = 0
        elif not pe_n:
            self.value = data & 0xF
        elif cep and cet:
            self.value = (self.value + 1) & 0xF


class Counter8:
    """An address byte: two cascaded 74HC163s sharing PE_n, SR_n and CEP."""

    def __init__(self):
        self.low = Counter163()    # bits 3:0, CET from the byte below (or tied high)
        self.high = Counter163()   # bits 7:4, CET = TC of the low chip

    @property
    def value(self):
        return (self.high.value << 4) | self.low.value

    def tc(self, cet=True):
        """Terminal count of the byte (feeds CET of the next byte's low chip)."""
        return self.high.tc(self.low.tc(cet))

    def clock(self, *, sr_n=True, pe_n=True, data=0, cep=False, cet=True):
        # The high chip's CET is the low chip's TC *before* the edge
        high_cet = self.low.tc(cet)
        self.low.clock(sr_n=sr_n, pe_n=pe_n, data=data, cep=cep, cet=cet)
        self.high.clock(sr_n=sr_n, pe_n=pe_n, data=data >> 4, cep=cep, cet=high_cet)


class Latch:
    """One address byte of the external latches, wired to the DUT's pins.

    control_signal / pe_n_bit  active-low pin wired to PE_n: loads the byte from `data_signal`
    cep_bit                    active-high ADDR_INC pin wired to CEP (optional)
    sr_n_bit                   active-low pin wired to SR_n, the synchronous clear (optional;
                               SR_n is tied high when omitted)
    carry_in                   the lower `Latch` whose TC enables this one
                               (omit for the lowest byte)
    """

    def __init__(self, clk, control_signal, pe_n_bit, data_signal, cep_bit=None, sr_n_bit=None,
                 carry_in=None):
        self._clk = clk
        self._control = control_signal
        self._pe_n_bit = pe_n_bit
        self._cep_bit = cep_bit
        self._sr_n_bit = sr_n_bit
        self._data = data_signal
        self._carry_in = carry_in
        self._counter = Counter8()
        self._log = logging.getLogger(f"cocotb.latch{pe_n_bit}")
        self._task = cocotb.start_soon(self._run())

    @property
    def value(self):
        return self._counter.value

    @property
    def carry_out(self):
        """Terminal count of this byte: it is 0xFF and the carry into it is set."""
        return self._counter.tc(self._cet())

    def _cet(self):
        return True if self._carry_in is None else self._carry_in.carry_out

    def _high(self, bit_index):
        return bit_index is not None and bit(self._control, bit_index) == 1

    def _low(self, bit_index):
        return bit_index is not None and asserted_low(self._control, bit_index)

    async def _run(self):
        while True:
            # Control, data and the lower byte's carry are stable by the falling edge
            # (the DUT only changes them just after a rising edge), so sample them there
            # and apply them at the next rising edge, as a synchronous part would.
            await FallingEdge(self._clk)
            load = self._low(self._pe_n_bit)
            clear = self._low(self._sr_n_bit)
            cep = self._high(self._cep_bit)
            cet = self._cet()
            data = self._data.value
            if load and not data.is_resolvable:
                load = False           # undriven/unknown bus: nothing sensible to load
            data = data.to_unsigned() if load else 0

            await RisingEdge(self._clk)
            before = self.value
            self._counter.clock(sr_n=not clear, pe_n=not load, data=data, cep=cep, cet=cet)
            if self.value != before or load or clear:
                what = "clear" if clear else "load" if load else "count"
                self._log.info(f"Latch {what}: {self.value:#04x}")

    def stop(self):
        self._task.kill()
