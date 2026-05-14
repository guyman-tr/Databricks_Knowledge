"""Audit + patch the human-readable wiki .md files for the same two slop
classes the .alter.sql remediation handled: codepoint mismatches and the
"Popular Investor" PI-slop residue.

Unlike the .alter.sql pipeline, the .md files were never touched by the
column-comment passes -- so they still carry the original LLM slop. This
script runs the SAME tightened-regex discovery + Tier-1 verdict directly
on markdown column-table rows.

A markdown column-table row looks like:

  | 17 | PlayerLevelID | int | YES | Customer experience/permission level. FK to Dictionary.PlayerLevel. 1=Standard; 4=Popular Investor; 7=VIP. Determines available features and risk limits. Default=0. Passthrough from Dim_Customer. (Tier 1 - Customer.CustomerStatic) |

We only modify the *description cell* (the 5th pipe-delimited cell) of such
rows. Prose paragraphs and batch summaries are left alone.

Run:
  python tools/audit_wiki_md_slop.py --audit-only  # report only
  python tools/audit_wiki_md_slop.py               # patch .md files in place
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"
TRUTH_JSON = REPO / "knowledge" / "_dictionary_truth.json"
OUT_REPORT = REPO / "knowledge" / "_wiki_md_slop_report.csv"

# Reuse the tightened audit regex + verdict logic from the SQL judge.
sys.path.insert(0, str(REPO / "tools"))
from audit_codepoint_claims import (  # type: ignore
    ENUM_NEQ, ENUM_PAREN, NOISE_LABELS,
    _trim_label, _normalize, _resolve_truth_key,
)

# PI residue config (mirrors audit_pi_residual.py).
SURGICAL_COLS = {"IsValidCustomer", "IsCreditReportValidCB", "IsValidETM"}
CANONICAL_COLS = {"PlayerLevelID", "Club", "ClubID", "PlayerLevel", "Tier", "CurrentTier"}
ALREADY_CORRECT_MARKERS = (
    "tracked by GuruStatusID",
    "PI is tracked by GuruStatusID",
)
CANONICAL_PLAYERLEVEL = (
    "Customer player-level tier. FK to DWH_dbo.Dim_PlayerLevel. "
    "Per dictionary (verified 2026-05-13): 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, "
    "4=Internal (in-house / eToro-employee accounts), 5=Silver, 6=Platinum Plus, "
    "7=Diamond. NOT a Popular Investor signal (PI is tracked by GuruStatusID). "
    "NOT a demo flag (demo is AccountTypeID=2). Default=0. "
    "(Tier 2 - DWH_dbo.Dim_PlayerLevel)"
)
PI_PHRASE = re.compile(r"Popular[\s\-]+Investor", re.IGNORECASE)

# Columns where the dictionary's Name value is a poor swap for the wiki's
# clean label and would degrade readability. DWH_dbo.Dim_Currency stores
# composite "<Country>, <Currency>" strings (e.g., "United States of America,
# US Dollar") -- the wiki keeps the ISO code (USD, EUR, GBP) which is more
# useful for both humans and SQL. Skip these in .md remediation.
SKIP_CODEPOINT_COLUMNS = {"CurrencyID", "Currency"}

# Markdown column-table row regex.
# Matches "| 17 | PlayerLevelID | int | YES | description... |".
# Captures the leading pipes (so we can rebuild the row) and the description.
ROW_RE = re.compile(
    r"^(?P<lead>\|\s*\d+\s*\|\s*)`?(?P<col>\w+)`?(?P<mid>\s*\|[^|\n]*\|[^|\n]*\|\s*)"
    r"(?P<desc>[^|\n]*)(?P<tail>\|\s*)$"
)


def _verdict(column: str, codepoint: str, claimed: str,
             file_relpath: str, truth: dict) -> tuple[str, str]:
    """Return (verdict, truth_name)."""
    key = _resolve_truth_key(column, file_relpath, truth)
    if key is None:
        return "UNRESOLVED_DICTIONARY", ""
    t = truth[key]
    rows = t.get("rows") or {}
    if not rows:
        return "UNRESOLVED_DICTIONARY", ""
    truth_name = rows.get(codepoint)
    if truth_name is None:
        return "UNKNOWN_CODEPOINT", ""
    nc = _normalize(claimed)
    nt = _normalize(truth_name)
    if nc == nt:
        return "MATCH", truth_name
    if nc and nt.startswith(nc + " "):
        return "MATCH", truth_name
    return "MISMATCH", truth_name


def _patch_desc(col: str, desc: str, file_relpath: str,
                truth: dict, hits: list[dict]) -> str:
    """Apply codepoint REPLACE substitutions to a description cell."""
    if col in SKIP_CODEPOINT_COLUMNS:
        return desc
    out = desc
    seen: set[tuple[str, str, str]] = set()
    for em in list(ENUM_NEQ.finditer(out)) + list(ENUM_PAREN.finditer(out)):
        cp = em.group("n")
        raw = em.group("label")
        claimed = _trim_label(raw)
        if not claimed or claimed.lower() in NOISE_LABELS:
            continue
        if (col, cp, claimed) in seen:
            continue
        seen.add((col, cp, claimed))
        v, truth_name = _verdict(col, cp, claimed, file_relpath, truth)
        if v == "MISMATCH":
            # Replace `<n>=<claimed>` with `<n>=<truth>` (or paren form).
            target_eq = f"{cp}={claimed}"
            target_eq_space = f"{cp} = {claimed}"
            target_paren = f"({cp}) {claimed}"
            for tgt in (target_eq, target_eq_space, target_paren):
                if tgt in out:
                    repl = tgt.replace(claimed, truth_name)
                    out = out.replace(tgt, repl)
                    hits.append({
                        "file_relpath": file_relpath, "column": col,
                        "fix_kind": "codepoint",
                        "detail": f"{tgt!r} -> {repl!r}"
                    })
                    break
    return out


def _maybe_pi(col: str, desc: str, file_relpath: str,
              hits: list[dict]) -> str:
    """Apply surgical (Popular Investor -> Internal) or canonical PI fix."""
    if not PI_PHRASE.search(desc):
        return desc
    if any(m in desc for m in ALREADY_CORRECT_MARKERS):
        return desc
    if col in SURGICAL_COLS:
        new = PI_PHRASE.sub("Internal", desc)
        hits.append({
            "file_relpath": file_relpath, "column": col,
            "fix_kind": "pi-surgical",
            "detail": f"{desc[:80]} -> {new[:80]}"
        })
        return new
    if col in CANONICAL_COLS:
        hits.append({
            "file_relpath": file_relpath, "column": col,
            "fix_kind": "pi-canonical",
            "detail": f"{desc[:80]} -> [canonical]"
        })
        return CANONICAL_PLAYERLEVEL
    return desc


def patch_file(p: Path, truth: dict, apply: bool) -> list[dict]:
    text = p.read_text(encoding="utf-8")
    hits: list[dict] = []
    new_lines: list[str] = []
    rel = str(p.relative_to(REPO)).replace("\\", "/")
    for line in text.splitlines():
        m = ROW_RE.match(line)
        if not m:
            new_lines.append(line)
            continue
        col = m.group("col")
        desc = m.group("desc")
        new_desc = _patch_desc(col, desc, rel, truth, hits)
        new_desc = _maybe_pi(col, new_desc, rel, hits)
        if new_desc != desc:
            new_lines.append(
                m.group("lead") + col + m.group("mid") + new_desc + m.group("tail")
            )
        else:
            new_lines.append(line)
    if hits and apply:
        p.write_text("\n".join(new_lines) + ("\n" if text.endswith("\n") else ""),
                     encoding="utf-8")
    return hits


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--audit-only", action="store_true")
    args = ap.parse_args()

    if not TRUTH_JSON.is_file():
        raise SystemExit(f"Missing {TRUTH_JSON}. Run fetch_dictionary_truth.py.")
    truth = json.loads(TRUTH_JSON.read_text(encoding="utf-8"))

    all_hits: list[dict] = []
    n_patched = 0
    for p in WIKI.rglob("*.md"):
        hits = patch_file(p, truth, apply=not args.audit_only)
        if hits:
            all_hits.extend(hits)
            n_patched += 1

    if not all_hits:
        print("No .md slop hits found.")
        return

    by_kind: dict[str, int] = defaultdict(int)
    by_col: dict[str, int] = defaultdict(int)
    files = set()
    for h in all_hits:
        by_kind[h["fix_kind"]] += 1
        by_col[h["column"]] += 1
        files.add(h["file_relpath"])

    print(f"Total fragment fixes:           {len(all_hits)}")
    print(f"Files affected:                 {len(files)}")
    print(f"Distinct columns affected:      {len(by_col)}")
    print()
    print("By fix_kind:")
    for k, n in sorted(by_kind.items(), key=lambda kv: -kv[1]):
        print(f"  {k:<24} {n}")
    print()
    print("Top columns:")
    for c, n in sorted(by_col.items(), key=lambda kv: -kv[1])[:25]:
        print(f"  {c:<32} {n}")

    OUT_REPORT.parent.mkdir(parents=True, exist_ok=True)
    with OUT_REPORT.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["file_relpath", "column", "fix_kind", "detail"])
        for h in all_hits:
            w.writerow([h["file_relpath"], h["column"], h["fix_kind"], h["detail"]])
    print(f"\nWrote report: {OUT_REPORT.relative_to(REPO)}")
    if args.audit_only:
        print("[--audit-only] .md files NOT patched.")
    else:
        print(f"Patched {n_patched} .md file(s) in place.")


if __name__ == "__main__":
    main()
