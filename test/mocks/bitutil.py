"""Helpers for reading cocotb signal values that may contain X/Z bits.

Partially-built RTL routinely leaves some outputs undriven (X) until every
consumer of a signal exists, so a "read this bit" or "read this byte" call
during early bring-up must not raise -- it should just report the unknown
bits as not-asserted, the same way a logic analyzer reads a floating pin
as whatever the pull direction says.
"""

from cocotb.types import Logic


def bit(signal, index):
    """Returns the given bit of `signal` as 0 or 1, treating X/Z as 0."""
    return 1 if signal.value[index] == Logic("1") else 0


def byte(signal):
    """Returns the full value of `signal` as an int, treating X/Z bits as 0."""
    value = signal.value
    return sum(bit(signal, i) << i for i in range(len(value)))
