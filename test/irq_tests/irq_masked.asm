; Target: vasm6502_oldstyle
; Test: IRQ held while I=1 is ignored, then taken after CLI
; Cycles: 107
; Done: $C01C
; IRQ is asserted with I=1; the following instructions must run uninterrupted. After CLI
; the IRQ is taken from the wait loop that follows, so the pushed PC is 'wait' with or
; without the NMOS one-instruction delay after CLI.
;
; Result layout:
;   $0300/$0301  values stored while the IRQ was held and masked
;   $0302/$0303  PCL/PCH as pushed by the IRQ
;   $0304        number of times the handler ran
;   $0305/$01FC  status inside the handler (PHP)
;   $01FF-$01FD  IRQ frame: PCH (patched), PCL (patched), status

        .org $C000
reset:
        ldx #$FF
        txs
        sei
        lda #$11        ; @irq
        sta $0300       ; Expect $11
        lda #$22
        sta $0301       ; Expect $22
        ldx #$03
spin:
        dex             ; IRQ still held and masked
        bne spin
        cli
wait:
        jmp wait

resume:
        lda $10
        sta $0304       ; Expect $01

done:
        jmp done        ; Infinite loop to terminate

irq:
        inc $10         ; @irq_off   Expect $01 at $0010
        php             ; Expect $34 at $01FC (I set)
        pla
        sta $0305       ; Expect $34
        tsx
        lda $0102,x     ; PCL pushed by the IRQ
        sta $0302       ; Expect <wait
        lda $0103,x     ; PCH pushed by the IRQ
        sta $0303       ; Expect >wait
        lda #<resume
        sta $0102,x
        lda #>resume
        sta $0103,x
        rti

nmi_trap:
        lda #$EE
        sta $03FE       ; Unexpected NMI
        jmp done

        .org $FFFA
        .word nmi_trap  ; NMI vector
        .word reset     ; Reset vector
        .word irq       ; IRQ/BRK vector
