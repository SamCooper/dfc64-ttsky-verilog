"""Assembler + NMOS 6502 reference model for the DFC64 test files.

The opcode table (mnemonic, mode, cycles) is read from 6502_test_completeness.md,
which was verified against masswerk.at.

Usage: python3 test/tools/sim6502.py [--write-json] [--stamp] test/*.asm
  Prints, per test, how many injected faults it detects (exit code 1 if any are missed).
  --write-json  rewrite each .json from the model
  --stamp       add/update the '; Cycles:' and '; Done:' header lines
"""
import re, sys, os, json

HERE = os.path.dirname(os.path.abspath(__file__))
REPORT = os.path.join(HERE, "..", "..", "6502_test_completeness.md")
RAM_END = 0x8000

MODE_KEY = {"accumulator": "A", "absolute": "abs", "absolute,X": "absX", "absolute,Y": "absY",
            "immediate": "imm", "implied": "impl", "indirect": "ind", "(indirect,X)": "Xind",
            "(indirect),Y": "indY", "relative": "rel", "zeropage": "zpg", "zeropage,X": "zpgX",
            "zeropage,Y": "zpgY"}
LEN = {"A": 1, "impl": 1, "imm": 2, "zpg": 2, "zpgX": 2, "zpgY": 2, "Xind": 2, "indY": 2,
       "rel": 2, "abs": 3, "absX": 3, "absY": 3, "ind": 3}


def load_table():
    table, ops = {}, {}
    for line in open(REPORT):
        m = re.match(r"\| \[.\] \| \$([0-9A-F]{2}) \| (.*?) \| `(\w{3}).*?` \| (\d) \| (\d)(\**) \|", line)
        if m:
            op, mode = int(m.group(1), 16), MODE_KEY[m.group(2)]
            table[op] = (m.group(3), mode, int(m.group(5)), len(m.group(6)))
            ops[(m.group(3), mode)] = op
    assert len(table) == 151, len(table)
    return table, ops


TABLE, OPS = load_table()
BRANCHES = {"BCC", "BCS", "BEQ", "BMI", "BNE", "BPL", "BVC", "BVS"}
ZP_OF = {"abs": "zpg", "absX": "zpgX", "absY": "zpgY"}


# ---------------------------------------------------------------- assembler

def eval_expr(s, labels, strict):
    s = s.strip()
    if s.startswith("<"):
        return eval_expr(s[1:], labels, strict) & 0xFF
    if s.startswith(">"):
        return (eval_expr(s[1:], labels, strict) >> 8) & 0xFF
    if s.startswith("(") and s.endswith(")") and s.count("(") == 1:
        return eval_expr(s[1:-1], labels, strict)
    terms = re.split(r"([+-])", s)
    total, sign = 0, 1
    for t in terms:
        t = t.strip()
        if t == "+": sign = 1; continue
        if t == "-": sign = -1; continue
        if t.startswith("$"): v = int(t[1:], 16)
        elif t.startswith("%"): v = int(t[1:], 2)
        elif t.isdigit(): v = int(t)
        elif t in labels: v = labels[t]
        elif strict: raise SystemExit(f"undefined symbol {t}")
        else: v = 0xC000
        total += sign * v
    return total


def has_label(s):
    return re.search(r"[A-Za-z_]\w*", re.sub(r"\$[0-9A-Fa-f]+", "", s)) is not None


def parse_operand(s):
    s = s.strip()
    if not s:
        return "impl", None
    if s.startswith("#"):
        return "imm", s[1:]
    m = re.fullmatch(r"\((.+),\s*[xX]\)", s)
    if m: return "Xind", m.group(1)
    m = re.fullmatch(r"\((.+)\),\s*[yY]", s)
    if m: return "indY", m.group(1)
    m = re.fullmatch(r"\(([^()]+)\)", s)
    if m: return "ind", m.group(1)
    m = re.fullmatch(r"(.+),\s*([xXyY])", s)
    if m: return "abs" + m.group(2).upper(), m.group(1)
    return "abs", s


