"""G3: build a stratified review sheet from a proposed_fixes.csv.

Picks 30 rows across the failure surface and renders each as a markdown
review card with the full upstream-climb hop trace so the reviewer can
verify methodology, not just the surface text.

Strata:
  - 3 SQL-derived rows (all of them — small population, every one matters)
  - 7 V_Liabilities rows (random) — the original benchmark wiki
  - 10 random from the rest (covers wiki passthrough + §3/alias buckets)
  - 10 additional random for breadth

Output:
    audits/_desc_quality_rewrite_corpusN/review_sheet.md
    audits/_desc_quality_rewrite_corpusN/review_sheet.csv  (machine-parseable)

The reviewer marks APPROVE / REJECT / EDIT in the sheet. The script does
NOT modify any wiki.

Usage:
    python tools/desc_quality/_build_review_sheet.py \
        --fixes audits/_desc_quality_rewrite_corpus9/proposed_fixes.csv \
        --sample-size 30 \
        --seed 42
"""

from __future__ import annotations

import argparse
import csv
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from tools.desc_quality.upstream_climber import (  # noqa: E402
    ClimbResult,
    climb_upstream,
)


_REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def _object_from_wiki_path(wiki_path: str) -> str:
    """Strip extension; rewriter passes object name without schema."""
    return Path(wiki_path).stem


def _is_sql_derived(row: dict) -> bool:
    return "sql-derived" in (row.get("new_description") or "")


def _is_v_liabilities(row: dict) -> bool:
    return "V_Liabilities" in (row.get("wiki_path") or "")


def _render_hop_trace(result: ClimbResult) -> str:
    """One-liner per hop with verdict + note."""
    lines: list[str] = []
    for i, h in enumerate(result.hops):
        chunks = [
            f"  hop[{i}]",
            f"{h.object_name}.{h.column_name}",
            f"[{h.verdict}]",
        ]
        if (h.source_cell or "").strip():
            chunks.append(f"src={h.source_cell.strip()[:80]!r}")
        if (h.note or "").strip():
            chunks.append(f"note={h.note.strip()[:80]!r}")
        lines.append(" ".join(chunks))
    if result.exhausted:
        lines.append(f"  EXHAUSTED reason={result.exhausted_reason}")
    if result.sql_terminal_expression:
        lines.append(
            f"  sql_walk: kind={result.sql_terminal_kind} "
            f"object={result.sql_object_name} "
            f"converge={result.sql_branches_converge} "
            f"leaves={len(result.sql_branch_leaves)}"
        )
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--fixes", required=True)
    ap.add_argument("--sample-size", type=int, default=30)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument(
        "--mode",
        choices=["stratified", "uniform"],
        default="stratified",
        help="stratified: 3 sql + 7 v_liabilities + N other; uniform: pure random",
    )
    ap.add_argument("--out-name", default="review_sheet",
                    help="Stem for review_sheet.md / review_sheet.csv")
    args = ap.parse_args()

    fixes = Path(args.fixes)
    if not fixes.is_absolute():
        fixes = (_REPO_ROOT / fixes).resolve()
    if not fixes.exists():
        print(f"Not found: {fixes}", file=sys.stderr)
        return 2

    with fixes.open(encoding="utf-8", newline="") as f:
        rows = list(csv.DictReader(f))

    rng = random.Random(args.seed)

    if args.mode == "uniform":
        # Pure random sample of size `--sample-size`.
        target_sql = sum(1 for r in rows if _is_sql_derived(r))
        target_vlia = 0
        target_other = 0
        rng.shuffle(rows)
        sample = rows[:args.sample_size]
        print(f"Sampling: {len(sample)} rows (uniform random)")
    else:
        # Stratify
        sql_rows = [r for r in rows if _is_sql_derived(r)]
        vlia_rows = [r for r in rows if _is_v_liabilities(r) and not _is_sql_derived(r)]
        other_rows = [r for r in rows if not _is_sql_derived(r) and not _is_v_liabilities(r)]

        rng.shuffle(vlia_rows)
        rng.shuffle(other_rows)

        target_sql = min(len(sql_rows), 3)
        target_vlia = min(len(vlia_rows), 7)
        target_other = max(args.sample_size - target_sql - target_vlia, 0)

        sample = []
        sample.extend(sql_rows[:target_sql])
        sample.extend(vlia_rows[:target_vlia])
        sample.extend(other_rows[:target_other])

        print(f"Sampling: {len(sample)} rows (sql={target_sql}, v_liabilities={target_vlia}, other={target_other})")

    # Build trace per sampled row
    sheet_lines: list[str] = []
    sheet_lines.append("# G3 Stratified Review Sheet\n")
    sheet_lines.append(f"Source: `{fixes.relative_to(_REPO_ROOT)}`\n")
    sheet_lines.append(f"Sample size: **{len(sample)}**  (sql={target_sql}, v_liabilities={target_vlia}, other={target_other})\n")
    sheet_lines.append(f"Random seed: {args.seed}\n")
    sheet_lines.append("Mark each item as `APPROVE / REJECT / EDIT(<your note>)` in the `VERDICT` line.\n")
    sheet_lines.append("---\n")

    csv_lines: list[list[str]] = [
        ["sample_idx", "stratum", "wiki_path", "column", "old_description", "new_description", "verdict_placeholder"]
    ]

    for idx, row in enumerate(sample, 1):
        if _is_sql_derived(row):
            stratum = "SQL-derived"
        elif _is_v_liabilities(row):
            stratum = "V_Liabilities"
        else:
            stratum = "other"

        wiki_path = row.get("wiki_path", "")
        col = row.get("column", "")
        old = row.get("old_description", "")
        new = row.get("new_description", "")

        obj = _object_from_wiki_path(wiki_path)
        try:
            res = climb_upstream(obj, col, hop_cap=5)
            trace = _render_hop_trace(res)
        except Exception as e:
            trace = f"  (climb failed: {e})"

        sheet_lines.append(f"## [{idx}/{len(sample)}] [{stratum}] `{col}` — `{Path(wiki_path).name}`\n")
        sheet_lines.append(f"- **wiki**: `{wiki_path}`")
        sheet_lines.append(f"- **column**: `{col}`")
        sheet_lines.append(f"- **old**: {old}")
        sheet_lines.append(f"- **new**: {new}")
        sheet_lines.append("- **trace**:")
        sheet_lines.append("```")
        sheet_lines.append(trace)
        sheet_lines.append("```")
        sheet_lines.append(f"- **VERDICT**: _________________________________")
        sheet_lines.append("\n---\n")

        csv_lines.append([str(idx), stratum, wiki_path, col, old, new, ""])

    out_md = fixes.parent / f"{args.out_name}.md"
    out_csv = fixes.parent / f"{args.out_name}.csv"
    out_md.write_text("\n".join(sheet_lines), encoding="utf-8")
    with out_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerows(csv_lines)

    print(f"Wrote: {out_md}")
    print(f"Wrote: {out_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
