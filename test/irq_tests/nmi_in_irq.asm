; Target: vasm6502_oldstyle
; Test: NMI nests inside an IRQ handler
; Cycles: 124
; Done: $C00D
; An IRQ is taken from the main wait loop; inside the handler (I=1) an NMI is pulsed on
; a second wait loop and must be taken. Both frames stay on the stack. Each handler
; copies its pushed PC, then patches it to its own resume address.
;
; Result layout:
;   $01FF-$01FD  IRQ frame: PCH (patched), PCL (patched), status
;   $01FC-$01FA  NMI frame: PCH (patched), PCL (patched), status (I=1, from the IRQ handler)
;   $0300/$0301  PCL/PCH as pushed by the IRQ
;   $0302/$0303  PCL/PCH as pushed by the NMI
;   $0304        SP inside the NMI handler
;   $0305        set by the IRQ handler after the NMI returned

        .org $C000
reset:
        ldx #$FF
        txs
        lda #$01        ; C=1, others clear
        pha
        plp
        jmp wait        ; enter by JMP: the PLP's dummy read must not fire the marker
wait:
        jmp wait        ; @irq

resume:
done:
        jmp done        ; Infinite loop to terminate

irq:
        lda #$01        ; @irq_off
iwait:
        jmp iwait       ; @nmi

iresume:
        tsx
        lda $0102,x     ; PCL pushed by the IRQ
        sta $0300       ; Expect <wait
        lda $0103,x     ; PCH pushed by the IRQ
        sta $0301       ; Expect >wait
        lda #<resume
        sta $0102,x
        lda #>resume
        sta $0103,x
        lda #$5A
        sta $0305       ; Expect $5A
        rti

nmi:
        tsx
        stx $0304       ; Expect $F9
        lda $0102,x     ; PCL pushed by the NMI
        sta $0302       ; Expect <iwait
        lda $0103,x     ; PCH pushed by the NMI
        sta $0303       ; Expect >iwait
        lda #<iresume
        sta $0102,x
        lda #>iresume
        sta $0103,x
        rti

        .org $FFFA
        .word nmi       ; NMI vector
        .word reset     ; Reset vector
        .word irq       ; IRQ/BRK vector