def assemble(path_or_text, is_text=False):
    """Returns (memory image dict, {source line index: address})."""
    lines = (path_or_text if is_text else open(path_or_text).read()).splitlines()

    def one_pass(labels, strict):
        mem, pc, found, where = (Once() if strict else {}), 0, {}, {}
        for idx, raw in enumerate(lines):
            line = raw.split(";", 1)[0].rstrip()
            m = re.match(r"^(\w+):\s*(.*)$", line.strip())
            if m:
                found[m.group(1)] = pc
                line = m.group(2)
            line = line.strip()
            if not line:
                continue
            parts = line.split(None, 1)
            op, arg = parts[0], (parts[1] if len(parts) > 1 else "")
            d = op.lower()
            if d == ".org":
                pc = eval_expr(arg, labels, strict); continue
            if d in (".word", ".byte"):
                for a in arg.split(","):
                    v = eval_expr(a, labels, strict)
                    if d == ".word":
                        mem[pc], mem[pc + 1] = v & 0xFF, (v >> 8) & 0xFF; pc += 2
                    else:
                        mem[pc] = v & 0xFF; pc += 1
                continue
            mn = op.upper()
            where[idx] = pc
            mode, expr = parse_operand(arg)
            if mn in BRANCHES:
                mode = "rel"
            elif mode == "impl" and (mn, "A") in OPS:
                mode = "A"
            elif mode in ZP_OF and (mn, ZP_OF[mode]) in OPS and not has_label(expr):
                if eval_expr(expr, labels, strict) <= 0xFF:
                    mode = ZP_OF[mode]
            if (mn, mode) not in OPS:
                raise SystemExit(f"unsupported {mn} {mode}: {raw}")
            mem[pc] = OPS[(mn, mode)]
            if mode == "rel":
                off = eval_expr(expr, labels, strict) - (pc + 2)
                if strict and not -128 <= off <= 127:
                    raise SystemExit(f"branch out of range ({off}): {raw}")
                mem[pc + 1] = off & 0xFF
            elif LEN[mode] >= 2:
                v = eval_expr(expr, labels, strict)
                mem[pc + 1] = v & 0xFF
                if LEN[mode] == 3:
                    mem[pc + 2] = (v >> 8) & 0xFF
            pc += LEN[mode]
        return mem, found, where

    class Once(dict):
        def __setitem__(self, k, v):
            if k in self:
                raise SystemExit(f"overlapping code at ${k:04X}")
            super().__setitem__(k, v)

    _, labels, _ = one_pass({}, False)
    mem, labels2, where = one_pass(labels, True)
    assert labels == labels2, "label addresses moved between passes"
    return mem, where


# ---------------------------------------------------------------- CPU model

C, Z, I, D, B, U, V, N = 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
AFFECTS = {  # flags each mnemonic may change (others must be preserved)
    "ADC": N | V | Z | C, "SBC": N | V | Z | C, "AND": N | Z, "ORA": N | Z, "EOR": N | Z,
    "ASL": N | Z | C, "LSR": N | Z | C, "ROL": N | Z | C, "ROR": N | Z | C,
    "INC": N | Z, "DEC": N | Z, "INX": N | Z, "INY": N | Z, "DEX": N | Z, "DEY": N | Z,
    "LDA": N | Z, "LDX": N | Z, "LDY": N | Z, "TAX": N | Z, "TAY": N | Z, "TXA": N | Z,
    "TYA": N | Z, "TSX": N | Z, "PLA": N | Z, "CMP": N | Z | C, "CPX": N | Z | C,
    "CPY": N | Z | C, "BIT": N | V | Z, "CLC": C, "SEC": C, "CLV": V, "CLD": D, "SED": D,
    "CLI": I, "SEI": I, "PLP": 0xFF, "RTI": 0xFF, "BRK": I,
}

FAULTS = ["no_zp_wrap", "no_carry", "drop_high", "no_nz", "flags_leak", "no_write",
          "no_carry_in", "no_decimal", "no_v", "cmp_c_inverted", "bit_no_v",
          "branch_inverted", "branch_no_page", "jmp_ind_fixed", "jsr_ret_pc", "rts_no_inc",
          "rti_inc", "brk_pc1", "brk_no_b", "brk_clear_d", "php_no_b", "no_stack_wrap"]


