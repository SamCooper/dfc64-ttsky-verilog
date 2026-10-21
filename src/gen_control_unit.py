#!/usr/bin/env python3
"""Generate src/dfc64_control_unit.v.

The control unit is assembled from
  * fixed Verilog fragments (src/fragments/*.vfrag), and
  * code generated from the microcode field table below plus two JSON files:
      src/fragments/fixed_stages.json  the fetch/decode stages at fixed ROM addresses
      src/opcode_stages.json           the stages of every opcode, in ROM order

Each stage in the JSON lists only the fields that differ from the defaults in FIELDS.
Adding a field to FIELDS widens the microword, the ROM entries and the output
assigns together; adding an opcode to the JSON adds its ROM stages and its dispatch
case. ROM addresses of the opcode stages are allocated sequentially from
FIRST_OPCODE_ADDR; the dispatch address of an opcode is its first stage.

It also writes src/opcode_cycles.json: the DFC64 clock cycles of every opcode (fetch
plus its stages), keyed by opcode byte, for the test completeness report.

The two JSON files are rewritten in a compact one-line-per-stage layout on every run.

Do not edit src/dfc64_control_unit.v by hand - edit the fragments, the JSON or this
script and re-run it (the test Makefile does so before compiling).
"""
import json
import os
import re
import sys
from collections import namedtuple

SRC_DIR = os.path.dirname(os.path.abspath(__file__))
FRAGMENT_DIR = os.path.join(SRC_DIR, "fragments")
FIXED_STAGES_JSON = os.path.join(FRAGMENT_DIR, "fixed_stages.json")
OPCODE_STAGES_JSON = os.path.join(SRC_DIR, "opcode_stages.json")
OPCODES_VERILOG = os.path.join(SRC_DIR, "dfc64_opcodes.v")
DEST = os.path.join(SRC_DIR, "dfc64_control_unit.v")
CYCLES_JSON = os.path.join(SRC_DIR, "opcode_cycles.json")

FIRST_OPCODE_ADDR = 0x10
ROM_SIZE = 256

# One entry per microword field, MSB first. `name` is both the JSON key and the name of
# the module output the field drives; `output` False means the field is internal
# (only uJump, which steers the sequencer in the fixed fragments).
Field = namedtuple("Field", "name width default output")
FIELDS = [
    Field("uJump",           3, "UJMP_STEP",  False),
    Field("alu_op",          4, "ALU_OP_ADD", True),
    Field("set_addr_c",      1, "false",      True),
    Field("flags_opcode",    1, "false",      True),
    Field("flags_ctl_c",     1, "false",      True),
    Field("flags_ctl_nz",    1, "false",      True),
    Field("al_inc",          1, "false",      True),
    Field("zp_clr_set",      1, "false",      True),
    Field("pc_inc",          1, "false",      True),
    Field("pc_jmp",          1, "false",      True),
    Field("write_en",        1, "false",      True),
    Field("mem_read_en",     1, "false",      True),
    Field("mem_write_en",    1, "false",      True),
    Field("read_reg_sel1",   4, "REG_ZERO",   True),
    Field("read_reg_sel2",   4, "REG_ZERO",   True),
    Field("write_reg_sel",   4, "REG_ZERO",   True),
]
UJUMP_WIDTH = 3      # the sequencer fragment slices the top 3 bits of the word
FETCH_JUMP = "UJMP_FETCH"


class GenError(Exception):
    pass


# --------------------------------------------------------------------------- inputs

def read_fragment(name):
    with open(os.path.join(FRAGMENT_DIR, name)) as f:
        return f.read()


def known_symbols():
    """localparam names defined in the fixed fragments (UJMP_*, REG_*, ...)."""
    symbols = set()
    for name in sorted(os.listdir(FRAGMENT_DIR)):
        if name.endswith(".vfrag"):
            symbols.update(re.findall(r"localparam\s+(\w+)\s*=", read_fragment(name)))
    return symbols


def opcode_values():
    """{OP_NAME: byte} parsed from dfc64_opcodes.v."""
    with open(OPCODES_VERILOG) as f:
        text = f.read()
    return {m.group(1): int(m.group(2), 16)
            for m in re.finditer(r"parameter\s+(OP_\w+)\s*=\s*8'h([0-9A-Fa-f]{2})", text)}


def load_json(path):
    with open(path) as f:
        return json.load(f)


def format_stage_json(data):
    """Compact layout: one line per stage (keeps the JSON files short)."""
    stage_line = lambda indent, stage: " " * indent + json.dumps(stage)
    if "opcodes" in data:
        ops = []
        for op in data["opcodes"]:
            stages = ",\n".join(stage_line(12, s) for s in op["stages"])
            ops.append(f'        {{"id": {json.dumps(op["id"])}, "stages": [\n{stages}\n        ]}}')
        return '{\n    "opcodes": [\n' + ",\n".join(ops) + "\n    ]\n}\n"
    stages = ",\n".join(stage_line(8, s) for s in data["stages"])
    return '{\n    "stages": [\n' + stages + "\n    ]\n}\n"


