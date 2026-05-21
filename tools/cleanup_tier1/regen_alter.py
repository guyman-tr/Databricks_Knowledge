#!/usr/bin/env python3
"""Regenerate `.alter.sql` ALTER COLUMN ... COMMENT lines from corrected wiki MDs.

Wraps `tools/merge_wiki_column_comments_into_alter.py` and extends it to also
UPDATE existing ALTER COLUMN comment lines whose text disagrees with the wiki's
current §4 Elements description (the merge tool only fills missing lines).
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "tools"))

# Re-use the wiki column catalog parser and SQL-comment helpers from the
# existing tool — single source of truth for what ends up in alter.sql.
from merge_wiki_column_comments_into_alter import (
    parse_wiki_column_catalog,
    format_comment_line,
    sql_string_for_comment,
    quote_column_name,
)

_ALTER_COMMENT_RE = re.compile(
    r"^(\s*ALTER\s+TABLE\s+\S+\s+ALTER\s+COLUMN\s+)(`?[A-Za-z0-9_./%&+\- ]+`?)"
    r"(\s+COMMENT\s+')(.*)('\s*;\s*)$",
    re.IGNORECASE,
)


def _strip_col_quote(col: str) -> str:
    return col.strip().strip("`")


def _rewrite_existing_comments(alter_text: str, wiki_desc: dict[str, str]) -> tuple[str, list[tuple[str, str, str]]]:
    """Walk alter.sql line-by-line; for each ALTER ... COMMENT 'X' line where
    the column appears in wiki_desc and the SQL-escaped wiki desc differs,
    rewrite the line. Returns (new_text, list of (col, old_inner, new_inner))."""
    out_lines: list[str] = []
    changes: list[tuple[str, str, str]] = []
    for line in alter_text.splitlines(keepends=True):
        m = _ALTER_COMMENT_RE.match(line)
        if not m:
            out_lines.append(line)
            continue
        col = _strip_col_quote(m.group(2))
        if col not in wiki_desc:
            out_lines.append(line)
            continue
        new_inner = sql_string_for_comment(wiki_desc[col])
        old_inner = m.group(4)
        if old_inner == new_inner:
            out_lines.append(line)
            continue
        new_line = f"{m.group(1)}{m.group(2)}{m.group(3)}{new_inner}{m.group(5)}"
        # preserve trailing newline if line ended with one
        if line.endswith("\n") and not new_line.endswith("\n"):
            new_line = new_line + "\n"
        out_lines.append(new_line)
        changes.append((col, old_inner, new_inner))
    return "".join(out_lines), changes


def regen_alter_for_wiki(wiki_md: Path, *, apply: bool) -> dict:
    """Regenerate alter.sql for a single wiki MD. Returns status dict."""
    alt = wiki_md.with_name(wiki_md.stem + ".alter.sql")
    if not alt.exists():
        return {"wiki": str(wiki_md.relative_to(REPO)).replace("\\", "/"),
                "alter": "",
                "status": "no_alter_file",
                "changes": 0,
                "appended": 0}
    md_text = wiki_md.read_text(encoding="utf-8", errors="replace")
    wiki_cols = parse_wiki_column_catalog(md_text)
    wiki_desc = dict(wiki_cols)
    if not wiki_desc:
        return {"wiki": str(wiki_md.relative_to(REPO)).replace("\\", "/"),
                "alter": str(alt.relative_to(REPO)).replace("\\", "/"),
                "status": "no_wiki_cols",
                "changes": 0,
                "appended": 0}
    alter_text = alt.read_text(encoding="utf-8", errors="replace")
    new_text, changes = _rewrite_existing_comments(alter_text, wiki_desc)
    # ALSO call merge to fill any truly-missing lines
    from merge_wiki_column_comments_into_alter import merge_alter_file
    if apply:
        if new_text != alter_text:
            alt.write_text(new_text, encoding="utf-8")
        _, _msg = merge_alter_file(alt, wiki_cols)
    return {"wiki": str(wiki_md.relative_to(REPO)).replace("\\", "/"),
            "alter": str(alt.relative_to(REPO)).replace("\\", "/"),
            "status": "ok",
            "changes": len(changes),
            "appended": 0,
            "diff_sample": changes[:3]}


def regen_for_corrections(corrections_path: Path, apply: bool) -> int:
    """Walk corrections CSV, find unique wiki paths, regen each one."""
    wikis: list[Path] = []
    seen: set[Path] = set()
    with corrections_path.open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            wp = row.get("wiki_path") or ""
            if not wp:
                continue
            p = REPO / wp
            if p in seen:
                continue
            seen.add(p)
            if p.exists():
                wikis.append(p)
    n_changed = 0
    for w in wikis:
        res = regen_alter_for_wiki(w, apply=apply)
        if res["changes"]:
            n_changed += 1
            mode = "UPDATE" if apply else "would-update"
            print(f"  {mode} {res['alter']} ({res['changes']} column comment edits)")
    print(f"Wikis scanned: {len(wikis)}, alter files with changes: {n_changed}")
    return n_changed


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--corrections",
                    default=str(REPO / "knowledge" / "_tier1_truth_corrections.csv"))
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--wiki", default="",
                    help="If set, regen only this single wiki path (relative to repo)")
    args = ap.parse_args()
    if args.wiki:
        p = REPO / args.wiki
        if not p.exists():
            print(f"not found: {p}")
            sys.exit(1)
        res = regen_alter_for_wiki(p, apply=args.apply)
        print(res)
        return
    regen_for_corrections(Path(args.corrections), apply=args.apply)


if __name__ == "__main__":
    main()
