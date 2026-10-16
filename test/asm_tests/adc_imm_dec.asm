; Target: vasm6502_oldstyle
; Test: ADC #immediate, decimal mode ($69)
; Cycles: 151
; Done: $C05E
; Checks the sum, carry in/out, and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Decimal mode (D=1) only; run this after the binary-mode tests pass.
; Flags follow NMOS behaviour:
; ADC: N and V from the intermediate result, Z from the binary sum;
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
        lda #$FF        ; Pre-seed a zero-result location
        sta $0304
        lda #$FF        ; Pre-seed a zero-result location
        sta $0305

        ; --- Case 1: decimal, C=0: 09 + 01 = 10 ---
        lda #$0C        ; D=1 I=1 N=0 V=0 Z=0 C=0
        pha
        plp
        lda #$09
        adc #$01
        sta $0300       ; Expect $10
        php             ; Expect $3C at $01FF

        ; --- Case 2: decimal, C=0: 12 + 34 = 46 ---
        lda #$0C        ; D=1 I=1 N=0 V=0 Z=0 C=0
        pha
        plp
        lda #$12
        adc #$34
        sta $0301       ; Expect $46
        php             ; Expect $3C at $01FE

        ; --- Case 3: decimal, C=1: 58 + 46 + 1 = 05, carry out ---
        lda #$0D        ; D=1 I=1 C=1 N=0 V=0 Z=0
        pha
        plp
        lda #$58
        adc #$46
        sta $0302       ; Expect $05
        php             ; Expect $FD at $01FD

        ; --- Case 4: decimal, C=0: 99 + 01 = 00, carry out (NMOS: Z from binary result) ---
        lda #$0C        ; D=1 I=1 N=0 V=0 Z=0 C=0
        pha
        plp
        lda #$99
        adc #$01
        sta $0303       ; Expect $00
        php             ; Expect $BD at $01FC

        ; --- Case 5: decimal, C=0: 50 + 50 = 00, carry out (NMOS: N and V from the intermediate result) ---
        lda #$0C        ; D=1 I=1 N=0 V=0 Z=0 C=0
        pha
        plp
        lda #$50
        adc #$50
        sta $0304       ; Expect $00
        php             ; Expect $FD at $01FB

        ; --- Case 6: decimal, C=1: 99 + 00 + 1 = 00, carry out ---
        lda #$0D        ; D=1 I=1 C=1 N=0 V=0 Z=0
        pha
        plp
        lda #$99
        adc #$00
        sta $0305       ; Expect $00
        php             ; Expect $BD at $01FA

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
