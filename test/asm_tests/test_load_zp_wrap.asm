; Target: vasm6502_oldstyle
; Tests Zero Page indexed addressing (ZP,X and ZP,Y) strict 8-bit wrap-around.
; If the base address plus index exceeds $FF, it must wrap to $00xx, not $01xx.

        .org $C000
reset:
        ; --- 0. Setup Memory ---
        ; Seed target Zero Page addresses (The correct read locations)
        lda #$AA
        sta $10
        lda #$BB
        sta $20
        lda #$CC
        sta $30
        
        ; Seed Page 1 addresses (Trap values to catch failure to wrap)
        ; If the CPU incorrectly crosses the page boundary, it will load these.
        lda #$99
        sta $0110
        lda #$88
        sta $0120
        lda #$77
        sta $0130

        ; --- 1. Test LDA ZP, X ---
        ; Base $F0 + Index $20 = $110 -> Must wrap to $0010
        ldx #$20
        lda $F0, X
        sta $50       ; Should store $AA (if it stores $99, wrap failed)

        ; --- 2. Test LDX ZP, Y ---
        ; Base $F0 + Index $30 = $120 -> Must wrap to $0020
        ldy #$30
        ldx $F0, Y
        stx $51       ; Should store $BB (if it stores $88, wrap failed)

        ; --- 3. Test LDY ZP, X ---
        ; Base $F0 + Index $40 = $130 -> Must wrap to $0030
        ldx #$40
        ldy $F0, X
        sty $52       ; Should store $CC (if it stores $77, wrap failed)

done:   
        jmp done      ; Infinite loop to terminate

        .org $FFFC
        .word reset   ; Reset vector
        .word $0000
