; Target: vasm6502_oldstyle
; Test: CMP #immediate ($C9)
; Cycles: 102
; Done: $C049
; Checks N/Z/C after the compare, and that the register and V are unchanged
; (the register is stored after each compare).
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
        sta $0304
        lda #$FF        ; Pre-seed a zero-result location
        sta $0306

        ; --- Case 1: equal (Z=1, C=1) ---
        lda #$5A
        cmp #$5A
        sta $0300       ; Expect $5A
        php             ; Expect $77 at $01FF

        ; --- Case 2: register < operand (C=0) ---
        lda #$5A
        cmp #$A5
        sta $0301       ; Expect $5A
        php             ; Expect $F4 at $01FE

        ; --- Case 3: register > operand (C=1) ---
        lda #$80
        cmp #$01
        sta $0302       ; Expect $80
        php             ; Expect $75 at $01FD

        ; --- Case 4: register < operand, result $FF (N=1) ---
        lda #$01
        cmp #$02
        sta $0303       ; Expect $01
        php             ; Expect $F4 at $01FC

        ; --- Case 5: $00 vs $80: unsigned, C=0, N=1 ---
        lda #$00
        cmp #$80
        sta $0304       ; Expect $00
        php             ; Expect $F4 at $01FB

        ; --- Case 6: $FF vs $00: C=1, N=1 ---
        lda #$FF
        cmp #$00
        sta $0305       ; Expect $FF
        php             ; Expect $F5 at $01FA

        ; --- Case 7: zero vs zero (Z=1, C=1) ---
        lda #$00
        cmp #$00
        sta $0306       ; Expect $00
        php             ; Expect $77 at $01F9

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
