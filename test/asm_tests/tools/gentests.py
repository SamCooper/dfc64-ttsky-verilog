"""Generate the DFC64 instruction tests (.asm + .json) for every official opcode.

Each test is built as a list of source lines. Lines can carry a tag:
  'result' - writes the test checks; annotated with "Expect ..." and pre-seeded
             with $FF when the expected value is $00 (so a missing write is caught)
  'expect' - PHP status capture; annotated with "Expect $xx at $01xx"

Usage: python3 test/tools/gentests.py   (rewrites every test in test/)

The test is assembled and run on the reference model (sim6502.py) to fill in the
annotations and the JSON, and re-run with injected faults to check it detects them.
"""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sim6502 as S

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
H = lambda v: f"${v:02X}"
HW = lambda v: f"${v:04X}"

PROLOGUE_P = 0x45  # C=1 I=1 V=1 D=0
TRAPV = [0x99, 0x66, 0x77, 0x33, 0xCC, 0x11]
TRAP_POOL = TRAPV + [0xEE, 0x22, 0x88, 0x44, 0xBB, 0x55]
ADDR_FAULTS = {"no_zp_wrap", "no_carry", "drop_high"}

MODE_NAME = {"imm": "#immediate", "zpg": "zeropage", "zpgX": "zeropage,X", "zpgY": "zeropage,Y",
             "abs": "absolute", "absX": "absolute,X", "absY": "absolute,Y",
             "Xind": "(indirect,X)", "indY": "(indirect),Y", "A": "accumulator",
             "impl": "implied", "rel": "relative", "ind": "indirect"}
SUFFIX = {"imm": "imm", "zpg": "zp", "zpgX": "zp_x", "zpgY": "zp_y", "abs": "abs", "absX": "abs_x",
          "absY": "abs_y", "Xind": "ind_x", "indY": "ind_y", "A": "acc", "ind": "ind"}


# ------------------------------------------------------------- addressing layouts
# Same layouts as the hand-written LDA tests. 'traps' are (address, fault-kind) pairs
# holding values that a faulty CPU would use instead of the correct location.

def geometry(mode, ix="X"):
    i = ix.lower()
    if mode == "zpg":
        return [dict(eff=0x00, op="$00", desc="lowest ZP address"),
                dict(eff=0xFF, op="$FF", desc="highest ZP address"),
                dict(eff=0x80, op="$80", desc="mid ZP address"),
                dict(eff=0x7F, op="$7F", desc="mid ZP address")]
    if mode in ("zpgX", "zpgY"):
        return [dict(eff=0x30, idx=0x20, op=f"$10,{i}", desc="$10 + $20 = $30, no wrap"),
                dict(eff=0x10, idx=0x20, op=f"$F0,{i}", traps=[(0x0110, "wrap failed")],
                     desc="$F0 + $20 = $110 -> must wrap to $10"),
                dict(eff=0x80, idx=0xFF, op=f"$81,{i}", traps=[(0x0180, "wrap failed")],
                     desc="$81 + $FF = $180 -> must wrap to $80"),
                dict(eff=0x40, idx=0x00, op=f"$40,{i}", desc=f"{ix} = 0")]
    if mode == "abs":
        return [dict(eff=0x1234, op="$1234", desc="absolute address"),
                dict(eff=0x7FFF, op="$7FFF", desc="top of RAM"),
                dict(eff=0x0200, op="$0200", desc="absolute address"),
                dict(eff=0x0100, op="$0100", traps=[(0x0000, "high byte dropped")],
                     desc="$0100, just above the zero page")]
    if mode in ("absX", "absY"):
        return [dict(eff=0x1235, idx=0x05, op=f"$1230,{i}", desc="$1230 + $05 = $1235, no page cross"),
                dict(eff=0x1310, idx=0x20, op=f"$12F0,{i}", traps=[(0x1210, "carry lost")],
                     desc="$12F0 + $20 = $1310, page cross"),
                dict(eff=0x2100, idx=0xFF, op=f"$2001,{i}", traps=[(0x2000, "carry lost")],
                     desc=f"$2001 + $FF = $2100, page cross with {ix} = $FF"),
                dict(eff=0x7FFF, idx=0x00, op=f"$7FFF,{i}", desc=f"{ix} = 0, top of RAM"),
                dict(eff=0x0010, idx=0x20, op=f"$FFF0,{i}", desc="$FFF0 + $20 = $10010 -> wraps to $0010")]
    if mode == "Xind":
        return [dict(eff=0x1234, idx=0x04, op="($20,x)", ptrs=[(0x24, 0x34), (0x25, 0x12)],
                     desc="pointer at $20 + $04 = $24 -> $1234"),
                dict(eff=0x2345, idx=0x20, op="($F0,x)", ptrs=[(0x10, 0x45), (0x11, 0x23), (0x0110, 0x56), (0x0111, 0x34)],
                     traps=[(0x3456, "wrap failed")], desc="pointer at $F0 + $20 = $110 -> must wrap to $10 -> $2345"),
                dict(eff=0x3040, idx=0xFF, op="($00,x)", ptrs=[(0xFF, 0x40), (0x00, 0x30), (0x0100, 0x50)],
                     traps=[(0x5040, "high byte read from $0100")],
                     desc="pointer at $00 + $FF = $FF, high byte from $00 -> $3040"),
                dict(eff=0x7FFF, idx=0x00, op="($80,x)", ptrs=[(0x80, 0xFF), (0x81, 0x7F)],
                     desc="X = 0, pointer at $80 -> $7FFF")]
    if mode == "indY":
        return [dict(eff=0x1234, idx=0x04, op="($20),y", ptrs=[(0x20, 0x30), (0x21, 0x12)],
                     desc="($20) = $1230 + $04 = $1234, no page cross"),
                dict(eff=0x1310, idx=0x20, op="($22),y", ptrs=[(0x22, 0xF0), (0x23, 0x12)],
                     traps=[(0x1210, "carry lost")], desc="($22) = $12F0 + $20 = $1310, page cross"),
                dict(eff=0x2100, idx=0xFF, op="($FF),y", ptrs=[(0xFF, 0x01), (0x00, 0x20), (0x0100, 0x30)],
                     traps=[(0x2000, "carry lost"), (0x3100, "high byte read from $0100")],
                     desc="pointer at $FF (high byte from $00) = $2001 + $FF = $2100"),
                dict(eff=0x7FFF, idx=0x00, op="($80),y", ptrs=[(0x80, 0xFF), (0x81, 0x7F)],
                     desc="Y = 0, ($80) = $7FFF"),
                dict(eff=0x0010, idx=0x20, op="($82),y", ptrs=[(0x82, 0xF0), (0x83, 0xFF)],
                     desc="($82) = $FFF0 + $20 = $10010 -> wraps to $0010")]
    raise ValueError(mode)


INDEX_REG = {"zpgX": "X", "absX": "X", "Xind": "X", "zpgY": "Y", "absY": "Y", "indY": "Y"}


