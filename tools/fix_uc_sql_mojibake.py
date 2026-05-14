#!/usr/bin/env python3
"""
Repair mojibake and accidental spaces inside COMMENT in UC-oriented SQL files.

Uses knowledge/synapse/Wiki/_uc_comment_sanitize.py (same rules as generators).

Run from repo root:
  python tools/fix_uc_sql_mojibake.py path/to/file.sql
  python tools/fix_uc_sql_mojibake.py --all-wiki-sql
  python tools/fix_uc_sql_mojibake.py --check path/to/file.sql   # exit 1 if changes needed
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"


def _ensure_wiki_path() -> None:
    s = str(WIKI)
    if s not in sys.path:
        sys.path.insert(0, s)


def fix_content(text: str, sanitize_fn) -> str:
    text = sanitize_fn(text)
    text = re.sub(r"\bC\s+OMMENT\b", "COMMENT", text, flags=re.IGNORECASE)
    return text


def collect_sql_paths(explicit: list[str], all_wiki: bool) -> list[Path]:
    if explicit:
        out: list[Path] = []
        for p in explicit:
            path = Path(p)
            if path.is_dir():
                out.extend(sorted(path.rglob("*.sql")))
            elif path.suffix.lower() == ".sql":
                out.append(path)
        return sorted(set(out))
    if all_wiki:
        return sorted(WIKI.rglob("*.sql"))
    return []


def main() -> int:
    ap = argparse.ArgumentParser(description="Fix UC SQL comment mojibake / broken COMMENT keyword.")
    ap.add_argument("paths", nargs="*", help="SQL files or directories")
    ap.add_argument("--all-wiki-sql", action="store_true", help="Process every .sql under knowledge/synapse/Wiki")
    ap.add_argument("--check", action="store_true", help="Do not write; exit 1 if any file would change")
    args = ap.parse_args()

    targets = collect_sql_paths(args.paths, args.all_wiki_sql)
    if not targets:
        print("No SQL files to process.", file=sys.stderr)
        return 1

    _ensure_wiki_path()
    from _uc_comment_sanitize import sanitize_uc_sql_comment_text

    changed_any = False
    for path in targets:
        try:
            raw = path.read_text(encoding="utf-8")
        except OSError as e:
            print(f"SKIP {path}: {e}", file=sys.stderr)
            continue
        fixed = fix_content(raw, sanitize_uc_sql_comment_text)
        if fixed == raw:
            continue
        changed_any = True
        if args.check:
            print(f"Would modify: {path}")
            continue
        path.write_text(fixed, encoding="utf-8", newline="\n")
        print(f"Updated: {path}")

    if args.check:
        return 1 if changed_any else 0
    if not changed_any:
        print("No changes needed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
