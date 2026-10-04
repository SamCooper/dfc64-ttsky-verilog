### Test Suite Index
*   [1. ALU Operations (Arithmetic & Logic)](#1-alu-operations-arithmetic--logic)
*   [2. Memory & Register Transfers](#2-memory--register-transfers)
*   [3. Shifts, Rotates & Bit Operations](#3-shifts-rotates--bit-operations)
*   [4. Stack, Subroutines & Interrupts](#4-stack-subroutines--interrupts)
*   [5. Control Flow & Increments/Decrements](#5-control-flow--incrementsdecrements)

### 1. ALU Operations (Arithmetic & Logic)
| Opcode | Mode | Test name | Description |
| :--- | :--- | :--- | :--- |
| ADC | IMM, ZP, ABS | `test_adc_basic` | Basic addition checking Zero, Negative, and Carry out flags. |
| ADC | ZP_X, ABS_X, ABS_Y | `test_adc_indexed_page` | Indexed addition testing page-boundary crossing penalty. |
| ADC | IND_X, IND_Y | `test_adc_indirect` | Pre/post-indexed indirect addition with zero-page wrap-around. |
| SBC | IMM, ZP, ABS | `test_sbc_borrow` | Subtraction testing inverted carry (borrow) logic and overflow. |
| SBC | ZP_X, ABS_X, ABS_Y | `test_sbc_indexed_page` | Indexed subtraction crossing page boundaries. |
| AND, ORA, EOR | IMM, ZP, ABS | `test_logic_basic` | Basic bitwise operations setting Z and N flags. |
| AND, ORA, EOR | IND_X, IND_Y | `test_logic_ind_page` | Indirect bitwise ops, verifying correct page boundary cycles. |
| CMP, CPX, CPY | IMM, ZP, ABS | `test_cmp_flags` | Compares checking exact flag outputs (Equal, Greater, Less). |
| CMP | ZP_X, ABS_X, ABS_Y | `test_cmp_indexed` | Indexed compares, including page boundary boundary tests. |

### 2. Memory & Register Transfers
| Opcode | Mode | Test name | Description |
| :--- | :--- | :--- | :--- |
| LDA, LDX, LDY | IMM, ZP, ABS | `test_load_basic` | Basic loads verifying N and Z flags are correctly set on value. |
| LDA, LDX, LDY | ZP_X, ZP_Y | `test_load_zp_wrap` | Zero page indexed loads testing strict 8-bit wrap-around (no carry to page 1). |
| LDA | IND_X, IND_Y | `test_lda_ind_page` | Indirect loads testing page crossing reads. |
| STA, STX, STY | ZP, ABS | `test_store_basic` | Basic memory writes. |
| STA | ABS_X, ABS_Y, IND_Y | `test_sta_indexed` | Verifies stores do NOT shortcut cycles on page crosses. |
| STX, STY | ZP_Y, ZP_X | `test_store_zp_cross` | STX with Y-index and STY with X-index checking ZP wrap-around. |
| TAX, TAY, TXA, TYA | IMP | `test_transfer_regs` | Register transfers setting N and Z flags. |
| TSX, TXS | IMP | `test_transfer_stack` | Verifies TXS does NOT affect flags, while TSX affects N and Z. |

### 3. Shifts, Rotates & Bit Operations
| Opcode | Mode | Test name | Description |
| :--- | :--- | :--- | :--- |
| ASL, LSR | ACC | `test_shift_acc` | Accumulator shifts testing Carry out and Zero flag. |
| ASL, LSR | ZP, ZP_X, ABS | `test_shift_mem` | Memory shifts verifying Read-Modify-Write (RMW) cycle accuracy. |
| ROL, ROR | ACC | `test_rotate_acc` | Accumulator rotates verifying Carry bit cycles through the register. |
| ROL, ROR | ZP, ABS_X | `test_rotate_mem` | RMW rotates, testing correct output on indexed page crosses. |
| BIT | ZP, ABS | `test_bit_flags` | BIT instruction setting N (bit 7), V (bit 6), and Z (A AND M) flags. |

### 4. Stack, Subroutines & Interrupts
| Opcode | Mode | Test name | Description |
| :--- | :--- | :--- | :--- |
| PHA, PLA | IMP | `test_stack_acc` | Push/Pull Accumulator, verifying PLA correctly sets Z and N flags. |
| PHP, PLP | IMP | `test_stack_flags` | Push/Pull flags, testing hardware B-flag (bit 4) behavior on push. |
| JSR, RTS | ABS, IMP | `test_subroutine` | Call/Return verifying PC-1 is pushed, and PC+1 is resumed upon RTS. |
| BRK, RTI | IMP | `test_brk_rti` | Software IRQ testing PC+2 push, flag push (B set), and vector fetch. |

### 5. Control Flow & Increments/Decrements
| Opcode | Mode | Test name | Description |
| :--- | :--- | :--- | :--- |
| BCC, BCS, BEQ, BNE | REL | `test_branch_fwd_bwd` | Forward/backward branches testing taken and untaken logic. |
| BMI, BPL, BVC, BVS | REL | `test_branch_page_cross` | Branches testing the extra cycle penalty when crossing a page boundary. |
| JMP | ABS | `test_jmp_abs` | Standard absolute execution jump. |
| JMP | IND | `test_jmp_ind_bug` | Indirect jump testing the historic 6502 page boundary bug (e.g., $xxFF). |
| CLC, SEC, CLD, SED | IMP | `test_flag_clears_sets` | Manual flag manipulation and verification. |
| CLI, SEI, CLV | IMP | `test_flag_interrupts` | Interrupt and overflow flag manipulation. |
| INC, DEC | ZP, ABS, ABS_X | `test_mem_inc_dec` | Memory RMW testing strict 0xFF to 0x00 and 0x00 to 0xFF wrap-around. |
| INX, INY, DEX, DEY | IMP | `test_reg_inc_dec` | Register increments/decrements testing N and Z flags on wrap. |
| NOP | IMP | `test_nop` | Verifies execution advances PC with no state changes. |