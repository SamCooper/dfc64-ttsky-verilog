#!/usr/bin/env bash
# Run locally the Verilator lint and Yosys synthesis steps that the `gds` GitHub action
# (TinyTapeout/tt-gds-action -> LibreLane 3.0.14) performs, plus the checks that fail the build.
#
#   tools/harden_checks.sh              # lint + generic synthesis (no PDK needed)
#   PDK_ROOT=~/pdk tools/harden_checks.sh   # also map to sky130_fd_sc_hd cells, like the real flow
#
# Outputs go to runs/local_checks/ (gitignored). Exit status is non-zero if any check fails.
#
# Mirrors librelane/steps/verilator.py (Verilator.Lint + Checker.Lint*) and
# librelane/scripts/pyosys/synthesize.py (Yosys.Synthesis + Checker.YosysSynthChecks /
# YosysUnmappedCells). The final ABC pass uses a plain `abc -liberty` rather than LibreLane's
# generated AREA 0 script, so cell counts will be close to, but not identical to, CI.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck disable=SC1091
source env.sh >/dev/null

OUT="$ROOT/runs/local_checks"
rm -rf "$OUT"
mkdir -p "$OUT"

PDK="sky130A"
SCL="sky130_fd_sc_hd"
CLOCK_PERIOD_NS=$(grep -o '"CLOCK_PERIOD": *[0-9.]*' src/config.json | grep -o '[0-9.]*$')
CLOCK_PERIOD_NS=${CLOCK_PERIOD_NS:-20}

