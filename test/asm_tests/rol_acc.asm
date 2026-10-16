; Target: vasm6502_oldstyle
; Test: ROL accumulator ($2A)
; Cycles: 139
; Done: $C04E
; Rotates left through carry; each case sets C first (via PLP).
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

        ; --- Case 1: C=0: $2D -> $5A ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$2D
        rol
        sta $0300       ; Expect $5A
        php             ; Expect $34 at $01FF

        ; --- Case 2: C=1: $00 -> $01 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$00
        rol
        sta $0301       ; Expect $01
        php             ; Expect $34 at $01FE

        ; --- Case 3: C=1: $80 -> $01, C=1 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$80
        rol
        sta $0302       ; Expect $01
        php             ; Expect $35 at $01FD

        ; --- Case 4: C=0: $80 -> $00, C=1 (Z=1) ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        lda #$80
        rol
        sta $0303       ; Expect $00
        php             ; Expect $37 at $01FC

        ; --- Case 5: C=1: $40 -> $81 (N=1) ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$40
        rol
        sta $0304       ; Expect $81
        php             ; Expect $B4 at $01FB

        ; --- Case 6: C=1: $FF -> $FF, C=1 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        lda #$FF
        rol
        sta $0305       ; Expect $FF
        php             ; Expect $B5 at $01FA

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
