"""Unit tests for the 74HC163 counter model in mocks/latch_163.py (plain Python, no simulator).

Run with:  python -m pytest test/test_counters.py
"""

from mocks.latch_163 import Counter163, Counter8


def make_address(value=0):
    """Four 74HC163s as two cascaded bytes, loaded with `value`."""
    low, high = Counter8(), Counter8()
    clock(low, high, load_low=True, load_high=True, data_low=value & 0xFF, data_high=value >> 8)
    return low, high


def clock(low, high, load_low=False, load_high=False, data_low=0, data_high=0, inc=False,
          clear_high=False):
    """One rising edge of the four-chip chain. load_* / clear_high say what the ASIC asks
    for; they become the chips' active-low PE_n / SR_n here. The high byte's CET is the
    low byte's TC *before* the edge."""
    high_cet = low.tc()
    low.clock(pe_n=not load_low, data=data_low, cep=inc)
    high.clock(sr_n=not clear_high, pe_n=not load_high, data=data_high, cep=inc, cet=high_cet)


def address(low, high):
    return (high.value << 8) | low.value


def test_chip_loads_and_counts():
    chip = Counter163()
    chip.clock(pe_n=False, data=0x9)
    assert chip.value == 0x9
    chip.clock(cep=True)
    assert chip.value == 0xA


def test_chip_load_is_active_low():
    chip = Counter163()
    chip.clock(pe_n=True, data=0x9)
    assert chip.value == 0


def test_chip_counts_only_with_both_enables():
    chip = Counter163()
    chip.clock(cep=True, cet=False)
    chip.clock(cep=False, cet=True)
    assert chip.value == 0


def test_chip_load_beats_count_and_wraps():
    chip = Counter163()
    chip.clock(pe_n=False, data=0xF, cep=True)
    assert chip.value == 0xF and chip.tc()
    chip.clock(cep=True)
    assert chip.value == 0 and not chip.tc()


def test_chip_terminal_count_needs_cet():
    chip = Counter163()
    chip.clock(pe_n=False, data=0xF)
    assert chip.tc(cet=True) and not chip.tc(cet=False)


def test_chip_clear_is_synchronous_active_low_and_beats_load():
    chip = Counter163()
    chip.clock(pe_n=False, data=0xB)
    chip.clock(sr_n=True)                    # clear not asserted
    assert chip.value == 0xB
    chip.clock(sr_n=False, pe_n=False, data=0x5, cep=True)
    assert chip.value == 0


def test_increment_within_low_nibble():
    low, high = make_address(0x1203)
    clock(low, high, inc=True)
    assert address(low, high) == 0x1204


def test_increment_carries_between_nibbles():
    low, high = make_address(0x120F)
    clock(low, high, inc=True)
    assert address(low, high) == 0x1210


def test_increment_carries_from_low_byte_into_high_byte():
    low, high = make_address(0x12FF)
    clock(low, high, inc=True)
    assert address(low, high) == 0x1300


def test_increment_carries_across_all_four_chips_and_wraps():
    low, high = make_address(0xFFFF)
    clock(low, high, inc=True)
    assert address(low, high) == 0x0000


def test_no_carry_unless_every_lower_chip_is_full():
    for start in (0x01FF, 0x10FF, 0x0FFE, 0xFEFF):
        low, high = make_address(start)
        clock(low, high, inc=True)
        assert address(low, high) == start + 1


def test_counts_every_value_in_sequence():
    low, high = make_address(0x0FF0)
    for expected in range(0x0FF1, 0x1010):
        clock(low, high, inc=True)
        assert address(low, high) == expected


def test_holds_without_increment():
    low, high = make_address(0xABCD)
    clock(low, high)
    assert address(low, high) == 0xABCD


def test_loading_one_byte_leaves_the_other():
    low, high = make_address(0x1234)
    clock(low, high, load_high=True, data_high=0x56)
    assert address(low, high) == 0x5634
    clock(low, high, load_low=True, data_low=0x78)
    assert address(low, high) == 0x5678


def test_load_wins_over_increment_on_the_loaded_byte():
    low, high = make_address(0x0010)
    clock(low, high, load_low=True, data_low=0x20, inc=True)
    assert address(low, high) == 0x0020


def test_carry_still_ripples_into_an_unloaded_byte_while_loading():
    # As on the real chain: the high chips only see ENP and the low chips' RCO, so a
    # simultaneous low-byte load + increment still bumps the high byte if the old low
    # byte was 0xFF.
    low, high = make_address(0x00FF)
    clock(low, high, load_low=True, data_low=0x10, inc=True)
    assert address(low, high) == 0x0110


def test_clear_zeroes_the_high_byte_only():
    low, high = make_address(0x12AB)
    clock(low, high, clear_high=True)
    assert address(low, high) == 0x00AB


def test_clear_beats_increment_and_load_on_the_high_byte():
    low, high = make_address(0x12FF)
    clock(low, high, inc=True, clear_high=True, load_high=True, data_high=0x77)
    assert address(low, high) == 0x0000
