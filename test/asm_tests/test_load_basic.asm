; Target: vasm6502_oldstyle
; Tests basic loads (LDA, LDX, LDY) with IMM, ZP, ABS addressing modes.

        .org $C000
reset:
        ; 1. Setup target memory to read from
        lda #$42
        sta $40       ; Write $42 to Zero Page $0040
        lda #$80
        sta $2000     ; Write $80 to Absolute $2000
        
        ; 2. Test IMM mode (Load 0, which also tests Z flag internally)
        sta $50       ; Store result to $0050
        lda #$00
        sta $50       ; Store result to $0050
        
        ; 3. Test ZP mode
        ldx $40       ; Load X with $42 from Zero Page
        stx $51       ; Store X result to $0051
        
        ; 4. Test ABS mode
        ldy $2000     ; Load Y with $80 from Absolute
        sty $52       ; Store Y result to $0052

done:   
        jmp done      ; Infinite loop to terminate

        .org $FFFC
        .word reset   ; Reset vector
        .word $0000
