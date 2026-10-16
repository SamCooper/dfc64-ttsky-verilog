; Target: vasm6502_oldstyle
; Test: RTI implied ($40)
; Cycles: 107
; Done: $C051
; Pulls the status then the address, and continues at that address (no +1).
; B and bit 5 of the pulled status are ignored. Each target starts with a PHP
; (so landing one byte late skips it), then stores a marker.
; Zero results are written over a $FF pre-seed so that a missing write is detected.

        .org $C000
reset:
        ldx #$FF
        txs

        ; --- Case 1: frame with status $FF ---
        lda #>i1
        pha
        lda #<i1
        pha
        lda #$FF
        pha
        ldy #$00        ; Make N/Z differ before the RTI
        rti
        lda #$EE
        sta $0300
i1:
        php             ; Expect $FF at $01FF (Restored status)
        lda #$01
        sta $0300       ; Expect $01

        ; --- Case 2: frame with status $00 ---
        lda #>i2
        pha
        lda #<i2
        pha
        lda #$00
        pha
        ldy #$80        ; Make N/Z differ before the RTI
        rti
        lda #$EE
        sta $0301
i2:
        php             ; Expect $30 at $01FE (Restored status)
        lda #$02
        sta $0301       ; Expect $02

        ; --- Case 3: SP = $FD, frame at $01FE, $01FF, $0100 (wrap), status $C3 ---
        lda #$C3
        sta $01FE
        lda #<i3
        sta $01FF
        lda #>i3
        sta $0100
        ldx #$FD
        txs
        ldy #$00        ; Make N/Z differ before the RTI
        rti
        lda #$EE
        sta $0302
i3:
        php             ; Expect $F3 at $0100 (Restored status)
        lda #$03
        sta $0302       ; Expect $03

done:
        jmp done        ; Infinite loop to terminate

        .org $FFFA
        .word done      ; NMI vector
        .word reset     ; Reset vector
        .word done      ; IRQ/BRK vector
