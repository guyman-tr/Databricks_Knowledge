#!/usr/bin/env python3
"""
Emit ALTER TABLE ... ALTER COLUMN ... COMMENT lines from a **name-based** JSON mapping.

Use this instead of ordinal / zip-based one-off scripts that produced wrong comments on
downstream UC objects (see knowledge/synapse/Wiki/README_downstream_column_comments.md).

Each mapping row binds target_column to text from either:
  - source_alter: sibling .alter.sql COMMENT for source_column (default: same as target_column)
  - source_wiki: wiki ## 4. Elements description for source_column (default: same as target_column)

Encoding matches merge_wiki_column_comments_into_alter.sql_string_for_comment for wiki paths.

Usage:
  python tools/emit_downstream_comments_from_mapping.py \\
    knowledge/synapse/Wiki/_downstream_column_comment_map.json \\
    -o knowledge/synapse/Wiki/_downstream_column_comments.regenerated.sql
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"
if str(WIKI_ROOT) not in sys.path:
    sys.path.insert(0, str(WIKI_ROOT))

from audit_wiki_alter_comment_parity import extract_comment_literals  # noqa: E402
from merge_wiki_column_comments_into_alter import (  # noqa: E402
    parse_wiki_column_catalog,
    sql_string_for_comment,
)

_CACHE_ALTER: dict[str, dict[str, str]] = {}
_CACHE_WIKI: dict[str, dict[str, str]] = {}


def _load_alter_literals(path: Path) -> dict[str, str]:
    key = str(path.resolve())
    if key not in _CACHE_ALTER:
        text = path.read_text(encoding="utf-8", errors="replace")
        _CACHE_ALTER[key] = extract_comment_literals(text)
    return _CACHE_ALTER[key]


def _load_wiki_desc(path: Path) -> dict[str, str]:
    key = str(path.resolve())
    if key not in _CACHE_WIKI:
        text = path.read_text(encoding="utf-8", errors="replace")
        rows = parse_wiki_column_catalog(text)
        _CACHE_WIKI[key] = {n: d for n, d in rows}
    return _CACHE_WIKI[key]


def resolve_literal(repo_root: Path, col: dict) -> str:
    src_col = col.get("source_column") or col["target_column"]
    if "source_alter" in col:
        p = (repo_root / col["source_alter"]).resolve()
        if not p.is_file():
            raise FileNotFoundError(f"source_alter: {p}")
        m = _load_alter_literals(p)
        k = src_col.strip()
        # case-insensitive lookup for alter
        for name, lit in m.items():
            if name.lower() == k.lower():
                return lit
        raise KeyError(f"Column {k!r} not in COMMENT section of {p}")
    if "source_wiki" in col:
        p = (repo_root / col["source_wiki"]).resolve()
        if not p.is_file():
            raise FileNotFoundError(f"source_wiki: {p}")
        m = _load_wiki_desc(p)
        k = src_col.strip()
        for name, desc in m.items():
            if name.lower() == k.lower():
                return sql_string_for_comment(desc)
        raise KeyError(f"Column {k!r} not in wiki Elements: {p}")
    raise ValueError("Each column needs source_alter or source_wiki")


def emit(data: dict, repo_root: Path) -> str:
    lines: list[str] = []
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    lines.append("-- ============================================================")
    lines.append("-- Downstream column COMMENT (from mapping JSON - name-based)")
    lines.append(f"-- Generated: {ts} UTC | tools/emit_downstream_comments_from_mapping.py")
    lines.append("-- See: knowledge/synapse/Wiki/README_downstream_column_comments.md")
    lines.append("-- ============================================================")
    lines.append("")

    tables = data.get("tables") or []
    for t in tables:
        fqn = t["uc_fqn"]
        cols = t.get("columns") or []
        lines.append(f"-- ----------------------------------------")
        lines.append(f"-- {fqn} ({len(cols)} columns)")
        lines.append(f"-- ----------------------------------------")
        for c in cols:
            tgt = c["target_column"]
            lit = resolve_literal(repo_root, c)
            lines.append(
                f"ALTER TABLE {fqn} ALTER COLUMN `{tgt}` COMMENT '{lit}';"
            )
        lines.append("")

    return "\n".join(lines) + "\n"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("mapping_json", type=Path, help="Path to _downstream_column_comment_map.json")
    ap.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Write SQL here (default: stdout)",
    )
    args = ap.parse_args()

    path = args.mapping_json.resolve()
    if not path.is_file():
        print("not found:", path, file=sys.stderr)
        sys.exit(1)

    data = json.loads(path.read_text(encoding="utf-8"))
    sql = emit(data, ROOT)
    if args.output:
        args.output.write_text(sql, encoding="utf-8")
        print("Wrote", args.output)
    else:
        print(sql, end="")


if __name__ == "__main__":
    main()