def mode_about(mode, ix, kind):
    """Header lines describing what an addressing layout covers.
    kind: 'read' (traps are read by mistake), 'rmw' (traps are modified by mistake), 'write'."""
    lines = {
        "zpg": ["Uses both ends of the zero page ($00 and $FF)."],
        "zpgX": [f"Base + {ix} must wrap within the zero page ($00xx), never cross into $01xx."],
        "abs": ["Covers the top of RAM ($7FFF) and $0100, the lowest address outside the zero page.",
                "All operands are >= $0100 so the assembler cannot pick the zero-page opcode."],
        "absX": [f"Covers no page cross, page cross (carry into the high byte), {ix} = $FF,",
                 f"{ix} = 0, and wrap-around from $FFxx into the zero page."],
        "Xind": ["The pointer address (base + X) must wrap within the zero page, and a",
                 "pointer at $FF must take its high byte from $00, not $0100."],
        "indY": ["Covers no page cross, page cross (carry into the high byte), a pointer at $FF",
                 "(high byte from $00, not $0100), Y = 0, and wrap-around from $FFxx into the zero page."],
    }
    lines["zpgY"], lines["absY"] = lines["zpgX"], lines["absX"]
    fault = {"zpgX": "fails to wrap", "zpgY": "fails to wrap", "abs": "drops the high byte",
             "absX": "fails to carry into the high byte", "absY": "fails to carry into the high byte",
             "Xind": "fails to wrap", "indY": "loses the carry or reads the pointer high byte from $0100"}
    out = list(lines.get(mode, []))
    if mode in fault and kind == "read":
        out.append(f"Trap values catch a CPU that {fault[mode]}.")
    elif mode in fault and kind == "rmw":
        out.append(f"Trap values sit where a CPU that {fault[mode]} would modify memory instead.")
    return out


# ------------------------------------------------------------- source builder

class Src:
    def __init__(self):
        self.lines, self.tags = [], {}

    def raw(self, text=""):
        self.lines.append(text)

    def ins(self, text, comment="", tag=None):
        line = f"        {text}"
        if comment:
            line = f"{line:<24}; {comment}"
        if tag:
            self.tags[len(self.lines)] = tag
        self.lines.append(line)

    def label(self, name):
        self.lines.append(f"{name}:")

    def section(self, text):
        self.raw()
        self.raw(f"        ; --- {text} ---")

    def set_p(self, p, why=""):
        self.ins(f"lda #{H(p)}", why or flags_text(p))
        self.ins("pha")
        self.ins("plp")

    def seed(self, addr, val, comment=""):
        if val == 0:
            return
        self.ins(f"lda #{H(val)}", comment)
        self.ins(f"sta {HW(addr) if addr > 0xFF else H(addr)}")


def flags_text(p):
    names = [n for n, b in zip("NV--DIZC", [0x80, 0x40, 0, 0, 8, 4, 2, 1]) if b]
    on = [n + "=1" for n, b in zip("NVDIZC", [0x80, 0x40, 8, 4, 2, 1]) if p & b]
    off = [n + "=0" for n, b in zip("NVDIZC", [0x80, 0x40, 8, 4, 2, 1]) if not p & b]
    return " ".join(on + off)


class Test:
    def __init__(self, name, opcodes, title, about, prologue_p=PROLOGUE_P, layout=True,
                 vectors=("done", "reset", "done")):
        self.name, self.opcodes, self.title, self.about = name, opcodes, title, about
        self.prologue_p, self.layout, self.vectors = prologue_p, layout, vectors
        self.setup = Src()
        self.body = Src()
        self.tail = Src()     # extra code blocks placed after 'done'
        self.preseed = []     # filled in by the build loop

    def header(self):
        ops = ", ".join(f"${o:02X}" for o in self.opcodes)
        h = [f"; Target: vasm6502_oldstyle", f"; Test: {self.title} ({ops})"]
        h += [f"; {l}" if l else ";" for l in self.about]
        if self.layout:
            h += [";", "; Result layout:",
                  ";   $0300+  value produced by each case",
                  ";   $01FF-  processor status after each case (one PHP per case, stack grows down)"]
        if self.prologue_p is not None:
            h += [f"; Initial status (via PLP): {flags_text(self.prologue_p)}"]
        h += ["; Zero results are written over a $FF pre-seed so that a missing write is detected."]
        return h

    def source(self):
        out, tags = [], {}
        def add(src):
            base = len(out)
            out.extend(src.lines)
            tags.update({base + k: v for k, v in src.tags.items()})
        out.extend(self.header())
        out += ["", "        .org $C000", "reset:"]
        out += ["        ldx #$FF", "        txs"]
        if self.prologue_p is not None:
            pro = Src(); pro.set_p(self.prologue_p); add(pro)
        if self.setup.lines or self.preseed:
            out += ["", "        ; --- Setup ---"]
            add(self.setup)
            for a in self.preseed:
                p = Src(); p.seed(a, 0xFF, "Pre-seed a zero-result location"); add(p)
        add(self.body)
        out += ["", "done:", "        jmp done        ; Infinite loop to terminate"]
        add(self.tail)
        out += ["", "        .org $FFFA",
                f"        .word {self.vectors[0]:<10}; NMI vector",
                f"        .word {self.vectors[1]:<10}; Reset vector",
                f"        .word {self.vectors[2]:<10}; IRQ/BRK vector", ""]
        return out, tags


# ------------------------------------------------------------- build + verify

def build(t):
    for _ in range(3):
        lines, tags = t.source()
        text = "\n".join(lines)
        img, where = S.assemble(text, is_text=True)
        cpu = S.CPU(img).run()
        by_pc = {}
        for pc, a, old, new in cpu.trace:
            by_pc.setdefault(pc, {})[a] = (old, new)
        zero = sorted({a for i, tag in tags.items() for a, (old, new) in by_pc.get(where[i], {}).items()
                       if new == 0 and old == 0 and a not in t.preseed})
        if not zero:
            break
        t.preseed += zero
    else:
        raise SystemExit(f"{t.name}: pre-seed did not converge")

    good = S.ram(cpu)
    fm = S.fault_matrix(img, set(t.opcodes), good)
    missed = [k for k, v in fm.items() if not v]

    # fault notes for result lines: what a faulty CPU writes there instead
    notes = {}
    for fl, why in (("no_zp_wrap", "wrap failed"), ("no_carry", "carry lost"),
                    ("drop_high", "high byte dropped")):
        if fl not in fm:
            continue
        c = S.CPU(img, [fl], set(t.opcodes))
        try:
            c.run()
        except RuntimeError:
            continue
        fb = {}
        for pc, a, old, new in c.trace:
            fb.setdefault(pc, {})[a] = new
        for i, tag in tags.items():
            if tag != "result":
                continue
            exp = by_pc.get(where[i], {})
            got = fb.get(where[i], {})
            for a, (_, new) in exp.items():
                if a in got and got[a] != new:
                    notes.setdefault(i, []).append(f"{H(got[a])} = {why}")

    # annotate
    for i, tag in tags.items():
        w = by_pc.get(where[i], {})
        parts = []
        for a, (_, new) in w.items():
            if tag == "result" and 0x0300 <= a <= 0x03FF and len(w) == 1:
                parts.append(f"Expect {H(new)}")
            else:
                parts.append(f"{H(new)} at {HW(a)}")
        if not parts:
            continue
        txt = parts[0] if parts[0].startswith("Expect") else "Expect " + ", ".join(parts)
        if i in notes:
            txt += f" ({', '.join(dict.fromkeys(notes[i]))})"
        line = lines[i]
        code, _, old = line.partition(";")
        old = old.strip()
        lines[i] = f"{code.rstrip():<23} ; {txt}" + (f" ({old})" if old else "")
    text = "\n".join(lines)
    # sanity: annotations must not change the binary
    assert S.assemble(text, is_text=True)[0] == img

    with open(f"{OUT}/{t.name}.asm", "w") as fh:
        fh.write(text)
    S.stamp(f"{OUT}/{t.name}.asm")
    with open(f"{OUT}/{t.name}.json", "w") as fh:
        fh.write(json.dumps(S.ram_json(cpu), indent=4) + "\n")
    return fm, missed


# ------------------------------------------------------------- test families

def opc(mn, mode):
    return S.OPS[(mn, mode)]


