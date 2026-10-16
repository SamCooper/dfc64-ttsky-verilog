; Target: vasm6502_oldstyle
; Test: ROR zeropage ($66)
; Cycles: 101
; Done: $C033
; Rotates right through carry; each case sets C first (via PLP).
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
        lda #$B4
        sta $00
        lda #$4A
        sta $FF
        lda #$01
        sta $80
        lda #$FE
        sta $7F

        ; --- Case 1: lowest ZP address, C=0: $B4 -> $5A ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ror $00         ; Expect $5A at $0000
        php             ; Expect $34 at $01FF

        ; --- Case 2: highest ZP address, C=1: $4A -> $A5 ---
        lda #$05        ; I=1 C=1 N=0 V=0 D=0 Z=0
        pha
        plp
        ror $FF         ; Expect $A5 at $00FF
        php             ; Expect $B4 at $01FE

        ; --- Case 3: mid ZP address, C=0: $01 -> $00, C=1 ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ror $80         ; Expect $00 at $0080
        php             ; Expect $37 at $01FD

        ; --- Case 4: mid ZP address, C=0: $FE -> $7F ---
        lda #$04        ; I=1 N=0 V=0 D=0 Z=0 C=0
        pha
        plp
        ror $7F         ; Expect $7F at $007F
        php             ; Expect $34 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
