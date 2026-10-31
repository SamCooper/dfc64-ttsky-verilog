; Target: vasm6502_oldstyle
; Test: NMI is edge-triggered: held low it is taken once
; Cycles: 283
; Done: $C02C
; NMI_n is pulled low and held; exactly one NMI must follow, even across a delay loop
; that runs with NMI_n still low. After NMI_n is released and pulled low again, a second
; NMI follows. The handler counts entries in $10 and returns to the address in $20/$21.
;
; Result layout:
;   $0010        number of handler entries
;   $0300        entries after the first falling edge and the delay loop
;   $0301        entries after the second falling edge
;   $0302        delay loop counter left over (Y)
;   $01FF-$01FD  NMI frame (second NMI): PCH (patched), PCL (patched), status

        .org $C000
reset:
        ldx #$FF
        txs
        lda #<r1
        sta $20
        lda #>r1
        sta $21
wait1:
        jmp wait1       ; @nmi_low

r1:
        ldy #$20        ; NMI_n still low: no further NMI
delay:
        dey
        bne delay
        iny
        sty $0302       ; Expect $01
        lda $10
        sta $0300       ; Expect $01
        lda #<r2        ; @nmi_high
        sta $20
        lda #>r2
        sta $21
wait2:
        jmp wait2       ; @nmi_low

r2:
        lda $10
        sta $0301       ; Expect $02

done:
        jmp done        ; Infinite loop to terminate

nmi:
        inc $10         ; Expect $02 at $0010
        tsx
        lda $20
        sta $0102,x
        lda $21
        sta $0103,x
        rti

irq_trap:
        lda #$EE
        sta $03FF       ; Unexpected IRQ/BRK
        jmp done

        .org $FFFA
        .word nmi       ; NMI vector
        .word reset     ; Reset vector
        .word irq_trap  ; IRQ/BRK vector