def seed_layout(t, cases, g, trap_values, data=True, trap_data=True):
    """Seed pointers, operand data and trap values for an addressing layout."""
    ptrs = [p for c in g for p in c.get("ptrs", [])]
    if ptrs:
        t.setup.raw("        ; Pointers")
        for a, v in ptrs:
            t.setup.seed(a, v)
    if data:
        t.setup.raw("        ; Operand values (correct locations)")
        for c, m in zip(g, cases):
            t.setup.seed(c["eff"], m)
    traps = [(a, why) for c in g for a, why in c.get("traps", [])]
    if traps and trap_data:
        t.setup.raw("        ; Trap values (used only by a faulty CPU)")
        for k, (a, why) in enumerate(traps):
            t.setup.seed(a, trap_values[k % len(trap_values)], why)


def read_test(mn, mode, reg, cases, about, extra_about=(), trap_values=TRAPV, suffix="", title_extra=""):
    """Instructions that read memory: loads, ALU ops, compares, BIT.
    cases: list of dicts with m (operand), a (register value, if used), p (status before)."""
    ix = INDEX_REG.get(mode, "X")
    if mn == "LDX" and mode in ("zpgY", "absY"): ix = "Y"
    if mn == "LDY" and mode in ("zpgX", "absX"): ix = "X"
    name = f"{mn.lower()}_{SUFFIX[mode]}{suffix}"
    t = Test(name, [opc(mn, mode)], f"{mn} {MODE_NAME[mode]}{title_extra}", list(about) + list(extra_about))
    if mode == "imm":
        g = [dict(op=None, desc="") for _ in cases]
    else:
        g = geometry(mode, ix)
        cases = cases[:len(g)]
        seed_layout(t, [c["m"] for c in cases], g, trap_values)
        t.about += mode_about(mode, ix, "read")
        if mode in ("absX", "absY", "indY"):
            t.about.append("Cycle note: cases 2 and 3 cross a page (+1 cycle on the 6502).")
    for n, (c, geo) in enumerate(zip(cases, g), 1):
        desc = c.get("desc") or geo["desc"]
        t.body.section(f"Case {n}: {desc}")
        if "p" in c:
            t.body.set_p(c["p"])
        if "idx" in geo:
            note = ""
            if "a" not in c and mn in ("LDA", "LDX", "LDY"):   # the index load sets the flags
                if geo["idx"] == 0xFF and not c["m"] & 0x80:
                    note = f"Also leaves N=1, so {mn} must clear it"
                elif geo["idx"] == 0x00 and c["m"]:
                    note = f"Also leaves Z=1, so {mn} must clear it"
            t.body.ins(f"ld{ix.lower()} #{H(geo['idx'])}", note)
        if "a" in c:
            t.body.ins(f"ld{reg.lower()} #{H(c['a'])}")
        operand = f"#{H(c['m'])}" if mode == "imm" else geo["op"]
        t.body.ins(f"{mn.lower()} {operand}")
        t.body.ins(f"st{reg.lower()} ${0x300 + n - 1:04X}", tag="result")
        t.body.ins("php", tag="expect")
    t.factory = lambda tv: read_test(mn, mode, reg, cases, about, extra_about, tv, suffix, title_extra)
    return t


def store_test(mn, mode, reg, about):
    ix = INDEX_REG.get(mode, "X")
    name = f"{mn.lower()}_{SUFFIX[mode]}"
    t = Test(name, [opc(mn, mode)], f"{mn} {MODE_NAME[mode]}", about)
    g = geometry(mode, ix)
    vals = [0x5A, 0xA5, 0x00, 0x7F, 0x3C][:len(g)]
    seed_layout(t, None, g, TRAPV, data=False, trap_data=False)
    t.about += mode_about(mode, ix, "write")
    for n, (v, geo) in enumerate(zip(vals, g), 1):
        t.body.section(f"Case {n}: {geo['desc']}")
        if "idx" in geo:
            t.body.ins(f"ld{ix.lower()} #{H(geo['idx'])}")
        t.body.ins(f"ld{reg.lower()} #{H(v)}")
        t.body.ins(f"{mn.lower()} {geo['op']}", tag="result")
        t.body.ins("php", "Flags must be unchanged by the store", tag="expect")
    return t


def rmw_test(mn, mode, cases, about):
    """Read-modify-write on memory. cases: list of (p or None, input)."""
    name = f"{mn.lower()}_{SUFFIX[mode]}"
    t = Test(name, [opc(mn, mode)], f"{mn} {MODE_NAME[mode]}", about)
    if mode == "A":
        for n, (p, v, desc) in enumerate(cases, 1):
            t.body.section(f"Case {n}: {desc}")
            if p is not None:
                t.body.set_p(p)
            t.body.ins(f"lda #{H(v)}")
            t.body.ins(mn.lower())
            t.body.ins(f"sta ${0x300 + n - 1:04X}", tag="result")
            t.body.ins("php", tag="expect")
        return t
    g = geometry(mode, "X")
    cases = cases[:len(g)]
    seed_layout(t, [v for _, v, _ in cases], g, TRAPV)
    t.about += mode_about(mode, "X", "rmw")
    t.about.append("The result is the modified memory location itself.")
    if mode == "absX":
        t.about.append("Cycle note: read-modify-write abs,X always takes 7 cycles (no page-cross variance).")
    for n, ((p, v, desc), geo) in enumerate(zip(cases, g), 1):
        t.body.section(f"Case {n}: {geo['desc']}, {desc}")
        if p is not None:
            t.body.set_p(p)
        if "idx" in geo:
            t.body.ins(f"ldx #{H(geo['idx'])}")
        t.body.ins(f"{mn.lower()} {geo['op']}", tag="result")
        t.body.ins("php", tag="expect")
    return t


ALL = []
def add(t): ALL.append(t); return t

FLAG_NOTE = "Checks the result and the N/Z flags, and that C and V are left unchanged."
P0, P1 = 0x04, 0x05  # I=1, plus C


# --- Loads -----------------------------------------------------------------
LOADV = [dict(m=0x5A), dict(m=0xA5), dict(m=0x00), dict(m=0x7F), dict(m=0x3C)]
for mn, reg, modes in (("LDA", "A", ["imm", "zpg", "zpgX", "abs", "absX", "absY", "Xind", "indY"]),
                       ("LDX", "X", ["imm", "zpg", "zpgY", "abs", "absY"]),
                       ("LDY", "Y", ["imm", "zpg", "zpgX", "abs", "absX"])):
    for mode in modes:
        cases = LOADV[:4] if mode == "imm" else LOADV   # layouts use as many cases as they have
        add(read_test(mn, mode, reg, cases, [f"Loads {reg}. " + FLAG_NOTE]))

# --- Logical ---------------------------------------------------------------
LOGIC = {
    "AND": [dict(a=0xF0, m=0x5A), dict(a=0xFF, m=0xA5), dict(a=0x0F, m=0xF0), dict(a=0x7F, m=0xFF), dict(a=0x3C, m=0xFF)],
    "ORA": [dict(a=0x50, m=0x0A), dict(a=0x80, m=0x25), dict(a=0x00, m=0x00), dict(a=0x70, m=0x0F), dict(a=0x30, m=0x0C)],
    "EOR": [dict(a=0xFF, m=0xA5), dict(a=0x0F, m=0xAA), dict(a=0xC3, m=0xC3), dict(a=0x80, m=0xFF), dict(a=0x0F, m=0x33)],
}
LOGIC_IMM_EXTRA = {"AND": [dict(a=0xAA, m=0x55)], "ORA": [dict(a=0xAA, m=0x55)], "EOR": [dict(a=0xFF, m=0xFF)]}
ALU_MODES = ["imm", "zpg", "zpgX", "abs", "absX", "absY", "Xind", "indY"]
for mn, cases in LOGIC.items():
    for mode in ALU_MODES:
        cs = cases[:4] + LOGIC_IMM_EXTRA[mn] if mode == "imm" else cases
        add(read_test(mn, mode, "A", cs, [FLAG_NOTE]))

