; Target: vasm6502_oldstyle
; Tests absolute indexed loads (ABS, X and ABS, Y) for A, X, and Y registers.
; Includes standard offsets and page-crossing offsets.

        .org $C000
reset:
        ; --- 0. Setup Target Memory ---
        ; Seed standard offsets
        lda #$11
        sta $2005
        lda #$33
        sta $3005
        lda #$55
        sta $4005
        lda #$77
        sta $5005
        
        ; Seed page-crossing offsets
        lda #$22
        sta $2140
        lda #$44
        sta $3140
        lda #$66
        sta $4140
        lda #$88
        sta $5140

        ; --- 1. Test LDA ABS, X ---
        ldx #$05
        lda $2000, X
        sta $10       ; Should load $11 (No page cross)
        
        ldx #$80
        lda $20C0, X
        sta $11       ; Should load $22 (Crosses page boundary to $2140)

        ; --- 2. Test LDA ABS, Y ---
        ldy #$05
        lda $3000, Y
        sta $12       ; Should load $33 (No page cross)
        
        ldy #$80
        lda $30C0, Y
        sta $13       ; Should load $44 (Crosses page boundary to $3140)

        ; --- 3. Test LDX ABS, Y ---
        ldy #$05
        ldx $4000, Y
        stx $14       ; Should load $55 (No page cross)
        
        ldy #$80
        ldx $40C0, Y
        stx $15       ; Should load $66 (Crosses page boundary to $4140)

        ; --- 4. Test LDY ABS, X ---
        ldx #$05
        ldy $5000, X
        sty $16       ; Should load $77 (No page cross)
        
        ldx #$80
        ldy $50C0, X
        sty $17       ; Should load $88 (Crosses page boundary to $5140)

done:   
        jmp done      ; Infinite loop to terminate

        .org $FFFC
        .word reset   ; Reset vector
        .word $0000
