| Implementation Phase | Opcode | Addressing Modes Required | ISA Test Created? |
| :--- | :--- | :--- | :--- |
| **1. System Basics** | [NOP](https://6502.org/tutorials/6502opcodes.html#NOP) | Implied | [ ] No |
| **2. Register Transfers** | [TAX](https://6502.org/tutorials/6502opcodes.html#TAX) | Implied | [ ] No |
| | [TXA](https://6502.org/tutorials/6502opcodes.html#TXA) | Implied | [ ] No |
| | [TAY](https://6502.org/tutorials/6502opcodes.html#TAY) | Implied | [ ] No |
| | [TYA](https://6502.org/tutorials/6502opcodes.html#TYA) | Implied | [ ] No |
| **3. Load & Store** | [LDA](https://6502.org/tutorials/6502opcodes.html#LDA) | Immediate, Zero Page, Zero Page,X, Absolute, Absolute,X, Absolute,Y, (Indirect,X), (Indirect),Y | [ ] No |
| | [LDX](https://6502.org/tutorials/6502opcodes.html#LDX) | Immediate, Zero Page, Zero Page,Y, Absolute, Absolute,Y | [ ] No |
| | [LDY](https://6502.org/tutorials/6502opcodes.html#LDY) | Immediate, Zero Page, Zero Page,X, Absolute, Absolute,X | [ ] No |
| | [STA](https://6502.org/tutorials/6502opcodes.html#STA) | Zero Page, Zero Page,X, Absolute, Absolute,X, Absolute,Y, (Indirect,X), (Indirect),Y | [ ] No |
| | [STX](https://6502.org/tutorials/6502opcodes.html#STX) | Zero Page, Zero Page,Y, Absolute | [ ] No |
| | [STY](https://6502.org/tutorials/6502opcodes.html#STY) | Zero Page, Zero Page,X, Absolute | [ ] No |
| **4. Stack Operations** | [TXS](https://6502.org/tutorials/6502opcodes.html#TXS) | Implied | [ ] No |
| | [TSX](https://6502.org/tutorials/6502opcodes.html#TSX) | Implied | [ ] No |
| | [PHA](https://6502.org/tutorials/6502opcodes.html#PHA) | Implied | [ ] No |
| | [PLA](https://6502.org/tutorials/6502opcodes.html#PLA) | Implied | [ ] No |
| | [PHP](https://6502.org/tutorials/6502opcodes.html#PHP) | Implied | [ ] No |
| | [PLP](https://6502.org/tutorials/6502opcodes.html#PLP) | Implied | [ ] No |
| **5. Logical (ALU)** | [AND](https://6502.org/tutorials/6502opcodes.html#AND) | Immediate, Zero Page, Zero Page,X, Absolute, Absolute,X, Absolute,Y, (Indirect,X), (Indirect),Y | [ ] No |
| | [ORA](https://6502.org/tutorials/6502opcodes.html#ORA) | Immediate, Zero Page, Zero Page,X, Absolute, Absolute,X, Absolute,Y, (Indirect,X), (Indirect),Y | [ ] No |
| | [EOR](https://6502.org/tutorials/6502opcodes.html#EOR) | Immediate, Zero Page, Zero Page,X, Absolute, Absolute,X, Absolute,Y, (Indirect,X), (Indirect),Y | [ ] No |
| | [BIT](https://6502.org/tutorials/6502opcodes.html#BIT) | Zero Page, Absolute | [ ] No |
| **6. Arithmetic & Compare** | [ADC](https://6502.org/tutorials/6502opcodes.html#ADC) | Immediate, Zero Page, Zero Page,X, Absolute, Absolute,X, Absolute,Y, (Indirect,X), (Indirect),Y | [ ] No |
| | [SBC](https://6502.org/tutorials/6502opcodes.html#SBC) | Immediate, Zero Page, Zero Page,X, Absolute, Absolute,X, Absolute,Y, (Indirect,X), (Indirect),Y | [ ] No |
| | [CMP](https://6502.org/tutorials/6502opcodes.html#CMP) | Immediate, Zero Page, Zero Page,X, Absolute, Absolute,X, Absolute,Y, (Indirect,X), (Indirect),Y | [ ] No |
| | [CPX](https://6502.org/tutorials/6502opcodes.html#CPX) | Immediate, Zero Page, Absolute | [ ] No |
| | [CPY](https://6502.org/tutorials/6502opcodes.html#CPY) | Immediate, Zero Page, Absolute | [ ] No |
| **7. Increment & Decrement** | [INX](https://6502.org/tutorials/6502opcodes.html#INX) | Implied | [ ] No |
| | [INY](https://6502.org/tutorials/6502opcodes.html#INY) | Implied | [ ] No |
| | [INC](https://6502.org/tutorials/6502opcodes.html#INC) | Zero Page, Zero Page,X, Absolute, Absolute,X | [ ] No |
| | [DEX](https://6502.org/tutorials/6502opcodes.html#DEX) | Implied | [ ] No |
| | [DEY](https://6502.org/tutorials/6502opcodes.html#DEY) | Implied | [ ] No |
| | [DEC](https://6502.org/tutorials/6502opcodes.html#DEC) | Zero Page, Zero Page,X, Absolute, Absolute,X | [ ] No |
| **8. Shifts & Rotates** | [ASL](https://6502.org/tutorials/6502opcodes.html#ASL) | Accumulator, Zero Page, Zero Page,X, Absolute, Absolute,X | [ ] No |
| | [LSR](https://6502.org/tutorials/6502opcodes.html#LSR) | Accumulator, Zero Page, Zero Page,X, Absolute, Absolute,X | [ ] No |
| | [ROL](https://6502.org/tutorials/6502opcodes.html#ROL) | Accumulator, Zero Page, Zero Page,X, Absolute, Absolute,X | [ ] No |
| | [ROR](https://6502.org/tutorials/6502opcodes.html#ROR) | Accumulator, Zero Page, Zero Page,X, Absolute, Absolute,X | [ ] No |
| **9. Status Flags** | [CLC](https://6502.org/tutorials/6502opcodes.html#CLC) | Implied | [ ] No |
| | [SEC](https://6502.org/tutorials/6502opcodes.html#SEC) | Implied | [ ] No |
| | [CLI](https://6502.org/tutorials/6502opcodes.html#CLI) | Implied | [ ] No |
| | [SEI](https://6502.org/tutorials/6502opcodes.html#SEI) | Implied | [ ] No |
| | [CLV](https://6502.org/tutorials/6502opcodes.html#CLV) | Implied | [ ] No |
| | [CLD](https://6502.org/tutorials/6502opcodes.html#CLD) | Implied | [ ] No |
| | [SED](https://6502.org/tutorials/6502opcodes.html#SED) | Implied | [ ] No |
| **10. Jumps & Subroutines** | [JMP](https://6502.org/tutorials/6502opcodes.html#JMP) | Absolute, Indirect | [ ] No |
| | [JSR](https://6502.org/tutorials/6502opcodes.html#JSR) | Absolute | [ ] No |
| | [RTS](https://6502.org/tutorials/6502opcodes.html#RTS) | Implied | [ ] No |
| | [BRK](https://6502.org/tutorials/6502opcodes.html#BRK) | Implied | [ ] No |
| | [RTI](https://6502.org/tutorials/6502opcodes.html#RTI) | Implied | [ ] No |
| **11. Branches** | [BCC](https://6502.org/tutorials/6502opcodes.html#BCC) | Relative | [ ] No |
| | [BCS](https://6502.org/tutorials/6502opcodes.html#BCS) | Relative | [ ] No |
| | [BEQ](https://6502.org/tutorials/6502opcodes.html#BEQ) | Relative | [ ] No |
| | [BNE](https://6502.org/tutorials/6502opcodes.html#BNE) | Relative | [ ] No |
| | [BMI](https://6502.org/tutorials/6502opcodes.html#BMI) | Relative | [ ] No |
| | [BPL](https://6502.org/tutorials/6502opcodes.html#BPL) | Relative | [ ] No |
| | [BVC](https://6502.org/tutorials/6502opcodes.html#BVC) | Relative | [ ] No |
| | [BVS](https://6502.org/tutorials/6502opcodes.html#BVS) | Relative | [ ] No |