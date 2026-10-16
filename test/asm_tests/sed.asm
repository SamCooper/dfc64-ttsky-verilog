; Target: vasm6502_oldstyle
; Test: SED implied ($F8)
; Cycles: 60
; Done: $C01B
; Sets D; all other flags must be unchanged.
;
; Result layout:
;   $0300+  value produced by each case
;   $01FF-  processor status after each case (one PHP per case, stack grows down)
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs

        ; --- Case 1: start N=1 V=1 D=1 I=1 Z=1 C=1 ---
        lda #$FF        ; N=1 V=1 D=1 I=1 Z=1 C=1
        pha
        plp
        sed
        php             ; Expect $FF at $01FF

        ; --- Case 2: start N=0 V=0 D=0 I=0 Z=0 C=0 ---
        lda #$00        ; N=0 V=0 D=0 I=0 Z=0 C=0
        pha
        plp
        sed
        php             ; Expect $38 at $01FE

        ; --- Case 3: start D=1 N=0 V=0 I=0 Z=0 C=0 ---
        lda #$08        ; D=1 N=0 V=0 I=0 Z=0 C=0
        pha
        plp
        sed
        php             ; Expect $38 at $01FD

        ; --- Case 4: start N=1 V=1 I=1 Z=1 C=1 D=0 ---
        lda #$F7        ; N=1 V=1 I=1 Z=1 C=1 D=0
        pha
        plp
        sed
        php             ; Expect $FF at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
