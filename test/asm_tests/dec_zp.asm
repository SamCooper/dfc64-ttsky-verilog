; Target: vasm6502_oldstyle
; Test: DEC zeropage ($C6)
; Cycles: 60
; Done: $C01F
; Decrements memory; checks N/Z and wrap $00 -> $FF.
; Checks that C and V are unchanged.
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
        lda #$5B
        sta $00
        lda #$01
        sta $80
        lda #$80
        sta $7F

        ; --- Case 1: lowest ZP address, $5B -> $5A ---
        dec $00         ; Expect $5A at $0000
        php             ; Expect $75 at $01FF

        ; --- Case 2: highest ZP address, $00 -> $FF ---
        dec $FF         ; Expect $FF at $00FF
        php             ; Expect $F5 at $01FE

        ; --- Case 3: mid ZP address, $01 -> $00 ---
        dec $80         ; Expect $00 at $0080
        php             ; Expect $77 at $01FD

        ; --- Case 4: mid ZP address, $80 -> $7F ---
        dec $7F         ; Expect $7F at $007F
        php             ; Expect $75 at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
