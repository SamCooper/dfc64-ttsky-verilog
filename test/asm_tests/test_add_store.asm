; test_add_store.asm
; Target: vasm6502_oldstyle

        .org $C000          ; ROM begins at 0xC000
reset:
        lda #$AA            ; Load 0xAA into Accumulator
        ldx #$02            ; Load 0x02 into X register
        sta $40, X          ; Store A into Zero Page at (0x40 + 0x02) = 0x42
        
        clc                 ; Clear carry before addition
        adc #$AB            ; Add 0xAB to A (0xAA + 0xAB = 0x155 -> A=0x55, Carry=1)
        inx                 ; Increment X to 0x03
        sta $40, X          ; Store A into Zero Page at 0x43

done:   
        jmp done            ; Infinite loop to terminate the test execution

        .org $FFFC          ; 6502 Reset Vector location
        .word reset         ; Tell CPU to boot from 'reset' label
        .word $0000         ; IRQ/BRK vector (unused)