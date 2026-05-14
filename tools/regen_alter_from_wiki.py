"""Fully regenerate the `-- ---- Column Comments ----` section of one or more
.alter.sql files from the corresponding wiki .md Elements table.

UNLIKE `merge_wiki_column_comments_into_alter.py` which only ADDS missing
comments, this script REPLACES the entire column-comments block with fresh
text from the wiki. Preserves: UC target(s), table-level comment, table tags,
column PII tags, and footer (LAST EXECUTION marker is stripped — will be
regenerated on next deploy).

This is the tool to run after a speckit-regen has produced new descriptions
(e.g., the Fact_CustomerAction + 8 DDR family rebuild on 2026-05-14) and
you need the .alter.sql files refreshed before redeploy.

Usage:
  python tools/regen_alter_from_wiki.py path/to/Table1.md [path/to/Table2.md ...]
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
WIKI_ROOT = REPO / "knowledge" / "synapse" / "Wiki"
if str(WIKI_ROOT) not in sys.path:
    sys.path.insert(0, str(WIKI_ROOT))

try:
    from _uc_comment_sanitize import sanitize_uc_sql_comment_text
except ImportError:
    def sanitize_uc_sql_comment_text(s: str) -> str:
        # Strip backticks and collapse whitespace
        return re.sub(r"\s+", " ", s.replace("\u00a0", " ")).strip()

# Reuse the wiki parser from the merge tool
from merge_wiki_column_comments_into_alter import (  # type: ignore
    parse_wiki_column_catalog,
    format_comment_line,
    quote_column_name,
)


ALTER_COMMENT_RE = re.compile(
    r"^ALTER\s+TABLE\s+(\S+)\s+ALTER\s+COLUMN\s+`?([A-Za-z0-9_]+)`?\s+COMMENT\s+",
    re.IGNORECASE,
)
SET_TAGS_RE = re.compile(
    r"^ALTER\s+TABLE\s+(\S+)\s+ALTER\s+COLUMN\s+`?([A-Za-z0-9_]+)`?\s+SET\s+TAGS",
    re.IGNORECASE,
)

COMMENT_HEADER = "-- ---- Column Comments ----"
PII_HEADER = "-- ---- Column PII Tags ----"
LAST_EXEC_HEADER = "-- == LAST EXECUTION =="


def extract_uc_targets_and_pii_blocks(text: str) -> tuple[list[str], dict, dict]:
    """From an existing .alter.sql return:
      - list of UC targets (one per dual-target case)
      - dict {target: set of columns with SET TAGS lines}
      - dict {target: list of full SET TAGS lines preserved verbatim}
    """
    lines = text.splitlines()
    targets: list[str] = []
    target_set = set()
    pii_cols: dict[str, set[str]] = {}
    pii_lines: dict[str, list[str]] = {}

    for ln in lines:
        m = ALTER_COMMENT_RE.match(ln.strip())
        if m:
            t = m.group(1)
            if t not in target_set:
                target_set.add(t)
                targets.append(t)
        m2 = SET_TAGS_RE.match(ln.strip())
        if m2:
            t = m2.group(1)
            col = m2.group(2)
            if t not in target_set:
                target_set.add(t)
                targets.append(t)
            pii_cols.setdefault(t, set()).add(col)
            pii_lines.setdefault(t, []).append(ln)

    return targets, pii_cols, pii_lines


def split_into_sections(text: str) -> dict[str, str]:
    """Split the .alter.sql into named sections by header lines."""
    HEADERS = [
        "-- ---- Table Comment ----",
        "-- ---- Table Tags ----",
        COMMENT_HEADER,
        PII_HEADER,
        LAST_EXEC_HEADER,
    ]
    lines = text.splitlines(keepends=True)
    sections: dict[str, list[str]] = {"_preamble": []}
    current = "_preamble"
    for line in lines:
        stripped = line.strip()
        if stripped in HEADERS:
            current = stripped
            sections[current] = [line]
        else:
            sections.setdefault(current, []).append(line)

    return {k: "".join(v) for k, v in sections.items()}


def regen_alter_file(md: Path, alt: Path) -> tuple[bool, str]:
    if not alt.exists():
        return False, f"no .alter.sql at {alt}"
    if not md.exists():
        return False, f"no .md at {md}"

    md_text = md.read_text(encoding="utf-8", errors="replace")
    cols = parse_wiki_column_catalog(md_text)
    if not cols:
        return False, "no wiki columns parsed"

    sections = split_into_sections(alt.read_text(encoding="utf-8", errors="replace"))
    alt_text = alt.read_text(encoding="utf-8", errors="replace")
    targets, pii_cols, pii_lines = extract_uc_targets_and_pii_blocks(alt_text)
    if not targets:
        return False, "no UC targets found in existing .alter.sql"

    # Build fresh Column Comments block
    new_block = [COMMENT_HEADER + "\n"]
    for target in targets:
        for col, desc in cols:
            new_block.append(format_comment_line(target, col, desc) + "\n")
    # Trailing blank line
    new_block.append("\n")
    sections[COMMENT_HEADER] = "".join(new_block)

    # Optionally: refresh PII Tags block to add new columns missing pii lines
    # (we keep existing pii lines as authoritative; only append missing)
    if PII_HEADER in sections:
        # Reconstruct PII block from scratch using preserved per-column lines,
        # adding default 'none' for new columns
        new_pii = [PII_HEADER + "\n"]
        all_cols = [c for c, _ in cols]
        for target in targets:
            existing = pii_cols.get(target, set())
            # First: preserve existing PII lines in their original order
            seen_for_target: set[str] = set()
            for ln in pii_lines.get(target, []):
                m = SET_TAGS_RE.match(ln.strip())
                if not m:
                    continue
                col = m.group(2)
                if col in seen_for_target:
                    continue
                seen_for_target.add(col)
                new_pii.append(ln.rstrip("\n") + "\n")
            # Then: add new columns with default pii=none
            for col in all_cols:
                if col not in seen_for_target:
                    new_pii.append(
                        f"ALTER TABLE {target} ALTER COLUMN {quote_column_name(col)} "
                        f"SET TAGS ('pii' = 'none');\n"
                    )
        new_pii.append("\n")
        sections[PII_HEADER] = "".join(new_pii)

    # Drop the LAST EXECUTION footer (it's stale once we regen)
    if LAST_EXEC_HEADER in sections:
        del sections[LAST_EXEC_HEADER]

    # Re-assemble in canonical order
    order = [
        "_preamble",
        "-- ---- Table Comment ----",
        "-- ---- Table Tags ----",
        COMMENT_HEADER,
        PII_HEADER,
    ]
    out = ""
    for k in order:
        if k in sections:
            out += sections[k]

    alt.write_text(out, encoding="utf-8")
    return True, f"regenerated {len(cols)} columns × {len(targets)} target(s)"


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2

    paths = [Path(p).resolve() for p in sys.argv[1:]]
    n_ok = 0
    n_fail = 0
    for md in paths:
        if md.suffix == ".sql":
            md = md.with_suffix(".sql").with_name(
                md.stem.replace(".alter", "") + ".md"
            )
        alt = md.with_name(md.stem + ".alter.sql")
        try:
            ok, msg = regen_alter_file(md, alt)
            rel = md.relative_to(REPO) if md.is_relative_to(REPO) else md
            if ok:
                print(f"  OK    {rel}: {msg}")
                n_ok += 1
            else:
                print(f"  FAIL  {rel}: {msg}")
                n_fail += 1
        except Exception as e:
            print(f"  FAIL  {md}: {e}")
            n_fail += 1
    print(f"\nDone: {n_ok} regenerated, {n_fail} failed")
    return 0 if n_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
