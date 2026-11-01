; Target: vasm6502_oldstyle
; Test: JMP (indirect) ($6C)
; Cycles: 74
; Done: $C03C
; Jumps through a pointer in RAM. Case 2 checks that the NMOS page-wrap bug is NOT present:
; JMP ($04FF) takes the low byte from $04FF and the high byte from $0500, not $0400.
; A CPU with the bug lands on the $E2 marker.
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
        ; Case 1 pointer at $0410 -> t1
        lda #<t1
        sta $0410
        lda #>t1
        sta $0411
        ; Case 2 pointer at $04FF: low $40, high from $0500 = $C6 (correct), $0400 = $C5 (NMOS bug)
        lda #$40
        sta $04FF
        lda #$C5
        sta $0400
        lda #$C6
        sta $0500

        ; --- Case 1: pointer within one page ---
        jmp ($0410)
        lda #$EE
        sta $0300
        jmp c2
t1:
        php             ; Expect $F5 at $01FF
        lda #$01
        sta $0300       ; Expect $01

        ; --- Case 2: pointer at a page end ($04FF), high byte from the next page ---
c2:
        jmp ($04FF)
        lda #$EE
        sta $0301
        jmp done

done:
        jmp done        ; Infinite loop to terminate

        .org $C540
t2_nmos:
        lda #$E2        ; Wrong: high byte from $0400 (NMOS bug)
        sta $0301
        jmp done

        .org $C640
t2:
        php             ; Expect $75 at $01FE
        lda #$02        ; High byte from $0500
        sta $0301       ; Expect $02
        jmp done

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
