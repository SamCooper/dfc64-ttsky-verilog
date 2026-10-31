Feature: IRQ and NMI
  The DFC64 takes interrupts on two active-low inputs, ui_in[0] = IRQ_n (level-sensitive,
  masked by I) and ui_in[1] = NMI_n (edge-triggered, not maskable), at instruction
  boundaries, as the NMOS 6502 does. Implemented by test_interrupts.py over test/irq_tests/;
  each scenario is one .asm file whose '; @irq' style markers drive the pins.

  Scenario: An IRQ is taken from a wait loop (irq_basic)
    Given I is clear and the CPU is spinning in a wait loop
    When IRQ_n is pulled low
    Then the CPU pushes the wait loop's address and the status with B=0 and U=1
    And it sets I and fetches the handler from $FFFE/$FFFF
    And A and the other flags are unchanged in the handler
    And RTI restores the pushed status

  Scenario: A masked IRQ waits for CLI (irq_masked)
    Given I is set
    When IRQ_n is pulled low and held
    Then the following instructions run uninterrupted
    And after CLI the IRQ is taken exactly once

  Scenario: IRQ is level-sensitive (irq_level)
    Given IRQ_n is held low
    When the handler returns with RTI
    Then the IRQ is taken again, until the handler releases IRQ_n

  Scenario: An NMI ignores I (nmi_basic)
    Given I is set and the CPU is spinning in a wait loop
    When NMI_n is pulsed low
    Then the CPU pushes the wait loop's address and the status with B=0 and U=1
    And it fetches the handler from $FFFA/$FFFB
    And RTI restores the pushed status

  Scenario: NMI is edge-triggered (nmi_edge)
    Given NMI_n is pulled low and held
    Then exactly one NMI is taken while it stays low
    When NMI_n is released and pulled low again
    Then a second NMI is taken

  Scenario: An NMI nests inside an IRQ handler (nmi_in_irq)
    Given the CPU is in the IRQ handler with I set
    When NMI_n is pulsed low
    Then the NMI is taken and its frame sits below the IRQ frame
    And both handlers return to where they were interrupted
