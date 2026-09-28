# DFC64 – Claude Code project rules

6502-compatible 8-bit CPU for a single Tiny Tapeout (Sky130, `ttsky`) tile. See `README.md` for the
architecture: pin map, time-multiplexed bus (ALE_L → ALE_H → data on `uio[7:0]`), and memory map.

## Environment
- Always `source env.sh` first (OSS CAD Suite from `~/tools/oss-cad-suite`, Python venv `.venv`, `digital` launcher).
- Run tests with `make -C test`. Lint with `verilator --lint-only -Wall -Wno-DECLFILENAME src/*.v`.

## Roles
- **Claude is the test engineer.** Write cocotb (Python) tests *before* the hardware exists (TDD/BDD).
- **The user designs the hardware in H. Neemann's Digital.** Verilog in `src/` is exported from Digital
  (or is the Tiny Tapeout top-level wrapper). Do **not** hand-edit exported Verilog in `src/`; report
  failures and let the user fix the schematic.

## Test layout
- `test/` – cocotb test modules (`test_*.py`), registered in `test/Makefile`.
- `test/mocks/` – async Python models of the off-chip parts: custom latches, 74HC138 decoder, SRAM/ROM/IO.
- `test/features/` – Given/When/Then feature descriptions (pytest-bdd style) the tests implement.
- Tests must drive/observe only the real TT pins (`ui_in`, `uo_out`, `uio_in`, `uio_out`, `uio_oe`,
  `clk`, `rst_n`, `ena`) – never internal signals – so the same suite runs against the gate-level netlist.

## Fixed names
- Top module: `tt_um_samcooper_dfc64` (set in `info.yaml` and `src/project.v`; do not rename without updating both).
