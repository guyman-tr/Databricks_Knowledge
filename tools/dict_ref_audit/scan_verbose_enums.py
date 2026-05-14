"""Scan every wiki .md Elements table for verbose dictionary enumerations.

Threshold: a description cell with 3 or more `N=Label` patterns is flagged
as a candidate for "FK to Dim_X" replacement. Under-threshold cells (e.g.
`0=No, 1=Yes`) are left alone.

Writes `knowledge/_dict_ref_candidates.csv` with one row per offending
Element row.
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"

sys.path.insert(0, str(REPO / "tools"))
from merge_wiki_column_comments_into_alter import (  # type: ignore
    _ELEMENTS_HEADER_RE,
    _NEXT_TOP_SECTION_RE,
    _is_sql_type_cell,
    is_plausible_column_name,
)

# A single "N=Label" enum entry. The label is non-greedy and terminates at
# a delimiter (comma, semicolon, pipe, closing-paren, period-space, end-of-line,
# or the words "or"/"and"/"else"). This prevents the label from swallowing
# trailing prose like ". Drives how the affiliate is compensated.".
ENUM_ENTRY_RE = re.compile(
    r"(?<![A-Za-z0-9_])(?P<n>-?\d+)\s*=\s*"
    r"(?P<label>[A-Za-z\[][A-Za-z0-9 &/+'_\-\(\)\]]{0,40}?)"
    r"(?=\s*(?:[,;\|\)]|\.\s|\.$|$|\bor\b|\band\b|\belse\b))",
)

THRESHOLD = 3

# Wiki paths to ignore entirely
SKIP_PATH_PARTS = {"_drafts", "_de_existing"}


def _elements_span(text: str) -> tuple[int, int] | None:
    m = _ELEMENTS_HEADER_RE.search(text)
    if not m:
        return None
    start_offset = m.end()
    nxt = _NEXT_TOP_SECTION_RE.search(text[start_offset:])
    end_offset = start_offset + nxt.start() if nxt else len(text)
    return start_offset, end_offset


def _parse_row(cells: list[str]) -> tuple[str, str] | None:
    """Pull (column_name, description) from a markdown table row's cells."""
    type_idxs = [i for i, c in enumerate(cells) if _is_sql_type_cell(c)]
    col_name = ""
    type_idx = -1
    for cand_idx in type_idxs:
        for j in range(cand_idx):
            cand = cells[j].strip().strip("`")
            if is_plausible_column_name(cand):
                col_name = cand
                type_idx = cand_idx
                break
        if col_name:
            break
    if not col_name:
        return None
    desc = ""
    _SKIP = {"", "NULL", "NOT NULL", "YES", "NO", "0", "1", "TRUE", "FALSE",
             "---", "------"}
    for k in range(len(cells) - 1, type_idx, -1):
        v = cells[k].strip()
        if v and v.upper() not in _SKIP:
            desc = v
            break
    if not desc:
        return None
    return col_name, desc


def parse_elements_rows(text: str) -> list[tuple[int, str, str]]:
    """Return [(line_no_1_indexed, column_name, description)] inside Elements."""
    span = _elements_span(text)
    if not span:
        return []
    start_off, end_off = span
    lines = text.splitlines()
    # Compute the 0-indexed line range from byte offsets.
    start_line = text[:start_off].count("\n")
    end_line = text[:end_off].count("\n")
    out: list[tuple[int, str, str]] = []
    for idx in range(start_line, min(end_line + 1, len(lines))):
        line = lines[idx]
        raw = line.strip()
        if not raw.startswith("|"):
            continue
        parts = [p.strip() for p in raw.split("|")]
        cells = (parts[1:-1] if (parts and parts[0] == "" and parts[-1] == "")
                 else parts)
        if len(cells) < 3:
            continue
        parsed = _parse_row(cells)
        if parsed is None:
            continue
        out.append((idx + 1, parsed[0], parsed[1]))
    return out


def find_enum_matches(desc: str) -> list[tuple[int, str, int, int]]:
    """Return [(n, label, start_pos, end_pos)] for each enum entry in desc."""
    res = []
    for m in ENUM_ENTRY_RE.finditer(desc):
        try:
            n = int(m.group("n"))
        except (TypeError, ValueError):
            continue
        label = m.group("label").strip().strip(",.")
        res.append((n, label, m.start(), m.end()))
    return res


def extract_enum_block(desc: str, matches: list) -> str:
    """Return the contiguous slice of `desc` covering all enum matches."""
    if not matches:
        return ""
    return desc[matches[0][2]:matches[-1][3]]


def main() -> int:
    md_files = sorted(WIKI.rglob("*.md"))
    md_files = [
        p for p in md_files
        if not p.name.endswith(".lineage.md")
        and not p.name.endswith(".review-needed.md")
        and not any(part in SKIP_PATH_PARTS for part in p.parts)
    ]
    print(f"Scanning {len(md_files)} wiki .md files...")

    rows = []
    for md in md_files:
        try:
            text = md.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line_no, col_name, desc in parse_elements_rows(text):
            matches = find_enum_matches(desc)
            if len(matches) < THRESHOLD:
                continue
            enum_block = extract_enum_block(desc, matches)
            claimed = "; ".join(f"{n}={label}" for n, label, _, _ in matches)
            rel = md.relative_to(REPO).as_posix()
            rows.append({
                "claim_id": f"{rel}::{col_name}::L{line_no}",
                "wiki_md": rel,
                "line_no": line_no,
                "column_name": col_name,
                "n_enum_entries": len(matches),
                "claimed_pairs": claimed,
                "current_desc": desc,
                "enum_block": enum_block,
            })

    out = REPO / "knowledge" / "_dict_ref_candidates.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=[
            "claim_id", "wiki_md", "line_no", "column_name",
            "n_enum_entries", "claimed_pairs", "current_desc", "enum_block",
        ])
        w.writeheader()
        for r in rows:
            w.writerow(r)

    print(f"Wrote {out.relative_to(REPO).as_posix()}: {len(rows)} candidate rows")
    # Per-column summary for quick eyeballing
    from collections import Counter
    by_col = Counter(r["column_name"] for r in rows)
    print(f"\nTop columns by candidate count:")
    for col, n in by_col.most_common(15):
        print(f"  {n:>4}  {col}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
