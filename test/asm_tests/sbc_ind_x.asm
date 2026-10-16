; Target: vasm6502_oldstyle
; Test: SBC (indirect,X) ($E1)
; Cycles: 205
; Done: $C087
; Checks the difference, borrow in/out (C=0 means borrow), and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Binary mode only (D=0); decimal mode is tested separately in sbc_imm_dec.
; The pointer address (base + X) must wrap within the zero page, and a
; pointer at $FF must take its high byte from $00, not $0100.
; Trap values catch a CPU that fails to wrap.
;
; Result layout:
;   $0300+  value produced by each case
;   $01FF-  processor status after each case (one PHP per case, stack grows down)
; Initial status (via PLP): V=1 I=1 C=1 N=0 D=0 Z=0
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs
        lda #$45        ; V=1 I=1 C=1 N=0 D=0 Z=0
        pha
        plp

        ; --- Setup ---
        ; Pointers
        lda #$34
        sta $24
        lda #$12
        sta $25
        lda #$45
        sta $10
        lda #$23
        sta $11
        lda #$56
        sta $0110
        lda #$34
        sta $0111
        lda #$40
        sta $FF
        lda #$30
        sta $00
        lda #$50
        sta $0100
        lda #$FF
        sta $80
        lda #$7F
        sta $81
        ; Operand values (correct locations)
        lda #$80
        sta $2345
        lda #$33
        sta $3040
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; wrap failed
        sta $3456
        lda #$66        ; high byte read from $0100
        sta $5040
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: pointer at $20 + $04 = $24 -> $1234 ---
        lda #$45        ; V=1 I=1 C=1 N=0 D=0 Z=0
        pha
        plp
        ldx #$04
        lda #$5A
        sbc ($20,x)
        sta $0300       ; Expect $5A
        php             ; Expect $35 at $01FF

        ; --- Case 2: pointer at $F0 + $20 = $110 -> must wrap to $10 -> $2345 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ldx #$20
        lda #$25
        sbc ($F0,x)
        sta $0301       ; Expect $A5 ($8C = wrap failed)
        php             ; Expect $F4 at $01FE

        ; --- Case 3: pointer at $00 + $FF = $FF, high byte from $00 -> $3040 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ldx #$FF
        lda #$33
        sbc ($00,x)
        sta $0302       ; Expect $00 ($CD = wrap failed)
        php             ; Expect $37 at $01FD

        ; --- Case 4: X = 0, pointer at $80 -> $7FFF ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$00
        lda #$80
        sbc ($80,x)
        sta $0303       ; Expect $7F
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