class CPU:
    def __init__(self, image, faults=(), target=()):
        self.m = bytearray(0x10000)
        for a, v in image.items():
            if a < RAM_END:
                raise SystemExit(f"code/data assembled into RAM at ${a:04X}")
            self.m[a] = v
        self.faults, self.target = set(faults), set(target)
        self.a = self.x = self.y = 0
        self.sp, self.p = 0xFD, U | I
        self.pc = self.m[0xFFFC] | self.m[0xFFFD] << 8
        self.cycles = 0
        self.trace = []          # (pc, addr, old, new)
        self.triggered = set()
        self.tgt = False
        self.cur = 0

    # fault helper: active only while executing a target opcode
    def f(self, name):
        return self.tgt and name in self.faults

    def hit(self, name, changed=True):
        if changed:
            self.triggered.add(name)

    def rd(self, a): return self.m[a & 0xFFFF]

    def wr(self, a, v):
        a &= 0xFFFF
        if self.f("no_write"):
            self.hit("no_write"); return
        if a >= RAM_END:
            raise RuntimeError(f"write to non-RAM ${a:04X}")
        self.trace.append((self.cur, a, self.m[a], v & 0xFF))
        self.m[a] = v & 0xFF

    def fetch(self):
        v = self.rd(self.pc); self.pc = (self.pc + 1) & 0xFFFF; return v

    def setf(self, flag, cond):
        self.p = (self.p | flag) if cond else (self.p & ~flag)

    def nz(self, v):
        if self.f("no_nz"):
            self.hit("no_nz", ((self.p & N) != (v & N)) or bool(self.p & Z) != (v == 0)); return
        self.setf(N, v & 0x80); self.setf(Z, v == 0)

    def zpw(self, a):
        if self.f("no_zp_wrap"):
            self.hit("no_zp_wrap", a > 0xFF); return a
        return a & 0xFF

    def idx(self, base, r):
        a = (base + r) & 0xFFFF
        cross = (a & 0xFF00) != (base & 0xFF00)
        if self.f("no_carry"):
            bad = (base & 0xFF00) | ((base + r) & 0xFF)
            self.hit("no_carry", bad != a); return bad, False
        return a, cross

    def ea(self, mode):
        """Effective address for memory modes -> (addr, page_crossed)."""
        if mode == "zpg":
            return self.fetch(), False
        if mode == "zpgX": return self.zpw(self.fetch() + self.x), False
        if mode == "zpgY": return self.zpw(self.fetch() + self.y), False
        if mode == "abs":
            lo, hi = self.fetch(), self.fetch()
            if self.f("drop_high"):
                self.hit("drop_high", hi != 0); return lo, False
            return lo | hi << 8, False
        if mode in ("absX", "absY"):
            base = self.fetch() | self.fetch() << 8
            return self.idx(base, self.x if mode == "absX" else self.y)
        if mode == "Xind":
            z = self.zpw(self.fetch() + self.x)
            return self.rd(z) | self.rd(self.zpw(z + 1)) << 8, False
        if mode == "indY":
            z = self.fetch()
            base = self.rd(z) | self.rd(self.zpw(z + 1)) << 8
            return self.idx(base, self.y)
        raise ValueError(mode)

    def sp_addr(self, sp):
        return 0x100 + sp

    def push(self, v):
        self.wr(self.sp_addr(self.sp), v)
        nsp = self.sp - 1
        if self.f("no_stack_wrap") and nsp < 0:
            self.hit("no_stack_wrap"); self.sp = -1  # next push lands at $00FF
        else:
            self.sp = nsp & 0xFF

    def pull(self):
        nsp = self.sp + 1
        if self.f("no_stack_wrap") and nsp > 0xFF:
            self.hit("no_stack_wrap"); self.sp = nsp
        else:
            self.sp = nsp & 0xFF
        return self.rd(self.sp_addr(self.sp))

    def adc(self, m):
        cin = self.p & C
        if self.f("no_carry_in"):
            self.hit("no_carry_in", cin != 0); cin = 0
        a = self.a
        dec = self.p & D
        if self.f("no_decimal"):
            self.hit("no_decimal", dec != 0); dec = 0
        if not dec:
            r = a + m + cin
            v = (~(a ^ m) & (a ^ r)) & 0x80
            self.setf(C, r > 0xFF); r &= 0xFF
        else:  # NMOS decimal (Bruce Clark, "Decimal Mode", appendix A)
            binr = (a + m + cin) & 0xFF
            al = (a & 0x0F) + (m & 0x0F) + cin
            if al >= 0x0A:
                al = ((al + 0x06) & 0x0F) + 0x10
            r = (a & 0xF0) + (m & 0xF0) + al
            v = (~(a ^ m) & (a ^ r)) & 0x80
            n_from = r
            if r >= 0xA0:
                r += 0x60
            self.setf(C, r >= 0x100); r &= 0xFF
            self.a = r
            self.setv(v)
            if self.f("no_nz"):
                self.hit("no_nz")
            else:
                self.setf(N, n_from & 0x80); self.setf(Z, binr == 0)
            return
        self.a = r
        self.setv(v)
        self.nz(r)

    def sbc(self, m):
        cin = self.p & C
        if self.f("no_carry_in"):
            self.hit("no_carry_in", cin == 0); cin = 1
        a = self.a
        binr = a - m - (1 - cin)
        v = ((a ^ m) & (a ^ binr)) & 0x80
        dec = self.p & D
        if self.f("no_decimal"):
            self.hit("no_decimal", dec != 0); dec = 0
        if dec:  # NMOS decimal: flags from the binary result
            al = (a & 0x0F) - (m & 0x0F) + cin - 1
            if al < 0:
                al = ((al - 0x06) & 0x0F) - 0x10
            r = (a & 0xF0) - (m & 0xF0) + al
            if r < 0:
                r -= 0x60
            self.a = r & 0xFF
        else:
            self.a = binr & 0xFF
        self.setf(C, binr >= 0)
        self.setv(v)
        self.nz(binr & 0xFF)

    def setv(self, v):
        if self.f("no_v"):
            self.hit("no_v", v != 0); v = 0
        self.setf(V, v)

    def cmp(self, reg, m):
        r = reg - m
        c = r >= 0
        if self.f("cmp_c_inverted"):
            self.hit("cmp_c_inverted"); c = not c
        self.setf(C, c)
        self.nz(r & 0xFF)

    def rmw(self, mn, v):
        cin = 1 if self.p & C else 0
        if mn in ("ROL", "ROR") and self.f("no_carry_in"):
            self.hit("no_carry_in", cin != 0); cin = 0
        if mn == "ASL": self.setf(C, v & 0x80); r = (v << 1) & 0xFF
        elif mn == "LSR": self.setf(C, v & 1); r = v >> 1
        elif mn == "ROL": self.setf(C, v & 0x80); r = ((v << 1) | cin) & 0xFF
        elif mn == "ROR": self.setf(C, v & 1); r = (v >> 1) | (cin << 7)
        elif mn == "INC": r = (v + 1) & 0xFF
        else: r = (v - 1) & 0xFF
        self.nz(r)
        return r

    def step(self):
        pc0 = self.cur = self.pc
        op = self.fetch()
        if op not in TABLE:
            raise RuntimeError(f"illegal opcode ${op:02X} at ${pc0:04X}")
        mn, mode, cyc, star = TABLE[op]
        self.tgt = op in self.target
        p_before = self.p
        self.cycles += cyc
        addr = None
        if mode not in ("impl", "A", "imm", "rel", "ind") and mn not in ("JMP", "JSR"):
            addr, cross = self.ea(mode)
            if cross and star == 1:
                self.cycles += 1
        val = lambda: (self.fetch() if mode == "imm" else self.rd(addr))

        if mn == "LDA": self.a = val(); self.nz(self.a)
        elif mn == "LDX": self.x = val(); self.nz(self.x)
        elif mn == "LDY": self.y = val(); self.nz(self.y)
        elif mn == "STA": self.wr(addr, self.a)
        elif mn == "STX": self.wr(addr, self.x)
        elif mn == "STY": self.wr(addr, self.y)
        elif mn == "ADC": self.adc(val())
        elif mn == "SBC": self.sbc(val())
        elif mn == "AND": self.a &= val(); self.nz(self.a)
        elif mn == "ORA": self.a |= val(); self.nz(self.a)
        elif mn == "EOR": self.a ^= val(); self.nz(self.a)
        elif mn == "CMP": self.cmp(self.a, val())
        elif mn == "CPX": self.cmp(self.x, val())
        elif mn == "CPY": self.cmp(self.y, val())
        elif mn == "BIT":
            m = val()
            self.setf(N, m & 0x80)
            vb = m & 0x40
            if self.f("bit_no_v"):
                self.hit("bit_no_v", vb != 0); vb = 0
            self.setf(V, vb)
            self.setf(Z, (self.a & m) == 0)
        elif mn in ("ASL", "LSR", "ROL", "ROR", "INC", "DEC"):
            if mode == "A":
                self.a = self.rmw(mn, self.a)
            else:
                self.wr(addr, self.rmw(mn, self.rd(addr)))
        elif mn == "INX": self.x = (self.x + 1) & 0xFF; self.nz(self.x)
        elif mn == "INY": self.y = (self.y + 1) & 0xFF; self.nz(self.y)
        elif mn == "DEX": self.x = (self.x - 1) & 0xFF; self.nz(self.x)
        elif mn == "DEY": self.y = (self.y - 1) & 0xFF; self.nz(self.y)
        elif mn == "TAX": self.x = self.a; self.nz(self.x)
        elif mn == "TAY": self.y = self.a; self.nz(self.y)
        elif mn == "TXA": self.a = self.x; self.nz(self.a)
        elif mn == "TYA": self.a = self.y; self.nz(self.a)
        elif mn == "TSX": self.x = self.sp & 0xFF; self.nz(self.x)
        elif mn == "TXS": self.sp = self.x
        elif mn == "PHA": self.push(self.a)
        elif mn == "PHP":
            v = self.p | B | U
            if self.f("php_no_b"):
                self.hit("php_no_b"); v &= ~B
            self.push(v)
        elif mn == "PLA": self.a = self.pull(); self.nz(self.a)
        elif mn == "PLP": self.p = (self.pull() & ~B) | U
        elif mn == "CLC": self.p &= ~C
        elif mn == "SEC": self.p |= C
        elif mn == "CLI": self.p &= ~I
        elif mn == "SEI": self.p |= I
        elif mn == "CLD": self.p &= ~D
        elif mn == "SED": self.p |= D
        elif mn == "CLV": self.p &= ~V
        elif mn == "NOP": pass
        elif mn in BRANCHES:
            off = self.fetch()
            off = off - 0x100 if off & 0x80 else off
            flag = {"BCC": C, "BCS": C, "BEQ": Z, "BNE": Z, "BMI": N, "BPL": N, "BVC": V, "BVS": V}[mn]
            want = mn in ("BCS", "BEQ", "BMI", "BVS")
            take = bool(self.p & flag) == want
            if self.f("branch_inverted"):
                self.hit("branch_inverted"); take = not take
            if take:
                t = (self.pc + off) & 0xFFFF
                self.cycles += 1
                if (t & 0xFF00) != (self.pc & 0xFF00):
                    self.cycles += 1
                    if self.f("branch_no_page"):
                        self.hit("branch_no_page"); t = (self.pc & 0xFF00) | (t & 0xFF)
                self.pc = t
        elif mn == "JMP":
            t = self.fetch() | self.fetch() << 8
            if mode == "ind":
                ptr = t
                hi_addr = (ptr & 0xFF00) | ((ptr + 1) & 0xFF)
                if self.f("jmp_ind_fixed"):
                    self.hit("jmp_ind_fixed", hi_addr != ptr + 1); hi_addr = ptr + 1
                t = self.rd(ptr) | self.rd(hi_addr) << 8
            self.pc = t
            if t == pc0:
                return False
        elif mn == "JSR":
            lo = self.fetch()
            ret = self.pc          # address of the JSR's last byte
            if self.f("jsr_ret_pc"):
                self.hit("jsr_ret_pc"); ret += 1
            self.push((ret >> 8) & 0xFF); self.push(ret & 0xFF)
            self.pc = lo | self.fetch() << 8
        elif mn == "RTS":
            t = self.pull() | self.pull() << 8
            if self.f("rts_no_inc"):
                self.hit("rts_no_inc"); self.pc = t
            else:
                self.pc = (t + 1) & 0xFFFF
        elif mn == "RTI":
            self.p = (self.pull() & ~B) | U
            t = self.pull() | self.pull() << 8
            if self.f("rti_inc"):
                self.hit("rti_inc"); t += 1
            self.pc = t & 0xFFFF
        elif mn == "BRK":
            ret = (self.pc + 1) & 0xFFFF
            if self.f("brk_pc1"):
                self.hit("brk_pc1"); ret = self.pc
            self.push(ret >> 8); self.push(ret & 0xFF)
            pv = self.p | B | U
            if self.f("brk_no_b"):
                self.hit("brk_no_b"); pv &= ~B
            self.push(pv)
            self.p |= I
            if self.f("brk_clear_d"):
                self.hit("brk_clear_d", bool(self.p & D)); self.p &= ~D
            self.pc = self.rd(0xFFFE) | self.rd(0xFFFF) << 8
        else:
            raise RuntimeError(f"unimplemented {mn}")

        if self.f("flags_leak"):
            keep = ~AFFECTS.get(mn, 0) & (N | V | Z | C)
            if keep:
                self.hit("flags_leak"); self.p ^= keep
        return True

    def run(self, limit=200000):
        for _ in range(limit):
            if not self.step():
                return self
        raise RuntimeError("did not terminate")