# --- Arithmetic ------------------------------------------------------------
ADC_IMM = [
    dict(p=P0, a=0x01, m=0x01, desc="binary, C=0: $01 + $01 = $02"),
    dict(p=P0, a=0x7F, m=0x01, desc="binary, C=0: $7F + $01 = $80 (overflow)"),
    dict(p=P0, a=0xFF, m=0x01, desc="binary, C=0: $FF + $01 = $00 (carry out)"),
    dict(p=P0, a=0x80, m=0x80, desc="binary, C=0: $80 + $80 = $00 (carry and overflow)"),
    dict(p=P1, a=0x01, m=0x01, desc="binary, C=1: $01 + $01 + 1 = $03"),
    dict(p=P1, a=0xFF, m=0x00, desc="binary, C=1: $FF + $00 + 1 = $00 (carry out)"),
    dict(p=P1, a=0x3F, m=0x40, desc="binary, C=1: $3F + $40 + 1 = $80 (overflow)"),
    dict(p=P0 | 0x40, a=0x10, m=0x20, desc="binary, V=1 before: $10 + $20 = $30 (V cleared)"),
    dict(p=P0 | 0x08, a=0x09, m=0x01, desc="decimal, C=0: 09 + 01 = 10"),
    dict(p=P0 | 0x08, a=0x12, m=0x34, desc="decimal, C=0: 12 + 34 = 46"),
    dict(p=P1 | 0x08, a=0x58, m=0x46, desc="decimal, C=1: 58 + 46 + 1 = 05, carry out"),
    dict(p=P0 | 0x08, a=0x99, m=0x01, desc="decimal, C=0: 99 + 01 = 00, carry out (NMOS: Z from binary result)"),
    dict(p=P0 | 0x08, a=0x50, m=0x50, desc="decimal, C=0: 50 + 50 = 00, carry out (NMOS: N and V from the intermediate result)"),
    dict(p=P1 | 0x08, a=0x99, m=0x00, desc="decimal, C=1: 99 + 00 + 1 = 00, carry out"),
]
SBC_IMM = [
    dict(p=P1, a=0x05, m=0x03, desc="binary, C=1: $05 - $03 = $02"),
    dict(p=P1, a=0x00, m=0x01, desc="binary, C=1: $00 - $01 = $FF (borrow)"),
    dict(p=P1, a=0x80, m=0x01, desc="binary, C=1: $80 - $01 = $7F (overflow)"),
    dict(p=P1, a=0x7F, m=0xFF, desc="binary, C=1: $7F - $FF = $80 (overflow, borrow)"),
    dict(p=P0, a=0x05, m=0x03, desc="binary, C=0: $05 - $03 - 1 = $01"),
    dict(p=P0, a=0x00, m=0x00, desc="binary, C=0: $00 - $00 - 1 = $FF (borrow)"),
    dict(p=P1, a=0x40, m=0x40, desc="binary, C=1: $40 - $40 = $00"),
    dict(p=P0, a=0x01, m=0x00, desc="binary, C=0: $01 - $00 - 1 = $00"),
    dict(p=P1 | 0x08, a=0x46, m=0x12, desc="decimal, C=1: 46 - 12 = 34"),
    dict(p=P1 | 0x08, a=0x10, m=0x01, desc="decimal, C=1: 10 - 01 = 09"),
    dict(p=P1 | 0x08, a=0x00, m=0x01, desc="decimal, C=1: 00 - 01 = 99 (borrow)"),
    dict(p=P0 | 0x08, a=0x32, m=0x02, desc="decimal, C=0: 32 - 02 - 1 = 29"),
    dict(p=P1 | 0x08, a=0x21, m=0x34, desc="decimal, C=1: 21 - 34 = 87 (borrow)"),
    dict(p=P0 | 0x08, a=0x00, m=0x00, desc="decimal, C=0: 00 - 00 - 1 = 99 (borrow)"),
]
ADC_MODE = [dict(p=P0 | 0x40, a=0x50, m=0x0A), dict(p=P1, a=0x50, m=0x54), dict(p=P0, a=0xFF, m=0x01),
            dict(p=P1, a=0x7E, m=0x00), dict(p=P0, a=0x1E, m=0x1E)]
SBC_MODE = [dict(p=P1 | 0x40, a=0x5A, m=0x00), dict(p=P1, a=0x25, m=0x80), dict(p=P1, a=0x33, m=0x33),
            dict(p=P0, a=0x80, m=0x00), dict(p=P1, a=0x50, m=0x14)]
ARITH_ABOUT = {"ADC": ["Checks the sum, carry in/out, and the N/Z/C/V flags.",
                       "Each case sets C, D and V first (via PLP)."],
               "SBC": ["Checks the difference, borrow in/out (C=0 means borrow), and the N/Z/C/V flags.",
                       "Each case sets C, D and V first (via PLP)."]}
BINARY_ONLY = "Binary mode only (D=0); decimal mode is tested separately in {}_imm_dec."
for mn, imm, mod in (("ADC", ADC_IMM, ADC_MODE), ("SBC", SBC_IMM, SBC_MODE)):
    binary = [c for c in imm if not c["p"] & 0x08]
    decimal = [c for c in imm if c["p"] & 0x08]
    for mode in ALU_MODES:
        add(read_test(mn, mode, "A", binary if mode == "imm" else mod, ARITH_ABOUT[mn],
                      [BINARY_ONLY.format(mn.lower())]))
    add(read_test(mn, "imm", "A", decimal, ARITH_ABOUT[mn],
                  ["Decimal mode (D=1) only; run this after the binary-mode tests pass.",
                   "Flags follow NMOS behaviour:",
                   "ADC: N and V from the intermediate result, Z from the binary sum;" if mn == "ADC" else
                   "SBC: N, V and Z from the binary difference."],
                  suffix="_dec", title_extra=", decimal mode"))

# --- Compares --------------------------------------------------------------
CMP_IMM = [dict(a=0x5A, m=0x5A, desc="equal (Z=1, C=1)"), dict(a=0x5A, m=0xA5, desc="register < operand (C=0)"),
           dict(a=0x80, m=0x01, desc="register > operand (C=1)"), dict(a=0x01, m=0x02, desc="register < operand, result $FF (N=1)"),
           dict(a=0x00, m=0x80, desc="$00 vs $80: unsigned, C=0, N=1"), dict(a=0xFF, m=0x00, desc="$FF vs $00: C=1, N=1"),
           dict(a=0x00, m=0x00, desc="zero vs zero (Z=1, C=1)")]
CMP_MODE = [dict(a=0x5A, m=0x5A), dict(a=0x5A, m=0xA5), dict(a=0x80, m=0x01), dict(a=0x01, m=0x02), dict(a=0x3C, m=0x1C)]
CMP_ABOUT = ["Checks N/Z/C after the compare, and that the register and V are unchanged",
             "(the register is stored after each compare)."]
for mode in ALU_MODES:
    add(read_test("CMP", mode, "A", CMP_IMM if mode == "imm" else CMP_MODE, CMP_ABOUT))
for mn, reg in (("CPX", "X"), ("CPY", "Y")):
    for mode in ("imm", "zpg", "abs"):
        add(read_test(mn, mode, reg, CMP_IMM if mode == "imm" else CMP_MODE, CMP_ABOUT))

# --- BIT -------------------------------------------------------------------
BIT_CASES = [dict(a=0x01, m=0xC0, desc="N=M7=1, V=M6=1, A AND M = 0 (Z=1)"),
             dict(a=0xFF, m=0x3F, desc="N=0, V=0 (cleared), A AND M <> 0"),
             dict(a=0x40, m=0x40, desc="V=1 only"),
             dict(a=0x80, m=0x80, desc="N=1 only")]
