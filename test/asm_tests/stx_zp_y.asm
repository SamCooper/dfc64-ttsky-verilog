; Target: vasm6502_oldstyle
; Test: STX zeropage,Y ($96)
; Cycles: 62
; Done: $C027
; Checks the value lands at the right address and that the flags are unchanged.
; A store to the wrong address shows up as a stray non-zero byte.
; Base + Y must wrap within the zero page ($00xx), never cross into $01xx.
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
        lda #$FF        ; Pre-seed a zero-result location
        sta $80

        ; --- Case 1: $10 + $20 = $30, no wrap ---
        ldy #$20
        ldx #$5A
        stx $10,y       ; Expect $5A at $0030
        php             ; Expect $75 at $01FF (Flags must be unchanged by the store)

        ; --- Case 2: $F0 + $20 = $110 -> must wrap to $10 ---
        ldy #$20
        ldx #$A5
        stx $F0,y       ; Expect $A5 at $0010
        php             ; Expect $F5 at $01FE (Flags must be unchanged by the store)

        ; --- Case 3: $81 + $FF = $180 -> must wrap to $80 ---
        ldy #$FF
        ldx #$00
        stx $81,y       ; Expect $00 at $0080
        php             ; Expect $77 at $01FD (Flags must be unchanged by the store)

        ; --- Case 4: Y = 0 ---
        ldy #$00
        ldx #$7F
        stx $40,y       ; Expect $7F at $0040
        php             ; Expect $75 at $01FC (Flags must be unchanged by the store)

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