def run_info(image):
    """(6502 cycles from the first instruction to the first fetch of the done loop, done address).
    The 7-cycle reset sequence is not included."""
    c = CPU(image).run()
    return c.cycles - 3, c.pc   # run() stops after executing the JMP-to-self once (3 cycles)


def stamp(path):
    """Write '; Cycles: n' and '; Done: $xxxx' after the '; Test:' header line(s)."""
    lines = open(path).read().split("\n")
    lines = [l for l in lines if not l.startswith(("; Cycles:", "; Done:"))]
    cycles, done = run_info(assemble("\n".join(lines), is_text=True)[0])
    at = max(i for i, l in enumerate(lines) if l.startswith("; Test:")) + 1
    lines[at:at] = [f"; Cycles: {cycles}", f"; Done: ${done:04X}"]
    with open(path, "w") as fh:
        fh.write("\n".join(lines))
    return cycles, done


def ram(cpu):
    return {a: cpu.m[a] for a in range(RAM_END) if cpu.m[a]}


def ram_json(cpu):
    return {f"0x{a:04X}": f"0x{v:02X}" for a, v in ram(cpu).items()}


def target_ops(path):
    """Opcodes under test, from the '; Test: ... ($XX)' header line(s)."""
    ops = set()
    for line in open(path):
        if line.startswith("; Test:"):
            ops |= {int(h, 16) for h in re.findall(r"\(\$([0-9A-F]{2})\)", line)}
    return ops


def fault_matrix(image, target, good):
    res = {}
    for fl in FAULTS:
        c = CPU(image, [fl], target)
        try:
            c.run()
            detected = ram(c) != good
        except RuntimeError:
            detected = True
        if c.triggered:
            res[fl] = detected
    return res


if __name__ == "__main__":
    write = "--write-json" in sys.argv
    stamping = "--stamp" in sys.argv
    files = [f for f in sys.argv[1:] if not f.startswith("--")]
    bad = 0
    for path in files:
        img, _ = assemble(path)
        cpu = CPU(img).run()
        good = ram(cpu)
        if stamping:
            stamp(path)
        if write:
            with open(os.path.splitext(path)[0] + ".json", "w") as fh:
                fh.write(json.dumps(ram_json(cpu), indent=4) + "\n")
        fm = fault_matrix(img, target_ops(path), good)
        missed = [k for k, v in fm.items() if not v]
        bad += bool(missed)
        print(f"{os.path.basename(path):<16} faults caught {sum(fm.values())}/{len(fm)}"
              + (f"  MISSED: {', '.join(missed)}" if missed else ""))
    sys.exit(1 if bad else 0)
