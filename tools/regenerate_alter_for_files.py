"""Targeted, idempotent regenerator: rewrite the `-- ---- Column Comments ----`
block of one or more `.alter.sql` files from the current wiki MD, leaving
the header, table-comment block, table-tags block, PII-tags block, and
`-- == LAST EXECUTION ==` footer untouched.

Use this when a wiki MD has been edited and the deployed alter must be
brought back in sync, OR to repair historic drift artifacts (e.g. the
2026-05-03 tier/header drift that hit BI_DB_KYC_Panel and
eMoneyClientBalance).

Key behaviors:
  * Discovers paired wiki MD next to the alter (`.alter.sql` <-> `.md`).
  * Calls the canonical `parse_wiki_column_catalog` from
    `tools/merge_wiki_column_comments_into_alter.py` — same parser used by
    the merge tool and the scaffolder, so this stays in lockstep.
  * Validates every produced (column, comment) pair via
    `tools/uc_comment_validator.assert_comment_safe` — refuses to write
    anything that would re-introduce the historic drift.
  * Only replaces the Column Comments block; all other sections are byte-
    identical to the input file (including the LAST EXECUTION footer, so
    deploy state is preserved). Re-run safely as many times as you want.
  * Preserves the COLUMN ORDER from the wiki (== ETL/SP order), which
    matches the historic convention.

Usage:
  python tools/regenerate_alter_for_files.py path/to/X.alter.sql [path/to/Y.alter.sql ...]
  python tools/regenerate_alter_for_files.py --md path/to/X.md
  python tools/regenerate_alter_for_files.py --dry-run path/to/X.alter.sql
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

from merge_wiki_column_comments_into_alter import (
    parse_wiki_column_catalog,
    format_comment_line,
    quote_column_name,
)
from uc_comment_validator import assert_comment_safe, BadCommentError

START_MARKER = "-- ---- Column Comments ----"
END_MARKERS = (
    "-- ---- Column PII Tags ----",
    "-- == LAST EXECUTION ==",
)

# Re-parse one existing comment line to recover the UC table identifier and
# to make sure we re-emit the same target.
_COMMENT_LINE_RE = re.compile(
    r"ALTER\s+TABLE\s+(\S+)\s+ALTER\s+COLUMN\s+([^\s]+)\s+COMMENT\s+",
    re.IGNORECASE,
)


def find_uc_target(block_text: str, full_text: str) -> str:
    """Recover the UC fully-qualified table from the existing block, or fall
    back to the `-- UC Target:` header line."""
    m = _COMMENT_LINE_RE.search(block_text)
    if m:
        return m.group(1)
    m = re.search(r"^--\s*UC Target:\s*(\S+)", full_text, re.MULTILINE)
    if m:
        return m.group(1).strip()
    raise RuntimeError("cannot find UC target (no existing ALTER lines and no UC Target header)")


def regenerate_block(uc_table: str, wiki_cols: list[tuple[str, str]]) -> str:
    """Build the new Column Comments block (no leading/trailing whitespace)."""
    lines = [START_MARKER]
    for col, desc in wiki_cols:
        assert_comment_safe(col, desc, context=f"{uc_table}.{col}")
        lines.append(format_comment_line(uc_table, col, desc))
    return "\n".join(lines) + "\n"


def rewrite_one(alter_path: Path, *, dry_run: bool) -> tuple[bool, str]:
    md_path = alter_path.with_name(alter_path.name.removesuffix(".alter.sql") + ".md")
    if not md_path.is_file():
        return False, f"missing wiki MD beside alter: {md_path}"
    text = alter_path.read_text(encoding="utf-8")

    start_idx = text.find(START_MARKER)
    if start_idx < 0:
        return False, "no '-- ---- Column Comments ----' section found"

    # Find earliest end marker after start.
    end_positions = [text.find(m, start_idx + len(START_MARKER)) for m in END_MARKERS]
    end_positions = [p for p in end_positions if p >= 0]
    if not end_positions:
        return False, "no end marker (PII Tags or LAST EXECUTION) found after Column Comments"
    end_idx = min(end_positions)

    old_block = text[start_idx:end_idx]
    uc_table = find_uc_target(old_block, text)

    md_text = md_path.read_text(encoding="utf-8")
    cols = parse_wiki_column_catalog(md_text)
    if not cols:
        return False, "wiki Elements parser returned 0 columns"

    try:
        new_block = regenerate_block(uc_table, cols)
    except BadCommentError as e:
        return False, f"drift guard refused: {e}"

    # Preserve any trailing blank line that was between the old block and
    # the next marker. Old format had a single blank line; we follow suit.
    # We replace [start_idx : end_idx) with new_block + "\n".
    new_text = text[:start_idx] + new_block + "\n" + text[end_idx:]

    # Collapse any accidental double-blank we just created (idempotent).
    new_text = re.sub(r"\n{3,}(?=-- ----)", "\n\n", new_text)

    if new_text == text:
        return False, "no change (alter already matches wiki)"
    if dry_run:
        return True, f"would rewrite {len(cols)} column comments (dry-run)"
    alter_path.write_text(new_text, encoding="utf-8")
    return True, f"rewrote {len(cols)} column comments"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("paths", nargs="*", help=".alter.sql or .md path(s)")
    ap.add_argument("--md", action="store_true",
                    help="Treat positional args as .md paths (resolve to siblings .alter.sql)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not args.paths:
        ap.error("provide at least one .alter.sql (or .md with --md) path")

    targets: list[Path] = []
    for p in args.paths:
        path = Path(p).resolve()
        if not path.exists():
            print(f"NOT FOUND: {p}")
            continue
        if args.md or path.suffix == ".md":
            sibling = path.with_name(path.name.removesuffix(".md") + ".alter.sql")
            if not sibling.is_file():
                print(f"NO ALTER beside MD: {sibling}")
                continue
            targets.append(sibling)
        else:
            targets.append(path)

    n_ok, n_skip, n_fail = 0, 0, 0
    for ap_ in targets:
        rel = ap_.relative_to(REPO).as_posix() if REPO in ap_.parents else str(ap_)
        try:
            changed, msg = rewrite_one(ap_, dry_run=args.dry_run)
        except Exception as e:
            print(f"FAIL {rel}: {e}")
            n_fail += 1
            continue
        if changed:
            print(f"OK   {rel} ({msg})")
            n_ok += 1
        else:
            print(f"SKIP {rel} ({msg})")
            n_skip += 1

    print(f"\nDone: {n_ok} rewritten, {n_skip} skipped, {n_fail} failed"
          + (" [DRY-RUN — no files written]" if args.dry_run else ""))


if __name__ == "__main__":
    main()