for mode in ("zpg", "abs"):
    add(read_test("BIT", mode, "A", BIT_CASES,
                  ["Checks N=M7, V=M6, Z=(A AND M)=0, and that A and C are unchanged."]))

# --- Stores ----------------------------------------------------------------
STORE_ABOUT = ["Checks the value lands at the right address and that the flags are unchanged.",
               "A store to the wrong address shows up as a stray non-zero byte."]
for mn, reg, modes in (("STA", "A", ["zpg", "zpgX", "abs", "absX", "absY", "Xind", "indY"]),
                       ("STX", "X", ["zpg", "zpgY", "abs"]), ("STY", "Y", ["zpg", "zpgX", "abs"])):
    for mode in modes:
        t = store_test(mn, mode, reg, list(STORE_ABOUT))
        if mode in ("absX", "absY", "indY"):
            t.about.append("Cycle note: indexed stores always take the extra cycle (no page-cross variance).")
        add(t)

# --- Shifts, rotates, INC/DEC on memory -------------------------------------
RMW_ABOUT = {"ASL": "Shifts left; bit 7 goes to C, bit 0 becomes 0.",
             "LSR": "Shifts right; bit 0 goes to C, bit 7 becomes 0 (N is always 0).",
             "ROL": "Rotates left through carry; each case sets C first (via PLP).",
             "ROR": "Rotates right through carry; each case sets C first (via PLP).",
             "INC": "Increments memory; checks N/Z and wrap $FF -> $00.",
             "DEC": "Decrements memory; checks N/Z and wrap $00 -> $FF."}
RMW_MEM = {
    "ASL": [(None, 0x2D, "$2D -> $5A"), (None, 0x52, "$52 -> $A4"), (None, 0x80, "$80 -> $00, C=1"), (None, 0x3F, "$3F -> $7E"), (None, 0x9E, "$9E -> $3C, C=1")],
    "LSR": [(None, 0xB4, "$B4 -> $5A"), (None, 0xFF, "$FF -> $7F, C=1"), (None, 0x01, "$01 -> $00, C=1"), (None, 0xFE, "$FE -> $7F"), (None, 0x78, "$78 -> $3C")],
    "ROL": [(P0, 0x2D, "C=0: $2D -> $5A"), (P1, 0x52, "C=1: $52 -> $A5"), (P0, 0x80, "C=0: $80 -> $00, C=1"), (P1, 0x3F, "C=1: $3F -> $7F"), (P0, 0x9E, "C=0: $9E -> $3C, C=1")],
    "ROR": [(P0, 0xB4, "C=0: $B4 -> $5A"), (P1, 0x4A, "C=1: $4A -> $A5"), (P0, 0x01, "C=0: $01 -> $00, C=1"), (P0, 0xFE, "C=0: $FE -> $7F"), (P1, 0x78, "C=1: $78 -> $BC")],
    "INC": [(None, 0x59, "$59 -> $5A"), (None, 0x7F, "$7F -> $80"), (None, 0xFF, "$FF -> $00"), (None, 0x7E, "$7E -> $7F"), (None, 0x3B, "$3B -> $3C")],
    "DEC": [(None, 0x5B, "$5B -> $5A"), (None, 0x00, "$00 -> $FF"), (None, 0x01, "$01 -> $00"), (None, 0x80, "$80 -> $7F"), (None, 0x3D, "$3D -> $3C")],
}
RMW_ACC = {
    "ASL": [(None, 0x2D, "$2D -> $5A"), (None, 0x81, "$81 -> $02, C=1"), (None, 0x40, "$40 -> $80 (N=1)"), (None, 0x80, "$80 -> $00, C=1 (Z=1)")],
    "LSR": [(None, 0xB4, "$B4 -> $5A"), (None, 0x01, "$01 -> $00, C=1 (Z=1)"), (None, 0x81, "$81 -> $40, C=1"), (None, 0xFE, "$FE -> $7F")],
    "ROL": [(P0, 0x2D, "C=0: $2D -> $5A"), (P1, 0x00, "C=1: $00 -> $01"), (P1, 0x80, "C=1: $80 -> $01, C=1"),
            (P0, 0x80, "C=0: $80 -> $00, C=1 (Z=1)"), (P1, 0x40, "C=1: $40 -> $81 (N=1)"), (P1, 0xFF, "C=1: $FF -> $FF, C=1")],
    "ROR": [(P0, 0xB4, "C=0: $B4 -> $5A"), (P1, 0x00, "C=1: $00 -> $80 (N=1)"), (P1, 0x01, "C=1: $01 -> $80, C=1"),
            (P0, 0x01, "C=0: $01 -> $00, C=1 (Z=1)"), (P0, 0xFF, "C=0: $FF -> $7F, C=1"), (P1, 0xFE, "C=1: $FE -> $FF")],
}
for mn in ("ASL", "LSR", "ROL", "ROR"):
    for mode in ("A", "zpg", "zpgX", "abs", "absX"):
        cases = RMW_ACC[mn] if mode == "A" else RMW_MEM[mn]
        add(rmw_test(mn, mode, cases, [RMW_ABOUT[mn], "Checks the result and the N/Z/C flags, and that V is unchanged."]))
for mn in ("INC", "DEC"):
    for mode in ("zpg", "zpgX", "abs", "absX"):
        add(rmw_test(mn, mode, RMW_MEM[mn], [RMW_ABOUT[mn], "Checks that C and V are unchanged."]))

# --- Register increment / decrement ----------------------------------------
for mn, reg, vals in (("INX", "X", [0x59, 0x7F, 0xFF, 0x7E]), ("INY", "Y", [0x59, 0x7F, 0xFF, 0x7E]),
                      ("DEX", "X", [0x5B, 0x00, 0x01, 0x80]), ("DEY", "Y", [0x5B, 0x00, 0x01, 0x80])):
    up = mn.startswith("IN")
    t = add(Test(mn.lower(), [opc(mn, "impl")], f"{mn} implied",
                 [f"{'Increments' if up else 'Decrements'} {reg}; checks N/Z, wrap "
                  f"{'$FF -> $00' if up else '$00 -> $FF'}, and that C and V are unchanged."]))
    for n, v in enumerate(vals, 1):
        r = (v + (1 if up else -1)) & 0xFF
        t.body.section(f"Case {n}: {H(v)} -> {H(r)}")
        t.body.ins(f"ld{reg.lower()} #{H(v)}")
        t.body.ins(mn.lower())
        t.body.ins(f"st{reg.lower()} ${0x2FF + n:04X}", tag="result")
        t.body.ins("php", tag="expect")

# --- Transfers -------------------------------------------------------------
def opposite(v):
    """A value whose N/Z flags differ from those of v, to show the transfer sets them."""
    return 0x80 if v == 0 else 0x00 if v & 0x80 else 0x80

for mn, src, dst, spare in (("TAX", "A", "X", "Y"), ("TAY", "A", "Y", "X"),
                            ("TXA", "X", "A", "Y"), ("TYA", "Y", "A", "X")):
    t = add(Test(mn.lower(), [opc(mn, "impl")], f"{mn} implied",
                 [f"Copies {src} to {dst}; checks the value, N/Z, and that C and V are unchanged.",
                  f"Before each transfer, {spare} is loaded so that N/Z are the opposite of the expected result."]))
    for n, v in enumerate([0x5A, 0xA5, 0x00, 0x7F], 1):
        t.body.section(f"Case {n}: {H(v)}")
        t.body.ins(f"ld{src.lower()} #{H(v)}")
        t.body.ins(f"ld{spare.lower()} #{H(opposite(v))}", "Set N/Z opposite to the result")
        t.body.ins(mn.lower())
        t.body.ins(f"st{dst.lower()} ${0x2FF + n:04X}", tag="result")
        t.body.ins("php", tag="expect")

