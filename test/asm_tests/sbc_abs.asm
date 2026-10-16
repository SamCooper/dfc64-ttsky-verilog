; Target: vasm6502_oldstyle
; Test: SBC absolute ($ED)
; Cycles: 124
; Done: $C04E
; Checks the difference, borrow in/out (C=0 means borrow), and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Binary mode only (D=0); decimal mode is tested separately in sbc_imm_dec.
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
        lda #$80
        sta $7FFF
        lda #$33
        sta $0200
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; high byte dropped
        sta $00
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: absolute address ---
        lda #$45        ; V=1 I=1 C=1 N=0 D=0 Z=0
        pha
        plp
        lda #$5A
        sbc $1234
        sta $0300       ; Expect $5A
        php             ; Expect $35 at $01FF

        ; --- Case 2: top of RAM ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$25
        sbc $7FFF
        sta $0301       ; Expect $A5 ($25 = high byte dropped)
        php             ; Expect $F4 at $01FE

        ; --- Case 3: absolute address ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$33
        sbc $0200
        sta $0302       ; Expect $00 ($9A = high byte dropped)
        php             ; Expect $37 at $01FD

        ; --- Case 4: $0100, just above the zero page ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$80
        sbc $0100
        sta $0303       ; Expect $7F ($E6 = high byte dropped)
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
