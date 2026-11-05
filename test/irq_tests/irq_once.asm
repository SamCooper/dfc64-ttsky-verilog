; Target: vasm6502_oldstyle
; Test: IRQ taken once after CLI
; Cycles: 70
; Done: $C023
; Minimal IRQ check: CLI, pull IRQ_n low, the handler runs once, releases IRQ_n and returns.
; The main loop polls the handler's counter and leaves once it is non-zero. The IRQ can be
; taken at either instruction of the poll loop, so the pushed PC is cleared afterwards and
; only the pushed status is kept.
; A DUT that never takes the IRQ times out in the poll loop and the irq_off marker never fires.
;
; Result layout:
;   $0010        number of handler entries
;   $0300        handler entries seen by the main loop
;   $0301        SP after RTI
;   $0302        status pushed by the IRQ (B=0, U=1, I=0)
;   $01FD-$01FF  IRQ frame, cleared after use

        .org $C000
reset:
        ldx #$FF
        txs
        cli
        jmp wait        ; enter by JMP: the CLI's dummy read must not fire the marker
wait:
        lda $10         ; @irq
        beq wait
        sta $0300       ; Expect $01
        tsx
        stx $0301       ; Expect $FF
        lda $01FD
        sta $0302       ; Expect $22 (U, Z from 'lda $10')
        lda #$00
        sta $01FD       ; pushed PC depends on which boundary took the IRQ: clear it
        sta $01FE
        sta $01FF

done:
        jmp done        ; Infinite loop to terminate

irq:
        inc $10         ; @irq_off   Expect $01 at $0010
        rti

nmi_trap:
        lda #$EE
        sta $03FE       ; Unexpected NMI
        jmp done

        .org $FFFA
        .word nmi_trap  ; NMI vector
        .word reset     ; Reset vector
        .word irq       ; IRQ/BRK vector
