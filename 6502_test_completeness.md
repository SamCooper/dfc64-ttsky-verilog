# 6502 Instruction Set: Test Completeness Report

Reference: [6502 Instruction Set (masswerk.at)](https://www.masswerk.at/6502/6502_instruction_set.html)

Scope: the official NMOS 6502 instruction set, 56 instructions and 151 opcodes. Each opcode/addressing-mode combination is listed as its own entry.

## How to Use

This report tracks which 6502 opcodes pass on DFC64. The marks, counts and percentages are updated automatically after each cocotb run (see [Results and this report](#results-and-this-report)).

- **[Summary](#summary):** one row per instruction category.
  - *Opcodes*: the number of opcode/addressing-mode entries.
  - *Done*: entries whose test passes.
  - *Failing*: entries whose last run failed.
  - *Remaining*: Opcodes minus Done.
  - *% Complete*: Done divided by Opcodes.

  The block underneath gives the latest run totals and lists the failing tests.
- **[Addressing Modes](#addressing-modes):** the same counts and % Complete for each addressing mode.
- **[Instructions](#instructions):** one heading per instruction. Each shows the flags it affects and its progress, then one row per opcode:

| Column | Meaning |
|--------|---------|
| Done | Status mark (see below) |
| Opcode | Hex opcode. `(D=1)` marks the separate decimal-mode entry for ADC and SBC |
| Mode / Syntax | Addressing mode and assembler syntax |
| Bytes | Instruction length |
| 6502 Cycles | NMOS 6502 cycle count (see the cycle notes below) |
| DFC64 Cycles | DFC64 clock cycles (fetch + microcode stages), from `src/opcode_cycles.json` |
| Test Case | Links to the test's `.asm` source and `.json` expected RAM. Results are matched to rows through this link, so keep it in place |

| Mark | Meaning |
|------|---------|
| `[ ]` | Not tested |
| `[~]` | Partially tested / in progress (set by hand; kept until the test is next run) |
| `[x]` | Tested and passing |
| `[!]` | Tested and failing |

**Cycle notes:** `*` add 1 cycle if a page boundary is crossed. `**` add 1 cycle if the branch is taken, add 1 more if it lands on a different page. `***` NMOS: the indirect address high byte is always fetched from the same page as the low byte (`JMP ($11FF)` reads `$11FF` and `$1100`).

The decimal-mode entries for ADC and SBC are not counted in the Summary or Addressing Modes tables. They are included in the ADC and SBC progress lines.

The [Opcode Matrix](#opcode-matrix) is a 16×16 grid that cross-checks where each opcode sits. [How the Tests Work](#how-the-tests-work), at the end, describes the test files, the harness and the tools.

## Summary

| Category | Instructions | Opcodes | Done | Failing | Remaining | % Complete |
|----------|-------------:|--------:|-----:|--------:|----------:|-----------:|
| [Transfer Instructions](#transfer-instructions) | 12 | 37 | 37 | 0 | 0 | 100% |
| [Stack Instructions](#stack-instructions) | 4 | 4 | 4 | 0 | 0 | 100% |
| [Decrements & Increments](#decrements--increments) | 6 | 12 | 0 | 12 | 12 | 0% |
| [Arithmetic Operations](#arithmetic-operations) | 2 | 16 | 0 | 16 | 16 | 0% |
| [Logical Operations](#logical-operations) | 3 | 24 | 0 | 24 | 24 | 0% |
| [Shift & Rotate Instructions](#shift--rotate-instructions) | 4 | 20 | 0 | 20 | 20 | 0% |
| [Flag Instructions](#flag-instructions) | 7 | 7 | 7 | 0 | 0 | 100% |
| [Comparisons](#comparisons) | 3 | 14 | 0 | 14 | 14 | 0% |
| [Conditional Branch Instructions](#conditional-branch-instructions) | 8 | 8 | 0 | 8 | 8 | 0% |
| [Jumps & Subroutines](#jumps--subroutines) | 3 | 4 | 1 | 3 | 3 | 25% |
| [Interrupts](#interrupts) | 2 | 2 | 0 | 2 | 2 | 0% |
| [Other](#other) | 2 | 3 | 1 | 2 | 2 | 33% |
| **Total** | **56** | **151** | **50** | **101** | **101** | **33%** |

ADC and SBC also have a separate decimal-mode (D=1) row each, so binary mode can be completed first. These two rows are not included in the opcode counts above.

<!-- results:start -->

**Last results:** 50 passed, 103 failed, 0 not run (of 153 tests).

**Decimal mode:** 0 of 2 done (0%).

| Failing test | Reason |
|--------------|--------|
| [adc_abs](test/asm_tests/adc_abs.asm) | [adc_abs] RAM mismatch at 0x1fc: Expected 0x34, got 0x35 |
| [adc_abs_x](test/asm_tests/adc_abs_x.asm) | [adc_abs_x] RAM mismatch at 0x1fc: Expected 0x34, got 0x35 |
| [adc_abs_y](test/asm_tests/adc_abs_y.asm) | [adc_abs_y] RAM mismatch at 0x1fc: Expected 0x34, got 0x35 |
| [adc_imm](test/asm_tests/adc_imm.asm) | [adc_imm] RAM mismatch at 0x1f8: Expected 0x34, got 0x74 |
| [adc_imm_dec](test/asm_tests/adc_imm_dec.asm) | [adc_imm_dec] RAM mismatch at 0x1fb: Expected 0xfd, got 0x3c |
| [adc_ind_x](test/asm_tests/adc_ind_x.asm) | [adc_ind_x] RAM mismatch at 0x1fc: Expected 0x34, got 0x35 |
| [adc_ind_y](test/asm_tests/adc_ind_y.asm) | [adc_ind_y] RAM mismatch at 0x1fc: Expected 0x34, got 0x35 |
| [adc_zp](test/asm_tests/adc_zp.asm) | [adc_zp] RAM mismatch at 0x1fc: Expected 0x34, got 0x35 |
| [adc_zp_x](test/asm_tests/adc_zp_x.asm) | [adc_zp_x] RAM mismatch at 0x1fc: Expected 0x34, got 0x35 |
| [and_abs](test/asm_tests/and_abs.asm) | [and_abs] RAM mismatch at 0x1fd: Expected 0x77, got 0x75 |
| [and_abs_x](test/asm_tests/and_abs_x.asm) | [and_abs_x] RAM mismatch at 0x1fd: Expected 0x77, got 0x75 |
| [and_abs_y](test/asm_tests/and_abs_y.asm) | [and_abs_y] RAM mismatch at 0x1fd: Expected 0x77, got 0x75 |
| [and_imm](test/asm_tests/and_imm.asm) | [and_imm] RAM mismatch at 0x1fb: Expected 0x77, got 0xf5 |
| [and_ind_x](test/asm_tests/and_ind_x.asm) | [and_ind_x] RAM mismatch at 0x1fd: Expected 0x77, got 0x75 |
| [and_ind_y](test/asm_tests/and_ind_y.asm) | [and_ind_y] RAM mismatch at 0x1fd: Expected 0x77, got 0x75 |
| [and_zp](test/asm_tests/and_zp.asm) | [and_zp] RAM mismatch at 0x1fd: Expected 0x77, got 0x75 |
| [and_zp_x](test/asm_tests/and_zp_x.asm) | [and_zp_x] RAM mismatch at 0x1fd: Expected 0x77, got 0x75 |
| [asl_abs](test/asm_tests/asl_abs.asm) | [asl_abs] RAM mismatch at 0x100: Expected 0x7e, got 0x3f |
| [asl_abs_x](test/asm_tests/asl_abs_x.asm) | [asl_abs_x] RAM mismatch at 0x10: Expected 0x3c, got 0x9e |
| [asl_acc](test/asm_tests/asl_acc.asm) | [asl_acc] RAM mismatch at 0x1fc: Expected 0x77, got 0xf5 |
| [asl_zp](test/asm_tests/asl_zp.asm) | [asl_zp] RAM mismatch at 0x0: Expected 0x5a, got 0x2d |
| [asl_zp_x](test/asm_tests/asl_zp_x.asm) | [asl_zp_x] RAM mismatch at 0x10: Expected 0xa4, got 0x52 |
| [bcc](test/asm_tests/bcc.asm) | [bcc] RAM mismatch at 0x300: Expected 0x1, got 0xee |
| [bcs](test/asm_tests/bcs.asm) | [bcs] RAM mismatch at 0x300: Expected 0x1, got 0xee |
| [beq](test/asm_tests/beq.asm) | [beq] RAM mismatch at 0x300: Expected 0x1, got 0xee |
| [bit_abs](test/asm_tests/bit_abs.asm) | [bit_abs] RAM mismatch at 0x1fc: Expected 0xb5, got 0xf5 |
| [bit_zp](test/asm_tests/bit_zp.asm) | [bit_zp] RAM mismatch at 0x1fc: Expected 0xb5, got 0xf5 |
| [bmi](test/asm_tests/bmi.asm) | [bmi] RAM mismatch at 0x300: Expected 0x1, got 0xee |
| [bne](test/asm_tests/bne.asm) | [bne] RAM mismatch at 0x300: Expected 0x1, got 0xee |
| [bpl](test/asm_tests/bpl.asm) | [bpl] RAM mismatch at 0x300: Expected 0x1, got 0xee |
| [brk](test/asm_tests/brk.asm) | [brk] RAM mismatch at 0x1ec: Expected 0x34, got 0x0 |
| [bvc](test/asm_tests/bvc.asm) | [bvc] RAM mismatch at 0x300: Expected 0x1, got 0xee |
| [bvs](test/asm_tests/bvs.asm) | [bvs] RAM mismatch at 0x300: Expected 0x1, got 0xee |
| [cmp_abs](test/asm_tests/cmp_abs.asm) | [cmp_abs] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cmp_abs_x](test/asm_tests/cmp_abs_x.asm) | [cmp_abs_x] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cmp_abs_y](test/asm_tests/cmp_abs_y.asm) | [cmp_abs_y] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cmp_imm](test/asm_tests/cmp_imm.asm) | [cmp_imm] RAM mismatch at 0x1fb: Expected 0xf4, got 0x77 |
| [cmp_ind_x](test/asm_tests/cmp_ind_x.asm) | [cmp_ind_x] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cmp_ind_y](test/asm_tests/cmp_ind_y.asm) | [cmp_ind_y] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cmp_zp](test/asm_tests/cmp_zp.asm) | [cmp_zp] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cmp_zp_x](test/asm_tests/cmp_zp_x.asm) | [cmp_zp_x] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cpx_abs](test/asm_tests/cpx_abs.asm) | [cpx_abs] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cpx_imm](test/asm_tests/cpx_imm.asm) | [cpx_imm] RAM mismatch at 0x1fb: Expected 0xf4, got 0x77 |
| [cpx_zp](test/asm_tests/cpx_zp.asm) | [cpx_zp] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cpy_abs](test/asm_tests/cpy_abs.asm) | [cpy_abs] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [cpy_imm](test/asm_tests/cpy_imm.asm) | [cpy_imm] RAM mismatch at 0x1fb: Expected 0xf4, got 0x77 |
| [cpy_zp](test/asm_tests/cpy_zp.asm) | [cpy_zp] RAM mismatch at 0x1fc: Expected 0xf4, got 0x75 |
| [dec_abs](test/asm_tests/dec_abs.asm) | [dec_abs] RAM mismatch at 0x100: Expected 0x7f, got 0x80 |
| [dec_abs_x](test/asm_tests/dec_abs_x.asm) | [dec_abs_x] RAM mismatch at 0x10: Expected 0x3c, got 0x3d |
| [dec_zp](test/asm_tests/dec_zp.asm) | [dec_zp] RAM mismatch at 0x0: Expected 0x5a, got 0x5b |
| [dec_zp_x](test/asm_tests/dec_zp_x.asm) | [dec_zp_x] RAM mismatch at 0x10: Expected 0xff, got 0x0 |
| [dex](test/asm_tests/dex.asm) | [dex] RAM mismatch at 0x1fc: Expected 0x75, got 0xf5 |
| [dey](test/asm_tests/dey.asm) | [dey] RAM mismatch at 0x1fc: Expected 0x75, got 0xf5 |
| [eor_abs](test/asm_tests/eor_abs.asm) | [eor_abs] RAM mismatch at 0x1fc: Expected 0x75, got 0xf5 |
| [eor_abs_x](test/asm_tests/eor_abs_x.asm) | [eor_abs_x] RAM mismatch at 0x1fc: Expected 0x75, got 0xf5 |
| [eor_abs_y](test/asm_tests/eor_abs_y.asm) | [eor_abs_y] RAM mismatch at 0x1fc: Expected 0x75, got 0xf5 |
| [eor_imm](test/asm_tests/eor_imm.asm) | [eor_imm] RAM mismatch at 0x1fb: Expected 0x77, got 0xf5 |
| [eor_ind_x](test/asm_tests/eor_ind_x.asm) | [eor_ind_x] RAM mismatch at 0x1fc: Expected 0x75, got 0xf5 |
| [eor_ind_y](test/asm_tests/eor_ind_y.asm) | [eor_ind_y] RAM mismatch at 0x1fc: Expected 0x75, got 0xf5 |
| [eor_zp](test/asm_tests/eor_zp.asm) | [eor_zp] RAM mismatch at 0x1fc: Expected 0x75, got 0xf5 |
| [eor_zp_x](test/asm_tests/eor_zp_x.asm) | [eor_zp_x] RAM mismatch at 0x1fc: Expected 0x75, got 0xf5 |
| [inc_abs](test/asm_tests/inc_abs.asm) | [inc_abs] RAM mismatch at 0x100: Expected 0x7f, got 0x7e |
| [inc_abs_x](test/asm_tests/inc_abs_x.asm) | [inc_abs_x] RAM mismatch at 0x10: Expected 0x3c, got 0x3b |
| [inc_zp](test/asm_tests/inc_zp.asm) | [inc_zp] RAM mismatch at 0x0: Expected 0x5a, got 0x59 |
| [inc_zp_x](test/asm_tests/inc_zp_x.asm) | [inc_zp_x] RAM mismatch at 0x10: Expected 0x80, got 0x7f |
| [inx](test/asm_tests/inx.asm) | [inx] RAM mismatch at 0x1fd: Expected 0x77, got 0xf5 |
| [iny](test/asm_tests/iny.asm) | [iny] RAM mismatch at 0x1fd: Expected 0x77, got 0xf5 |
| [jmp_ind](test/asm_tests/jmp_ind.asm) | [jmp_ind] RAM mismatch at 0x1fe: Expected 0x75, got 0x0 |
| [jsr](test/asm_tests/jsr.asm) | [jsr] RAM mismatch at 0x100: Expected 0xc0, got 0x0 |
| [lsr_abs](test/asm_tests/lsr_abs.asm) | [lsr_abs] RAM mismatch at 0x100: Expected 0x7f, got 0xfe |
| [lsr_abs_x](test/asm_tests/lsr_abs_x.asm) | [lsr_abs_x] RAM mismatch at 0x10: Expected 0x3c, got 0x78 |
| [lsr_acc](test/asm_tests/lsr_acc.asm) | [lsr_acc] RAM mismatch at 0x1fc: Expected 0x74, got 0xf5 |
| [lsr_zp](test/asm_tests/lsr_zp.asm) | [lsr_zp] RAM mismatch at 0x0: Expected 0x5a, got 0xb4 |
| [lsr_zp_x](test/asm_tests/lsr_zp_x.asm) | [lsr_zp_x] RAM mismatch at 0x10: Expected 0x7f, got 0xff |
| [ora_abs](test/asm_tests/ora_abs.asm) | [ora_abs] RAM mismatch at 0x300: Expected 0x5a, got 0x50 |
| [ora_abs_x](test/asm_tests/ora_abs_x.asm) | [ora_abs_x] RAM mismatch at 0x300: Expected 0x5a, got 0x50 |
| [ora_abs_y](test/asm_tests/ora_abs_y.asm) | [ora_abs_y] RAM mismatch at 0x300: Expected 0x5a, got 0x50 |
| [ora_imm](test/asm_tests/ora_imm.asm) | [ora_imm] RAM mismatch at 0x300: Expected 0x5a, got 0x50 |
| [ora_ind_x](test/asm_tests/ora_ind_x.asm) | [ora_ind_x] RAM mismatch at 0x300: Expected 0x5a, got 0x50 |
| [ora_ind_y](test/asm_tests/ora_ind_y.asm) | [ora_ind_y] RAM mismatch at 0x300: Expected 0x5a, got 0x50 |
| [ora_zp](test/asm_tests/ora_zp.asm) | [ora_zp] RAM mismatch at 0x300: Expected 0x5a, got 0x50 |
| [ora_zp_x](test/asm_tests/ora_zp_x.asm) | [ora_zp_x] RAM mismatch at 0x300: Expected 0x5a, got 0x50 |
| [rol_abs](test/asm_tests/rol_abs.asm) | [rol_abs] RAM mismatch at 0x100: Expected 0x7f, got 0x3f |
| [rol_abs_x](test/asm_tests/rol_abs_x.asm) | [rol_abs_x] RAM mismatch at 0x10: Expected 0x3c, got 0x9e |
| [rol_acc](test/asm_tests/rol_acc.asm) | [rol_acc] RAM mismatch at 0x1fb: Expected 0xb4, got 0x35 |
| [rol_zp](test/asm_tests/rol_zp.asm) | [rol_zp] RAM mismatch at 0x0: Expected 0x5a, got 0x2d |
| [rol_zp_x](test/asm_tests/rol_zp_x.asm) | [rol_zp_x] RAM mismatch at 0x10: Expected 0xa5, got 0x52 |
| [ror_abs](test/asm_tests/ror_abs.asm) | [ror_abs] RAM mismatch at 0x100: Expected 0x7f, got 0xfe |
| [ror_abs_x](test/asm_tests/ror_abs_x.asm) | [ror_abs_x] RAM mismatch at 0x10: Expected 0xbc, got 0x78 |
| [ror_acc](test/asm_tests/ror_acc.asm) | [ror_acc] RAM mismatch at 0x1fa: Expected 0xb4, got 0xb5 |
| [ror_zp](test/asm_tests/ror_zp.asm) | [ror_zp] RAM mismatch at 0x0: Expected 0x5a, got 0xb4 |
| [ror_zp_x](test/asm_tests/ror_zp_x.asm) | [ror_zp_x] RAM mismatch at 0x10: Expected 0xa5, got 0x4a |
| [rti](test/asm_tests/rti.asm) | [rti] RAM mismatch at 0x100: Expected 0xf3, got 0xc0 |
| [rts](test/asm_tests/rts.asm) | [rts] RAM mismatch at 0x100: Expected 0x77, got 0xc5 |
| [sbc_abs](test/asm_tests/sbc_abs.asm) | [sbc_abs] RAM mismatch at 0x1fc: Expected 0x75, got 0xb4 |
| [sbc_abs_x](test/asm_tests/sbc_abs_x.asm) | [sbc_abs_x] RAM mismatch at 0x1fc: Expected 0x75, got 0xb4 |
| [sbc_abs_y](test/asm_tests/sbc_abs_y.asm) | [sbc_abs_y] RAM mismatch at 0x1fc: Expected 0x75, got 0xb4 |
| [sbc_imm](test/asm_tests/sbc_imm.asm) | [sbc_imm] RAM mismatch at 0x1f8: Expected 0x37, got 0x34 |
| [sbc_imm_dec](test/asm_tests/sbc_imm_dec.asm) | [sbc_imm_dec] RAM mismatch at 0x1fa: Expected 0xbc, got 0x3e |
| [sbc_ind_x](test/asm_tests/sbc_ind_x.asm) | [sbc_ind_x] RAM mismatch at 0x1fc: Expected 0x75, got 0xb4 |
| [sbc_ind_y](test/asm_tests/sbc_ind_y.asm) | [sbc_ind_y] RAM mismatch at 0x1fc: Expected 0x75, got 0xb4 |
| [sbc_zp](test/asm_tests/sbc_zp.asm) | [sbc_zp] RAM mismatch at 0x1fc: Expected 0x75, got 0xb4 |
| [sbc_zp_x](test/asm_tests/sbc_zp_x.asm) | [sbc_zp_x] RAM mismatch at 0x1fc: Expected 0x75, got 0xb4 |

<!-- results:end -->

## Addressing Modes

| Abbrev. | Mode | Syntax | Opcodes | Done | % Complete |
|---------|------|--------|--------:|-----:|-----------:|
| `A` | accumulator | `OPC A` | 4 | 0 | 0% |
| `abs` | absolute | `OPC oper` | 23 | 7 | 30% |
| `abs,X` | absolute,X | `OPC oper,X` | 15 | 3 | 20% |
| `abs,Y` | absolute,Y | `OPC oper,Y` | 9 | 3 | 33% |
| `#` | immediate | `OPC #oper` | 11 | 3 | 27% |
| `impl` | implied | `OPC` | 25 | 18 | 72% |
| `ind` | indirect | `OPC (oper)` | 1 | 0 | 0% |
| `X,ind` | (indirect,X) | `OPC (oper,X)` | 8 | 2 | 25% |
| `ind,Y` | (indirect),Y | `OPC (oper),Y` | 8 | 2 | 25% |
| `rel` | relative | `OPC oper` | 8 | 0 | 0% |
| `zpg` | zeropage | `OPC oper` | 21 | 6 | 28% |
| `zpg,X` | zeropage,X | `OPC oper,X` | 16 | 4 | 25% |
| `zpg,Y` | zeropage,Y | `OPC oper,Y` | 2 | 2 | 100% |

## Instructions

### Transfer Instructions

#### LDA: Load Accumulator with Memory

Flags affected: `N Z`

**Progress:** 8 of 8 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $A9 | immediate | `LDA #oper` | 2 | 2 | 6 | [lda_imm.asm](test/asm_tests/lda_imm.asm) / [lda_imm.json](test/asm_tests/lda_imm.json) |
| [x] | $A5 | zeropage | `LDA oper` | 2 | 3 | 7 | [lda_zp.asm](test/asm_tests/lda_zp.asm) / [lda_zp.json](test/asm_tests/lda_zp.json) |
| [x] | $B5 | zeropage,X | `LDA oper,X` | 2 | 4 | 7 | [lda_zp_x.asm](test/asm_tests/lda_zp_x.asm) / [lda_zp_x.json](test/asm_tests/lda_zp_x.json) |
| [x] | $AD | absolute | `LDA oper` | 3 | 4 | 10 | [lda_abs.asm](test/asm_tests/lda_abs.asm) / [lda_abs.json](test/asm_tests/lda_abs.json) |
| [x] | $BD | absolute,X | `LDA oper,X` | 3 | 4* | 10 | [lda_abs_x.asm](test/asm_tests/lda_abs_x.asm) / [lda_abs_x.json](test/asm_tests/lda_abs_x.json) |
| [x] | $B9 | absolute,Y | `LDA oper,Y` | 3 | 4* | 10 | [lda_abs_y.asm](test/asm_tests/lda_abs_y.asm) / [lda_abs_y.json](test/asm_tests/lda_abs_y.json) |
| [x] | $A1 | (indirect,X) | `LDA (oper,X)` | 2 | 6 | 12 | [lda_ind_x.asm](test/asm_tests/lda_ind_x.asm) / [lda_ind_x.json](test/asm_tests/lda_ind_x.json) |
| [x] | $B1 | (indirect),Y | `LDA (oper),Y` | 2 | 5* | 12 | [lda_ind_y.asm](test/asm_tests/lda_ind_y.asm) / [lda_ind_y.json](test/asm_tests/lda_ind_y.json) |

#### LDX: Load Index X with Memory

Flags affected: `N Z`

**Progress:** 5 of 5 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $A2 | immediate | `LDX #oper` | 2 | 2 | 6 | [ldx_imm.asm](test/asm_tests/ldx_imm.asm) / [ldx_imm.json](test/asm_tests/ldx_imm.json) |
| [x] | $A6 | zeropage | `LDX oper` | 2 | 3 | 7 | [ldx_zp.asm](test/asm_tests/ldx_zp.asm) / [ldx_zp.json](test/asm_tests/ldx_zp.json) |
| [x] | $B6 | zeropage,Y | `LDX oper,Y` | 2 | 4 | 7 | [ldx_zp_y.asm](test/asm_tests/ldx_zp_y.asm) / [ldx_zp_y.json](test/asm_tests/ldx_zp_y.json) |
| [x] | $AE | absolute | `LDX oper` | 3 | 4 | 10 | [ldx_abs.asm](test/asm_tests/ldx_abs.asm) / [ldx_abs.json](test/asm_tests/ldx_abs.json) |
| [x] | $BE | absolute,Y | `LDX oper,Y` | 3 | 4* | 10 | [ldx_abs_y.asm](test/asm_tests/ldx_abs_y.asm) / [ldx_abs_y.json](test/asm_tests/ldx_abs_y.json) |

#### LDY: Load Index Y with Memory

Flags affected: `N Z`

**Progress:** 5 of 5 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $A0 | immediate | `LDY #oper` | 2 | 2 | 6 | [ldy_imm.asm](test/asm_tests/ldy_imm.asm) / [ldy_imm.json](test/asm_tests/ldy_imm.json) |
| [x] | $A4 | zeropage | `LDY oper` | 2 | 3 | 7 | [ldy_zp.asm](test/asm_tests/ldy_zp.asm) / [ldy_zp.json](test/asm_tests/ldy_zp.json) |
| [x] | $B4 | zeropage,X | `LDY oper,X` | 2 | 4 | 7 | [ldy_zp_x.asm](test/asm_tests/ldy_zp_x.asm) / [ldy_zp_x.json](test/asm_tests/ldy_zp_x.json) |
| [x] | $AC | absolute | `LDY oper` | 3 | 4 | 10 | [ldy_abs.asm](test/asm_tests/ldy_abs.asm) / [ldy_abs.json](test/asm_tests/ldy_abs.json) |
| [x] | $BC | absolute,X | `LDY oper,X` | 3 | 4* | 10 | [ldy_abs_x.asm](test/asm_tests/ldy_abs_x.asm) / [ldy_abs_x.json](test/asm_tests/ldy_abs_x.json) |

#### STA: Store Accumulator in Memory

Flags affected: `-`

**Progress:** 7 of 7 done (100%)

> Indexed stores always take the extra cycle (no page-cross variance).

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $85 | zeropage | `STA oper` | 2 | 3 | 7 | [sta_zp.asm](test/asm_tests/sta_zp.asm) / [sta_zp.json](test/asm_tests/sta_zp.json) |
| [x] | $95 | zeropage,X | `STA oper,X` | 2 | 4 | 7 | [sta_zp_x.asm](test/asm_tests/sta_zp_x.asm) / [sta_zp_x.json](test/asm_tests/sta_zp_x.json) |
| [x] | $8D | absolute | `STA oper` | 3 | 4 | 10 | [sta_abs.asm](test/asm_tests/sta_abs.asm) / [sta_abs.json](test/asm_tests/sta_abs.json) |
| [x] | $9D | absolute,X | `STA oper,X` | 3 | 5 | 10 | [sta_abs_x.asm](test/asm_tests/sta_abs_x.asm) / [sta_abs_x.json](test/asm_tests/sta_abs_x.json) |
| [x] | $99 | absolute,Y | `STA oper,Y` | 3 | 5 | 10 | [sta_abs_y.asm](test/asm_tests/sta_abs_y.asm) / [sta_abs_y.json](test/asm_tests/sta_abs_y.json) |
| [x] | $81 | (indirect,X) | `STA (oper,X)` | 2 | 6 | 12 | [sta_ind_x.asm](test/asm_tests/sta_ind_x.asm) / [sta_ind_x.json](test/asm_tests/sta_ind_x.json) |
| [x] | $91 | (indirect),Y | `STA (oper),Y` | 2 | 6 | 12 | [sta_ind_y.asm](test/asm_tests/sta_ind_y.asm) / [sta_ind_y.json](test/asm_tests/sta_ind_y.json) |

#### STX: Store Index X in Memory

Flags affected: `-`

**Progress:** 3 of 3 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $86 | zeropage | `STX oper` | 2 | 3 | 7 | [stx_zp.asm](test/asm_tests/stx_zp.asm) / [stx_zp.json](test/asm_tests/stx_zp.json) |
| [x] | $96 | zeropage,Y | `STX oper,Y` | 2 | 4 | 7 | [stx_zp_y.asm](test/asm_tests/stx_zp_y.asm) / [stx_zp_y.json](test/asm_tests/stx_zp_y.json) |
| [x] | $8E | absolute | `STX oper` | 3 | 4 | 10 | [stx_abs.asm](test/asm_tests/stx_abs.asm) / [stx_abs.json](test/asm_tests/stx_abs.json) |

#### STY: Store Index Y in Memory

Flags affected: `-`

**Progress:** 3 of 3 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $84 | zeropage | `STY oper` | 2 | 3 | 7 | [sty_zp.asm](test/asm_tests/sty_zp.asm) / [sty_zp.json](test/asm_tests/sty_zp.json) |
| [x] | $94 | zeropage,X | `STY oper,X` | 2 | 4 | 7 | [sty_zp_x.asm](test/asm_tests/sty_zp_x.asm) / [sty_zp_x.json](test/asm_tests/sty_zp_x.json) |
| [x] | $8C | absolute | `STY oper` | 3 | 4 | 10 | [sty_abs.asm](test/asm_tests/sty_abs.asm) / [sty_abs.json](test/asm_tests/sty_abs.json) |

#### TAX: Transfer Accumulator to Index X

Flags affected: `N Z`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $AA | implied | `TAX` | 1 | 2 | 4 | [tax.asm](test/asm_tests/tax.asm) / [tax.json](test/asm_tests/tax.json) |

#### TAY: Transfer Accumulator to Index Y

Flags affected: `N Z`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $A8 | implied | `TAY` | 1 | 2 | 4 | [tay.asm](test/asm_tests/tay.asm) / [tay.json](test/asm_tests/tay.json) |

#### TSX: Transfer Stack Pointer to Index X

Flags affected: `N Z`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $BA | implied | `TSX` | 1 | 2 | 4 | [tsx.asm](test/asm_tests/tsx.asm) / [tsx.json](test/asm_tests/tsx.json) |

#### TXA: Transfer Index X to Accumulator

Flags affected: `N Z`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $8A | implied | `TXA` | 1 | 2 | 4 | [txa.asm](test/asm_tests/txa.asm) / [txa.json](test/asm_tests/txa.json) |

#### TXS: Transfer Index X to Stack Register

Flags affected: `-`

**Progress:** 1 of 1 done (100%)

> Does not affect flags.

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $9A | implied | `TXS` | 1 | 2 | 4 | [txs.asm](test/asm_tests/txs.asm) / [txs.json](test/asm_tests/txs.json) |

#### TYA: Transfer Index Y to Accumulator

Flags affected: `N Z`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $98 | implied | `TYA` | 1 | 2 | 4 | [tya.asm](test/asm_tests/tya.asm) / [tya.json](test/asm_tests/tya.json) |

### Stack Instructions

#### PHA: Push Accumulator on Stack

Flags affected: `-`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $48 | implied | `PHA` | 1 | 3 | 7 | [pha.asm](test/asm_tests/pha.asm) / [pha.json](test/asm_tests/pha.json) |

#### PHP: Push Processor Status on Stack

Flags affected: `-`

**Progress:** 1 of 1 done (100%)

> Pushed status has B (bit 4) and bit 5 set.

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $08 | implied | `PHP` | 1 | 3 | 7 | [php.asm](test/asm_tests/php.asm) / [php.json](test/asm_tests/php.json) |

#### PLA: Pull Accumulator from Stack

Flags affected: `N Z`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $68 | implied | `PLA` | 1 | 4 | 7 | [pla.asm](test/asm_tests/pla.asm) / [pla.json](test/asm_tests/pla.json) |

#### PLP: Pull Processor Status from Stack

Flags affected: `from stack`

**Progress:** 1 of 1 done (100%)

> B and bit 5 are ignored when pulled.

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $28 | implied | `PLP` | 1 | 4 | 7 | [plp.asm](test/asm_tests/plp.asm) / [plp.json](test/asm_tests/plp.json) |

### Decrements & Increments

#### DEC: Decrement Memory by One

Flags affected: `N Z`

**Progress:** 0 of 4 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $C6 | zeropage | `DEC oper` | 2 | 5 | | [dec_zp.asm](test/asm_tests/dec_zp.asm) / [dec_zp.json](test/asm_tests/dec_zp.json) |
| [!] | $D6 | zeropage,X | `DEC oper,X` | 2 | 6 | | [dec_zp_x.asm](test/asm_tests/dec_zp_x.asm) / [dec_zp_x.json](test/asm_tests/dec_zp_x.json) |
| [!] | $CE | absolute | `DEC oper` | 3 | 6 | | [dec_abs.asm](test/asm_tests/dec_abs.asm) / [dec_abs.json](test/asm_tests/dec_abs.json) |
| [!] | $DE | absolute,X | `DEC oper,X` | 3 | 7 | | [dec_abs_x.asm](test/asm_tests/dec_abs_x.asm) / [dec_abs_x.json](test/asm_tests/dec_abs_x.json) |

#### DEX: Decrement Index X by One

Flags affected: `N Z`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $CA | implied | `DEX` | 1 | 2 | | [dex.asm](test/asm_tests/dex.asm) / [dex.json](test/asm_tests/dex.json) |

#### DEY: Decrement Index Y by One

Flags affected: `N Z`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $88 | implied | `DEY` | 1 | 2 | | [dey.asm](test/asm_tests/dey.asm) / [dey.json](test/asm_tests/dey.json) |

#### INC: Increment Memory by One

Flags affected: `N Z`

**Progress:** 0 of 4 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $E6 | zeropage | `INC oper` | 2 | 5 | | [inc_zp.asm](test/asm_tests/inc_zp.asm) / [inc_zp.json](test/asm_tests/inc_zp.json) |
| [!] | $F6 | zeropage,X | `INC oper,X` | 2 | 6 | | [inc_zp_x.asm](test/asm_tests/inc_zp_x.asm) / [inc_zp_x.json](test/asm_tests/inc_zp_x.json) |
| [!] | $EE | absolute | `INC oper` | 3 | 6 | | [inc_abs.asm](test/asm_tests/inc_abs.asm) / [inc_abs.json](test/asm_tests/inc_abs.json) |
| [!] | $FE | absolute,X | `INC oper,X` | 3 | 7 | | [inc_abs_x.asm](test/asm_tests/inc_abs_x.asm) / [inc_abs_x.json](test/asm_tests/inc_abs_x.json) |

#### INX: Increment Index X by One

Flags affected: `N Z`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $E8 | implied | `INX` | 1 | 2 | | [inx.asm](test/asm_tests/inx.asm) / [inx.json](test/asm_tests/inx.json) |

#### INY: Increment Index Y by One

Flags affected: `N Z`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $C8 | implied | `INY` | 1 | 2 | | [iny.asm](test/asm_tests/iny.asm) / [iny.json](test/asm_tests/iny.json) |

### Arithmetic Operations

#### ADC: Add Memory to Accumulator with Carry

Flags affected: `N Z C V`

**Progress:** 0 of 9 done (0%)

> Test both binary and decimal (D=1) mode.

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $69 | immediate | `ADC #oper` | 2 | 2 | | [adc_imm.asm](test/asm_tests/adc_imm.asm) / [adc_imm.json](test/asm_tests/adc_imm.json) |
| [!] | $69 (D=1) | immediate, decimal mode | `ADC #oper` | 2 | 2 | | [adc_imm_dec.asm](test/asm_tests/adc_imm_dec.asm) / [adc_imm_dec.json](test/asm_tests/adc_imm_dec.json) |
| [!] | $65 | zeropage | `ADC oper` | 2 | 3 | | [adc_zp.asm](test/asm_tests/adc_zp.asm) / [adc_zp.json](test/asm_tests/adc_zp.json) |
| [!] | $75 | zeropage,X | `ADC oper,X` | 2 | 4 | | [adc_zp_x.asm](test/asm_tests/adc_zp_x.asm) / [adc_zp_x.json](test/asm_tests/adc_zp_x.json) |
| [!] | $6D | absolute | `ADC oper` | 3 | 4 | | [adc_abs.asm](test/asm_tests/adc_abs.asm) / [adc_abs.json](test/asm_tests/adc_abs.json) |
| [!] | $7D | absolute,X | `ADC oper,X` | 3 | 4* | | [adc_abs_x.asm](test/asm_tests/adc_abs_x.asm) / [adc_abs_x.json](test/asm_tests/adc_abs_x.json) |
| [!] | $79 | absolute,Y | `ADC oper,Y` | 3 | 4* | | [adc_abs_y.asm](test/asm_tests/adc_abs_y.asm) / [adc_abs_y.json](test/asm_tests/adc_abs_y.json) |
| [!] | $61 | (indirect,X) | `ADC (oper,X)` | 2 | 6 | | [adc_ind_x.asm](test/asm_tests/adc_ind_x.asm) / [adc_ind_x.json](test/asm_tests/adc_ind_x.json) |
| [!] | $71 | (indirect),Y | `ADC (oper),Y` | 2 | 5* | | [adc_ind_y.asm](test/asm_tests/adc_ind_y.asm) / [adc_ind_y.json](test/asm_tests/adc_ind_y.json) |

#### SBC: Subtract Memory from Accumulator with Borrow

Flags affected: `N Z C V`

**Progress:** 0 of 9 done (0%)

> Test both binary and decimal (D=1) mode.

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $E9 | immediate | `SBC #oper` | 2 | 2 | | [sbc_imm.asm](test/asm_tests/sbc_imm.asm) / [sbc_imm.json](test/asm_tests/sbc_imm.json) |
| [!] | $E9 (D=1) | immediate, decimal mode | `SBC #oper` | 2 | 2 | | [sbc_imm_dec.asm](test/asm_tests/sbc_imm_dec.asm) / [sbc_imm_dec.json](test/asm_tests/sbc_imm_dec.json) |
| [!] | $E5 | zeropage | `SBC oper` | 2 | 3 | | [sbc_zp.asm](test/asm_tests/sbc_zp.asm) / [sbc_zp.json](test/asm_tests/sbc_zp.json) |
| [!] | $F5 | zeropage,X | `SBC oper,X` | 2 | 4 | | [sbc_zp_x.asm](test/asm_tests/sbc_zp_x.asm) / [sbc_zp_x.json](test/asm_tests/sbc_zp_x.json) |
| [!] | $ED | absolute | `SBC oper` | 3 | 4 | | [sbc_abs.asm](test/asm_tests/sbc_abs.asm) / [sbc_abs.json](test/asm_tests/sbc_abs.json) |
| [!] | $FD | absolute,X | `SBC oper,X` | 3 | 4* | | [sbc_abs_x.asm](test/asm_tests/sbc_abs_x.asm) / [sbc_abs_x.json](test/asm_tests/sbc_abs_x.json) |
| [!] | $F9 | absolute,Y | `SBC oper,Y` | 3 | 4* | | [sbc_abs_y.asm](test/asm_tests/sbc_abs_y.asm) / [sbc_abs_y.json](test/asm_tests/sbc_abs_y.json) |
| [!] | $E1 | (indirect,X) | `SBC (oper,X)` | 2 | 6 | | [sbc_ind_x.asm](test/asm_tests/sbc_ind_x.asm) / [sbc_ind_x.json](test/asm_tests/sbc_ind_x.json) |
| [!] | $F1 | (indirect),Y | `SBC (oper),Y` | 2 | 5* | | [sbc_ind_y.asm](test/asm_tests/sbc_ind_y.asm) / [sbc_ind_y.json](test/asm_tests/sbc_ind_y.json) |

### Logical Operations

#### AND: AND Memory with Accumulator

Flags affected: `N Z`

**Progress:** 0 of 8 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $29 | immediate | `AND #oper` | 2 | 2 | | [and_imm.asm](test/asm_tests/and_imm.asm) / [and_imm.json](test/asm_tests/and_imm.json) |
| [!] | $25 | zeropage | `AND oper` | 2 | 3 | | [and_zp.asm](test/asm_tests/and_zp.asm) / [and_zp.json](test/asm_tests/and_zp.json) |
| [!] | $35 | zeropage,X | `AND oper,X` | 2 | 4 | | [and_zp_x.asm](test/asm_tests/and_zp_x.asm) / [and_zp_x.json](test/asm_tests/and_zp_x.json) |
| [!] | $2D | absolute | `AND oper` | 3 | 4 | | [and_abs.asm](test/asm_tests/and_abs.asm) / [and_abs.json](test/asm_tests/and_abs.json) |
| [!] | $3D | absolute,X | `AND oper,X` | 3 | 4* | | [and_abs_x.asm](test/asm_tests/and_abs_x.asm) / [and_abs_x.json](test/asm_tests/and_abs_x.json) |
| [!] | $39 | absolute,Y | `AND oper,Y` | 3 | 4* | | [and_abs_y.asm](test/asm_tests/and_abs_y.asm) / [and_abs_y.json](test/asm_tests/and_abs_y.json) |
| [!] | $21 | (indirect,X) | `AND (oper,X)` | 2 | 6 | | [and_ind_x.asm](test/asm_tests/and_ind_x.asm) / [and_ind_x.json](test/asm_tests/and_ind_x.json) |
| [!] | $31 | (indirect),Y | `AND (oper),Y` | 2 | 5* | | [and_ind_y.asm](test/asm_tests/and_ind_y.asm) / [and_ind_y.json](test/asm_tests/and_ind_y.json) |

#### EOR: Exclusive-OR Memory with Accumulator

Flags affected: `N Z`

**Progress:** 0 of 8 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $49 | immediate | `EOR #oper` | 2 | 2 | | [eor_imm.asm](test/asm_tests/eor_imm.asm) / [eor_imm.json](test/asm_tests/eor_imm.json) |
| [!] | $45 | zeropage | `EOR oper` | 2 | 3 | | [eor_zp.asm](test/asm_tests/eor_zp.asm) / [eor_zp.json](test/asm_tests/eor_zp.json) |
| [!] | $55 | zeropage,X | `EOR oper,X` | 2 | 4 | | [eor_zp_x.asm](test/asm_tests/eor_zp_x.asm) / [eor_zp_x.json](test/asm_tests/eor_zp_x.json) |
| [!] | $4D | absolute | `EOR oper` | 3 | 4 | | [eor_abs.asm](test/asm_tests/eor_abs.asm) / [eor_abs.json](test/asm_tests/eor_abs.json) |
| [!] | $5D | absolute,X | `EOR oper,X` | 3 | 4* | | [eor_abs_x.asm](test/asm_tests/eor_abs_x.asm) / [eor_abs_x.json](test/asm_tests/eor_abs_x.json) |
| [!] | $59 | absolute,Y | `EOR oper,Y` | 3 | 4* | | [eor_abs_y.asm](test/asm_tests/eor_abs_y.asm) / [eor_abs_y.json](test/asm_tests/eor_abs_y.json) |
| [!] | $41 | (indirect,X) | `EOR (oper,X)` | 2 | 6 | | [eor_ind_x.asm](test/asm_tests/eor_ind_x.asm) / [eor_ind_x.json](test/asm_tests/eor_ind_x.json) |
| [!] | $51 | (indirect),Y | `EOR (oper),Y` | 2 | 5* | | [eor_ind_y.asm](test/asm_tests/eor_ind_y.asm) / [eor_ind_y.json](test/asm_tests/eor_ind_y.json) |

#### ORA: OR Memory with Accumulator

Flags affected: `N Z`

**Progress:** 0 of 8 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $09 | immediate | `ORA #oper` | 2 | 2 | | [ora_imm.asm](test/asm_tests/ora_imm.asm) / [ora_imm.json](test/asm_tests/ora_imm.json) |
| [!] | $05 | zeropage | `ORA oper` | 2 | 3 | | [ora_zp.asm](test/asm_tests/ora_zp.asm) / [ora_zp.json](test/asm_tests/ora_zp.json) |
| [!] | $15 | zeropage,X | `ORA oper,X` | 2 | 4 | | [ora_zp_x.asm](test/asm_tests/ora_zp_x.asm) / [ora_zp_x.json](test/asm_tests/ora_zp_x.json) |
| [!] | $0D | absolute | `ORA oper` | 3 | 4 | | [ora_abs.asm](test/asm_tests/ora_abs.asm) / [ora_abs.json](test/asm_tests/ora_abs.json) |
| [!] | $1D | absolute,X | `ORA oper,X` | 3 | 4* | | [ora_abs_x.asm](test/asm_tests/ora_abs_x.asm) / [ora_abs_x.json](test/asm_tests/ora_abs_x.json) |
| [!] | $19 | absolute,Y | `ORA oper,Y` | 3 | 4* | | [ora_abs_y.asm](test/asm_tests/ora_abs_y.asm) / [ora_abs_y.json](test/asm_tests/ora_abs_y.json) |
| [!] | $01 | (indirect,X) | `ORA (oper,X)` | 2 | 6 | | [ora_ind_x.asm](test/asm_tests/ora_ind_x.asm) / [ora_ind_x.json](test/asm_tests/ora_ind_x.json) |
| [!] | $11 | (indirect),Y | `ORA (oper),Y` | 2 | 5* | | [ora_ind_y.asm](test/asm_tests/ora_ind_y.asm) / [ora_ind_y.json](test/asm_tests/ora_ind_y.json) |

### Shift & Rotate Instructions

#### ASL: Shift Left One Bit (Memory or Accumulator)

Flags affected: `N Z C`

**Progress:** 0 of 5 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $0A | accumulator | `ASL A` | 1 | 2 | | [asl_acc.asm](test/asm_tests/asl_acc.asm) / [asl_acc.json](test/asm_tests/asl_acc.json) |
| [!] | $06 | zeropage | `ASL oper` | 2 | 5 | | [asl_zp.asm](test/asm_tests/asl_zp.asm) / [asl_zp.json](test/asm_tests/asl_zp.json) |
| [!] | $16 | zeropage,X | `ASL oper,X` | 2 | 6 | | [asl_zp_x.asm](test/asm_tests/asl_zp_x.asm) / [asl_zp_x.json](test/asm_tests/asl_zp_x.json) |
| [!] | $0E | absolute | `ASL oper` | 3 | 6 | | [asl_abs.asm](test/asm_tests/asl_abs.asm) / [asl_abs.json](test/asm_tests/asl_abs.json) |
| [!] | $1E | absolute,X | `ASL oper,X` | 3 | 7 | | [asl_abs_x.asm](test/asm_tests/asl_abs_x.asm) / [asl_abs_x.json](test/asm_tests/asl_abs_x.json) |

#### LSR: Shift One Bit Right (Memory or Accumulator)

Flags affected: `N(=0) Z C`

**Progress:** 0 of 5 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $4A | accumulator | `LSR A` | 1 | 2 | | [lsr_acc.asm](test/asm_tests/lsr_acc.asm) / [lsr_acc.json](test/asm_tests/lsr_acc.json) |
| [!] | $46 | zeropage | `LSR oper` | 2 | 5 | | [lsr_zp.asm](test/asm_tests/lsr_zp.asm) / [lsr_zp.json](test/asm_tests/lsr_zp.json) |
| [!] | $56 | zeropage,X | `LSR oper,X` | 2 | 6 | | [lsr_zp_x.asm](test/asm_tests/lsr_zp_x.asm) / [lsr_zp_x.json](test/asm_tests/lsr_zp_x.json) |
| [!] | $4E | absolute | `LSR oper` | 3 | 6 | | [lsr_abs.asm](test/asm_tests/lsr_abs.asm) / [lsr_abs.json](test/asm_tests/lsr_abs.json) |
| [!] | $5E | absolute,X | `LSR oper,X` | 3 | 7 | | [lsr_abs_x.asm](test/asm_tests/lsr_abs_x.asm) / [lsr_abs_x.json](test/asm_tests/lsr_abs_x.json) |

#### ROL: Rotate One Bit Left (Memory or Accumulator)

Flags affected: `N Z C`

**Progress:** 0 of 5 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $2A | accumulator | `ROL A` | 1 | 2 | | [rol_acc.asm](test/asm_tests/rol_acc.asm) / [rol_acc.json](test/asm_tests/rol_acc.json) |
| [!] | $26 | zeropage | `ROL oper` | 2 | 5 | | [rol_zp.asm](test/asm_tests/rol_zp.asm) / [rol_zp.json](test/asm_tests/rol_zp.json) |
| [!] | $36 | zeropage,X | `ROL oper,X` | 2 | 6 | | [rol_zp_x.asm](test/asm_tests/rol_zp_x.asm) / [rol_zp_x.json](test/asm_tests/rol_zp_x.json) |
| [!] | $2E | absolute | `ROL oper` | 3 | 6 | | [rol_abs.asm](test/asm_tests/rol_abs.asm) / [rol_abs.json](test/asm_tests/rol_abs.json) |
| [!] | $3E | absolute,X | `ROL oper,X` | 3 | 7 | | [rol_abs_x.asm](test/asm_tests/rol_abs_x.asm) / [rol_abs_x.json](test/asm_tests/rol_abs_x.json) |

#### ROR: Rotate One Bit Right (Memory or Accumulator)

Flags affected: `N Z C`

**Progress:** 0 of 5 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $6A | accumulator | `ROR A` | 1 | 2 | | [ror_acc.asm](test/asm_tests/ror_acc.asm) / [ror_acc.json](test/asm_tests/ror_acc.json) |
| [!] | $66 | zeropage | `ROR oper` | 2 | 5 | | [ror_zp.asm](test/asm_tests/ror_zp.asm) / [ror_zp.json](test/asm_tests/ror_zp.json) |
| [!] | $76 | zeropage,X | `ROR oper,X` | 2 | 6 | | [ror_zp_x.asm](test/asm_tests/ror_zp_x.asm) / [ror_zp_x.json](test/asm_tests/ror_zp_x.json) |
| [!] | $6E | absolute | `ROR oper` | 3 | 6 | | [ror_abs.asm](test/asm_tests/ror_abs.asm) / [ror_abs.json](test/asm_tests/ror_abs.json) |
| [!] | $7E | absolute,X | `ROR oper,X` | 3 | 7 | | [ror_abs_x.asm](test/asm_tests/ror_abs_x.asm) / [ror_abs_x.json](test/asm_tests/ror_abs_x.json) |

### Flag Instructions

#### CLC: Clear Carry Flag

Flags affected: `C=0`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $18 | implied | `CLC` | 1 | 2 | 4 | [clc.asm](test/asm_tests/clc.asm) / [clc.json](test/asm_tests/clc.json) |

#### CLD: Clear Decimal Mode

Flags affected: `D=0`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $D8 | implied | `CLD` | 1 | 2 | 4 | [cld.asm](test/asm_tests/cld.asm) / [cld.json](test/asm_tests/cld.json) |

#### CLI: Clear Interrupt Disable Bit

Flags affected: `I=0`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $58 | implied | `CLI` | 1 | 2 | 4 | [cli.asm](test/asm_tests/cli.asm) / [cli.json](test/asm_tests/cli.json) |

#### CLV: Clear Overflow Flag

Flags affected: `V=0`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $B8 | implied | `CLV` | 1 | 2 | 4 | [clv.asm](test/asm_tests/clv.asm) / [clv.json](test/asm_tests/clv.json) |

#### SEC: Set Carry Flag

Flags affected: `C=1`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $38 | implied | `SEC` | 1 | 2 | 4 | [sec.asm](test/asm_tests/sec.asm) / [sec.json](test/asm_tests/sec.json) |

#### SED: Set Decimal Flag

Flags affected: `D=1`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $F8 | implied | `SED` | 1 | 2 | 4 | [sed.asm](test/asm_tests/sed.asm) / [sed.json](test/asm_tests/sed.json) |

#### SEI: Set Interrupt Disable Status

Flags affected: `I=1`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $78 | implied | `SEI` | 1 | 2 | 4 | [sei.asm](test/asm_tests/sei.asm) / [sei.json](test/asm_tests/sei.json) |

### Comparisons

#### CMP: Compare Memory with Accumulator

Flags affected: `N Z C`

**Progress:** 0 of 8 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $C9 | immediate | `CMP #oper` | 2 | 2 | | [cmp_imm.asm](test/asm_tests/cmp_imm.asm) / [cmp_imm.json](test/asm_tests/cmp_imm.json) |
| [!] | $C5 | zeropage | `CMP oper` | 2 | 3 | | [cmp_zp.asm](test/asm_tests/cmp_zp.asm) / [cmp_zp.json](test/asm_tests/cmp_zp.json) |
| [!] | $D5 | zeropage,X | `CMP oper,X` | 2 | 4 | | [cmp_zp_x.asm](test/asm_tests/cmp_zp_x.asm) / [cmp_zp_x.json](test/asm_tests/cmp_zp_x.json) |
| [!] | $CD | absolute | `CMP oper` | 3 | 4 | | [cmp_abs.asm](test/asm_tests/cmp_abs.asm) / [cmp_abs.json](test/asm_tests/cmp_abs.json) |
| [!] | $DD | absolute,X | `CMP oper,X` | 3 | 4* | | [cmp_abs_x.asm](test/asm_tests/cmp_abs_x.asm) / [cmp_abs_x.json](test/asm_tests/cmp_abs_x.json) |
| [!] | $D9 | absolute,Y | `CMP oper,Y` | 3 | 4* | | [cmp_abs_y.asm](test/asm_tests/cmp_abs_y.asm) / [cmp_abs_y.json](test/asm_tests/cmp_abs_y.json) |
| [!] | $C1 | (indirect,X) | `CMP (oper,X)` | 2 | 6 | | [cmp_ind_x.asm](test/asm_tests/cmp_ind_x.asm) / [cmp_ind_x.json](test/asm_tests/cmp_ind_x.json) |
| [!] | $D1 | (indirect),Y | `CMP (oper),Y` | 2 | 5* | | [cmp_ind_y.asm](test/asm_tests/cmp_ind_y.asm) / [cmp_ind_y.json](test/asm_tests/cmp_ind_y.json) |

#### CPX: Compare Memory and Index X

Flags affected: `N Z C`

**Progress:** 0 of 3 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $E0 | immediate | `CPX #oper` | 2 | 2 | | [cpx_imm.asm](test/asm_tests/cpx_imm.asm) / [cpx_imm.json](test/asm_tests/cpx_imm.json) |
| [!] | $E4 | zeropage | `CPX oper` | 2 | 3 | | [cpx_zp.asm](test/asm_tests/cpx_zp.asm) / [cpx_zp.json](test/asm_tests/cpx_zp.json) |
| [!] | $EC | absolute | `CPX oper` | 3 | 4 | | [cpx_abs.asm](test/asm_tests/cpx_abs.asm) / [cpx_abs.json](test/asm_tests/cpx_abs.json) |

#### CPY: Compare Memory and Index Y

Flags affected: `N Z C`

**Progress:** 0 of 3 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $C0 | immediate | `CPY #oper` | 2 | 2 | | [cpy_imm.asm](test/asm_tests/cpy_imm.asm) / [cpy_imm.json](test/asm_tests/cpy_imm.json) |
| [!] | $C4 | zeropage | `CPY oper` | 2 | 3 | | [cpy_zp.asm](test/asm_tests/cpy_zp.asm) / [cpy_zp.json](test/asm_tests/cpy_zp.json) |
| [!] | $CC | absolute | `CPY oper` | 3 | 4 | | [cpy_abs.asm](test/asm_tests/cpy_abs.asm) / [cpy_abs.json](test/asm_tests/cpy_abs.json) |

### Conditional Branch Instructions

#### BCC: Branch on Carry Clear (C=0)

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $90 | relative | `BCC oper` | 2 | 2** | | [bcc.asm](test/asm_tests/bcc.asm) / [bcc.json](test/asm_tests/bcc.json) |

#### BCS: Branch on Carry Set (C=1)

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $B0 | relative | `BCS oper` | 2 | 2** | | [bcs.asm](test/asm_tests/bcs.asm) / [bcs.json](test/asm_tests/bcs.json) |

#### BEQ: Branch on Result Zero (Z=1)

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $F0 | relative | `BEQ oper` | 2 | 2** | | [beq.asm](test/asm_tests/beq.asm) / [beq.json](test/asm_tests/beq.json) |

#### BMI: Branch on Result Minus (N=1)

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $30 | relative | `BMI oper` | 2 | 2** | | [bmi.asm](test/asm_tests/bmi.asm) / [bmi.json](test/asm_tests/bmi.json) |

#### BNE: Branch on Result not Zero (Z=0)

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $D0 | relative | `BNE oper` | 2 | 2** | | [bne.asm](test/asm_tests/bne.asm) / [bne.json](test/asm_tests/bne.json) |

#### BPL: Branch on Result Plus (N=0)

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $10 | relative | `BPL oper` | 2 | 2** | | [bpl.asm](test/asm_tests/bpl.asm) / [bpl.json](test/asm_tests/bpl.json) |

#### BVC: Branch on Overflow Clear (V=0)

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $50 | relative | `BVC oper` | 2 | 2** | | [bvc.asm](test/asm_tests/bvc.asm) / [bvc.json](test/asm_tests/bvc.json) |

#### BVS: Branch on Overflow Set (V=1)

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $70 | relative | `BVS oper` | 2 | 2** | | [bvs.asm](test/asm_tests/bvs.asm) / [bvs.json](test/asm_tests/bvs.json) |

### Jumps & Subroutines

#### JMP: Jump to New Location

Flags affected: `-`

**Progress:** 1 of 2 done (50%)

> Indirect: NMOS page-wrap bug: `JMP ($xxFF)` fetches the high byte from `$xx00`.

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $4C | absolute | `JMP oper` | 3 | 3 | 8 | [jmp_abs.asm](test/asm_tests/jmp_abs.asm) / [jmp_abs.json](test/asm_tests/jmp_abs.json) |
| [!] | $6C | indirect | `JMP (oper)` | 3 | 5*** | | [jmp_ind.asm](test/asm_tests/jmp_ind.asm) / [jmp_ind.json](test/asm_tests/jmp_ind.json) |

#### JSR: Jump to New Location Saving Return Address

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

> Pushes PC+2 (address of last byte of JSR).

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $20 | absolute | `JSR oper` | 3 | 6 | | [jsr.asm](test/asm_tests/jsr.asm) / [jsr.json](test/asm_tests/jsr.json) |

#### RTS: Return from Subroutine

Flags affected: `-`

**Progress:** 0 of 1 done (0%)

> Pulls PC, then adds 1.

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $60 | implied | `RTS` | 1 | 6 | | [rts.asm](test/asm_tests/rts.asm) / [rts.json](test/asm_tests/rts.json) |

### Interrupts

#### BRK: Force Break

Flags affected: `I=1`

**Progress:** 0 of 1 done (0%)

> Pushes PC+2 and status with B set; jumps via the IRQ vector at $FFFE/$FFFF.

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $00 | implied | `BRK` | 1 | 7 | | [brk.asm](test/asm_tests/brk.asm) / [brk.json](test/asm_tests/brk.json) |

#### RTI: Return from Interrupt

Flags affected: `from stack`

**Progress:** 0 of 1 done (0%)

> Pulls status then PC (no +1).

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $40 | implied | `RTI` | 1 | 6 | | [rti.asm](test/asm_tests/rti.asm) / [rti.json](test/asm_tests/rti.json) |

### Other

#### BIT: Test Bits in Memory with Accumulator

Flags affected: `N=M7 V=M6 Z`

**Progress:** 0 of 2 done (0%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [!] | $24 | zeropage | `BIT oper` | 2 | 3 | | [bit_zp.asm](test/asm_tests/bit_zp.asm) / [bit_zp.json](test/asm_tests/bit_zp.json) |
| [!] | $2C | absolute | `BIT oper` | 3 | 4 | | [bit_abs.asm](test/asm_tests/bit_abs.asm) / [bit_abs.json](test/asm_tests/bit_abs.json) |

#### NOP: No Operation

Flags affected: `-`

**Progress:** 1 of 1 done (100%)

| Done | Opcode | Mode | Syntax | Bytes | 6502 Cycles | DFC64 Cycles | Test Case |
|:----:|:------:|------|--------|:-----:|:-----------:|:------------:|-------|
| [x] | $EA | implied | `NOP` | 1 | 2 | | [nop.asm](test/asm_tests/nop.asm) / [nop.json](test/asm_tests/nop.json) |

## Opcode Matrix

Cross-check of all 151 official opcodes (row = high nibble, column = low nibble). Blank cells are illegal/undocumented opcodes and are out of scope.

| HI\LO | -0 | -1 | -2 | -3 | -4 | -5 | -6 | -7 | -8 | -9 | -A | -B | -C | -D | -E | -F |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **0-** | BRK impl | ORA X,ind |  |  |  | ORA zpg | ASL zpg |  | PHP impl | ORA # | ASL A |  |  | ORA abs | ASL abs |  |
| **1-** | BPL rel | ORA ind,Y |  |  |  | ORA zpg,X | ASL zpg,X |  | CLC impl | ORA abs,Y |  |  |  | ORA abs,X | ASL abs,X |  |
| **2-** | JSR abs | AND X,ind |  |  | BIT zpg | AND zpg | ROL zpg |  | PLP impl | AND # | ROL A |  | BIT abs | AND abs | ROL abs |  |
| **3-** | BMI rel | AND ind,Y |  |  |  | AND zpg,X | ROL zpg,X |  | SEC impl | AND abs,Y |  |  |  | AND abs,X | ROL abs,X |  |
| **4-** | RTI impl | EOR X,ind |  |  |  | EOR zpg | LSR zpg |  | PHA impl | EOR # | LSR A |  | JMP abs | EOR abs | LSR abs |  |
| **5-** | BVC rel | EOR ind,Y |  |  |  | EOR zpg,X | LSR zpg,X |  | CLI impl | EOR abs,Y |  |  |  | EOR abs,X | LSR abs,X |  |
| **6-** | RTS impl | ADC X,ind |  |  |  | ADC zpg | ROR zpg |  | PLA impl | ADC # | ROR A |  | JMP ind | ADC abs | ROR abs |  |
| **7-** | BVS rel | ADC ind,Y |  |  |  | ADC zpg,X | ROR zpg,X |  | SEI impl | ADC abs,Y |  |  |  | ADC abs,X | ROR abs,X |  |
| **8-** |  | STA X,ind |  |  | STY zpg | STA zpg | STX zpg |  | DEY impl |  | TXA impl |  | STY abs | STA abs | STX abs |  |
| **9-** | BCC rel | STA ind,Y |  |  | STY zpg,X | STA zpg,X | STX zpg,Y |  | TYA impl | STA abs,Y | TXS impl |  |  | STA abs,X |  |  |
| **A-** | LDY # | LDA X,ind | LDX # |  | LDY zpg | LDA zpg | LDX zpg |  | TAY impl | LDA # | TAX impl |  | LDY abs | LDA abs | LDX abs |  |
| **B-** | BCS rel | LDA ind,Y |  |  | LDY zpg,X | LDA zpg,X | LDX zpg,Y |  | CLV impl | LDA abs,Y | TSX impl |  | LDY abs,X | LDA abs,X | LDX abs,Y |  |
| **C-** | CPY # | CMP X,ind |  |  | CPY zpg | CMP zpg | DEC zpg |  | INY impl | CMP # | DEX impl |  | CPY abs | CMP abs | DEC abs |  |
| **D-** | BNE rel | CMP ind,Y |  |  |  | CMP zpg,X | DEC zpg,X |  | CLD impl | CMP abs,Y |  |  |  | CMP abs,X | DEC abs,X |  |
| **E-** | CPX # | SBC X,ind |  |  | CPX zpg | SBC zpg | INC zpg |  | INX impl | SBC # | NOP impl |  | CPX abs | SBC abs | INC abs |  |
| **F-** | BEQ rel | SBC ind,Y |  |  |  | SBC zpg,X | INC zpg,X |  | SED impl | SBC abs,Y |  |  |  | SBC abs,X | INC abs,X |  |

## How the Tests Work

Each test is a pair of files in [test/](test/asm_tests/), with the same name (for example `adc_zp_x.asm` and `adc_zp_x.json`):

- **`.asm`**: a 6502 program that runs one instruction (one opcode, in one addressing mode) through several cases and stores the outcome of each case in RAM.
- **`.json`**: every non-zero byte of RAM ($0000–$BFFF) after the program finishes, as `"0xADDR": "0xVAL"` pairs.

The harness ([test_asm.py](test_asm.py)) assembles the `.asm` with `vasm6502_oldstyle -Fbin -dotdir` and loads the binary at `$C000`. It releases reset, runs the program until it reaches its end loop, and then compares memory with the `.json`.

File names are `<mnemonic>_<mode>`, using the mode suffixes `imm`, `zp`, `zp_x`, `zp_y`, `abs`, `abs_x`, `abs_y`, `ind_x`, `ind_y`, `ind` and `acc`. Instructions with only one mode use the plain mnemonic (`tax`, `bcc`, `brk`). Decimal-mode tests add `_dec` (`adc_imm_dec`).

### Header fields

Every `.asm` starts with a comment block. The first four lines have a fixed format because tools read them:

| Line | Example | Read by | Meaning |
|------|---------|---------|---------|
| `; Target:` | `; Target: vasm6502_oldstyle` | people | Assembler the source is written for. |
| `; Test:` | `; Test: ADC (indirect),Y ($71)` | `sim6502.py` | Instruction and mode under test. The `($XX)` opcode tells the tools which opcode to inject faults into. |
| `; Cycles:` | `; Cycles: 244` | harness | 6502 cycles from the first instruction to the first fetch of the end loop, counted by the reference model. The 7-cycle reset sequence is **not** included. |
| `; Done:` | `; Done: $C0A1` | harness | Address of the `done: jmp done` end loop. |

The rest of the header describes the test: what it checks, the result layout, the initial status, and cycle notes where the 6502 timing varies between cases.

`Cycles` and `Done` are produced by the reference model, not written by hand. Regenerate them after any change to a test (see [Regenerating tests](#regenerating-tests)).

### How the harness uses `Cycles` and `Done`

- **Budget:** each test gets `(Cycles + 7 + 2×3) × ASM_CLOCKS_PER_CYCLE × 2` clocks. `ASM_CLOCKS_PER_CYCLE` is an environment variable and defaults to 8 until the real DFC64 figure is measured.
- **End of test:** the test ends when the SRAM mock has recorded **two** reads of the `Done` address (`sram.reads`). The first read can be a dummy read made by the 1-byte instruction just before `done:`, which happens before that instruction's own write. The second read is the loop fetching itself again, so all writes are complete by then.
- **Timeout:** running out of budget is a **failure**. The message lists the last 16 addresses read.
- **Log:** each test logs how many clocks it took to first reach `Done`, and the average clocks per 6502 cycle. This is the starting data for the **DFC64 Cycles** column.
- **Test directory:** `ASM_TEST_DIR` chooses the directory to run (default `tests/asm`).

### Results and this report

After every test, the harness merges the outcome into `asm_results.json` (next to `test_asm.py`): pass/fail, the failure message, the clocks taken to reach `Done`, the expected 6502 cycles and the time. It then runs [update_report.py](test/asm_tests/tools/update_report.py), which:

- **Done cells:** sets `[x]` for a pass and `[!]` for a fail. Rows whose test hasn't been run keep their current mark.
- **Summary:** recounts Done, Failing, Remaining and % Complete for each category and the total.
- **Addressing Modes:** recounts Done and % Complete for each mode.
- **Instructions:** rewrites the **Progress** line under each instruction heading.
- **Decimal mode:** the decimal-mode rows count only towards the ADC/SBC progress lines and the "Decimal mode" line, not the Summary or Addressing Modes.
- **Rounding:** percentages are rounded down, so 100% means every entry is done.
- **Results block:** rewrites the block under the Summary (between the `<!-- results:start/end -->` markers) with the latest totals and a table of failing tests with their reasons.

Results are merged, so running a single test (`TESTCASE=test_adc_imm`) updates only that row. To start from scratch, delete `asm_results.json`. Settings:

- `ASM_RESULTS_FILE`: a different location for the results file.
- `ASM_UPDATE_REPORT=0`: record results without touching the report.

To rebuild the report from an existing results file, run `python3 test/tools/update_report.py`.

### Program layout and conventions

- **Code and vectors:** code starts at `$C000` (ROM). Vectors are at `$FFFA`: NMI → `done`, reset → `reset`, IRQ/BRK → `done` (`brk` uses its own handler). The program ends in `done: jmp done`.
- **Prologue:** `ldx #$FF / txs` sets a known stack pointer, because the reset value is undefined. `lda #$45 / pha / plp` sets C=1, V=1, I=1, D=0, so the test also shows that instructions which shouldn't change C and V leave them alone. Tests that are about flags set the status explicitly in each case.
- **Setup:** seeds operands, pointers and trap values in RAM before the cases run.
- **Cases:** each case starts with `; --- Case n: … ---`. A typical case sets the index register, runs the instruction under test, stores the result, then runs `PHP`.
- **Result layout:** results go to `$0300` upwards, one byte per case. Each case's status is pushed with `PHP`, so status bytes go from `$01FF` downwards. Some tests also record SP (via `TSX`) at `$0310` upwards.
- **`Expect` comments:** `; Expect $5A` (a result at `$03xx`) and `; Expect $75 at $01FF` (any other address) give the value the line writes on a correct CPU. They're generated from the reference model and match the `.json`.
- **Zero results:** a result of `$00` can't be told apart from untouched RAM. Every location that should end up `$00` is first pre-seeded with `$FF`, so a missing write leaves `$FF` behind and is caught.
- **Traps:** these are non-zero values placed where a faulty CPU would read by mistake (no zero-page wrap, lost carry into the high byte, dropped high byte, pointer high byte read from `$0100`). Each trap value is different. Where the result would differ, the `Expect` comment names it, for example `Expect $A5 ($99 = wrap failed)`.
- **Wrong-path markers:** in branch and jump tests, every path the CPU shouldn't take stores `$EE` (or `$E2` for a specific known bug, for example JMP indirect without the NMOS page bug).
- **Dependencies:** tests rely on a few other instructions working: `LDA/LDX/LDY #`, `STA/STX/STY`, `TXS`, `PHA`, `PLP`, `PHP` and `JMP`. Get those passing first.

### What the JSON check covers

- **RAM ($0000–$BFFF):** must match the `.json` exactly. Any byte not listed must be `$00`, so a stray write anywhere is caught.
- **ROM ($C000+):** must still match the loaded binary.
- **Not checked:** registers and flags directly (the tests store them to RAM), cycle timing, dummy reads and writes, and the order of bus accesses.

### Assumed CPU behaviour

The expected results follow the **NMOS 6502**. A CPU that behaves like the CMOS 65C02 will fail these on purpose:

- **JMP indirect:** `JMP ($xxFF)` takes its high byte from `$xx00`.
- **BRK:** doesn't clear D. It pushes PC+2 and the status with B set, and sets I.
- **Decimal mode flags:** ADC sets N and V from the intermediate result and Z from the binary sum. SBC sets N, V and Z from the binary difference. Decimal mode is tested only in `adc_imm_dec` and `sbc_imm_dec`, so binary mode can pass first.
- **PHP/BRK:** the pushed status always has B (bit 4) and bit 5 set. PLP and RTI ignore those bits when pulling.

### Regenerating tests

The tools are in [test/tools/](test/asm_tests/tools/):

- `python3 test/tools/gentests.py` regenerates every test (all 153 `.asm`/`.json` pairs). It builds each `.asm`, runs it on the reference model to fill in the `Expect` comments, pre-seeds, `Cycles`/`Done` and the `.json`, and checks that the test catches the injected CPU faults it applies to.
- `python3 test/tools/sim6502.py --stamp --write-json test/<name>.asm` updates `Cycles`/`Done` and the `.json` of a test edited by hand. Prefer changing `gentests.py`, because the next regeneration overwrites hand edits.
- `python3 test/tools/sim6502.py test/*.asm` reports, for each test, how many injected faults it catches. It exits with code 1 if any are missed.

Regenerating overwrites hand edits to the generated tests. Make lasting changes in `gentests.py`.
