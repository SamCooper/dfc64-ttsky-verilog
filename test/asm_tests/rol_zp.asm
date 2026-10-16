; Target: vasm6502_oldstyle
; Test: ROL zeropage ($26)
; Cycles: 101
; Done: $C033
; Rotates left through carry; each case sets C first (via PLP).
; Checks the result and the N/Z/C flags, and that V is unchanged.
; Uses both ends of the zero page ($00 and $FF).
; The result is the modified memory location itself.
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
        lda #$2D
        sta $00
        lda #$52
        sta $FF
        lda #$80
        sta $80
        lda #$3F
        sta $7F

        ; --- Case 1: lowest ZP address, C=0: $2D -> $5A ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        rol $00         ; Expect $5A at $0000
        php             ; Expect $34 at $01FF

        ; --- Case 2: highest ZP address, C=1: $52 -> $A5 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        rol $FF         ; Expect $A5 at $00FF
        php             ; Expect $B4 at $01FE

        ; --- Case 3: mid ZP address, C=0: $80 -> $00, C=1 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        rol $80         ; Expect $00 at $0080
        php             ; Expect $37 at $01FD

        ; --- Case 4: mid ZP address, C=1: $3F -> $7F ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        rol $7F         ; Expect $7F at $007F
        php             ; Expect $34 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
