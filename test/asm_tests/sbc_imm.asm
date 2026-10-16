; Target: vasm6502_oldstyle
; Test: SBC #immediate ($E9)
; Cycles: 185
; Done: $C071
; Checks the difference, borrow in/out (C=0 means borrow), and the N/Z/C/V flags.
; Each case sets C, D and V first (via PLP).
; Binary mode only (D=0); decimal mode is tested separately in sbc_imm_dec.
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
        sta $0306
        lda #$FF        ; Pre-seed a zero-result location
        sta $0307

        ; --- Case 1: binary, C=1: $05 - $03 = $02 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$05
        sbc #$03
        sta $0300       ; Expect $02
        php             ; Expect $35 at $01FF

        ; --- Case 2: binary, C=1: $00 - $01 = $FF (borrow) ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$00
        sbc #$01
        sta $0301       ; Expect $FF
        php             ; Expect $B4 at $01FE

        ; --- Case 3: binary, C=1: $80 - $01 = $7F (overflow) ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$80
        sbc #$01
        sta $0302       ; Expect $7F
        php             ; Expect $75 at $01FD

        ; --- Case 4: binary, C=1: $7F - $FF = $80 (overflow, borrow) ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$7F
        sbc #$FF
        sta $0303       ; Expect $80
        php             ; Expect $F4 at $01FC

        ; --- Case 5: binary, C=0: $05 - $03 - 1 = $01 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$05
        sbc #$03
        sta $0304       ; Expect $01
        php             ; Expect $35 at $01FB

        ; --- Case 6: binary, C=0: $00 - $00 - 1 = $FF (borrow) ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$00
        sbc #$00
        sta $0305       ; Expect $FF
        php             ; Expect $B4 at $01FA

        ; --- Case 7: binary, C=1: $40 - $40 = $00 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$40
        sbc #$40
        sta $0306       ; Expect $00
        php             ; Expect $37 at $01F9

        ; --- Case 8: binary, C=0: $01 - $00 - 1 = $00 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$01
        sbc #$00
        sta $0307       ; Expect $00
        php             ; Expect $37 at $01F8

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
