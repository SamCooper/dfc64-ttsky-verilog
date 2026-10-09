; Target: vasm6502_oldstyle
; Tests LDA across IND_X and IND_Y addressing modes, including zero-page pointer
; wrapping and effective address page-boundary crossing.

        .org $C000
reset:
        ; --- 0. Setup Pointers and Target Memory ---
        ; Pointer 1 (for IND, X) at $0010 pointing to $2000
        lda #$00
        sta $10       ; Pointer 1 LSB
        lda #$20
        sta $11       ; Pointer 1 MSB
        
        ; Target 1 data
        lda #$AA
        sta $2000

        ; Pointer 2 (for IND, Y) at $0020 pointing to $30C0
        lda #$C0
        sta $20       ; Pointer 2 LSB
        lda #$30
        sta $21       ; Pointer 2 MSB
        
        ; Target 2 data
        lda #$BB
        sta $3140

        ; --- 1. Test LDA (IND, X) with Zero-Page Wrap ---
        ; Base $F0 + Index $20 = $0110 -> Wraps to $0010
        ; Fetches pointer from $0010 (which is $2000)
        ldx #$20
        lda ($F0, X)
        sta $50       ; Should store $AA

        ; --- 2. Test LDA (IND), Y with Page Cross ---
        ; Pointer at $0020 is $30C0. Index Y is $80.
        ; $30C0 + $80 = $3140 (Page crossed from $30xx to $31xx)
        ldy #$80
        lda ($20), Y
        sta $51       ; Should store $BB

done:   
        jmp done      ; Infinite loop to terminate

        .org $FFFC
        .word reset   ; Reset vector
        .word $0000
