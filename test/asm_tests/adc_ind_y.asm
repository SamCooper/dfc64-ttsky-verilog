; Target: vasm6502_oldstyle
; Test: ADC (indirect),Y ($71)
; Cycles: 244
; Done: $C0A1
; Checks the sum, carry in/out, and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Binary mode only (D=0); decimal mode is tested separately in adc_imm_dec.
; Covers no page cross, page cross (carry into the high byte), a pointer at $FF
; (high byte from $00, not $0100), Y = 0, and wrap-around from $FFxx into the zero page.
; Trap values catch a CPU that loses the carry or reads the pointer high byte from $0100.
; Cycle note: cases 2 and 3 cross a page (+1 cycle on the 6502).
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
        ; Pointers
        lda #$30
        sta $20
        lda #$12
        sta $21
        lda #$F0
        sta $22
        lda #$12
        sta $23
        lda #$01
        sta $FF
        lda #$20
        sta $00
        lda #$30
        sta $0100
        lda #$FF
        sta $80
        lda #$7F
        sta $81
        lda #$F0
        sta $82
        lda #$FF
        sta $83
        ; Operand values (correct locations)
        lda #$0A
        sta $1234
        lda #$54
        sta $1310
        lda #$01
        sta $2100
        lda #$1E
        sta $10
        ; Trap values (used only by a faulty CPU)
        lda #$99        ; carry lost
        sta $1210
        lda #$66        ; carry lost
        sta $2000
        lda #$77        ; high byte read from $0100
        sta $3100
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: ($20) = $1230 + $04 = $1234, no page cross ---
        lda #$44        ; V=1 I=1 N=0 D=0 Z=0 C=0
        pha
        plp
        ldy #$04
        lda #$50
        adc ($20),y
        sta $0300       ; Expect $5A
        php             ; Expect $34 at $01FF

        ; --- Case 2: ($22) = $12F0 + $20 = $1310, page cross ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ldy #$20
        lda #$50
        adc ($22),y
        sta $0301       ; Expect $A5 ($EA = carry lost)
        php             ; Expect $F4 at $01FE

        ; --- Case 3: pointer at $FF (high byte from $00) = $2001 + $FF = $2100 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldy #$FF
        lda #$FF
        adc ($FF),y
        sta $0302       ; Expect $00 ($76 = wrap failed, $65 = carry lost)
        php             ; Expect $37 at $01FD

        ; --- Case 4: Y = 0, ($80) = $7FFF ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ldy #$00
        lda #$7E
        adc ($80),y
        sta $0303       ; Expect $7F
        php             ; Expect $34 at $01FC

        ; --- Case 5: ($82) = $FFF0 + $20 = $10010 -> wraps to $0010 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldy #$20
        lda #$1E
        adc ($82),y
        sta $0304       ; Expect $3C ($1E = carry lost)
        php             ; Expect $34 at $01FB

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