t = add(Test("tsx", [opc("TSX", "impl")], "TSX implied",
             ["Copies the stack pointer to X; checks the value and N/Z.",
              "Each case sets SP with TXS; the PHP then lands at $0100+SP."]))
for n, v in enumerate([0x5A, 0xA5, 0x00, 0x7F], 1):
    t.body.section(f"Case {n}: SP = {H(v)}")
    t.body.ins(f"ldx #{H(v)}")
    t.body.ins("txs")
    t.body.ins(f"ldy #{H(opposite(v))}", "Set N/Z opposite to the result")
    t.body.ins("tsx")
    t.body.ins(f"stx ${0x2FF + n:04X}", tag="result")
    t.body.ins("php", "Pushed at $0100+SP", tag="expect")

t = add(Test("txs", [opc("TXS", "impl")], "TXS implied",
             ["Copies X to the stack pointer and must not change any flags.",
              "The PHP after each TXS shows where SP points ($0100+X)."]))
for n, v in enumerate([0x80, 0x00, 0xFF, 0x7F], 1):
    t.body.section(f"Case {n}: X = {H(v)}")
    t.body.ins(f"ldy #{H(opposite(v))}", "N/Z opposite to what X would give")
    t.body.ins(f"ldx #{H(v)}")
    t.body.ins(f"ldy #{H(opposite(v))}", "Restore N/Z opposite to X")
    t.body.ins("txs")
    t.body.ins("php", "Lands at $0100+X, flags unchanged", tag="expect")

# --- Stack -----------------------------------------------------------------
t = add(Test("pha", [opc("PHA", "impl")], "PHA implied",
             ["Pushes A; checks the pushed bytes, the SP decrement (via TSX) and stack-page wrap",
              "($0100 -> $01FF), and that the flags are unchanged."], layout=False))
t.body.section("Cases 1-3: SP = $80, push $5A, $A5, $00")
t.body.ins("ldx #$80"); t.body.ins("txs")
for v in (0x5A, 0xA5, 0x00):
    t.body.ins(f"lda #{H(v)}"); t.body.ins("pha", tag="result")
t.body.ins("tsx"); t.body.ins("stx $0300", tag="result")
t.body.ins("php", tag="expect")
t.body.section("Cases 4-6: SP = $01, push across the wrap")
t.body.ins("ldx #$01"); t.body.ins("txs")
for v in (0xC3, 0x3C, 0x81):
    t.body.ins(f"lda #{H(v)}"); t.body.ins("pha", tag="result")
t.body.ins("tsx"); t.body.ins("stx $0301", tag="result")
t.body.ins("php", tag="expect")

t = add(Test("pla", [opc("PLA", "impl")], "PLA implied",
             ["Pulls A; checks the value, N/Z, and stack-page wrap ($01FF -> $0100).",
              "Each case points SP just below a seeded byte; the PHP afterwards overwrites that byte."]))
PLA_CASES = [(0x80, 0x5A), (0x90, 0xA5), (0xA0, 0x00), (0xB0, 0x7F), (0xFF, 0x3C)]
for sp, v in PLA_CASES:
    t.setup.seed(0x100 + ((sp + 1) & 0xFF), v)
for n, (sp, v) in enumerate(PLA_CASES, 1):
    t.body.section(f"Case {n}: SP = {H(sp)}, pull {H(v)} from ${0x100 + ((sp + 1) & 0xFF):04X}"
                   + (" (wrap)" if sp == 0xFF else ""))
    t.body.ins(f"ldx #{H(sp)}"); t.body.ins("txs")
    t.body.ins(f"ldy #{H(opposite(v))}", "Set N/Z opposite to the result")
    t.body.ins("pla")
    t.body.ins(f"sta ${0x2FF + n:04X}", tag="result")
    t.body.ins("php", tag="expect")

t = add(Test("php", [opc("PHP", "impl")], "PHP implied",
             ["Pushes the status; B (bit 4) and bit 5 are always set in the pushed byte."],
             prologue_p=None))
for n, p in enumerate([0x00, 0xFF, 0xC3, 0x0C, 0x41], 1):
    t.body.section(f"Case {n}: status {flags_text(p)}")
    t.body.set_p(p)
    t.body.ins("php", tag="result")
t.body.section("Case 6: a second PHP shows the first one left the flags unchanged")
t.body.ins("php", tag="result")

t = add(Test("plp", [opc("PLP", "impl")], "PLP implied",
             ["Pulls the status; N V D I Z C come from the stack, B and bit 5 are ignored.",
              "The PHP after each PLP shows the resulting status."], prologue_p=None))
for n, p in enumerate([0xFF, 0x00, 0xC3, 0x3C, 0xCF], 1):
    t.body.section(f"Case {n}: pull {H(p)}")
    t.body.ins(f"lda #{H(p)}"); t.body.ins("pha")
    t.body.ins(f"ldy #{H(opposite(p))}", "Make N/Z differ before the pull")
    t.body.ins("plp")
    t.body.ins("php", tag="expect")

# --- Flag instructions -----------------------------------------------------
FLAGS = {"CLC": (0x01, 0), "SEC": (0x01, 1), "CLD": (0x08, 0), "SED": (0x08, 1),
         "CLI": (0x04, 0), "SEI": (0x04, 1), "CLV": (0x40, 0)}
for mn, (bit, val) in FLAGS.items():
    fname = {1: "C", 8: "D", 4: "I", 0x40: "V"}[bit]
    t = add(Test(mn.lower(), [opc(mn, "impl")], f"{mn} implied",
                 [f"{'Sets' if val else 'Clears'} {fname}; all other flags must be unchanged."], prologue_p=None))
    starts = [0xFF, 0x00, bit, 0xFF & ~bit]
    for n, p in enumerate(starts, 1):
        t.body.section(f"Case {n}: start {flags_text(p)}")
        t.body.set_p(p)
        t.body.ins(mn.lower())
        t.body.ins("php", tag="expect")

# --- NOP -------------------------------------------------------------------
t = add(Test("nop", [opc("NOP", "impl")], "NOP implied",
             ["Must change nothing: A, X, Y, the flags and memory are checked afterwards.",
              "Also checks that NOP is one byte long (the next instruction runs)."], prologue_p=None))
for n, (p, a, x, y) in enumerate([(0xFF, 0x5A, 0xA5, 0x7F), (0x00, 0x3C, 0xC3, 0x81)], 1):
    t.body.section(f"Case {n}: status {H(p)}, A={H(a)} X={H(x)} Y={H(y)}")
    t.body.ins(f"lda #{H(p)}"); t.body.ins("pha")
    t.body.ins(f"ldx #{H(x)}"); t.body.ins(f"ldy #{H(y)}"); t.body.ins(f"lda #{H(a)}")
    t.body.ins("plp", "Set flags last (A, X, Y are kept)")
    t.body.ins("nop")
    t.body.ins("php", tag="expect")
    base = 0x300 + (n - 1) * 3
    t.body.ins(f"sta ${base:04X}", tag="result")
    t.body.ins(f"stx ${base + 1:04X}", tag="result")
    t.body.ins(f"sty ${base + 2:04X}", tag="result")

# --- Branches --------------------------------------------------------------
BR = {"BCC": (0x01, 0), "BCS": (0x01, 1), "BNE": (0x02, 0), "BEQ": (0x02, 1),
      "BPL": (0x80, 0), "BMI": (0x80, 1), "BVC": (0x40, 0), "BVS": (0x40, 1)}
