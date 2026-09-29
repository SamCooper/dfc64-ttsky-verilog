# SPDX-FileCopyrightText: © 2026 Sam Cooper
# SPDX-License-Identifier: Apache-2.0

"""Bus test suite implementing test/features/bus_latching.feature.

Pin mapping (per src/project.v's `assign uo_out = {3'b0, mre_set, mwe_set,
ai_set, ahe_set, ale_set}`), all active-HIGH strobes matching this design's
"_set" convention (asserted when the bit is 1):
    uo_out[0] = ALE_L (ale_set)   uo_out[1] = ALE_H (ahe_set)
    uo_out[3] = MEM_WE (mwe_set) uo_out[4] = MEM_OE (mre_set)

Drives/observes only real TT pins (ui_in, uo_out, uio_in, uio_out, clk,
rst_n, ena), per CLAUDE.md, so this suite is unchanged when later run
against the gate-level netlist.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Edge, SimTimeoutError, with_timeout

from mocks.bitutil import bit, byte
from mocks.latch_573 import Latch
from mocks.sram import SRAM

ALE_L = 0
ALE_H = 1
ALE_I = 2
MEM_WE = 3
MEM_OE = 4

RESET_VECTOR = 0xFFFC


async def _boot(dut):
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)


def _wire_bus(dut):
    """Given: instantiate the off-chip latches + SRAM, wired to the DUT's pins."""
    low_latch = Latch(dut.uo_out, ALE_L, dut.uio_out)
    high_latch = Latch(dut.uo_out, ALE_H, dut.uio_out)
    sram = SRAM(
        low_latch,
        high_latch,
        data_out_signal=dut.uio_out,
        data_in_signal=dut.uio_in,
        control_signal=dut.uo_out,
        we_bit=MEM_WE,
        oe_bit=MEM_OE,
    )
    return low_latch, high_latch, sram


async def _watch_rising_bit(control_signal, bit_index, on_rise):
    """Repeatedly waits for `control_signal` (a whole vector) to change and
    calls `on_rise()` whenever the given bit rises 0->1 (this design's
    "_set" signals -- e.g. mwe_set, mre_set -- are active-high strobes).

    Icarus Verilog's VPI can't register value-change callbacks on
    bit-selects of a vector, so bit edges are detected in Python off
    whole-vector Edge triggers instead.
    """
    previous = bit(control_signal, bit_index)
    while True:
        await Edge(control_signal)
        current = bit(control_signal, bit_index)
        if previous == 0 and current == 1:
            on_rise()
        previous = current


@cocotb.test()
async def test_reset_vector_fetch_reads_and_latches_correct_addresses(dut):
    """
    Given a reset vector at $FFFC/$FFFD pointing at $1234, with opcode
      $EA (NOP) stored at $1234,
    When the ASIC comes out of reset,
    Then the low/high address latches sequentially capture $FFFC then
      $FFFD while MEM_OE_n reads back the vector bytes, and finally the
      address latches capture $1234 while MEM_OE_n reads back the opcode
      byte.
    """
    await _boot(dut)
    low_latch, high_latch, sram = _wire_bus(dut)

    target = 0x1234
    sram.memory[RESET_VECTOR] = target & 0xFF
    sram.memory[RESET_VECTOR + 1] = (target >> 8) & 0xFF
    sram.memory[target] = 0xEA  # NOP

    # When: release reset.
    dut.rst_n.value = 1

    reads = []
    cocotb.start_soon(
        _watch_rising_bit(dut.uo_out, MEM_OE, lambda: reads.append(sram.address))
    )

    try:
        await with_timeout(ClockCycles(dut.clk, 40), 400, "us")
    except SimTimeoutError:
        pass

    # Then: the CPU's first bus cycles fetch the reset vector, then the
    # opcode it points at.
    assert RESET_VECTOR in reads, (
        f"expected a memory read of the reset vector low byte at "
        f"${RESET_VECTOR:04X}; observed reads at "
        f"{[f'${a:04X}' for a in reads]}"
    )
    assert (RESET_VECTOR + 1) in reads, (
        f"expected a memory read of the reset vector high byte at "
        f"${RESET_VECTOR + 1:04X}; observed reads at "
        f"{[f'${a:04X}' for a in reads]}"
    )
    assert target in reads, (
        f"expected a memory read of the first opcode at ${target:04X}; "
        f"observed reads at {[f'${a:04X}' for a in reads]}"
    )


@cocotb.test()
async def test_cpu_write_reaches_memory(dut):
    """
    Given a reset vector pointing at a small program that stores a known
      byte to a known address ($STA $2000, #$7E, then an infinite loop),
    When the ASIC executes it,
    Then the SRAM mock observes MEM_WE_n asserted with the address
      latches holding $2000 and $7E on the bus.
    """
    await _boot(dut)
    low_latch, high_latch, sram = _wire_bus(dut)

    target_addr = 0x2000
    expected_value = 0x7E
    program_start = 0x1234

    sram.memory[RESET_VECTOR] = program_start & 0xFF
    sram.memory[RESET_VECTOR + 1] = (program_start >> 8) & 0xFF
    # LDA #$7E ; STA $2000 ; JMP program_start (spin)
    sram.memory[program_start + 0] = 0xA9  # LDA #imm
    sram.memory[program_start + 1] = expected_value
    sram.memory[program_start + 2] = 0x8D  # STA abs
    sram.memory[program_start + 3] = target_addr & 0xFF
    sram.memory[program_start + 4] = (target_addr >> 8) & 0xFF
    sram.memory[program_start + 5] = 0x4C  # JMP abs
    sram.memory[program_start + 6] = program_start & 0xFF
    sram.memory[program_start + 7] = (program_start >> 8) & 0xFF

    dut.rst_n.value = 1

    writes = []
    cocotb.start_soon(
        _watch_rising_bit(
            dut.uo_out,
            MEM_WE,
            lambda: writes.append((sram.address, byte(dut.uio_out))),
        )
    )

    try:
        await with_timeout(ClockCycles(dut.clk, 60), 600, "us")
    except SimTimeoutError:
        pass

    assert (target_addr, expected_value) in writes, (
        f"expected a write of ${expected_value:02X} to ${target_addr:04X}; "
        f"observed writes {[(f'${a:04X}', f'${v:02X}') for a, v in writes]}"
    )
    assert sram.memory[target_addr] == expected_value
