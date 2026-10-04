; test_lda_sta.asm
; Target: vasm6502_oldstyle
TARGET1 = $2000              ; 
TARGET2 = $2FFF              ; 

        .org $C000          ; ROM begins at 0xC000
reset:
        lda #$7E            ; Load into Accumulator
        sta TARGET1         ; Store A
        lda #$DE            ; Load into Accumulator
        sta TARGET2         ; Store A

done:   
        jmp done            ; Infinite loop to terminate the test execution

        .org $FFFC          ; 6502 Reset Vector location
        .word reset         ; Tell CPU to boot from 'reset' label
        .word $0000         ; IRQ/BRK vector (unused)