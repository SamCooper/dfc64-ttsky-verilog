"""Shared runner for the .asm/.json test suites (test_assembly.py, test_interrupts.py).

Each .asm is assembled with vasm, loaded as ROM at $C000 and run until the second read
of its '; Done:' address. RAM $0000-$BFFF must then match the .json exactly (every other
byte still zero) and the ROM image must be intact.
"""
import os
import re
import glob
import json
import subprocess
import sys
import time
import tempfile
import cocotb
from cocotb.triggers import ClockCycles, Event, First, ReadOnly, RisingEdge

from test_bus import _boot, _wire_bus

_HERE = os.path.dirname(os.path.abspath(__file__))


def _vasm():
    """The assembler: $VASM, else the copy in tools/vasm/, else vasm6502_oldstyle on PATH."""
    bundled = os.path.join(_HERE, "..", "tools", "vasm", "vasm6502_oldstyle")
    return os.environ.get("VASM") or (bundled if os.access(bundled, os.X_OK) else "vasm6502_oldstyle")

# DFC64 clocks per 6502 cycle used for the timeout budget. Not known yet, so this is
# deliberately generous; override with the environment variable once measured.
CLOCKS_PER_CYCLE = int(os.environ.get("ASM_CLOCKS_PER_CYCLE", "8"))
TIMEOUT_MARGIN = 2           # budget multiplier on top of the expected clocks
RESET_CYCLES = 7             # 6502 reset sequence (not included in '; Cycles:')
LOOP_CYCLES = 3              # one pass of 'done: jmp done'

# Reads of the Done address needed before stopping. The first can be a dummy read
# made by the 1-byte instruction just before 'done:' (e.g. the final PHP, before its
# stack write), so wait for the second, which is the loop fetching itself again.
DONE_READS = 2


def _read_header(asm_file):
    """Return (cycles, done_address) from the '; Cycles:' and '; Done:' header lines."""
    with open(asm_file, "r") as f:
        text = f.read()
    cycles = re.search(r"^; Cycles: (\d+)\s*$", text, re.M)
    done = re.search(r"^; Done: \$([0-9A-Fa-f]{4})\s*$", text, re.M)
    assert cycles and done, \
        f"{os.path.basename(asm_file)} is missing the '; Cycles:' / '; Done:' header lines"
    return int(cycles.group(1)), int(done.group(1), 16)


async def _watch_done(dut, sram, done_addr, reached, state):
    """Set `reached` once the Done address has been read DONE_READS times.

    Uses the SRAM mock's own record of reads (sram.reads, a list of addresses), so
    the harness sees exactly what memory saw. Only the reads added since the last
    clock are scanned.
    """
    seen = 0
    while True:
        await RisingEdge(dut.clk)
        await ReadOnly()
        state["clocks"] += 1
        new_reads = sram.reads[seen:]
        seen += len(new_reads)
        for addr in new_reads:
            if addr == done_addr:
                state["done_reads"] += 1
                if state["done_reads"] == 1:
                    state["first_done_clock"] = state["clocks"]
        if state["done_reads"] >= DONE_READS:
            reached.set()
            return


