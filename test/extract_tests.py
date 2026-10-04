#!/usr/bin/env python3
import os
import sys
import argparse

def parse_and_extract(input_file, output_dir):
    """Parses a combined test definition file and splits it into .asm and .json files."""
    
    os.makedirs(output_dir, exist_ok=True)
    
    with open(input_file, 'r') as f:
        lines = f.readlines()
        
    current_test = None
    current_section = None
    buffers = {"ASM": [], "JSON": []}
    
    def save_current_test():
        """Writes the buffered ASM and JSON to disk."""
        if current_test:
            asm_path = os.path.join(output_dir, f"{current_test}.asm")
            json_path = os.path.join(output_dir, f"{current_test}.json")
            
            with open(asm_path, 'w') as asm_f:
                asm_f.write("".join(buffers["ASM"]).strip() + "\n")
                
            with open(json_path, 'w') as json_f:
                json_f.write("".join(buffers["JSON"]).strip() + "\n")
                
            print(f"Generated: {asm_path} and {json_path}")
            
    for line in lines:
        stripped_line = line.strip()
        
        # State Transitions
        if stripped_line.startswith("@@@ TEST:"):
            save_current_test() # Flush previous test to disk
            current_test = stripped_line.split("@@@ TEST:")[1].strip()
            buffers = {"ASM": [], "JSON": []}
            current_section = None
            
        elif stripped_line == "=== ASM ===":
            current_section = "ASM"
            
        elif stripped_line == "=== JSON ===":
            current_section = "JSON"
            
        # Line Accumulation
        else:
            if current_section:
                buffers[current_section].append(line)
                
    # Flush the final test to disk
    save_current_test()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract .asm and .json from combined test files.")
    parser.add_argument("--input", help="Path to the combined test definition file (e.g., tests.testdef)", default='test_suite.testdef')
    parser.add_argument("--output", help="Directory to output the generated .asm and .json files", default='asm_tests')
    
    args = parser.parse_args()
    parse_and_extract(args.input, args.output)
