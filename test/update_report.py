"""Update 6502_test_completeness.md from the harness results (asm_results.json).

Usage: python3 test/tools/update_report.py [results.json] [report.md]

- Done cells: [x] = passed, [!] = failed. Rows whose test was not in the results
  keep their current mark (so manual marks such as [~] survive until the test runs).
- Rows are matched to results through the .asm link in their Test Case column.
- Rebuilt from the Done cells:
    Summary table (Done / Failing / Remaining / % Complete per category, and a total),
    Addressing Modes table (Opcodes / Done / % Complete per mode),
    a "Progress" line under each instruction heading,
    and the block between <!-- results:start --> / <!-- results:end --> with the
    last-run totals and the failing tests.
  The decimal-mode (D=1) entries count towards their instruction's progress only.
"""
import json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
REPORT = os.path.join(ROOT, "6502_test_completeness.md")
RESULTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "asm_results.json")

ROW = re.compile(r"^\| \[(.)\] \| \$([0-9A-F]{2})( \(D=1\))? \| ([^|]+?) \|")
LINK = re.compile(r"\[[a-z0-9_]+\.asm\]\(test/([a-z0-9_]+)\.asm\)")
START, END = "<!-- results:start -->", "<!-- results:end -->"
PROGRESS = "**Progress:**"


def anchor(name):
    return "".join(c for c in name.lower().replace(" ", "-") if c.isalnum() or c == "-")


def pct(done, total):
    return f"{done * 100 // total}%" if total else "-"   # rounded down: 100% only when all done


def update(results_path=RESULTS, report_path=REPORT):
    results = {}
    if os.path.exists(results_path):
        with open(results_path) as f:
            results = json.load(f)
    with open(report_path) as f:
        lines = f.read().split("\n")

    # 1. Apply results to the Done cells and tally by category, instruction and mode
    cats, insts, modes = [], [], {}
    in_ins = False
    for i, line in enumerate(lines):
        if line.startswith("## "):
            in_ins = line == "## Instructions"
            continue
        if not in_ins:
            continue
        if line.startswith("### "):
            cats.append(dict(name=line[4:].strip(), ins=0, ops=0, done=0, fail=0, dec=0, dec_done=0))
            continue
        if line.startswith("#### "):
            cats[-1]["ins"] += 1
            insts.append(dict(rows=0, done=0))
            continue
        m = ROW.match(line)
        if not m:
            continue
        mark, decimal, mode = m.group(1), bool(m.group(3)), m.group(4).strip()
        link = LINK.search(line)
        r = results.get(link.group(1)) if link else None
        if r:
            mark = "x" if r["status"] == "pass" else "!"
            lines[i] = line[:3] + mark + line[4:]
        c, ins = cats[-1], insts[-1]
        ins["rows"] += 1
        ins["done"] += mark == "x"
        if decimal:
            c["dec"] += 1
            c["dec_done"] += mark == "x"
            continue
        c["ops"] += 1
        c["done"] += mark == "x"
        c["fail"] += mark == "!"
        md = modes.setdefault(mode, dict(ops=0, done=0))
        md["ops"] += 1
        md["done"] += mark == "x"

    # 2. Summary table
    head = next(i for i, l in enumerate(lines) if l.startswith("| Category |"))
    end = next(i for i in range(head, len(lines)) if lines[i].startswith("| **Total**"))
    table = ["| Category | Instructions | Opcodes | Done | Failing | Remaining | % Complete |",
             "|----------|-------------:|--------:|-----:|--------:|----------:|-----------:|"]
    tot = dict(ins=0, ops=0, done=0, fail=0)
    for c in cats:
        table.append(f"| [{c['name']}](#{anchor(c['name'])}) | {c['ins']} | {c['ops']} | {c['done']} | "
                     f"{c['fail']} | {c['ops'] - c['done']} | {pct(c['done'], c['ops'])} |")
        for k in tot:
            tot[k] += c[k]
    table.append(f"| **Total** | **{tot['ins']}** | **{tot['ops']}** | **{tot['done']}** | "
                 f"**{tot['fail']}** | **{tot['ops'] - tot['done']}** | **{pct(tot['done'], tot['ops'])}** |")
    lines[head:end + 1] = table

    # 3. Addressing Modes table: keep Abbrev/Mode/Syntax, recompute the counts
    head = next(i for i, l in enumerate(lines) if l.startswith("| Abbrev."))
    end = head + 2
    while end < len(lines) and lines[end].startswith("|"):
        end += 1
    table = ["| Abbrev. | Mode | Syntax | Opcodes | Done | % Complete |",
             "|---------|------|--------|--------:|-----:|-----------:|"]
    for row in lines[head + 2:end]:
        abbrev, mode, syntax = [x.strip() for x in row.strip("|").split("|")[:3]]
        md = modes.get(mode, dict(ops=0, done=0))
        table.append(f"| {abbrev} | {mode} | {syntax} | {md['ops']} | {md['done']} | {pct(md['done'], md['ops'])} |")
    lines[head:end] = table

    # 4. Progress line under each instruction heading (after its "Flags affected" line)
    out, n, skip_blank = [], -1, False
    for line in lines:
        if skip_blank:
            skip_blank = False
            if line == "":
                continue
        if line.startswith(PROGRESS):
            skip_blank = True
            continue
        out.append(line)
        if line.startswith("#### "):
            n += 1
        elif line.startswith("Flags affected:") and n >= 0:
            ins = insts[n]
            out += ["", f"{PROGRESS} {ins['done']} of {ins['rows']} done ({pct(ins['done'], ins['rows'])})"]
    lines = out

    # 5. Results block (after the decimal-mode note that follows the Summary table)
    dec = sum(c["dec"] for c in cats)
    dec_done = sum(c["dec_done"] for c in cats)
    tests_in_report = tot["ops"] + dec
    passed = sorted(t for t, r in results.items() if r["status"] == "pass")
    failed = sorted(t for t, r in results.items() if r["status"] != "pass")
    block = [START, ""]
    if results:
        last = max(r.get("time", "") for r in results.values())
        block.append(f"**Last results:** {len(passed)} passed, {len(failed)} failed, "
                     f"{tests_in_report - len(results)} not run (of {tests_in_report} tests). "
                     f"Most recent test run: {last}.")
    else:
        block.append("**Last results:** no test results yet. Run the cocotb suite (test_asm.py) "
                     "or `python3 test/tools/update_report.py` after a run.")
    block += ["", f"**Decimal mode:** {dec_done} of {dec} done ({pct(dec_done, dec)})."]
    if failed:
        block += ["", "| Failing test | Reason |", "|--------------|--------|"]
        for t in failed:
            msg = results[t].get("message", "").strip().splitlines()
            reason = (msg[0] if msg else "").replace("|", "\\|")
            if len(reason) > 160:
                reason = reason[:157] + "..."
            block.append(f"| [{t}](test/{t}.asm) | {reason} |")
    block += ["", END]
    if START in lines:
        a, b = lines.index(START), lines.index(END)
        lines[a:b + 1] = block
    else:
        note = next(i for i, l in enumerate(lines) if l.startswith("ADC and SBC also have a separate"))
        lines[note + 1:note + 1] = [""] + block

    with open(report_path, "w") as f:
        f.write("\n".join(lines))
    return tot


if __name__ == "__main__":
    args = sys.argv[1:]
    tot = update(*(args + [RESULTS, REPORT][len(args):]))
    print(f"Report updated: {tot['done']} of {tot['ops']} opcodes done ({pct(tot['done'], tot['ops'])}), "
          f"{tot['fail']} failing")
