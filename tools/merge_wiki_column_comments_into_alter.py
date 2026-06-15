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

# Regression guard against the 2026-05-03 tier/header drift bug
# (BI_DB_KYC_Panel, eMoneyClientBalance). See tools/uc_comment_validator.py.
_validator_path = Path(__file__).resolve().parent / "uc_comment_validator.py"
if str(_validator_path.parent) not in sys.path:
    sys.path.insert(0, str(_validator_path.parent))
from uc_comment_validator import assert_comment_safe, BadCommentError

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

# Stricter variant: cell must contain ONLY a SQL type, optionally with a single
# `(...)` qualifier (or `[...](N)` Synapse-style). Used by the format-flexible
# parser so a description like "int discussion" doesn't get mistaken for a
# type cell.
_TYPE_CELL_STRICT = re.compile(
    r"^(int|bigint|smallint|tinyint|bit|datetime|datetime2|date|time|smalldatetime|"
    r"uniqueidentifier|money|decimal|numeric|float|real|varchar|nvarchar|char|nchar|"
    r"text|ntext|varbinary|xml|geography|geometry|sql_variant|image|timestamp|"
    r"unknown|any)(\([^)]*\))?$",
    re.I,
)


def _type_cell_at(parts: list[str], idx: int) -> bool:
    if len(parts) <= idx:
        return False
    raw = parts[idx].strip()
    # Element tables sometimes use `[int]`, `[varchar](100)` instead of plain `varchar(100)`.
    if raw.startswith("["):
        end = raw.find("]")
        if end <= 1:
            return False
        base = raw[1:end].strip()
    else:
        base = raw.split("(", 1)[0].strip()
    return bool(_TYPE_CELL.match(base + " "))


def _type_cell_ok(parts: list[str]) -> bool:
    return _type_cell_at(parts, 3)


def _is_sql_type_cell(raw: str) -> bool:
    """Strict check: cell value is a SQL type (optionally with a parenthesized
    size, optionally followed by a NULL/NOT NULL qualifier). Filters out
    narrative cells that merely *contain* a type word."""
    s = (raw or "").strip()
    if not s:
        return False
    # Strip trailing nullability qualifier so cells like `int NOT NULL`,
    # `decimal(16,2) NULL`, `varchar(50) NOT NULL` are all recognized.
    s_no_null = re.sub(r"\s+(NOT\s+NULL|NULL)\s*$", "", s, flags=re.I).strip()
    if s_no_null.startswith("["):
        end = s_no_null.find("]")
        if end <= 1:
            return False
        base = s_no_null[1:end].strip()
        suffix = s_no_null[end + 1:].strip()
        # Synapse `[varchar](100)` pattern: tolerate (...) suffix
        if suffix and not re.match(r"^\([^)]*\)$", suffix):
            return False
        return bool(_TYPE_CELL_STRICT.match(base))
    return bool(_TYPE_CELL_STRICT.match(s_no_null))


def is_plausible_column_name(name: str) -> bool:
    """True for SQL identifier-like cells used in wiki Elements first column.

    Synapse DDL often surfaces bracketed names with spaces (`[Deposit Amounts]`);
    Unicode Catalog export may keep spaced names intact. Permit spaces and &
    inside bracket-stripped identifiers so parse_wiki_column_catalog retains
    those columns for ALTER regeneration.
    """
    n = name.strip().strip("`").strip()
    if n.startswith("[") and n.endswith("]") and len(n) >= 2:
        n = n[1:-1].strip()
    if not n or len(n) > 128:
        return False
    # Allow spaced Synapse identifiers (excluding tabs/newlines inside the token).
    if any(c in n for c in "\t\n"):
        return False
    if n.isdigit():
        return False
    low = n.lower()
    if low in SKIP_NAMES:
        return False
    if "★" in n or "☆" in n:
        return False
    # Synapse / UC may use slashes (Organic/Paid), hyphens (BNY-eToro_Units),
    # spaces (Deposit Amounts), ampersands (Compensation P&L Adjustment),
    # plus/percent/period (UnitsNOP+1%, UnitsNOP-50%, etoro.IsActive_v2), etc.
    if not re.match(r"^[A-Za-z0-9_/\-+%&. ]+$", n):
        return False
    return True


_ELEMENTS_HEADER_RE = re.compile(
    r"^#{1,4}\s+\d+(?:\.\d+)?\.?\s*(?:Elements?|Columns?|Column\s+Catalog|"
    r"Column\s+Inventory)\b",
    re.MULTILINE | re.IGNORECASE,
)
_NEXT_TOP_SECTION_RE = re.compile(r"^#{1,3}\s+\d+\.", re.MULTILINE)


def _scope_to_elements_section(text: str) -> str:
    """Return the slice of `text` covering the Elements section only.

    If no Elements header is found, returns the whole text (back-compat).
    This prevents value-map tables in earlier sections (e.g.
    ``| 1 | FixPerUnit | meaning |``) from being mis-parsed as column rows.
    """
    m = _ELEMENTS_HEADER_RE.search(text)
    if not m:
        return text
    body = text[m.end():]
    nxt = _NEXT_TOP_SECTION_RE.search(body)
    if nxt:
        return body[: nxt.start()]
    return body