for mn, (bit, want) in BR.items():
    fname = {1: "C", 2: "Z", 0x80: "N", 0x40: "V"}[bit]
    b = mn.lower()
    def p_for(taken, others_set):
        flag = bit if (want if taken else not want) else 0
        return ((0xCF & ~bit) if others_set else 0) | flag
    t = add(Test(b, [opc(mn, "rel")], f"{mn} relative",
                 [f"Branches when {fname}={want}. Checks taken and not-taken, forward and backward,",
                  "maximum offsets (+127 / -128) across a page boundary, and that the other flags",
                  "do not affect the decision. Each path stores a marker ($EE = wrong path) and",
                  "captures the status with PHP.",
                  "Cycle note: 2 not taken, 3 taken, 4 taken across a page."], prologue_p=None))
    B_, T_ = t.body, t.tail
    def land(src, slot, marker):
        src.ins("php", tag="expect")
        src.ins(f"lda #{H(marker)}")
        src.ins(f"sta ${slot:04X}", tag="result")

    B_.section(f"Case 1: taken forward ({fname}={want}, other flags clear)")
    B_.set_p(p_for(True, False)); B_.ins(f"{b} c1_ok")
    land(B_, 0x300, 0xEE); B_.ins("jmp c2")
    B_.label("c1_ok"); land(B_, 0x300, 0x01)

    B_.section(f"Case 2: not taken ({fname}={int(not want)}, other flags set)")
    B_.label("c2"); B_.set_p(p_for(False, True)); B_.ins(f"{b} c2_bad")
    land(B_, 0x301, 0x02); B_.ins("jmp c3")
    B_.label("c2_bad"); land(B_, 0x301, 0xEE)

    B_.section(f"Case 3: taken backward ({fname}={want}, other flags set)")
    B_.label("c3"); B_.set_p(p_for(True, True)); B_.ins("jmp c3_br")
    B_.label("c3_ok"); land(B_, 0x302, 0x03); B_.ins("jmp c4")
    B_.label("c3_br"); B_.ins(f"{b} c3_ok")
    land(B_, 0x302, 0xEE); B_.ins("jmp c4")

    B_.section(f"Case 4: not taken ({fname}={int(not want)}, other flags clear)")
    B_.label("c4"); B_.set_p(p_for(False, False)); B_.ins(f"{b} c4_bad")
    land(B_, 0x303, 0x04); B_.ins("jmp c5")
    B_.label("c4_bad"); land(B_, 0x303, 0xEE)

    B_.section("Case 5: taken forward, offset +127, crossing $C1xx -> $C2xx")
    B_.label("c5"); B_.set_p(p_for(True, False)); B_.ins("jmp c5_br")

    T_.raw(); T_.ins(".org $C1F0")
    T_.label("c5_br"); T_.ins(f"{b} c5_ok", "$C1F2 + 127 = $C271")
    land(T_, 0x304, 0xEE); T_.ins("jmp c6")
    T_.raw(); T_.ins(".org $C271")
    T_.label("c5_ok"); land(T_, 0x304, 0x05); T_.ins("jmp c6")

    T_.section("Case 6: taken backward, offset -128, crossing $C4xx -> $C3xx")
    T_.ins(".org $C300")
    T_.label("c6"); T_.set_p(p_for(True, True)); T_.ins("jmp c6_br")
    T_.raw(); T_.ins(".org $C390")
    T_.label("c6_ok"); land(T_, 0x305, 0x06); T_.ins("jmp done")
    T_.raw(); T_.ins(".org $C40E")
    T_.label("c6_br"); T_.ins(f"{b} c6_ok", "$C410 - 128 = $C390")
    land(T_, 0x305, 0xEE); T_.ins("jmp done")

# --- JMP -------------------------------------------------------------------
t = add(Test("jmp_abs", [opc("JMP", "abs")], "JMP absolute",
             ["Jumps forward, backward and to another page. Each target stores a marker;",
              "skipped code stores $EE."], prologue_p=PROLOGUE_P, layout=False))
t.body.section("Case 1: jump forward over a failure marker")
t.body.ins("jmp j1"); t.body.ins("lda #$EE"); t.body.ins("sta $0300", tag="result")
t.body.label("j1"); t.body.ins("php", tag="expect"); t.body.ins("lda #$01"); t.body.ins("sta $0300", tag="result")
t.body.section("Case 2: jump to another page ($C500), which jumps back")
t.body.ins("jmp j2"); t.body.label("j2_back")
t.body.section("Case 3: jump backward")
t.body.ins("jmp j3_fwd")
t.body.label("j3"); t.body.ins("php", tag="expect"); t.body.ins("lda #$03"); t.body.ins("sta $0302", tag="result"); t.body.ins("jmp done")
t.body.label("j3_fwd"); t.body.ins("jmp j3")
t.body.ins("lda #$EE"); t.body.ins("sta $0302", tag="result")
t.tail.raw(); t.tail.ins(".org $C500")
t.tail.label("j2"); t.tail.ins("php", tag="expect"); t.tail.ins("lda #$02"); t.tail.ins("sta $0301", tag="result"); t.tail.ins("jmp j2_back")

t = add(Test("jmp_ind", [opc("JMP", "ind")], "JMP (indirect)",
             ["Jumps through a pointer in RAM. Case 2 checks the NMOS page-wrap bug:",
              "JMP ($04FF) takes the low byte from $04FF and the high byte from $0400, not $0500.",
              "A CPU without the bug lands on the $E2 marker."], prologue_p=PROLOGUE_P, layout=False))
t.setup.raw("        ; Case 1 pointer at $0410 -> t1")
t.setup.ins("lda #<t1"); t.setup.ins("sta $0410"); t.setup.ins("lda #>t1"); t.setup.ins("sta $0411")
t.setup.raw("        ; Case 2 pointer at $04FF: low $40, high from $0400 = $C5 (NMOS), $0500 = $C6 (fixed)")
t.setup.seed(0x04FF, 0x40); t.setup.seed(0x0400, 0xC5); t.setup.seed(0x0500, 0xC6)
t.body.section("Case 1: pointer within one page")
t.body.ins("jmp ($0410)")
t.body.ins("lda #$EE"); t.body.ins("sta $0300", tag="result"); t.body.ins("jmp c2")
t.body.label("t1"); t.body.ins("php", tag="expect"); t.body.ins("lda #$01"); t.body.ins("sta $0300", tag="result")
t.body.section("Case 2: pointer at a page end ($04FF), NMOS wrap bug")
t.body.label("c2"); t.body.ins("jmp ($04FF)")
t.body.ins("lda #$EE"); t.body.ins("sta $0301", tag="result"); t.body.ins("jmp done")
t.tail.raw(); t.tail.ins(".org $C540")
t.tail.label("t2"); t.tail.ins("php", tag="expect"); t.tail.ins("lda #$02", "NMOS: high byte from $0400"); t.tail.ins("sta $0301", tag="result"); t.tail.ins("jmp done")
t.tail.raw(); t.tail.ins(".org $C640")
t.tail.label("t2_fixed"); t.tail.ins("lda #$E2", "Wrong: high byte from $0500"); t.tail.ins("sta $0301", tag="result"); t.tail.ins("jmp done")

# --- JSR / RTS / RTI / BRK ---------------------------------------------------
t = add(Test("jsr", [opc("JSR", "abs")], "JSR absolute",
             ["Pushes the address of its own last byte (PC+2), high byte first, then jumps.",
              "Subroutines record SP (via TSX) and return with JMP, so RTS is not needed.",
              "Case 1 starts with SP = $00 to check the stack-page wrap."], prologue_p=PROLOGUE_P, layout=False))
