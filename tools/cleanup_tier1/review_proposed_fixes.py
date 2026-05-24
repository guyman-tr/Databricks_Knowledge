"""review_proposed_fixes.py — interactive accept/reject of LLM-proposed fixes.

Walks every FAIL row in a `report.csv` produced by `llm_column_audit.py`,
prints BEFORE / AFTER side-by-side, and asks for a one-letter verdict:

    [a]ccept    — write this fix to report.accepted.csv (will be applied)
    [r]eject    — skip; do not write to accepted file
    [e]dit      — open $EDITOR (or notepad) on the proposed_fix; result is
                  saved as the accepted text
    [s]kip      — same as reject but flag for "needs human" review
    [q]uit      — stop reviewing; what you accepted so far is saved

Output:
    <report-dir>/report.accepted.csv    — only the accepted rows, with the
                                          (possibly edited) text in proposed_fix
    <report-dir>/report.review-state.json — your verdicts; re-running the
                                          review picks up where you left off

Usage:
  python -m cleanup_tier1.review_proposed_fixes --report audits/_llm_.../report.csv
  python -m cleanup_tier1.review_proposed_fixes --report ... --auto-accept-low
"""
from __future__ import annotations

import argparse
import csv
import json
import os
import subprocess
import sys
import tempfile
import textwrap
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def _wrap(text: str, indent: str = "  ") -> str:
    return textwrap.fill(text or "", width=120,
                         initial_indent=indent, subsequent_indent=indent,
                         break_long_words=False, replace_whitespace=False)


def _edit_in_external_editor(initial_text: str) -> str | None:
    editor = os.environ.get("EDITOR") or ("notepad" if os.name == "nt" else "vi")
    with tempfile.NamedTemporaryFile(
        "w", suffix=".txt", delete=False, encoding="utf-8"
    ) as f:
        f.write(initial_text)
        f.write("\n\n# Lines starting with '#' will be stripped. Save and close.\n")
        tmp_path = Path(f.name)
    try:
        subprocess.call([editor, str(tmp_path)])
        text = tmp_path.read_text(encoding="utf-8")
    finally:
        try:
            tmp_path.unlink()
        except OSError:
            pass
    lines = [ln for ln in text.splitlines() if not ln.lstrip().startswith("#")]
    return "\n".join(lines).strip() or None


def _print_row(idx: int, total: int, row: dict) -> None:
    sev = row.get("severity") or "?"
    print()
    print("=" * 100)
    print(f"[{idx}/{total}]  {row['column_name']}  in  "
          f"{row['wiki_path']}:{row['line_no']}   severity={sev}")
    print("=" * 100)
    print()
    print(f"  REASON   : {row['reason']}")
    bc = row.get("body_contradiction") or ""
    if bc:
        print(f"  BODY-LIE : {bc}")
    pw = row.get("parent_wiki") or "(unresolved)"
    pt = row.get("parent_tier") or "?"
    print(f"  PARENT   : {pw}  (T{pt})")
    if row.get("parent_desc"):
        print()
        print("  PARENT DESCRIPTION:")
        print(_wrap(row["parent_desc"], indent="    "))
    print()
    print("  BEFORE:")
    print(_wrap(row["current_desc"], indent="    "))
    print()
    print("  AFTER (proposed):")
    proposed = row.get("proposed_fix") or "<no proposed_fix — must mark skip>"
    print(_wrap(proposed, indent="    "))
    print()