# --- Read top module and source list from info.yaml (as tt_tool.py --create-user-config does) ---
TOP=$(sed -n 's/^ *top_module: *"\([^"]*\)".*/\1/p' info.yaml)
mapfile -t SOURCES < <(awk '
  /^ *source_files:/ {in_list=1; next}
  in_list && /^ *- / {gsub(/^ *- *"?|"? *(#.*)?$/, ""); print "src/" $0; next}
  in_list && !/^ *(#.*)?$/ {in_list=0}
' info.yaml)

if [[ -z "$TOP" || ${#SOURCES[@]} -eq 0 ]]; then
  echo "ERROR: could not read top_module / source_files from info.yaml" >&2
  exit 2
fi
for f in "${SOURCES[@]}"; do
  [[ -f "$f" ]] || { echo "ERROR: $f is listed in info.yaml but does not exist" >&2; exit 2; }
done
# Warn about Verilog files in src/ that info.yaml does not list (CI will not see them).
for f in src/*.v; do
  printf '%s\n' "${SOURCES[@]}" | grep -qx "$f" || echo "NOTE: $f is not in info.yaml source_files (ignored by CI)"
done

echo "Top module : $TOP"
echo "Sources    : ${SOURCES[*]}"
echo "Output dir : $OUT"
echo

FAILED=0
fail() { echo "  FAIL: $*"; FAILED=1; }
pass() { echo "  ok:   $*"; }

DEFINES=("PDK_$PDK" "SCL_$SCL" "__librelane__" "__pnr__" "USE_POWER_PINS")

# ============================================================================================
# 1. Verilator.Lint
# ============================================================================================
echo "== Verilator lint =="
LINT_DIR="$OUT/verilator-lint"
mkdir -p "$LINT_DIR"
cat > "$LINT_DIR/_deps.vlt" <<'EOF'
`verilator_config
lint_off -rule DECLFILENAME
lint_off -rule EOFNEWLINE
EOF

LINT_CMD=(verilator --lint-only
  --waiver-output "$LINT_DIR/_waivers_output.vlt"
  --Wall --top-module "$TOP" "$LINT_DIR/_deps.vlt"
  --Wno-fatal --Werror-LATCH --Werror-MULTIDRIVEN
  -I"$ROOT/src")
for d in "${DEFINES[@]}"; do LINT_CMD+=("+define+$d"); done
LINT_CMD+=("${SOURCES[@]}")

printf '%q ' "${LINT_CMD[@]}" > "$LINT_DIR/cmd.sh"; echo >> "$LINT_DIR/cmd.sh"
"${LINT_CMD[@]}" > "$LINT_DIR/verilator-lint.log" 2>&1
LINT_RC=$?

LINT_WARN=$(grep -c '%Warning-' "$LINT_DIR/verilator-lint.log")
LINT_LATCH=$(grep -cE '%(Error|Warning)-LATCH' "$LINT_DIR/verilator-lint.log")
LINT_TIMING=$(grep -c '%Error-NEEDTIMINGOPT' "$LINT_DIR/verilator-lint.log")
LINT_ERR=$(sed -nE 's/^\s*%Error: Exiting due to ([0-9]+) error\(s\).*/\1/p' "$LINT_DIR/verilator-lint.log" | tail -1)
LINT_ERR=${LINT_ERR:-0}

grep -E '%(Warning|Error)' "$LINT_DIR/verilator-lint.log" | sed 's/^/    /'
if [[ $LINT_RC -ne 0 && $LINT_ERR -eq 0 ]]; then
  fail "verilator exited unexpectedly with return code $LINT_RC (see $LINT_DIR/verilator-lint.log)"
fi
[[ $LINT_ERR -eq 0 ]]    && pass "lint errors: 0"         || fail "lint errors: $LINT_ERR"
[[ $LINT_TIMING -eq 0 ]] && pass "timing constructs: 0"   || fail "timing constructs: $LINT_TIMING"
[[ $LINT_LATCH -eq 0 ]]  && pass "inferred latches: 0"    || fail "inferred latches: $LINT_LATCH"
echo "  info: lint warnings: $LINT_WARN (reported in CI, not fatal)"
echo

# ============================================================================================
# 2. Yosys.Synthesis
# ============================================================================================
echo "== Yosys synthesis =="
SYN_DIR="$OUT/yosys-synthesis"
mkdir -p "$SYN_DIR"

LIB=""
if [[ -n "${PDK_ROOT:-}" ]]; then
  LIB="$PDK_ROOT/$PDK/libs.ref/$SCL/lib/${SCL}__tt_025C_1v80.lib"
  [[ -f "$LIB" ]] || { echo "  WARNING: $LIB not found; doing generic synthesis only"; LIB=""; }
fi
[[ -z "$LIB" ]] && echo "  info: PDK_ROOT not set: stopping before sky130 cell mapping (dfflibmap/abc -liberty)"

YS="$SYN_DIR/synth.ys"
{
  for f in "${SOURCES[@]}"; do
    printf 'read_verilog -defer -noautowire -sv -I%s' "$ROOT/src"
    for d in "${DEFINES[@]}"; do printf ' -D%s' "$d"; done
    printf ' %s\n' "$ROOT/$f"
  done
  cat <<EOF
hierarchy -check -top $TOP -nokeep_prints -nokeep_asserts
rename -top $TOP
# --- librelane_synth ---
hierarchy -check -top $TOP -nokeep_prints -nokeep_asserts
proc_clean
proc_rmdead
proc_prune
proc_init
proc_arst
proc_rom
proc_mux
tee -o $SYN_DIR/latch.rpt proc_dlatch
proc_dff
proc_memwr
proc_clean
tee -o $SYN_DIR/pre_synth_chk.rpt check
opt_expr
flatten
opt_expr
opt_clean
opt -nodffe -nosdff
fsm
opt
wreduce
peepopt
opt_clean
alumacc
share
opt
memory -nomap
opt_clean
opt -fast -mux_undef -mux_bool -undriven -fine
opt_share
memory_map
opt -mux_undef -mux_bool -undriven -fine
opt_share
techmap
opt -fast
opt -fast
abc
opt -fast
hierarchy -check -top $TOP
check
stat
# --- back in synthesize ---
delete t:\$print
delete t:\$assert
opt
opt_clean -purge
tee -o $SYN_DIR/pre_techmap.rpt stat
EOF
  if [[ -n "$LIB" ]]; then
    cat <<EOF
dfflibmap -liberty $LIB
tee -o $SYN_DIR/post_dff.rpt stat
abc -D $(awk "BEGIN{print $CLOCK_PERIOD_NS*1000}") -liberty $LIB
hilomap -hicell ${SCL}__conb_1 HI -locell ${SCL}__conb_1 LO
splitnets
opt_clean -purge
insbuf -buf ${SCL}__buf_2 A X
tee -o $SYN_DIR/chk.rpt check
tee -o $SYN_DIR/stat.rpt stat -liberty $LIB
EOF
  else
    cat <<EOF
tee -o $SYN_DIR/chk.rpt check
tee -o $SYN_DIR/stat.rpt stat
EOF
  fi
  echo "write_verilog -noexpr -nohex -nodec -defparam $SYN_DIR/$TOP.nl.v"
} > "$YS"

yosys -q -l "$SYN_DIR/yosys-synthesis.log" -s "$YS" > /dev/null 2>&1
SYN_RC=$?
if [[ $SYN_RC -ne 0 ]]; then
  grep -E 'ERROR' "$SYN_DIR/yosys-synthesis.log" | sed 's/^/    /'
  fail "yosys exited with code $SYN_RC (see $SYN_DIR/yosys-synthesis.log)"
else
  pass "yosys synthesis completed"

  # Checker.YosysSynthChecks: problems found by the final `check` (logic loops, conflicting drivers, ...)
  CHK=$(sed -nE 's/.*Found and reported ([0-9]+) problems.*/\1/p' "$SYN_DIR/chk.rpt" | tail -1)
  CHK=${CHK:-0}
  if [[ $CHK -eq 0 ]]; then pass "yosys check problems: 0"; else
    grep -E '^Warning' "$SYN_DIR/chk.rpt" | sed 's/^/    /'
    fail "yosys check problems: $CHK (see $SYN_DIR/chk.rpt)"
  fi

  LATCHES=$(grep -c 'Latch inferred' "$SYN_DIR/latch.rpt")
  if [[ $LATCHES -eq 0 ]]; then pass "yosys inferred latches: 0"; else
    grep 'Latch inferred' "$SYN_DIR/latch.rpt" | sed 's/^/    /'
    fail "yosys inferred latches: $LATCHES"
  fi

  if [[ -n "$LIB" ]]; then
    # Checker.YosysUnmappedCells: any remaining internal $... cells after mapping
    UNMAPPED=$(grep -cE '^\s+[0-9]+.*\$_|^\s+\$_\S+\s+[0-9]+' "$SYN_DIR/stat.rpt")
    [[ $UNMAPPED -eq 0 ]] && pass "unmapped cells: 0" || fail "unmapped cells found (see $SYN_DIR/stat.rpt)"
    AREA=$(sed -nE 's/.*Chip area for (top )?module.*: *([0-9.]+).*/\2/p' "$SYN_DIR/stat.rpt" | tail -1)
    echo "  info: cell area ${AREA:-?} um^2 (a 1x1 ttsky tile is ~161x111.52 um = ~17955 um^2 die; aim well below)"
  fi
  CELLS=$(grep -E '^\s+[0-9]+\s+cells$|Number of cells:' "$SYN_DIR/stat.rpt" | tail -1 | grep -oE '[0-9]+' | head -1)
  echo "  info: cell count ${CELLS:-?} (full report: $SYN_DIR/stat.rpt)"
fi
echo

if [[ $FAILED -eq 0 ]]; then
  echo "All checks passed."
else
  echo "Some checks FAILED."
fi
exit $FAILED
