#!/usr/bin/env python3
"""
Wiki *.alter.sql — Unity Catalog target validation.

1) **Default (structural):** every `ALTER TABLE <name>` must be a valid dotted
   identifier (letters, digits, underscore, dots only — **no spaces**). This
   catches prose accidentally pasted as the object name (e.g. "Not directly
   exported...", "Likely already in UC...").

2) **Optional `--mapping`:** `<name>` must appear in
   `knowledge/synapse/Wiki/_generic_pipeline_mapping.json` as `uc_table`, either
   exactly or prefixed with `main.` (both forms are accepted).

3) **ALTER COLUMN sanity (2026-03-30):** reject lines that look like
   `ALTER COLUMN Tier 1` … `Tier 5` (documentation tiers mistaken for columns),
   and `ALTER COLUMN Foo/Bar` without backticks (Databricks requires `` `Foo/Bar` ``).

The mapping file is a point-in-time backup; `--mapping` may report many rows until
the snapshot matches all generated alters.

Usage:
  python tools/audit_alter_uc_mapping.py
  python tools/audit_alter_uc_mapping.py --mapping
  python tools/audit_alter_uc_mapping.py path/to/File.alter.sql
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPPING_PATH = ROOT / "knowledge/synapse/Wiki/_generic_pipeline_mapping.json"
WIKI_ROOT = ROOT / "knowledge/synapse/Wiki"

ALTER_TABLE_RE = re.compile(
    r"^ALTER\s+TABLE\s+(\S+)\s+",
    re.IGNORECASE | re.MULTILINE,
)

# Valid UC path fragment: no spaces, no prose — catalog.schema.table style
VALID_DOTTED_ID = re.compile(r"^[A-Za-z_][A-Za-z0-9_.]*$")

# Documentation tier accidentally emitted as a column name (not a real DDL column)
BOGUS_TIER_COLUMN = re.compile(r"ALTER\s+COLUMN\s+Tier\s+\d+\b", re.IGNORECASE)


def bad_unquoted_slash_column(line: str) -> bool:
    """Column token contains / but is not backtick-wrapped (Databricks needs `` `a/b` ``)."""
    if "ALTER COLUMN" not in line or "/" not in line:
        return False
    m = re.search(
        r"ALTER\s+COLUMN\s+(?!`)(\S+)\s+(COMMENT|SET\s+TAGS)\b",
        line,
        re.IGNORECASE,
    )
    if not m:
        return False
    col = m.group(1).strip()
    if col.startswith("`"):
        return False
    if col.startswith("["):
        return False  # SQL Server bracket identifier; migrate to backticks separately
    return "/" in col


def load_valid_targets() -> set[str]:
    data = json.loads(MAPPING_PATH.read_text(encoding="utf-8"))
    mappings = data.get("mappings") or []
    out: set[str] = set()
    for row in mappings:
        uc = row.get("uc_table")
        if isinstance(uc, str) and uc.strip():
            u = uc.strip()
            out.add(u)
            out.add(f"main.{u}")
    return out


def scan_file(
    path: Path, valid: set[str] | None, require_mapping: bool
) -> list[tuple[int, str, str]]:
    text = path.read_text(encoding="utf-8")
    issues: list[tuple[int, str, str]] = []
    for m in ALTER_TABLE_RE.finditer(text):
        target = m.group(1).strip("`")
        line_no = text.count("\n", 0, m.start()) + 1
        if not VALID_DOTTED_ID.match(target):
            issues.append((line_no, target, "invalid_dotted_identifier"))
        elif require_mapping and valid is not None and target not in valid:
            issues.append((line_no, target, "not_in_generic_pipeline_mapping"))
    return issues


def scan_column_lines(path: Path) -> list[tuple[int, str, str]]:
    """ALTER COLUMN anti-patterns that break Databricks deploy."""
    text = path.read_text(encoding="utf-8")
    issues: list[tuple[int, str, str]] = []
    for line_no, line in enumerate(text.splitlines(), 1):
        if BOGUS_TIER_COLUMN.search(line):
            issues.append((line_no, line.strip()[:100], "bogus_tier_as_column"))
        if bad_unquoted_slash_column(line):
            issues.append((line_no, line.strip()[:100], "unquoted_slash_column"))
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit wiki alter.sql UC targets.")
    parser.add_argument(
        "--mapping",
        action="store_true",
        help="Require each target to exist in _generic_pipeline_mapping.json",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        help="Specific .alter.sql files (default: all under knowledge/synapse/Wiki)",
    )
    args = parser.parse_args()

    valid: set[str] | None = None
    if args.mapping:
        if not MAPPING_PATH.is_file():
            print(f"Missing mapping file: {MAPPING_PATH}", file=sys.stderr)
            return 2
        valid = load_valid_targets()
        if not valid:
            print("No uc_table entries found in mapping JSON.", file=sys.stderr)
            return 2

    if args.paths:
        files: list[Path] = []
        for p in args.paths:
            pp = Path(p).resolve()
            if pp.is_dir():
                files.extend(sorted(pp.rglob("*.alter.sql")))
            elif pp.is_file():
                files.append(pp)
        files = sorted(set(files))
    else:
        files = sorted(WIKI_ROOT.rglob("*.alter.sql"))

    total = 0
    for fp in files:
        if not fp.is_file():
            print(f"Skip (not a file): {fp}", file=sys.stderr)
            continue
        rel = fp.relative_to(ROOT)
        for line_no, target, reason in scan_file(fp, valid, args.mapping):
            total += 1
            print(f"{rel}:{line_no}: {reason}: {target}")
        for line_no, snippet, reason in scan_column_lines(fp):
            total += 1
            print(f"{rel}:{line_no}: {reason}: {snippet}")

    if total:
        msg = f"{total} issue(s)."
        if not args.mapping:
            msg += " Re-run with --mapping to check _generic_pipeline_mapping.json."
        print(msg, file=sys.stderr)
        return 1

    mode = "structural + mapping" if args.mapping else "structural"
    print(f"OK ({mode}): {len(files)} alter file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
