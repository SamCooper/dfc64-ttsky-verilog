; Target: vasm6502_oldstyle
; Test: INY implied ($C8)
; Cycles: 63
; Done: $C028
; Increments Y; checks N/Z, wrap $FF -> $00, and that C and V are unchanged.
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
        sta $0302

        ; --- Case 1: $59 -> $5A ---
        ldy #$59
        iny
        sty $0300       ; Expect $5A
        php             ; Expect $75 at $01FF

        ; --- Case 2: $7F -> $80 ---
        ldy #$7F
        iny
        sty $0301       ; Expect $80
        php             ; Expect $F5 at $01FE

        ; --- Case 3: $FF -> $00 ---
        ldy #$FF
        iny
        sty $0302       ; Expect $00
        php             ; Expect $77 at $01FD

        ; --- Case 4: $7E -> $7F ---
        ldy #$7E
        iny
        sty $0303       ; Expect $7F
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
