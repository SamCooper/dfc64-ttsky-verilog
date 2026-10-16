; Target: vasm6502_oldstyle
; Test: ADC zeropage ($65)
; Cycles: 118
; Done: $C048
; Checks the sum, carry in/out, and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Binary mode only (D=0); decimal mode is tested separately in adc_imm_dec.
; Uses both ends of the zero page ($00 and $FF).
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
        ; Operand values (correct locations)
        lda #$0A
        sta $00
        lda #$54
        sta $FF
        lda #$01
        sta $80
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: lowest ZP address ---
        lda #$44        ; V=1 I=1 N=0 D=0 Z=0 C=0
        pha
        plp
        lda #$50
        adc $00
        sta $0300       ; Expect $5A
        php             ; Expect $34 at $01FF

        ; --- Case 2: highest ZP address ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$50
        adc $FF
        sta $0301       ; Expect $A5
        php             ; Expect $F4 at $01FE

        ; --- Case 3: mid ZP address ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$FF
        adc $80
        sta $0302       ; Expect $00
        php             ; Expect $37 at $01FD

        ; --- Case 4: mid ZP address ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$7E
        adc $7F
        sta $0303       ; Expect $7F
        php             ; Expect $34 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