t.body.section("Case 1: SP = $00, pushes to $0100 and $01FF (wrap)")
t.body.ins("ldx #$00"); t.body.ins("txs")
t.body.ins("jsr sub1", tag="result"); t.body.label("ret1")
t.body.section("Case 2: JSR in mid-page")
t.body.ins("jsr sub2", tag="result"); t.body.label("ret2")
t.body.section("Case 3: JSR at $C2FE; its last byte is $C300, so the pushed address needs a carry")
t.body.ins("jmp c3")
t.tail.raw(); t.tail.ins(".org $C2FE")
t.tail.label("c3"); t.tail.ins("jsr sub3", tag="result")
t.tail.label("ret3"); t.tail.ins("jmp done")
t.tail.raw(); t.tail.ins(".org $C600")
for n, ret in ((1, "ret1"), (2, "ret2"), (3, "ret3")):
    t.tail.label(f"sub{n}"); t.tail.ins("tsx"); t.tail.ins(f"stx ${0x30F + n:04X}", "SP after the JSR", tag="result")
    t.tail.ins("php", "Flags unchanged by JSR", tag="expect"); t.tail.ins(f"lda #{H(n)}"); t.tail.ins(f"sta ${0x2FF + n:04X}", tag="result")
    t.tail.ins(f"jmp {ret}")

t = add(Test("rts", [opc("RTS", "impl")], "RTS implied",
             ["Pulls an address and continues at address + 1. Return addresses are pushed by",
              "hand (PHA) so JSR is not needed. Each target stores a marker and records SP."],
             prologue_p=PROLOGUE_P, layout=False))
t.body.section("Case 1: return to r1")
t.body.ins("lda #>(r1-1)"); t.body.ins("pha"); t.body.ins("lda #<(r1-1)"); t.body.ins("pha")
t.body.ins("rts")
t.body.ins("lda #$EE"); t.body.ins("sta $0300", tag="result")
t.body.label("r1"); t.body.ins("tsx"); t.body.ins("stx $0310", "SP after the RTS", tag="result")
t.body.ins("php", "Flags unchanged by RTS", tag="expect"); t.body.ins("lda #$01"); t.body.ins("sta $0300", tag="result")
t.body.section("Case 2: pulled address $C4FF; +1 must carry into the high byte -> $C500")
t.body.ins("lda #>(r2-1)"); t.body.ins("pha"); t.body.ins("lda #<(r2-1)"); t.body.ins("pha")
t.body.ins("rts")
t.body.section("Case 3: SP = $FE, pulls from $01FF and $0100 (wrap)")
t.body.label("c3")
t.body.ins("lda #<(r3-1)"); t.body.ins("sta $01FF"); t.body.ins("lda #>(r3-1)"); t.body.ins("sta $0100")
t.body.ins("ldx #$FE"); t.body.ins("txs")
t.body.ins("rts")
t.body.ins("lda #$EE"); t.body.ins("sta $0302", tag="result")
t.tail.raw(); t.tail.ins(".org $C400")
t.tail.label("r2_bad"); t.tail.ins("lda #$E2", "Wrong: no carry into the high byte"); t.tail.ins("sta $0301", tag="result"); t.tail.ins("jmp c3")
t.tail.raw(); t.tail.ins(".org $C500")
t.tail.label("r2"); t.tail.ins("tsx"); t.tail.ins("stx $0311", "SP after the RTS", tag="result")
t.tail.ins("php", "Flags unchanged by RTS", tag="expect"); t.tail.ins("lda #$02"); t.tail.ins("sta $0301", tag="result"); t.tail.ins("jmp c3")
t.tail.raw(); t.tail.ins(".org $C600")
t.tail.label("r3"); t.tail.ins("tsx"); t.tail.ins("stx $0312", "SP after the RTS", tag="result")
t.tail.ins("php", "Flags unchanged by RTS", tag="expect"); t.tail.ins("lda #$03"); t.tail.ins("sta $0302", tag="result"); t.tail.ins("jmp done")

t = add(Test("rti", [opc("RTI", "impl")], "RTI implied",
             ["Pulls the status then the address, and continues at that address (no +1).",
              "B and bit 5 of the pulled status are ignored. Each target starts with a PHP",
              "(so landing one byte late skips it), then stores a marker."], prologue_p=None, layout=False))
for n, (p, sp) in enumerate([(0xFF, None), (0x00, None), (0xC3, 0xFD)], 1):
    if sp is None:
        t.body.section(f"Case {n}: frame with status {H(p)}")
        t.body.ins(f"lda #>i{n}"); t.body.ins("pha"); t.body.ins(f"lda #<i{n}"); t.body.ins("pha")
        t.body.ins(f"lda #{H(p)}"); t.body.ins("pha")
    else:
        t.body.section(f"Case {n}: SP = $FD, frame at $01FE, $01FF, $0100 (wrap), status {H(p)}")
        t.body.ins(f"lda #{H(p)}"); t.body.ins("sta $01FE")
        t.body.ins(f"lda #<i{n}"); t.body.ins("sta $01FF")
        t.body.ins(f"lda #>i{n}"); t.body.ins("sta $0100")
        t.body.ins("ldx #$FD"); t.body.ins("txs")
    t.body.ins(f"ldy #{H(opposite(p))}", "Make N/Z differ before the RTI")
    t.body.ins("rti")
    t.body.ins("lda #$EE"); t.body.ins(f"sta ${0x2FF + n:04X}", tag="result")
    t.body.label(f"i{n}"); t.body.ins("php", "Restored status", tag="expect")
    t.body.ins(f"lda #{H(n)}"); t.body.ins(f"sta ${0x2FF + n:04X}", tag="result")

t = add(Test("brk", [opc("BRK", "impl")], "BRK implied",
             ["Pushes PC+2 (skipping a padding byte) and the status with B set, sets I, and",
              "jumps through the IRQ/BRK vector. On the NMOS 6502, D is not cleared.",
              "The handler records its own status with PHP, drops it with PLA, and returns with RTI.",
              "Case 2 runs with SP = $EF so its stack frame does not overwrite case 1."],
             prologue_p=None, layout=False, vectors=("done", "reset", "handler")))
t.body.section("Case 1: status N V D Z C set, I clear")
t.body.set_p(0xCB)
t.body.ins("brk", tag="result"); t.body.ins("nop", "Padding byte (skipped)")
t.body.ins("lda #$01"); t.body.ins("sta $0300", tag="result")
t.body.section("Case 2: SP = $EF, status clear, BRK at $C2FE (PC+2 = $C300 needs a carry)")
t.body.ins("ldx #$EF"); t.body.ins("txs")
t.body.set_p(0x00)
t.body.ins("jmp c2")
t.tail.raw(); t.tail.ins(".org $C2FE")
t.tail.label("c2"); t.tail.ins("brk", tag="result"); t.tail.ins("nop", "Padding byte (skipped)")
t.tail.ins("lda #$02"); t.tail.ins("sta $0301", tag="result"); t.tail.ins("jmp done")
t.tail.raw(); t.tail.ins(".org $C600")
t.tail.label("handler"); t.tail.ins("php", "Status inside the handler: I set, D unchanged", tag="expect")
t.tail.ins("pla"); t.tail.ins("rti")


# ------------------------------------------------------------- main

if __name__ == "__main__":
    names = [t.name for t in ALL]
    assert len(names) == len(set(names)), "duplicate test names"
    covered = {o for t in ALL for o in t.opcodes}
    assert covered == set(S.TABLE), sorted(set(S.TABLE) - covered)
    problems = 0
    for t in ALL:
        fm, missed = build(t)
        tries = 0
        while set(missed) & ADDR_FAULTS and getattr(t, "factory", None) and tries < len(TRAP_POOL):
            tries += 1
            t = t.factory(TRAP_POOL[tries:] + TRAP_POOL[:tries])
            fm, missed = build(t)
        if missed:
            problems += 1
            print(f"{t.name:<10} faults {sum(fm.values())}/{len(fm)} MISSED {missed}")
    print(f"{len(ALL)} tests written, {problems} with problems")
