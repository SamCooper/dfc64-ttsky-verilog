; Target: vasm6502_oldstyle
; Test: ADC absolute ($6D)
; Cycles: 130
; Done: $C053
; Checks the sum, carry in/out, and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Binary mode only (D=0); decimal mode is tested separately in adc_imm_dec.
; Covers the top of RAM ($7FFF) and $0100, the lowest address outside the zero page.
; All operands are >= $0100 so the assembler cannot pick the zero-page opcode.
; Trap values catch a CPU that drops the high byte.
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
        sta $1234
        lda #$54
        sta $7FFF
        lda #$01
        sta $0200
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; high byte dropped
        sta $00
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: absolute address ---
        lda #$44        ; V=1 I=1 N=0 D=0 Z=0 C=0
        pha
        plp
        lda #$50
        adc $1234
        sta $0300       ; Expect $5A ($50 = high byte dropped)
        php             ; Expect $34 at $01FF

        ; --- Case 2: top of RAM ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$50
        adc $7FFF
        sta $0301       ; Expect $A5 ($51 = high byte dropped)
        php             ; Expect $F4 at $01FE

        ; --- Case 3: absolute address ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$FF
        adc $0200
        sta $0302       ; Expect $00 ($98 = high byte dropped)
        php             ; Expect $37 at $01FD

        ; --- Case 4: $0100, just above the zero page ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$7E
        adc $0100
        sta $0303       ; Expect $7F ($18 = high byte dropped)
        php             ; Expect $34 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
