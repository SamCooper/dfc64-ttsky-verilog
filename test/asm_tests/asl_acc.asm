; Target: vasm6502_oldstyle
; Test: ASL accumulator ($0A)
; Cycles: 63
; Done: $C028
; Shifts left; bit 7 goes to C, bit 0 becomes 0.
; Checks the result and the N/Z/C flags, and that V is unchanged.
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
        sta $0303

        ; --- Case 1: $2D -> $5A ---
        lda #$2D
        asl
        sta $0300       ; Expect $5A
        php             ; Expect $74 at $01FF

        ; --- Case 2: $81 -> $02, C=1 ---
        lda #$81
        asl
        sta $0301       ; Expect $02
        php             ; Expect $75 at $01FE

        ; --- Case 3: $40 -> $80 (N=1) ---
        lda #$40
        asl
        sta $0302       ; Expect $80
        php             ; Expect $F4 at $01FD

        ; --- Case 4: $80 -> $00, C=1 (Z=1) ---
        lda #$80
        asl
        sta $0303       ; Expect $00
        php             ; Expect $77 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
