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
        files = [Path(p) for p in args.paths]
    else:
        files = sorted(WIKI_ROOT.rglob("*.alter.sql"))

    total = 0
    for fp in files:
        if not fp.is_file():
            print(f"Skip (not a file): {fp}", file=sys.stderr)
            continue
        for line_no, target, reason in scan_file(fp, valid, args.mapping):
            total += 1
            rel = fp.relative_to(ROOT)
            print(f"{rel}:{line_no}: {reason}: {target}")

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
