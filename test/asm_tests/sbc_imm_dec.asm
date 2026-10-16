; Target: vasm6502_oldstyle
; Test: SBC #immediate, decimal mode ($E9)
; Cycles: 133
; Done: $C04F
; Checks the difference, borrow in/out (C=0 means borrow), and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Decimal mode (D=1) only; run this after the binary-mode tests pass.
; Flags follow NMOS behaviour:
; SBC: N, V and Z from the binary difference.
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

        ; --- Case 1: decimal, C=1: 46 - 12 = 34 ---
        lda #$0D        ; D=1 I=1 C=1 N=0 V=0 Z=0
        pha
        plp
        lda #$46
        sbc #$12
        sta $0300       ; Expect $34
        php             ; Expect $3D at $01FF

        ; --- Case 2: decimal, C=1: 10 - 01 = 09 ---
        lda #$0D        ; D=1 I=1 C=1 N=0 V=0 Z=0
        pha
        plp
        lda #$10
        sbc #$01
        sta $0301       ; Expect $09
        php             ; Expect $3D at $01FE

        ; --- Case 3: decimal, C=1: 00 - 01 = 99 (borrow) ---
        lda #$0D        ; D=1 I=1 C=1 N=0 V=0 Z=0
        pha
        plp
        lda #$00
        sbc #$01
        sta $0302       ; Expect $99
        php             ; Expect $BC at $01FD

        ; --- Case 4: decimal, C=0: 32 - 02 - 1 = 29 ---
        lda #$0C        ; D=1 I=1 N=0 V=0 Z=0 C=0
        pha
        plp
        lda #$32
        sbc #$02
        sta $0303       ; Expect $29
        php             ; Expect $3D at $01FC

        ; --- Case 5: decimal, C=1: 21 - 34 = 87 (borrow) ---
        lda #$0D        ; D=1 I=1 C=1 N=0 V=0 Z=0
        pha
        plp
        lda #$21
        sbc #$34
        sta $0304       ; Expect $87
        php             ; Expect $BC at $01FB

        ; --- Case 6: decimal, C=0: 00 - 00 - 1 = 99 (borrow) ---
        lda #$0C        ; D=1 I=1 N=0 V=0 Z=0 C=0
        pha
        plp
        lda #$00
        sbc #$00
        sta $0305       ; Expect $99
        php             ; Expect $BC at $01FA

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
