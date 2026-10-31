; Target: vasm6502_oldstyle
; Test: IRQ is level-sensitive: held through RTI it is taken again
; Cycles: 127
; Done: $C00F
; IRQ is held low; each RTI back to the wait loop re-enables I, so the IRQ is taken again.
; On the third entry the handler releases the IRQ, patches the return address to 'resume'
; and returns. A missing release would loop forever (timeout).
;
; Result layout:
;   $0010        number of handler entries
;   $0300        handler entries seen at 'resume'
;   $0301/$0302  PCL/PCH as pushed by the last IRQ
;   $01FF-$01FD  IRQ frame: PCH (patched), PCL (patched), status

        .org $C000
reset:
        ldx #$FF
        txs
        cli
        jmp wait        ; enter by JMP: the CLI's dummy read must not fire the marker
wait:
        jmp wait        ; @irq

resume:
        lda $10
        sta $0300       ; Expect $03

done:
        jmp done        ; Infinite loop to terminate

irq:
        inc $10         ; Expect $03 at $0010
        lda $10
        cmp #$03
        beq release
        rti             ; IRQ still held: taken again straight away

nmi_trap:
        lda #$EE
        sta $03FE       ; Unexpected NMI
        jmp done

release:
        tsx             ; @irq_off
        lda $0102,x     ; PCL pushed by the IRQ
        sta $0301       ; Expect <wait
        lda $0103,x     ; PCH pushed by the IRQ
        sta $0302       ; Expect >wait
        lda #<resume
        sta $0102,x
        lda #>resume
        sta $0103,x
        rti

        .org $FFFA
        .word nmi_trap  ; NMI vector
        .word reset     ; Reset vector
        .word irq       ; IRQ/BRK vector
