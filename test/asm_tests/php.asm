; Target: vasm6502_oldstyle
; Test: PHP implied ($08)
; Cycles: 67
; Done: $C01D
; Pushes the status; B (bit 4) and bit 5 are always set in the pushed byte.
;
; Result layout:
;   $0300+  value produced by each case
;   $01FF-  processor status after each case (one PHP per case, stack grows down)
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs

        ; --- Case 1: status N=0 V=0 D=0 I=0 Z=0 C=0 ---
        lda #$00        ; N=0 V=0 D=0 I=0 Z=0 C=0
        pha
        plp
        php             ; Expect $30 at $01FF

        ; --- Case 2: status N=1 V=1 D=1 I=1 Z=1 C=1 ---
        lda #$FF        ; N=1 V=1 D=1 I=1 Z=1 C=1
        pha
        plp
        php             ; Expect $FF at $01FE

        ; --- Case 3: status N=1 V=1 Z=1 C=1 D=0 I=0 ---
        lda #$C3        ; N=1 V=1 Z=1 C=1 D=0 I=0
        pha
        plp
        php             ; Expect $F3 at $01FD

        ; --- Case 4: status D=1 I=1 N=0 V=0 Z=0 C=0 ---
        lda #$0C        ; D=1 I=1 N=0 V=0 Z=0 C=0
        pha
        plp
        php             ; Expect $3C at $01FC

        ; --- Case 5: status V=1 C=1 N=0 D=0 I=0 Z=0 ---
        lda #$41        ; V=1 C=1 N=0 D=0 I=0 Z=0
        pha
        plp
        php             ; Expect $71 at $01FB

        ; --- Case 6: a second PHP shows the first one left the flags unchanged ---
        php             ; Expect $71 at $01FA

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