def parse_wiki_column_catalog(text: str) -> list[tuple[str, str]]:
    """Return ordered (column_name, description) from Elements-style markdown rows.

    Format-flexible. Locates the SQL-type cell anywhere in the row, takes the
    column name as the first plausible identifier *before* it, and the
    description as the last non-empty cell *after* it. Handles all observed
    wiki shapes:

    - OLD 5-cell ordinal:  ``| # | Column | Type | NULL | Description |``
    - NEW 3-cell:          ``| Column | Type | Description |``
    - NEW 4-cell nullable: ``| Column | Nullable | Type | Description |``
    - NEW 5-cell ordinal:  ``| # | Column | Type | NULL | Description |``
                           (= same as OLD; covered)

    A row is accepted only when a strict SQL-type token (e.g. ``int``,
    ``varchar(4000)``) appears as a standalone cell — that gates out
    property tables, narrative tables, and value-map tables.

    Parsing is scoped to the ``## N. Elements`` (or equivalent) section if
    present, so value-map tables earlier in the wiki cannot leak into the
    column list.
    """
    rows: list[tuple[str, str]] = []
    seen: set[str] = set()

    scoped = _scope_to_elements_section(text)

    for line in scoped.splitlines():
        raw = line.strip()
        if not raw.startswith("|"):
            continue
        parts = [p.strip() for p in raw.split("|")]
        # parts[0] and parts[-1] are empties from leading/trailing pipes.
        cells = parts[1:-1] if (parts and parts[0] == "" and parts[-1] == "") else parts
        if len(cells) < 3:
            continue

        # Primary path: locate a strict SQL-type cell and anchor on it.
        # Some column names (e.g., `Date`, `Time`, `Money`) collide with SQL
        # types — in 4-cell ordinal rows ``| 1 | Date | date | desc |`` the
        # column-name cell at idx 1 also passes ``_is_sql_type_cell`` and would
        # be wrongly anchored. So gather ALL candidate type indexes and pick
        # the first one that yields a non-empty col_name search.
        candidate_type_idxs = [i for i, c in enumerate(cells) if _is_sql_type_cell(c)]

        col_name = ""
        desc = ""
        type_idx = -1

        for cand_idx in candidate_type_idxs:
            # Column name = first plausible identifier strictly before this idx.
            for j in range(cand_idx):
                cand = cells[j].strip().strip("`")
                if is_plausible_column_name(cand):
                    col_name = cand
                    type_idx = cand_idx
                    break
            if col_name:
                break

        if candidate_type_idxs and not col_name:
            continue

        if type_idx >= 0:
            # Description = first *substantial* cell after the type cell. Skips
            # nullability flags ("NULL"/"NOT NULL"/"YES"/"NO"/"0"/"1") and short
            # tags ("Tier 1"). Fallback: last non-empty cell.
            _SKIP = {"", "NULL", "NOT NULL", "YES", "NO", "0", "1", "TRUE", "FALSE", "---", "------"}
            # Regression guard: never grab a separate "Tier N" column (or
            # leaked analyst notes like ETL_METADATA / CODE-BACKED) as the
            # description. The First5Actions / IFRS15 leak (2026-05-03) came
            # from exactly this — a Tier cell with a space passed the
            # "substantial" check and got picked as the comment.
            _SKIP_TAG_RE = re.compile(
                r"^(tier\s*[0-4]\.?|t[0-4]|etl[_\-\s]?metadata|code[\-\s]?backed|"
                r"name[\-\s]?inferred|inferred|verbatim|unverified|unknown)$",
                re.IGNORECASE,
            )
            for k in range(type_idx + 1, len(cells)):
                v = cells[k].strip()
                if v.upper() in _SKIP:
                    continue
                if _SKIP_TAG_RE.match(v):
                    continue
                # Substantial: contains a space (likely a sentence) OR length >= 25.
                if " " in v or len(v) >= 25:
                    desc = v
                    break
            if not desc:
                # No "substantial" candidate — fall back to last non-empty cell
                for k in range(len(cells) - 1, type_idx, -1):
                    v = cells[k].strip()
                    if not v or v.upper() in _SKIP:
                        continue
                    if _SKIP_TAG_RE.match(v):
                        continue
                    desc = v
                    break
        else:
            # Fallback: ordinal-anchored shape with no Type column, e.g.
            #   | # | Column | Description | Source | Tier |
            # Conservative — must have a strict digit ordinal at cells[0],
            # plausible column at cells[1], and a meaty description at cells[2].
            if len(cells) < 3:
                continue
            if not cells[0].strip().isdigit():
                continue
            cand_col = cells[1].strip().strip("`")
            if not is_plausible_column_name(cand_col):
                continue
            cand_desc = cells[2].strip()
            if len(cand_desc) < 30 or cand_desc in ("---", "------"):
                continue
            col_name = cand_col
            desc = cand_desc

        if not desc:
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


def quote_column_name(col: str) -> str:
    """Backtick-quote column names that contain non-identifier chars (e.g.
    ``EOD_Equity_FX/Comm/Ind``). Plain ``A-Za-z0-9_`` names are emitted bare
    to preserve historical alter-file output."""
    c = col.strip().strip("`")
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", c):
        return c
    return f"`{c}`"


def format_comment_line(table: str, col: str, description: str) -> str:
    assert_comment_safe(col, description, context=f"{table}.{col}")
    esc = sql_string_for_comment(description)
    qcol = quote_column_name(col)
    return f"ALTER TABLE {table} ALTER COLUMN {qcol} COMMENT '{esc}';"


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
