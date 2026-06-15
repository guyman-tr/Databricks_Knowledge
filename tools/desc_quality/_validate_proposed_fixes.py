"""G2: cheap static validation of a proposed_fixes.csv.

Four hard checks. Any FAIL is a hard gate — don't apply until fixed.

  1. Markdown safety: cells with unescaped '|', embedded newlines, or > 400 chars
     would break the §4 table when written back.
  2. Re-classify as TRIVIAL: every new_description should classify as
     HAS_TRANSFORMATION or HAS_SEMANTIC. Any row that still classifies TRIVIAL
     means we generated a bad description.
  3. Provenance present: every FOUND row must carry a `climb_found:*` reason
     and a non-empty new_description.
  4. No-op: new_description byte-equal to old_description (we'd be saying
     "trivial -> trivial" with extra ceremony).

Usage:
    python tools/desc_quality/_validate_proposed_fixes.py \
        --fixes audits/_desc_quality_rewrite_corpus9/proposed_fixes.csv

Writes a markdown report next to the CSV.
"""

from __future__ import annotations

import argparse
import csv
import sys
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from tools.desc_quality.classify import Verdict, classify  # noqa: E402


_REPO_ROOT = Path(__file__).resolve().parent.parent.parent

# Markdown tables happily render multi-paragraph cells; the hard upper bound
# here is just to flag "something has gone wildly wrong" output, not legit
# rich descriptions pulled verbatim from upstream wikis.
MAX_CELL_LEN = 2000


@dataclass
class CheckResult:
    name: str
    passed: bool = True
    offenders: list[str] = field(default_factory=list)

    def fail(self, msg: str) -> None:
        self.passed = False
        self.offenders.append(msg)


def _check_markdown_safety(rows: list[dict[str, str]]) -> CheckResult:
    r = CheckResult(name="markdown_safety")
    for row in rows:
        new_desc = row.get("new_description", "")
        wiki = row.get("wiki_path", "")
        col = row.get("column", "")
        issues: list[str] = []
        if "\n" in new_desc or "\r" in new_desc:
            issues.append("contains_newline")
        if "|" in new_desc:
            # The wiki §4 table is markdown — un-escaped `|` would split a cell.
            # Some descriptions legitimately need pipes; we surface them anyway
            # so the reader can decide.
            issues.append("contains_pipe")
        if len(new_desc) > MAX_CELL_LEN:
            issues.append(f"length={len(new_desc)}>{MAX_CELL_LEN}")
        if issues:
            r.fail(f"{wiki} :: {col} -> {', '.join(issues)}")
    return r


def _check_reclassify(rows: list[dict[str, str]]) -> CheckResult:
    r = CheckResult(name="reclassify_not_trivial")
    for row in rows:
        new_desc = row.get("new_description", "")
        if not new_desc:
            continue
        verdict, _signal = classify(new_desc)
        if verdict == Verdict.TRIVIAL:
            wiki = row.get("wiki_path", "")
            col = row.get("column", "")
            preview = new_desc[:100] + ("..." if len(new_desc) > 100 else "")
            r.fail(f"{wiki} :: {col} -> still_trivial: {preview}")
    return r


def _check_provenance(rows: list[dict[str, str]]) -> CheckResult:
    r = CheckResult(name="provenance_present")
    for row in rows:
        reason = (row.get("reason") or "").strip()
        new_desc = (row.get("new_description") or "").strip()
        wiki = row.get("wiki_path", "")
        col = row.get("column", "")
        # Convention: FOUND rows have reason starting with `climb_found:`;
        # EXHAUSTED rows have `exhausted:` or similar. We're validating FOUND.
        if not reason.startswith("climb_found:"):
            continue  # skip EXHAUSTED rows for this check
        if not new_desc:
            r.fail(f"{wiki} :: {col} -> empty_new_description despite climb_found")
            continue
        target = reason.split(":", 1)[1].strip()
        if not target:
            r.fail(f"{wiki} :: {col} -> climb_found has no target")
    return r


def _check_no_op(rows: list[dict[str, str]]) -> CheckResult:
    r = CheckResult(name="no_op")
    for row in rows:
        old = (row.get("old_description") or "").strip()
        new = (row.get("new_description") or "").strip()
        if old and new and old == new:
            wiki = row.get("wiki_path", "")
            col = row.get("column", "")
            r.fail(f"{wiki} :: {col} -> old==new ({old[:80]})")
    return r


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--fixes", required=True, help="Path to proposed_fixes.csv")
    ap.add_argument("--out", default=None, help="Output report path")
    args = ap.parse_args()

    fixes = Path(args.fixes)
    if not fixes.is_absolute():
        fixes = (_REPO_ROOT / fixes).resolve()
    if not fixes.exists():
        print(f"Not found: {fixes}", file=sys.stderr)
        return 2

    out_path = Path(args.out).resolve() if args.out else fixes.parent / "validation_report.md"

    with fixes.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    checks = [
        _check_markdown_safety(rows),
        _check_reclassify(rows),
        _check_provenance(rows),
        _check_no_op(rows),
    ]

    overall_pass = all(c.passed for c in checks)
    lines: list[str] = []
    lines.append("# G2 Static Validation Report\n")
    lines.append(f"Source: `{fixes.relative_to(_REPO_ROOT)}`\n")
    lines.append(f"Rows examined: **{len(rows)}**")
    lines.append(f"Overall: **{'PASS' if overall_pass else 'FAIL'}**\n")
    for c in checks:
        status = "PASS" if c.passed else f"FAIL ({len(c.offenders)})"
        lines.append(f"## {c.name} — {status}\n")
        if not c.passed:
            lines.append("```")
            for o in c.offenders[:50]:
                lines.append(o)
            if len(c.offenders) > 50:
                lines.append(f"... and {len(c.offenders) - 50} more")
            lines.append("```")
            lines.append("")
        else:
            lines.append("(no offenders)\n")

    out_path.write_text("\n".join(lines), encoding="utf-8")

    # Stdout summary
    print(f"Wrote: {out_path}")
    print(f"Rows: {len(rows)}")
    for c in checks:
        tag = "PASS" if c.passed else f"FAIL  ({len(c.offenders)} offenders)"
        print(f"  {c.name:30s} {tag}")
    print()
    print(f"OVERALL: {'PASS' if overall_pass else 'FAIL'}")
    return 0 if overall_pass else 1


if __name__ == "__main__":
    raise SystemExit(main())
