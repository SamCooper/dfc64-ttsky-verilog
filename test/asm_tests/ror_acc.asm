; Target: vasm6502_oldstyle
; Test: ROR accumulator ($6A)
; Cycles: 139
; Done: $C04E
; Rotates right through carry; each case sets C first (via PLP).
; Checks the result and the N/Z/C flags, and that V is unchanged.
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

        ; --- Case 1: C=0: $B4 -> $5A ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$B4
        ror
        sta $0300       ; Expect $5A
        php             ; Expect $34 at $01FF

        ; --- Case 2: C=1: $00 -> $80 (N=1) ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$00
        ror
        sta $0301       ; Expect $80
        php             ; Expect $B4 at $01FE

        ; --- Case 3: C=1: $01 -> $80, C=1 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$01
        ror
        sta $0302       ; Expect $80
        php             ; Expect $B5 at $01FD

        ; --- Case 4: C=0: $01 -> $00, C=1 (Z=1) ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$01
        ror
        sta $0303       ; Expect $00
        php             ; Expect $37 at $01FC

        ; --- Case 5: C=0: $FF -> $7F, C=1 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$FF
        ror
        sta $0304       ; Expect $7F
        php             ; Expect $35 at $01FB

        ; --- Case 6: C=1: $FE -> $FF ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$FE
        ror
        sta $0305       ; Expect $FF
        php             ; Expect $B4 at $01FA

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
