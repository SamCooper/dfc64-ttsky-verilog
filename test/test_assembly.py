import os
import glob
import json
import subprocess
import cocotb
from cocotb.triggers import ClockCycles, SimTimeoutError, with_timeout

# Import your existing, proven hardware wiring setup directly[cite: 1]
from test_bus import _boot, _wire_bus

async def _run_assembly_test(dut, asm_file):
    """Dynamically compiles and executes a single assembly test, checking full memory integrity."""
    
    # 1. Path Resolution
    base_name = os.path.splitext(asm_file)[0]
    bin_file = f"{base_name}.bin"
    json_file = f"{base_name}.json"
    
    assert os.path.exists(json_file), f"Missing expected output JSON for {asm_file}"

    # 2. Compile with vasm
    compile_cmd = [
        "vasm6502_oldstyle", 
        "-Fbin", "-dotdir", 
        "-o", bin_file, asm_file
    ]
    result = subprocess.run(compile_cmd, capture_output=True, text=True)
    assert result.returncode == 0, f"Compilation failed for {asm_file}:\n{result.stderr}"

    # 3. Setup Hardware via test_bus.py logic
    # This initializes the clock, enables the ASIC, and drives reset low[cite: 1]
    await _boot(dut) 
    
    # This wires up the low/high latches and the SRAM mock[cite: 1]
    low_latch, high_latch, sram = _wire_bus(dut) 

    # 4. Load the Binary into ROM (0xC000)
    with open(bin_file, "rb") as f:
        rom_data = f.read()
        for i, byte in enumerate(rom_data):
            # Your SRAM mock handles memory access via a dictionary[cite: 1]
            sram.memory[0xC000 + i] = byte

    # 5. Execute Simulation
    # Release the reset pin as defined in your test setup[cite: 1]
    dut.rst_n.value = 1 
    
    # Run enough cycles to complete the test. We use with_timeout as a safety net 
    # to catch infinite loops (similar to your existing test_bus strategy)[cite: 1]
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
        actual_val = sram.memory.get(addr, 0x00) # Default to 0x00 if untouched
        
        if addr in expected_ram:
            # Check explicitly modified bytes
            assert actual_val == expected_ram[addr], \
                f"[{base_name}] RAM mismatch at {hex(addr)}: Expected {hex(expected_ram[addr])}, got {hex(actual_val)}"
        else:
            # Ensure untouched RAM remains exactly 0x00
            assert actual_val == 0x00, \
                f"[{base_name}] Memory leak/rogue write at {hex(addr)}: Expected 0x00, got {hex(actual_val)}"

    # B. Verify ROM Integrity (0xC000 - 0xFFFF)
    for i, original_byte in enumerate(rom_data):
        addr = 0xC000 + i
        actual_val = sram.memory.get(addr, 0x00)
        assert actual_val == original_byte, \
            f"[{base_name}] ROM corruption at {hex(addr)}: Expected {hex(original_byte)}, got {hex(actual_val)}. Did the CPU write to ROM?"

    dut._log.info(f"Passed: {base_name} (RAM untouched, ROM secure)")
    
    # 8. Cleanup
    if os.path.exists(bin_file):
        os.remove(bin_file)

# --- MODERN COCOTB DYNAMIC TEST GENERATOR ---
# This entirely replaces the deprecated TestFactory. 
# It finds all .asm files, creates an async wrapper for each, 
# applies the @cocotb.test() decorator, and registers it to the module.

asm_files = glob.glob("asm_tests/*.asm")

for asm_file in asm_files:
    # Create a safe, unique test name based on the filename
    safe_name = os.path.basename(asm_file).replace('.', '_').replace('-', '_')
    test_name = f"test_asm_{safe_name}"

    # Define the wrapped test function, capturing the specific file path via default arg
    @cocotb.test()
    async def dynamic_test_wrapper(dut, file_path=asm_file):
        await _run_assembly_test(dut, file_path)
    
    # Rename the function internally so Pytest/Cocotb logging looks clean
    dynamic_test_wrapper.__name__ = test_name
    dynamic_test_wrapper.__qualname__ = test_name
    
    # Inject it into the global namespace so Cocotb discovers it
    globals()[test_name] = dynamic_test_wrapper