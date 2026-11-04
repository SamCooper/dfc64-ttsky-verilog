To support a full 64KB address space within the pin constraints of a standard Tiny Tapeout tile, the DFC64 utilizes a time-multiplexed bus paired with external PCB-level decoding. This splits the architecture into a strict logical memory map for the 6502 CPU and a coordinated physical layout of support ICs on the host board.

### Logical Memory Map

The 64KB address space is divided into eight discrete 8KB chunks using a 74HC138 3-to-8 line decoder reading the top three address bits (`A13`, `A14`, `A15`). Because 6502 architecture requires RAM at the bottom (for Zero Page and Stack) and ROM at the top (for reset vectors), the blocks are allocated as follows:

| Address Range | Size | Hardware Target | Decoder Output | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0xC000 - 0xFFFF` | 16KB | ROM | `Y6`, `Y7` (ANDed) | Boot ROM. Contains reset vectors at `0xFFFC/D`. |
| `0x8000 - 0xBFFF` | 16KB | Video RAM | `Y4`, `Y5` (ANDed) | Graphical framebuffer memory for display output. |
| `0x6000 - 0x7FFF` | 8KB | I/O Peripherals | `Y3` | Memory-mapped I/O (UART, Timers, SPI). Can be subdivided via ASIC pins or cascaded decoders. |
| `0x0000 - 0x5FFF` | 24KB | System RAM | `Y0`, `Y1`, `Y2` (ANDed) | General memory. Includes Zero Page (`0x0000-0x00FF`) and Hardware Stack (`0x0100-0x01FF`). |
