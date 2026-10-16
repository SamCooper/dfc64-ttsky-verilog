; Target: vasm6502_oldstyle
; Test: LSR zeropage ($46)
; Cycles: 65
; Done: $C023
; Shifts right; bit 0 goes to C, bit 7 becomes 0 (N is always 0).
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
        lda #$FF
        sta $FF
        lda #$01
        sta $80
        lda #$FE
        sta $7F

        ; --- Case 1: lowest ZP address, $B4 -> $5A ---
        lsr $00         ; Expect $5A at $0000
        php             ; Expect $74 at $01FF

        ; --- Case 2: highest ZP address, $FF -> $7F, C=1 ---
        lsr $FF         ; Expect $7F at $00FF
        php             ; Expect $75 at $01FE

        ; --- Case 3: mid ZP address, $01 -> $00, C=1 ---
        lsr $80         ; Expect $00 at $0080
        php             ; Expect $77 at $01FD

        ; --- Case 4: mid ZP address, $FE -> $7F ---
        lsr $7F         ; Expect $7F at $007F
        php             ; Expect $74 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
