; Target: vasm6502_oldstyle
; Test: ASL zeropage ($06)
; Cycles: 65
; Done: $C023
; Shifts left; bit 7 goes to C, bit 0 becomes 0.
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

        ; --- Case 1: lowest ZP address, $2D -> $5A ---
        asl $00         ; Expect $5A at $0000
        php             ; Expect $74 at $01FF

        ; --- Case 2: highest ZP address, $52 -> $A4 ---
        asl $FF         ; Expect $A4 at $00FF
        php             ; Expect $F4 at $01FE

        ; --- Case 3: mid ZP address, $80 -> $00, C=1 ---
        asl $80         ; Expect $00 at $0080
        php             ; Expect $77 at $01FD

        ; --- Case 4: mid ZP address, $3F -> $7E ---
        asl $7F         ; Expect $7E at $007F
        php             ; Expect $74 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
