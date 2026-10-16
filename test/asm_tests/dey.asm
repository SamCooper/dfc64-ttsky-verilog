; Target: vasm6502_oldstyle
; Test: DEY implied ($88)
; Cycles: 63
; Done: $C028
; Decrements Y; checks N/Z, wrap $00 -> $FF, and that C and V are unchanged.
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

        ; --- Case 1: $5B -> $5A ---
        ldy #$5B
        dey
        sty $0300       ; Expect $5A
        php             ; Expect $75 at $01FF

        ; --- Case 2: $00 -> $FF ---
        ldy #$00
        dey
        sty $0301       ; Expect $FF
        php             ; Expect $F5 at $01FE

        ; --- Case 3: $01 -> $00 ---
        ldy #$01
        dey
        sty $0302       ; Expect $00
        php             ; Expect $77 at $01FD

        ; --- Case 4: $80 -> $7F ---
        ldy #$80
        dey
        sty $0303       ; Expect $7F
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