async def run_asm_test(dut, asm_file, info, stimulus=None):
    """Compile and execute a single assembly test, checking full memory integrity.

    `stimulus(dut, sram)`, if given, returns a coroutine that is started alongside the
    Done watcher just before reset is released (the ROM is already loaded by then).
    """

    # 1. Path Resolution
    asm_filename = os.path.basename(asm_file)
    base_name = os.path.splitext(asm_filename)[0]
    dut._log.info(f"Starting test: {base_name}")

    # The JSON should sit right next to the ASM file in the source directory
    json_file = os.path.splitext(asm_file)[0] + ".json"
    assert os.path.exists(json_file), f"Missing expected output JSON for {asm_filename}"

    # Per-test run time, from the reference model's cycle count
    cycles, done_addr = _read_header(asm_file)
    info["cycles"] = cycles
    budget = (cycles + RESET_CYCLES + DONE_READS * LOOP_CYCLES) * CLOCKS_PER_CYCLE * TIMEOUT_MARGIN

    # 2. Compile into an ephemeral, auto-cleaning directory
    with tempfile.TemporaryDirectory() as temp_dir:
        bin_file = os.path.join(temp_dir, f"{base_name}.bin")

        compile_cmd = [
            _vasm(),
            "-Fbin", "-dotdir",
            "-o", bin_file, asm_file
        ]
        result = subprocess.run(compile_cmd, capture_output=True, text=True)
        assert result.returncode == 0, f"Compilation failed for {asm_filename}:\n{result.stderr}"

        # 3. Setup Hardware via test_bus.py logic
        await _boot(dut)
        low_latch, high_latch, sram = _wire_bus(dut)

        # 4. Load the Binary into ROM (0xC000)
        with open(bin_file, "rb") as f:
            rom_data = f.read()
            for i, byte in enumerate(rom_data):
                sram.memory[0xC000 + i] = byte

    # 5. Execute Simulation: run until the program reaches its Done loop, or fail
    #    once the test's clock budget is used up.
    reached = Event()
    state = {"clocks": 0, "done_reads": 0, "first_done_clock": None}
    cocotb.start_soon(_watch_done(dut, sram, done_addr, reached, state))
    if stimulus is not None:
        cocotb.start_soon(stimulus(dut, sram))
    dut.rst_n.value = 1

    await First(reached.wait(), ClockCycles(dut.clk, budget))
    assert reached.is_set(), (
        f"[{base_name}] did not reach Done (${done_addr:04X}) within {budget} clocks "
        f"(expected {cycles} 6502 cycles; Done read {state['done_reads']} time(s)); "
        f"last reads: {' '.join(f'${a:04X}' for a in sram.reads[-16:]) or 'none'}")

    clocks = state["first_done_clock"]
    info["clocks"] = clocks
    dut._log.info(f"{base_name}: reached Done after {clocks} clocks "
                  f"({cycles} 6502 cycles + reset, {clocks / (cycles + RESET_CYCLES):.2f} clocks/cycle)")

    # 6. Parse Expected JSON
    with open(json_file, "r") as f:
        expected_state_raw = json.load(f)
    expected_ram = {int(k, 16): int(v, 16) for k, v in expected_state_raw.items()}

    # 7. RIGOROUS MEMORY VERIFICATION
    try:
        # A. Verify RAM (0x0000 - 0xBFFF)
        for addr in range(0x0000, 0xC000):
            # Directly access the bytearray
            actual_val = sram.memory[addr]

            if addr in expected_ram:
                assert actual_val == expected_ram[addr], \
                    f"[{base_name}] RAM mismatch at {hex(addr)}: Expected {hex(expected_ram[addr])}, got {hex(actual_val)}"
            else:
                assert actual_val == 0x00, \
                    f"[{base_name}] Memory leak/rogue write at {hex(addr)}: Expected 0x00, got {hex(actual_val)}"

        # B. Verify ROM Integrity (0xC000 - 0xFFFF)
        for i, original_byte in enumerate(rom_data):
            addr = 0xC000 + i
            actual_val = sram.memory[addr]
            assert actual_val == original_byte, \
                f"[{base_name}] ROM corruption at {hex(addr)}: Expected {hex(original_byte)}, got {hex(actual_val)}"
    except BaseException:
        dut._log.error(f"[{base_name}] RAM writes (latest value per address):")
        for addr, value in sorted(sram.writes.items()):
            dut._log.error(f"[{base_name}]   ${addr:04X}: ${value:02X}")
        if not sram.writes:
            dut._log.error(f"[{base_name}]   none")
        raise

    dut._log.info(f"Passed: {base_name} (RAM untouched, ROM secure)")

# --- MODERN COCOTB DYNAMIC TEST GENERATOR ---

def _record_result(dut, asm_file, status, info, results_file, update_report, message=""):
    """Merge one test's outcome into results_file and (optionally) refresh the markdown
    report. Errors here are logged, never allowed to change the test's own result."""
    name = os.path.splitext(os.path.basename(asm_file))[0]
    try:
        results = {}
        if os.path.exists(results_file):
            with open(results_file) as f:
                results = json.load(f)
        results[name] = {"status": status, "message": message,
                         "time": time.strftime("%Y-%m-%d %H:%M:%S"), **info}
        tmp = results_file + ".tmp"
        with open(tmp, "w") as f:
            json.dump(results, f, indent=4, sort_keys=True)
        os.replace(tmp, results_file)
        if update_report:
            sys.path.insert(0, os.path.join(_HERE, "test", "tools"))
            import update_report as report
            report.update(results_file)
    except Exception as e:
        dut._log.warning(f"Could not record result for {name}: {e}")


def create_test(asm_file_path, test_name, run, results_file, update_report):
    """Factory to scope the file path and apply the decorator.
    `run(dut, asm_file, info)` is the coroutine that performs the test."""

    # 1. Define the raw async function
    async def dynamic_test(dut):
        info = {}
        try:
            await run(dut, asm_file_path, info)
        except BaseException as e:
            _record_result(dut, asm_file_path, "fail", info, results_file, update_report,
                           str(e) or type(e).__name__)
            raise
        _record_result(dut, asm_file_path, "pass", info, results_file, update_report)

    # 2. Rename it BEFORE decorating so Cocotb picks up the right name
    dynamic_test.__name__ = test_name
    dynamic_test.__qualname__ = test_name

    # 3. Apply the decorator programmatically and return the TestGenerator object
    return cocotb.test()(dynamic_test)


def register_tests(namespace, test_dir, results_file, update_report, run=run_asm_test):
    """Register one cocotb test per .asm in test_dir into `namespace` (a module's globals())."""
    for asm_file in sorted(glob.glob(os.path.join(test_dir, "*.asm"))):
        # Calculate the clean test name here
        test_name = os.path.splitext(os.path.basename(asm_file))[0]

        # Ensure it starts with 'test_' for standard test discovery
        if not test_name.startswith("test_"):
            test_name = f"test_{test_name}"

        # Generate the test and assign it to the namespace using our calculated string key
        namespace[test_name] = create_test(asm_file, test_name, run, results_file, update_report)
