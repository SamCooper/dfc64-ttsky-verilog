import os
import glob
import json
import subprocess
import tempfile
import cocotb
from cocotb.triggers import ClockCycles, SimTimeoutError, with_timeout

# Import your existing, proven hardware wiring setup directly[cite: 1]
from test_bus import _boot, _wire_bus

async def _run_assembly_test(dut, asm_file):
    """Dynamically compiles and executes a single assembly test, checking full memory integrity."""
    
    # 1. Path Resolution
    asm_filename = os.path.basename(asm_file)
    base_name = os.path.splitext(asm_filename)[0]
    
    # The JSON should sit right next to the ASM file in the source directory
    json_file = os.path.splitext(asm_file)[0] + ".json"
    assert os.path.exists(json_file), f"Missing expected output JSON for {asm_filename}"

    # 2. Compile into an ephemeral, auto-cleaning directory
    with tempfile.TemporaryDirectory() as temp_dir:
        bin_file = os.path.join(temp_dir, f"{base_name}.bin")

        compile_cmd = [
            "vasm6502_oldstyle", 
            "-Fbin", "-dotdir", 
            "-o", bin_file, asm_file
        ]
        result = subprocess.run(compile_cmd, capture_output=True, text=True)
        assert result.returncode == 0, f"Compilation failed for {asm_filename}:\n{result.stderr}"

        # 3. Setup Hardware via test_bus.py logic[cite: 1]
        await _boot(dut)
        low_latch, high_latch, sram = _wire_bus(dut)

        # 4. Load the Binary into ROM (0xC000)
        with open(bin_file, "rb") as f:
            rom_data = f.read()
            for i, byte in enumerate(rom_data):
                sram.memory[0xC000 + i] = byte

    # 5. Execute Simulation
    dut.rst_n.value = 1 
    
    try:
        await with_timeout(ClockCycles(dut.clk, 200), 2, "ms")
    except SimTimeoutError:
        pass # Expected if the assembly program ends in an infinite JMP loop

    # 6. Parse Expected JSON
    with open(json_file, "r") as f:
        expected_state_raw = json.load(f)
    expected_ram = {int(k, 16): int(v, 16) for k, v in expected_state_raw.items()}

    # 7. RIGOROUS MEMORY VERIFICATION
    
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

    dut._log.info(f"Passed: {base_name} (RAM untouched, ROM secure)")

# --- MODERN COCOTB DYNAMIC TEST GENERATOR ---

asm_files = glob.glob("asm_tests/*.asm")

for asm_file in asm_files:
    # Extract the exact filename without the extension (e.g., 'test_add_store')
    test_name = os.path.splitext(os.path.basename(asm_file))[0]

    @cocotb.test()
    async def dynamic_test_wrapper(dut, file_path=asm_file):
        await _run_assembly_test(dut, file_path)
    
    # Rename the function internally so Pytest/Cocotb logging uses this exact name
    dynamic_test_wrapper.__name__ = test_name
    dynamic_test_wrapper.__qualname__ = test_name
    
    globals()[test_name] = dynamic_test_wrapper