def _ask(prompt: str, valid: str) -> str:
    while True:
        ans = input(prompt).strip().lower()[:1]
        if ans in valid:
            return ans
        print(f"  please type one of: {valid}")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", required=True,
                    help="path to report.csv from llm_column_audit.py")
    ap.add_argument("--auto-accept-low", action="store_true",
                    help="auto-accept severity=LOW (cosmetic) without asking")
    ap.add_argument("--severity", default="HIGH,MEDIUM,LOW",
                    help="comma-separated severities to review (default: all)")
    ap.add_argument("--show-only-fail", action="store_true", default=True,
                    help=argparse.SUPPRESS)
    args = ap.parse_args(argv)

    report = Path(args.report)
    if not report.is_absolute():
        report = REPO / report
    if not report.exists():
        print(f"ERROR: report not found: {report}", file=sys.stderr)
        return 2

    rows = list(csv.DictReader(report.open(encoding="utf-8")))
    severities = {s.strip().upper() for s in args.severity.split(",") if s.strip()}
    fails = [
        r for r in rows
        if r.get("verdict") == "FAIL"
        and (r.get("severity") or "LOW").upper() in severities
    ]
    if not fails:
        print("No FAIL rows match — nothing to review.")
        return 0

    # Resume state (per-report)
    report_dir = report.parent
    state_path = report_dir / "report.review-state.json"
    accepted_path = report_dir / "report.accepted.csv"
    state = {}
    if state_path.exists():
        try:
            state = json.loads(state_path.read_text(encoding="utf-8"))
        except Exception:
            state = {}
    print(f"Loaded {len(rows)} report rows; {len(fails)} FAILs to review")
    if state:
        print(f"Resuming — {len(state)} previous verdicts loaded from "
              f"{state_path.name}")

    accepted_rows: list[dict] = []
    counts: Counter = Counter()
    quit_early = False
    for idx, row in enumerate(fails, 1):
        key = f"{row['wiki_path']}::{row['line_no']}::{row['column_name']}"
        prev = state.get(key)
        if prev:
            # Reuse the previous decision; also re-add to accepted if needed
            verdict = prev["verdict"]
            counts[verdict] += 1
            if verdict == "accept":
                # Reconstitute the accepted record with possibly-edited text
                acc = dict(row)
                acc["proposed_fix"] = prev.get("text", row.get("proposed_fix", ""))
                accepted_rows.append(acc)
            continue

        if args.auto_accept_low and (row.get("severity") or "").upper() == "LOW" \
                and row.get("proposed_fix"):
            counts["accept"] += 1
            state[key] = {"verdict": "accept", "text": row["proposed_fix"]}
            accepted_rows.append(row)
            print(f"  [auto-accept LOW] {key}")
            continue

        _print_row(idx, len(fails), row)
        valid = "arsq"
        if row.get("proposed_fix"):
            valid = "arseq"
        ans = _ask(f"  [a]ccept / [r]eject / [e]dit / [s]kip / [q]uit  > ", valid)
        if ans == "q":
            quit_early = True
            break
        if ans == "a":
            counts["accept"] += 1
            state[key] = {"verdict": "accept", "text": row["proposed_fix"]}
            accepted_rows.append(row)
        elif ans == "r":
            counts["reject"] += 1
            state[key] = {"verdict": "reject"}
        elif ans == "s":
            counts["skip"] += 1
            state[key] = {"verdict": "skip", "note": "needs human"}
        elif ans == "e":
            edited = _edit_in_external_editor(row.get("proposed_fix") or "")
            if not edited:
                print("  (empty after edit — treating as REJECT)")
                counts["reject"] += 1
                state[key] = {"verdict": "reject", "note": "empty after edit"}
                continue
            counts["accept"] += 1
            state[key] = {"verdict": "accept", "text": edited}
            edited_row = dict(row)
            edited_row["proposed_fix"] = edited
            accepted_rows.append(edited_row)

    # Persist state
    state_path.write_text(json.dumps(state, indent=2), encoding="utf-8")

    # Write accepted CSV
    if accepted_rows:
        fieldnames = list(accepted_rows[0].keys())
        with accepted_path.open("w", encoding="utf-8", newline="") as f:
            w = csv.DictWriter(f, fieldnames=fieldnames)
            w.writeheader()
            for r in accepted_rows:
                w.writerow(r)
        print()
        print(f"Wrote {len(accepted_rows)} accepted row(s) to "
              f"{accepted_path.relative_to(REPO)}")
    else:
        print("No accepts to write.")

    print(f"State saved to {state_path.relative_to(REPO)}")
    print(f"Summary: accept={counts['accept']} reject={counts['reject']} "
          f"skip={counts['skip']}"
          + (" (quit early)" if quit_early else ""))
    print()
    print("Next step:")
    print(f"  python -m cleanup_tier1.apply_column_fixes --report "
          f"{accepted_path.relative_to(REPO).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
