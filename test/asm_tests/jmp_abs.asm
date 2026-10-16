; Target: vasm6502_oldstyle
; Test: JMP absolute ($4C)
; Cycles: 58
; Done: $C02C
; Jumps forward, backward and to another page. Each target stores a marker;
; skipped code stores $EE.
; Initial status (via PLP): V=1 I=1 C=1 N=0 D=0 Z=0
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs
        lda #$45        ; V=1 I=1 C=1 N=0 D=0 Z=0
        pha
        plp

        ; --- Case 1: jump forward over a failure marker ---
        jmp j1
        lda #$EE
        sta $0300
j1:
        php             ; Expect $75 at $01FF
        lda #$01
        sta $0300       ; Expect $01

        ; --- Case 2: jump to another page ($C500), which jumps back ---
        jmp j2
j2_back:

        ; --- Case 3: jump backward ---
        jmp j3_fwd
j3:
        php             ; Expect $75 at $01FD
        lda #$03
        sta $0302       ; Expect $03
        jmp done
j3_fwd:
        jmp j3
        lda #$EE
        sta $0302

done:
        jmp done        ; Infinite loop to terminate

        .org $C500
j2:
        php             ; Expect $75 at $01FE
        lda #$02
        sta $0301       ; Expect $02
        jmp j2_back

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
