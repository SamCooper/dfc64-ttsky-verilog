; Target: vasm6502_oldstyle
; Test: ADC absolute,X ($7D)
; Cycles: 177
; Done: $C074
; Checks the sum, carry in/out, and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Binary mode only (D=0); decimal mode is tested separately in adc_imm_dec.
; Covers no page cross, page cross (carry into the high byte), X = $FF,
; X = 0, and wrap-around from $FFxx into the zero page.
; Trap values catch a CPU that fails to carry into the high byte.
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
        ; Operand values (correct locations)
        lda #$0A
        sta $1235
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
        lda #$FF        ; Pre-seed a zero-result location
        sta $0302

        ; --- Case 1: $1230 + $05 = $1235, no page cross ---
        lda #$44        ; V=1 I=1 N=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$05
        lda #$50
        adc $1230,x
        sta $0300       ; Expect $5A
        php             ; Expect $34 at $01FF

        ; --- Case 2: $12F0 + $20 = $1310, page cross ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ldx #$20
        lda #$50
        adc $12F0,x
        sta $0301       ; Expect $A5 ($EA = carry lost)
        php             ; Expect $F4 at $01FE

        ; --- Case 3: $2001 + $FF = $2100, page cross with X = $FF ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$FF
        lda #$FF
        adc $2001,x
        sta $0302       ; Expect $00 ($65 = carry lost)
        php             ; Expect $37 at $01FD

        ; --- Case 4: X = 0, top of RAM ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ldx #$00
        lda #$7E
        adc $7FFF,x
        sta $0303       ; Expect $7F
        php             ; Expect $34 at $01FC

        ; --- Case 5: $FFF0 + $20 = $10010 -> wraps to $0010 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ldx #$20
        lda #$1E
        adc $FFF0,x
        sta $0304       ; Expect $3C ($1E = carry lost)
        php             ; Expect $34 at $01FB

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
