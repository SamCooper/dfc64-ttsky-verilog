; Target: vasm6502_oldstyle
; Test: CLV implied ($B8)
; Cycles: 60
; Done: $C01B
; Clears V; all other flags must be unchanged.
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
        clv
        php             ; Expect $BF at $01FF

        ; --- Case 2: start N=0 V=0 D=0 I=0 Z=0 C=0 ---
        lda #$00        ; N=0 V=0 D=0 I=0 Z=0 C=0
        pha
        plp
        clv
        php             ; Expect $30 at $01FE

        ; --- Case 3: start V=1 N=0 D=0 I=0 Z=0 C=0 ---
        lda #$40        ; V=1 N=0 D=0 I=0 Z=0 C=0
        pha
        plp
        clv
        php             ; Expect $30 at $01FD

        ; --- Case 4: start N=1 D=1 I=1 Z=1 C=1 V=0 ---
        lda #$BF        ; N=1 D=1 I=1 Z=1 C=1 V=0
        pha
        plp
        clv
        php             ; Expect $BF at $01FC

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
