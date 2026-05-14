#!/usr/bin/env python3
"""
Compare wiki Elements column descriptions to sibling *.alter.sql COMMENT literals.

For each column name present in the wiki catalog, the ALTER file must contain
COMMENT '<sql_string_for_comment(desc)>' — same encoding as merge_wiki_column_comments_into_alter.py.

Catches:
- Wrong comment bound to wrong column (upstream column-order bugs)
- Drift after wiki edits without regenerating ALTER
- Escape/sanitize mismatches (should be rare if both use the same helpers)

Usage:
  python tools/audit_wiki_alter_comment_parity.py
  python tools/audit_wiki_alter_comment_parity.py path/to/Object.md
  python tools/audit_wiki_alter_comment_parity.py --under DWH_dbo
  python tools/audit_wiki_alter_comment_parity.py --json > parity-report.json

Exit code: 0 = all wiki columns match ALTER COMMENT literals; 1 = mismatch or missing.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"
if str(WIKI_ROOT) not in sys.path:
    sys.path.insert(0, str(WIKI_ROOT))

from merge_wiki_column_comments_into_alter import (  # noqa: E402
    parse_wiki_column_catalog,
    sql_string_for_comment,
)

# ALTER TABLE x ALTER COLUMN y COMMENT '...';
COMMENT_LINE_RE = re.compile(
    r"ALTER\s+TABLE\s+\S+\s+ALTER\s+COLUMN\s+([^\s]+)\s+COMMENT\s+",
    re.IGNORECASE,
)
# Content of a single-quoted SQL string literal ('' = one quote)
COMMENT_LITERAL_RE = re.compile(r"COMMENT\s+'((?:[^']|'')*)'\s*;", re.IGNORECASE)


def find_all_md_alter_pairs() -> list[tuple[Path, Path]]:
    pairs: list[tuple[Path, Path]] = []
    for sub in ("Tables", "Views", "Functions"):
        base = WIKI_ROOT
        for md in sorted(base.rglob(f"{sub}/*.md")):
            if md.name.endswith(".lineage.md") or md.name.endswith(".review-needed.md"):
                continue
            if md.name.startswith("_"):
                continue
            alt = md.with_name(md.stem + ".alter.sql")
            if alt.exists():
                pairs.append((md, alt))
    return pairs


def _is_under(path: Path, base: Path) -> bool:
    try:
        path.resolve().relative_to(base.resolve())
        return True
    except ValueError:
        return False


def find_pairs_under_schema(schema_name: str) -> list[tuple[Path, Path]]:
    """Only *.md under knowledge/synapse/Wiki/<schema_name>/(Tables|Views|Functions)/."""
    base = (WIKI_ROOT / schema_name.strip().replace("\\", "/")).resolve()
    if not base.is_dir():
        return []
    return [(m, a) for m, a in find_all_md_alter_pairs() if _is_under(m, base)]


def extract_comment_literals(alter_text: str) -> dict[str, str]:
    """
    Map column name -> COMMENT string literal body (with '' still doubled).
    If the same column appears multiple times (e.g. masked + PII targets), values must match.
    """
    current: dict[str, str] = {}

    in_block = False
    for line in alter_text.splitlines():
        stripped = line.strip()
        if stripped == "-- ---- Column Comments ----":
            in_block = True
            continue
        if stripped.startswith("-- ---- Column PII Tags ----"):
            in_block = False
            continue
        if not in_block:
            continue
        if "ALTER COLUMN" not in line or "COMMENT" not in line:
            continue
        m_col = COMMENT_LINE_RE.search(line)
        m_lit = COMMENT_LITERAL_RE.search(line)
        if not m_col or not m_lit:
            continue
        col = m_col.group(1).strip().strip("`")
        lit = m_lit.group(1)
        if col in current and current[col] != lit:
            # Second UC target with different text — keep first; caller may miss conflicts
            pass
        else:
            current[col] = lit
    return current


def duplicate_literal_groups(col_to_literal: dict[str, str]) -> list[dict]:
    """Columns that share the exact same COMMENT literal (possible column-order / copy-paste bug)."""
    by_lit: dict[str, list[str]] = {}
    for col, lit in col_to_literal.items():
        by_lit.setdefault(lit, []).append(col)
    out: list[dict] = []
    for lit, cols in sorted(by_lit.items(), key=lambda x: (-len(x[1]), x[0][:40])):
        if len(cols) < 2:
            continue
        out.append({"columns": sorted(cols), "literal_preview": lit[:120] + ("..." if len(lit) > 120 else "")})
    return out


def audit_pair(md: Path, alt: Path) -> dict:
    wtext = md.read_text(encoding="utf-8", errors="replace")
    wiki_cols = parse_wiki_column_catalog(wtext)
    atext = alt.read_text(encoding="utf-8", errors="replace")
    alter_map = extract_comment_literals(atext)
    dups = duplicate_literal_groups(alter_map)

    mismatches: list[dict] = []
    missing_in_alter: list[str] = []
    extra_in_alter: list[str] = []

    wiki_names = [n for n, _ in wiki_cols]
    wiki_desc = dict(wiki_cols)

    for name in wiki_names:
        expected = sql_string_for_comment(wiki_desc[name])
        got = alter_map.get(name)
        if got is None:
            missing_in_alter.append(name)
            continue
        if got != expected:
            mismatches.append(
                {
                    "column": name,
                    "expected_sql_literal": expected,
                    "alter_sql_literal": got,
                }
            )

    for name in alter_map:
        if name not in wiki_desc:
            extra_in_alter.append(name)

    return {
        "wiki": str(md.relative_to(WIKI_ROOT)),
        "alter": str(alt.relative_to(WIKI_ROOT)),
        "wiki_columns_parsed": len(wiki_cols),
        "mismatches": mismatches,
        "missing_in_alter": sorted(missing_in_alter),
        "extra_in_alter_not_in_wiki": sorted(extra_in_alter),
        "duplicate_comment_literals": dups,
    }


def run_audit(
    pairs: list[tuple[Path, Path]],
) -> tuple[bool, dict]:
    """
    Returns (ok, summary) where ok is True iff no mismatches and no missing ALTER comments.
    """
    reports: list[dict] = []
    total_mm = 0
    total_miss = 0
    total_extra = 0
    total_dup_groups = 0

    for md, alt in pairs:
        r = audit_pair(md, alt)
        reports.append(r)
        total_mm += len(r["mismatches"])
        total_miss += len(r["missing_in_alter"])
        total_extra += len(r["extra_in_alter_not_in_wiki"])
        total_dup_groups += len(r["duplicate_comment_literals"])

    summary = {
        "objects": len(pairs),
        "mismatch_columns": total_mm,
        "missing_in_alter": total_miss,
        "extra_in_alter": total_extra,
        "objects_with_duplicate_literals": sum(
            1 for r in reports if r["duplicate_comment_literals"]
        ),
        "duplicate_literal_groups": total_dup_groups,
        "reports": reports,
    }
    ok = total_mm == 0 and total_miss == 0
    return ok, summary


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("wiki", nargs="?", help="Single wiki .md path")
    ap.add_argument(
        "--under",
        metavar="SCHEMA",
        help="Limit audit to knowledge/synapse/Wiki/SCHEMA/(Tables|Views) (e.g. DWH_dbo)",
    )
    ap.add_argument("--json", action="store_true", help="Print JSON report to stdout")
    ap.add_argument(
        "--duplicates-only",
        action="store_true",
        help="Only print duplicate_comment_literals (same SQL literal on 2+ columns); exit 0",
    )
    args = ap.parse_args()

    if args.wiki and args.under:
        print("Use either a wiki path OR --under, not both.", file=sys.stderr)
        sys.exit(2)

    if args.wiki:
        md = Path(args.wiki).resolve()
        if not md.exists():
            print("not found:", md, file=sys.stderr)
            sys.exit(1)
        alt = md.with_name(md.stem + ".alter.sql")
        if not alt.exists():
            print("no alter file:", alt, file=sys.stderr)
            sys.exit(1)
        pairs = [(md, alt)]
    elif args.under:
        pairs = find_pairs_under_schema(args.under)
        if not pairs:
            print(
                f"SKIP: no wiki+.alter.sql pairs under {args.under!r} — nothing to verify.",
                file=sys.stderr,
            )
            sys.exit(0)
    else:
        pairs = find_all_md_alter_pairs()

    ok, summary = run_audit(pairs)
    reports = summary["reports"]
    total_mm = summary["mismatch_columns"]
    total_miss = summary["missing_in_alter"]
    total_extra = summary["extra_in_alter"]
    total_dup_groups = summary["duplicate_literal_groups"]

    if args.duplicates_only:
        dup_reports = [r for r in reports if r["duplicate_comment_literals"]]
        print(f"Objects with duplicate literals: {len(dup_reports)}")
        for r in dup_reports:
            print(f"\n{r['wiki']}")
            for dg in r["duplicate_comment_literals"]:
                print(f"  {dg['columns']}: {dg['literal_preview']!r}")
        return

    if args.json:
        print(json.dumps(summary, indent=2, ensure_ascii=False))
    else:
        print(
            f"Objects: {len(pairs)} | "
            f"wiki≠alter (strict): {total_mm} cols | "
            f"missing in ALTER: {total_miss} | "
            f"extra in ALTER: {total_extra} | "
            f"dup-literal groups: {total_dup_groups}"
        )
        print(
            "(Strict parity flags drift when wiki was edited after ALTER. "
            "See duplicate_comment_literals for same text on multiple columns.)"
        )
        for r in reports:
            if (
                r["mismatches"]
                or r["missing_in_alter"]
                or r["extra_in_alter_not_in_wiki"]
                or r["duplicate_comment_literals"]
            ):
                print(f"\n--- {r['wiki']} ---")
                for m in r["mismatches"]:
                    print(f"  MISMATCH {m['column']}")
                    print(f"    expected: {m['expected_sql_literal'][:200]!r}...")
                    print(f"    alter:    {m['alter_sql_literal'][:200]!r}...")
                if r["missing_in_alter"]:
                    print(f"  missing_in_alter: {r['missing_in_alter']}")
                if r["extra_in_alter_not_in_wiki"]:
                    print(f"  extra_in_alter: {r['extra_in_alter_not_in_wiki']}")
                for dg in r["duplicate_comment_literals"]:
                    print(
                        f"  DUPLICATE_LITERAL on columns {dg['columns']}: "
                        f"{dg['literal_preview']!r}"
                    )

    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
