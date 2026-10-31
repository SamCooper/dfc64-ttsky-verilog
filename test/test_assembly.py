"""Instruction tests: one cocotb test per test/asm_tests/*.asm (see asm_harness.py)."""
import os

from asm_harness import register_tests

# Directory holding the .asm/.json test pairs
ASM_TEST_DIR = os.environ.get("ASM_TEST_DIR", "asm_tests/quick")

# Results of each run are merged into this file, and the compliance report is
# updated from it after every test (set ASM_UPDATE_REPORT=0 to skip the report).
_HERE = os.path.dirname(os.path.abspath(__file__))
RESULTS_FILE = os.environ.get("ASM_RESULTS_FILE", os.path.join(_HERE, "asm_results.json"))
UPDATE_REPORT = os.environ.get("ASM_UPDATE_REPORT", "1") != "0"

register_tests(globals(), ASM_TEST_DIR, RESULTS_FILE, UPDATE_REPORT)
