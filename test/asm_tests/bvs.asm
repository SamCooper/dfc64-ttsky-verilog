; Target: vasm6502_oldstyle
; Test: BVS relative ($70)
; Cycles: 154
; Done: $C064
; Branches when V=1. Checks taken and not-taken, forward and backward,
; maximum offsets (+127 / -128) across a page boundary, and that the other flags
; do not affect the decision. Each path stores a marker ($EE = wrong path) and
; captures the status with PHP.
; Cycle note: 2 not taken, 3 taken, 4 taken across a page.
;
; Result layout:
;   $0300+  value produced by each case
;   $01FF-  processor status after each case (one PHP per case, stack grows down)
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs

        ; --- Case 1: taken forward (V=1, other flags clear) ---
        lda #$40        ; V=1 N=0 D=0 I=0 Z=0 C=0
        pha
        plp
        bvs c1_ok
        php
        lda #$EE
        sta $0300
        jmp c2
c1_ok:
        php             ; Expect $70 at $01FF
        lda #$01
        sta $0300       ; Expect $01

        ; --- Case 2: not taken (V=0, other flags set) ---
c2:
        lda #$8F        ; N=1 D=1 I=1 Z=1 C=1 V=0
        pha
        plp
        bvs c2_bad
        php             ; Expect $BF at $01FE
        lda #$02
        sta $0301       ; Expect $02
        jmp c3
c2_bad:
        php
        lda #$EE
        sta $0301

        ; --- Case 3: taken backward (V=1, other flags set) ---
c3:
        lda #$CF        ; N=1 V=1 D=1 I=1 Z=1 C=1
        pha
        plp
        jmp c3_br
c3_ok:
        php             ; Expect $FF at $01FD
        lda #$03
        sta $0302       ; Expect $03
        jmp c4
c3_br:
        bvs c3_ok
        php
        lda #$EE
        sta $0302
        jmp c4

        ; --- Case 4: not taken (V=0, other flags clear) ---
c4:
        lda #$00        ; N=0 V=0 D=0 I=0 Z=0 C=0
        pha
        plp
        bvs c4_bad
        php             ; Expect $30 at $01FC
        lda #$04
        sta $0303       ; Expect $04
        jmp c5
c4_bad:
        php
        lda #$EE
        sta $0303

        ; --- Case 5: taken forward, offset +127, crossing $C1xx -> $C2xx ---
c5:
        lda #$40        ; V=1 N=0 D=0 I=0 Z=0 C=0
        pha
        plp
        jmp c5_br

done:
        jmp done        ; Infinite loop to terminate

        .org $C1F0
c5_br:
        bvs c5_ok       ; $C1F2 + 127 = $C271
        php
        lda #$EE
        sta $0304
        jmp c6

        .org $C271
c5_ok:
        php             ; Expect $70 at $01FB
        lda #$05
        sta $0304       ; Expect $05
        jmp c6

        ; --- Case 6: taken backward, offset -128, crossing $C4xx -> $C3xx ---
        .org $C300
c6:
        lda #$CF        ; N=1 V=1 D=1 I=1 Z=1 C=1
        pha
        plp
        jmp c6_br

        .org $C390
c6_ok:
        php             ; Expect $FF at $01FA
        lda #$06
        sta $0305       ; Expect $06
        jmp done

        .org $C40E
c6_br:
        bvs c6_ok       ; $C410 - 128 = $C390
        php
        lda #$EE
        sta $0305
        jmp done

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
