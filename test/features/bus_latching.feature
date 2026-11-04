Feature: Time-multiplexed address/data bus
  The DFC64 ASIC exposes a 16-bit address space over an 8-bit bidirectional
  bus (uio[7:0]) by sequencing two address counter loads (LOAD_L_n, LOAD_H_n)
  followed by a data phase (MEM_WE or MEM_OE), per the memory architecture
  described in README.md.

  Scenario: Latching the low address byte
    Given the ASIC drives a byte on the bus
    When LOAD_L_n pulses
    Then the low address counters hold that byte

  Scenario: Latching the high address byte
    Given the ASIC drives a byte on the bus
    When LOAD_H_n pulses
    Then the high address counters hold that byte

  Scenario: Writing a byte to memory
    Given a 16-bit address has been latched via LOAD_L_n and LOAD_H_n
    When the ASIC asserts MEM_WE with a data byte on the bus
    Then the memory mock stores that byte at the latched address

  Scenario: Reading a byte from memory
    Given a 16-bit address has been latched via LOAD_L_n and LOAD_H_n
    And the memory mock holds a known byte at that address
    When the ASIC asserts MEM_OE
    Then the ASIC observes that byte on the bus
