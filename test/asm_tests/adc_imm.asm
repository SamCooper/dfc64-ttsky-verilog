; Target: vasm6502_oldstyle
; Test: ADC #immediate ($69)
; Cycles: 191
; Done: $C076
; Checks the sum, carry in/out, and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Binary mode only (D=0); decimal mode is tested separately in adc_imm_dec.
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
        lda #$FF        ; Pre-seed a zero-result location
        sta $0303
        lda #$FF        ; Pre-seed a zero-result location
        sta $0305

        ; --- Case 1: binary, C=0: $01 + $01 = $02 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$01
        adc #$01
        sta $0300       ; Expect $02
        php             ; Expect $34 at $01FF

        ; --- Case 2: binary, C=0: $7F + $01 = $80 (overflow) ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$7F
        adc #$01
        sta $0301       ; Expect $80
        php             ; Expect $F4 at $01FE

        ; --- Case 3: binary, C=0: $FF + $01 = $00 (carry out) ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$FF
        adc #$01
        sta $0302       ; Expect $00
        php             ; Expect $37 at $01FD

        ; --- Case 4: binary, C=0: $80 + $80 = $00 (carry and overflow) ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$80
        adc #$80
        sta $0303       ; Expect $00
        php             ; Expect $77 at $01FC

        ; --- Case 5: binary, C=1: $01 + $01 + 1 = $03 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$01
        adc #$01
        sta $0304       ; Expect $03
        php             ; Expect $34 at $01FB

        ; --- Case 6: binary, C=1: $FF + $00 + 1 = $00 (carry out) ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$FF
        adc #$00
        sta $0305       ; Expect $00
        php             ; Expect $37 at $01FA

        ; --- Case 7: binary, C=1: $3F + $40 + 1 = $80 (overflow) ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$3F
        adc #$40
        sta $0306       ; Expect $80
        php             ; Expect $F4 at $01F9

        ; --- Case 8: binary, V=1 before: $10 + $20 = $30 (V cleared) ---
        lda #$44        ; V=1 I=1 N=0 D=0 Z=0 C=0
        pha
        plp
        lda #$10
        adc #$20
        sta $0307       ; Expect $30
        php             ; Expect $34 at $01F8

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