def reformat_json_files():
    """Rewrite the stage JSON files in the compact layout (only if they differ)."""
    for path in (FIXED_STAGES_JSON, OPCODE_STAGES_JSON):
        with open(path) as f:
            text = f.read()
        new = format_stage_json(json.loads(text))
        if new != text:
            with open(path, "w") as f:
                f.write(new)
            print(f"gen_control_unit.py: reformatted {os.path.relpath(path)}")


# ---------------------------------------------------------------------- stage -> text

def field_text(field, value, symbols, where):
    """Verilog literal/symbol for one field value (JSON bool/int/str)."""
    if field.width == 1:
        if value in (True, "true", 1, "1"):
            return "1'b1"
        if value in (False, "false", 0, "0"):
            return "1'b0"
        raise GenError(f"{where}: '{field.name}' must be true/false, got {value!r}")
    if isinstance(value, int) and not isinstance(value, bool):
        if not 0 <= value < (1 << field.width):
            raise GenError(f"{where}: '{field.name}' value {value} does not fit in {field.width} bits")
        return f"{field.width}'d{value}"
    if value not in symbols:
        raise GenError(f"{where}: '{field.name}' value {value!r} is not a localparam in the fragments")
    return value


def stage_columns(stage, symbols, where):
    unknown = set(stage) - {f.name for f in FIELDS} - {"addr"}
    if unknown:
        raise GenError(f"{where}: unknown field(s) {sorted(unknown)}")
    return [field_text(f, stage.get(f.name, f.default), symbols, where) for f in FIELDS]


def check_stages(stages, label):
    """A routine ends in UJMP_FETCH and has no FETCH before its last stage."""
    for i, stage in enumerate(stages):
        last = i == len(stages) - 1
        is_fetch = stage.get("uJump") == FETCH_JUMP
        if last and not is_fetch:
            raise GenError(f"{label}: last stage must have uJump {FETCH_JUMP}")
        if is_fetch and not last:
            raise GenError(f"{label}: stage {i} has uJump {FETCH_JUMP} before the end of the routine")


# ------------------------------------------------------------------------- generators

def gen_output_ports(ctx):
    outs = [f for f in FIELDS if f.output]
    width = max(len(f"[{f.width - 1}:0]") for f in outs if f.width > 1)
    lines = []
    for f in outs:
        rng = f"[{f.width - 1}:0]" if f.width > 1 else ""
        lines.append(f"    output {rng:<{width}} {f.name}")
    return ",\n".join(lines) + "\n"


def gen_word_size(ctx):
    size = sum(f.width for f in FIELDS)
    return f"    localparam MICRO_ROM_WORD_SIZE = {size};\n"


def gen_rom(ctx):
    symbols = ctx["symbols"]
    entries = []        # (addr, [column texts], comment or None)
    ctx["dispatch"] = []   # (opcode name, byte, address)

    fixed = load_json(FIXED_STAGES_JSON)["stages"]
    for stage in fixed:
        if "addr" not in stage:
            raise GenError("fixed_stages.json: every stage needs an 'addr'")
        addr = int(stage["addr"], 0)
        entries.append((addr, stage_columns(stage, symbols, f"fixed stage {stage['addr']}"),
                        "fixed fetch/decode stage" if not entries else None))

    addr = FIRST_OPCODE_ADDR
    seen = set()
    for op in load_json(OPCODE_STAGES_JSON)["opcodes"]:
        name = op["id"]
        if name not in ctx["opcodes"]:
            raise GenError(f"opcode id {name!r} is not defined in dfc64_opcodes.v")
        if name in seen:
            raise GenError(f"opcode {name} appears twice in opcode_stages.json")
        seen.add(name)
        check_stages(op["stages"], name)
        ctx["dispatch"].append((name, ctx["opcodes"][name], addr))
        for i, stage in enumerate(op["stages"]):
            entries.append((addr, stage_columns(stage, symbols, f"{name} stage {i}"),
                            name if i == 0 else None))
            addr += 1

    used = [a for a, _, _ in entries]
    if len(set(used)) != len(used):
        raise GenError("ROM address clash between fixed stages and opcode stages")
    if max(used) >= ROM_SIZE:
        raise GenError(f"microcode needs {max(used) + 1} ROM entries, only {ROM_SIZE} available")

    # Pad each column so the ROM reads as a table
    widths = [max(len(cols[i]) for _, cols, _ in entries) for i in range(len(FIELDS))]
    lines = []
    for addr, cols, comment in entries:
        if comment:
            if lines:
                lines.append("")
            lines.append(f"        // {comment}")
        cells = [c + "," if i < len(cols) - 1 else c for i, c in enumerate(cols)]
        cells = [c.ljust(widths[i] + 1) if i < len(cols) - 1 else c for i, c in enumerate(cells)]
        lines.append(f"        micro_rom[8'h{addr:02x}] = {{{' '.join(cells).rstrip()}}};")
    return "\n".join(lines) + "\n"


