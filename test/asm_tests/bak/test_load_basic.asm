; Target: vasm6502_oldstyle
; Tests basic loads (LDA, LDX, LDY) across IMM, ZP, and ABS addressing modes.

        .org $C000
reset:
        ; --- 0. Setup target memory to read from ---
        ; (Using basic instructions to seed the RAM)
        lda #$AA
        sta $10       ; Seed ZP $10 with $AA
        lda #$BB
        sta $11       ; Seed ZP $11 with $BB
        lda #$CC
        sta $12       ; Seed ZP $12 with $CC
        
        lda #$DD
        sta $2010     ; Seed ABS $2010 with $DD
        lda #$EE
        sta $2011     ; Seed ABS $2011 with $EE
        lda #$FF
        sta $2012     ; Seed ABS $2012 with $FF
        
        ; --- 1. Test IMMEDIATE Mode ---
        lda #$11
        sta $50       ; A should be $11
        ldx #$22
        stx $51       ; X should be $22
        ldy #$33
        sty $52       ; Y should be $33
        
        ; --- 2. Test ZERO PAGE Mode ---
        lda $10
        sta $60       ; A should be $AA
        ldx $11
        stx $61       ; X should be $BB
        ldy $12
        sty $62       ; Y should be $CC
        
        ; --- 3. Test ABSOLUTE Mode ---
        lda $2010
        sta $70       ; A should be $DD
        ldx $2011
        stx $71       ; X should be $EE
        ldy $2012
        sty $72       ; Y should be $FF

done:   
        jmp done      ; Infinite loop to terminate

        .org $FFFC
        .word reset   ; Reset vector
        .word $0000
