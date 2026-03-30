"""
Fill missing ALTER COLUMN ... COMMENT lines from wiki Elements tables.

Preserves existing alter.sql structure; inserts new statements before each
`-- ---- Column PII Tags ----` section (and handles multiple UC targets).

Usage:
  python tools/merge_wiki_column_comments_into_alter.py              # all pairs with .alter.sql
  python tools/merge_wiki_column_comments_into_alter.py path/to/X.md # single wiki
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

WIKI_ROOT = Path(__file__).resolve().parents[1] / "knowledge" / "synapse" / "Wiki"
if str(WIKI_ROOT) not in sys.path:
    sys.path.insert(0, str(WIKI_ROOT))

from _uc_comment_sanitize import sanitize_uc_sql_comment_text
SCHEMAS = ["DWH_dbo", "BI_DB_dbo", "Dealing_dbo"]

# Only skip tokens that appear as *header* labels in element tables, not real SQL columns.
SKIP_NAMES = {
    "column",
    "element",
    "#",
    "property",
    "staging",
    "source",
    "dwh",
    "rule",
    # not "category" — real column Category exists on Dim_ActionType, etc.
    "sentinel",
    "tier",
    "notes",
    "return",
    "param",
    "ordinal",
}

COMMENT_LINE_RE = re.compile(
    r"ALTER\s+TABLE\s+(\S+)\s+ALTER\s+COLUMN\s+([^\s]+)\s+COMMENT\s+",
    re.IGNORECASE,
)

# Third cell in real element rows is a SQL type; filters value-map / narrative tables.
_TYPE_CELL = re.compile(
    r"^(int|bigint|smallint|tinyint|bit|datetime|datetime2|date|time|smalldatetime|"
    r"uniqueidentifier|money|decimal|numeric|float|real|varchar|nvarchar|char|nchar|"
    r"text|ntext|varbinary|xml|geography|geometry|sql_variant|image|timestamp|"
    r"unknown|any)(\(|\s|$)",
    re.I,
)


def _type_cell_ok(parts: list[str]) -> bool:
    if len(parts) < 4:
        return False
    raw = parts[3].strip()
    # Element tables sometimes use `[int]`, `[varchar](100)` instead of plain `varchar(100)`.
    if raw.startswith("["):
        end = raw.find("]")
        if end <= 1:
            return False
        base = raw[1:end].strip()
    else:
        base = raw.split("(", 1)[0].strip()
    return bool(_TYPE_CELL.match(base + " "))


def is_plausible_column_name(name: str) -> bool:
    n = name.strip().strip("`").strip()
    if not n or len(n) > 128:
        return False
    if any(c in n for c in " \t\n"):
        return False
    if n.isdigit():
        return False
    low = n.lower()
    if low in SKIP_NAMES:
        return False
    if "★" in n or "☆" in n:
        return False
    # Synapse / UC may use slashes (Organic/Paid), hyphens (BNY-eToro_Units), etc.
    if not re.match(r"^[A-Za-z0-9_/\-]+$", n):
        return False
    return True


def parse_wiki_column_catalog(text: str) -> list[tuple[str, str]]:
    """Return ordered (column_name, description) from Elements-style markdown rows."""
    rows: list[tuple[str, str]] = []
    seen: set[str] = set()

    for line in text.splitlines():
        raw = line.strip()
        if not raw.startswith("|"):
            continue
        parts = [p.strip() for p in raw.split("|")]
        if len(parts) < 5:
            continue
        ord_cell = parts[1]
        if not ord_cell.isdigit():
            continue
        col_name = parts[2].strip().strip("`")
        if not is_plausible_column_name(col_name):
            continue
        if not _type_cell_ok(parts):
            continue

        if len(parts) < 6:
            continue
        if len(parts) >= 8:
            desc = parts[6]
        elif len(parts) == 7:
            desc = parts[5]
        else:
            desc = parts[4]

        if not desc or desc in ("---", "------"):
            continue
        if col_name in seen:
            continue
        seen.add(col_name)
        rows.append((col_name, desc))
    return rows


def sql_string_for_comment(text: str, max_len: int = 1024) -> str:
    t = sanitize_uc_sql_comment_text(text).replace("'", "''")
    if len(t) > max_len:
        t = t[: max_len - 3] + "..."
    return t


def format_comment_line(table: str, col: str, description: str) -> str:
    esc = sql_string_for_comment(description)
    return f"ALTER TABLE {table} ALTER COLUMN {col} COMMENT '{esc}';"


def merge_alter_file(alter_path: Path, wiki_cols: list[tuple[str, str]]) -> tuple[bool, str]:
    text = alter_path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines(keepends=True)

    wiki_names = [n for n, _ in wiki_cols]
    wiki_desc = dict(wiki_cols)

    if not wiki_cols:
        return False, "no wiki columns parsed"

    out: list[str] = []
    i = 0
    changed = False

    while i < len(lines):
        line = lines[i]

        if line.strip() == "-- ---- Column Comments ----":
            out.append(line)
            i += 1
            table = ""
            existing: set[str] = set()
            while i < len(lines) and not lines[i].strip().startswith(
                "-- ---- Column PII Tags ----"
            ):
                ln = lines[i]
                m = COMMENT_LINE_RE.search(ln)
                if m:
                    table = m.group(1)
                    existing.add(m.group(2).strip("`"))
                out.append(ln)
                i += 1

            if table:
                missing = [n for n in wiki_names if n not in existing]
                if missing:
                    for col in missing:
                        out.append(format_comment_line(table, col, wiki_desc[col]) + "\n")
                    changed = True
            continue

        out.append(line)
        i += 1

    if changed:
        alter_path.write_text("".join(out), encoding="utf-8")
    return changed, "ok" if changed else "no missing comments"


def find_md_with_alter() -> list[tuple[Path, Path]]:
    pairs: list[tuple[Path, Path]] = []
    for sch in SCHEMAS:
        base = WIKI_ROOT / sch
        if not base.exists():
            continue
        for md in sorted(base.rglob("*.md")):
            if md.name.endswith(".lineage.md") or md.name.endswith(".review-needed.md"):
                continue
            if md.name.startswith("_"):
                continue
            rel = md.relative_to(base)
            if len(rel.parts) < 2 or rel.parts[0] not in ("Tables", "Views"):
                continue
            alt = md.with_name(md.stem + ".alter.sql")
            if alt.exists():
                pairs.append((md, alt))
    return pairs


def main() -> None:
    if len(sys.argv) > 1:
        md = Path(sys.argv[1]).resolve()
        if not md.exists():
            print("not found:", md)
            sys.exit(1)
        alt = md.with_name(md.stem + ".alter.sql")
        if not alt.exists():
            print("no alter file:", alt)
            sys.exit(1)
        pairs = [(md, alt)]
    else:
        pairs = find_md_with_alter()

    n_ok = 0
    n_changed = 0
    n_fail = 0
    for md, alt in pairs:
        try:
            wtext = md.read_text(encoding="utf-8", errors="replace")
            cols = parse_wiki_column_catalog(wtext)
            ch, msg = merge_alter_file(alt, cols)
            rel = md.relative_to(WIKI_ROOT)
            if ch:
                print(f"MERGED {rel} (+missing comments)")
                n_changed += 1
            else:
                n_ok += 1
        except Exception as e:
            print(f"FAIL {md}: {e}")
            n_fail += 1

    print(
        f"Done: {n_changed} updated, {n_ok} unchanged (no gaps or no parsed wiki cols), {n_fail} failed"
    )


if __name__ == "__main__":
    main()