def needs_extra_bytes(op):
    """Mirror of needs_zero/one/two_extra in the fragments: operand bytes to fetch."""
    bit = lambda n: (op >> n) & 1
    zero = op in (0x00, 0x40, 0x60) or (bit(3), bit(2), bit(0)) == (1, 0, 0)
    two = op == 0x20 or ((op & 0xF) == 0x9 and bit(4)) or ((op >> 2) & 3) == 3
    return 0 if zero else (2 if two else 1)


def gen_dispatch(extra):
    def generate(ctx):
        group = [(n, a) for n, v, a in ctx["dispatch"] if needs_extra_bytes(v) == extra]
        width = max((len(n) for n, _ in group), default=0)
        return "".join(f"                    {n + ':':<{width + 1}} dispatch_address = 8'h{a:02x};\n"
                       for n, a in group)
    return generate


def gen_assigns(ctx):
    outs = [f for f in FIELDS if f.output]
    name_w = max(len(f.name) for f in outs)
    lines = []
    pos = sum(f.width for f in FIELDS)
    for f in FIELDS:
        pos -= f.width
        if not f.output:
            continue
        sel = f"[{pos}]" if f.width == 1 else f"[{pos + f.width - 1}:{pos}]"
        lines.append(f"    assign {f.name:<{name_w}} = current_micro_word{sel};")
    return "\n".join(lines) + "\n"


# Output file = these pieces in order: fragment file names, or generator functions.
SOURCES = [
    "01_header.vfrag",
    gen_output_ports,
    "02_params_a.vfrag",
    gen_word_size,
    "03_params_b.vfrag",
    gen_rom,
    "04_mapper_a.vfrag",
    gen_dispatch(0),
    "05_mapper_b.vfrag",
    gen_dispatch(1),
    "06_mapper_c.vfrag",
    gen_dispatch(2),
    "07_sequencer.vfrag",
    gen_assigns,
    "08_footer.vfrag",
]


def opcode_cycles(ctx):
    """{opcode byte: (OP name, DFC64 clock cycles)} for every opcode in the stage JSON.

    cycles = fixed fetch stages executed before this opcode's dispatch + its own stages.
    The fetch stages are walked from ROM address 0 up to the stage whose uJump is
    UJMP_DISPATCH_<n+1>, where n is the number of operand bytes the opcode needs.
    """
    fixed = {int(s["addr"], 0): s for s in load_json(FIXED_STAGES_JSON)["stages"]}
    stage_counts = {op["id"]: len(op["stages"]) for op in load_json(OPCODE_STAGES_JSON)["opcodes"]}
    cycles = {}
    for name, value, _ in ctx["dispatch"]:
        target = f"UJMP_DISPATCH_{needs_extra_bytes(value) + 1}"
        fetch = next((addr + 1 for addr in sorted(fixed) if fixed[addr].get("uJump") == target), None)
        if fetch is None:
            raise GenError(f"{name}: no fixed stage with uJump {target} to end its fetch")
        cycles[value] = (name, fetch + stage_counts[name])
    return cycles


def write_cycles_json(ctx):
    cycles = opcode_cycles(ctx)
    lines = [f'    "{value:02X}": {{"id": "{name}", "cycles": {count}}}'
             for value, (name, count) in sorted(cycles.items())]
    text = "{\n" + ",\n".join(lines) + "\n}\n"
    return write_if_changed(CYCLES_JSON, text)


def write_if_changed(path, text):
    # Only touch a file when the content changes, so make does not rebuild needlessly
    if os.path.exists(path):
        with open(path) as f:
            if f.read() == text:
                return False
    with open(path, "w") as f:
        f.write(text)
    print(f"gen_control_unit.py: wrote {os.path.relpath(path)}")
    return True


def generate():
    if FIELDS[0].width != UJUMP_WIDTH or FIELDS[0].name != "uJump":
        raise GenError(f"the first field must be the {UJUMP_WIDTH}-bit uJump the sequencer slices")
    ctx = {"symbols": known_symbols(), "opcodes": opcode_values()}
    parts = [read_fragment(s) if isinstance(s, str) else s(ctx) for s in SOURCES]
    header = "// Generated by gen_control_unit.py - DO NOT EDIT. Edit src/fragments/, "\
             "src/opcode_stages.json or the script.\n"
    return header + "".join(parts), ctx


def main():
    try:
        reformat_json_files()
        text, ctx = generate()
        write_cycles_json(ctx)
    except GenError as e:
        sys.exit(f"gen_control_unit.py: error: {e}")
    write_if_changed(DEST, text)


if __name__ == "__main__":
    main()
