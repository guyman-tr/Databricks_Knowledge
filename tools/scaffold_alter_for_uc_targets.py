"""Scaffold .alter.sql files for arbitrary (wiki_md, uc_target) pairs.

Designed for the 43 NO_COMMENTS_AT_ALL backfill (Bonnie's Tier-1 ProdSchemas
wikis → bronze/silver UC tables), but generic enough to handle any wiki MD
in the repo whose Elements/Table-Elements section follows the conventional
patterns.

Process per (wiki, uc) pair:
  1. Parse the wiki MD for:
       * table blurb (heading + first `>` quote / first paragraph after §1)
       * column inventory from `## N. Elements`, `## N. Table Elements`,
         `## N. Data Elements`, or `## N.X. Elements` section.
       * Tolerates bold-wrapped column names (`**Name**`), 4-7-cell row
         shapes, optional Confidence / Tier / Default / PK / Null columns.
  2. Fetch actual UC column list via information_schema (case-preserving).
  3. Intersect wiki columns ∩ UC columns (case-insensitive match) —
     emit ALTER only for cols that exist in UC, using UC's exact casing.
  4. Validate every (col, comment) via uc_comment_validator.assert_comment_safe.
  5. Write `<wiki_md_dir>/<wiki_stem>.alter.sql` with full header, table
     comment block, column comments block, and the PII tags block.
  6. Print a summary so the caller can spot wikis where 0 cols mapped.

Usage:
    python tools/scaffold_alter_for_uc_targets.py --targets tools/lakebridge/bare_43_targets.json
    python tools/scaffold_alter_for_uc_targets.py --targets <json>  --dry-run
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from collections import defaultdict

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
sys.path.insert(0, str(REPO / "knowledge" / "synapse" / "Wiki"))

from uc_comment_validator import assert_comment_safe, BadCommentError, validate_alter_sql
from _uc_comment_sanitize import sanitize_uc_sql_comment_text


# ----------------------------- WIKI PARSING -----------------------------

# H2 ONLY (`## N. ...` or `## ...`) to avoid colliding with H3 subsections like
# "### 2.2 Column Promotion" which would otherwise hijack the scope.
# Accepted forms:
#   "## 4. Elements"            "## Elements"
#   "## 2. Table Elements"
#   "## 4. Data Elements"       "## Output Columns"
#   "## 2. Column Catalog"
#   "## N. Column Inventory"
ELEMENTS_HEADER_RE = re.compile(
    r"^##\s+(?:\d+(?:\.\d+)?\.?\s*)?"
    r"(?:Table\s+|Data\s+|Output\s+)?"
    r"(?:Elements?|Columns?|Column\s+Catalog|Column\s+Inventory)\b",
    re.MULTILINE | re.IGNORECASE,
)
# Next top-level section after the Elements block.  H2 only — H3 subsections
# inside Elements must NOT terminate scope (e.g. Dim_Customer.md groups its
# Elements rows under "### 3.1 Customer Identity").
NEXT_SECTION_RE = re.compile(r"^##\s+(?:\d+(?:\.\d+)?\.?\s+)?\S", re.MULTILINE)

# Cell tagged with a SQL type — flexible. Accept e.g. int, varchar(50),
# decimal(16,2), bit, datetime, nvarchar(max), nchar(5), uniqueidentifier,
# and tolerate trailing column-attribute keywords (MASKED, COLLATE ..., etc.).
TYPE_CELL_RE = re.compile(
    r"^\s*"
    r"(?P<base>int|bigint|smallint|tinyint|bit|datetime2?|smalldatetime|"
    r"date|time|uniqueidentifier|money|smallmoney|decimal|numeric|float|"
    r"real|varchar|nvarchar|char|nchar|text|ntext|varbinary|binary|xml|"
    r"geography|geometry|sql_variant|image|timestamp|rowversion|hierarchyid)"
    r"(?:\([^)]*\))?"
    r"(?:\s+(?:MASKED|SPARSE|FILESTREAM|IDENTITY(?:\(\d+,\s*\d+\))?|"
    r"NOT\s+NULL|NULL|NOT\s+FOR\s+REPLICATION|ROWGUIDCOL|COLLATE\s+\S+))*"
    r"\s*$",
    re.IGNORECASE,
)

COLUMN_HEADER_TOKENS = {"column", "element", "field", "name", "column name", "elements"}
TYPE_HEADER_TOKENS = {"type", "data type", "data_type", "datatype", "sql type"}
DESC_HEADER_TOKENS = {"description", "meaning", "notes", "semantics", "purpose",
                      "business meaning", "what", "summary"}


def _strip_md(s: str) -> str:
    """Strip bold markers, backticks, and surrounding whitespace from a cell."""
    v = s.strip()
    if v.startswith("**") and v.endswith("**") and len(v) >= 4:
        v = v[2:-2].strip()
    if v.startswith("`") and v.endswith("`") and len(v) >= 2:
        v = v[1:-1].strip()
    return v


def _is_type(cell: str) -> bool:
    raw = _strip_md(cell)
    if not raw:
        return False
    if raw.startswith("[") and raw.endswith("]"):
        raw = raw[1:-1].strip()
    return bool(TYPE_CELL_RE.match(raw))


_IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _is_identifier(cell: str) -> bool:
    v = _strip_md(cell)
    if v.startswith("[") and v.endswith("]") and len(v) >= 2:
        v = v[1:-1].strip()
    return bool(v) and len(v) <= 128 and bool(_IDENT_RE.match(v))


_PIPE_PLACEHOLDER = "\x00PIPE\x00"


def _row_cells(line: str) -> list[str]:
    raw = line.strip()
    if not raw.startswith("|"):
        return []
    # Honor markdown's `\|` escape — temporarily swap, split, then restore.
    protected = raw.replace(r"\|", _PIPE_PLACEHOLDER)
    cells = [c.strip().replace(_PIPE_PLACEHOLDER, "|") for c in protected.split("|")]
    if cells and cells[0] == "":
        cells = cells[1:]
    if cells and cells[-1] == "":
        cells = cells[:-1]
    return cells


def _is_separator_row(cells: list[str]) -> bool:
    if not cells:
        return False
    return all(re.match(r"^:?-{2,}:?$", c.strip()) for c in cells if c.strip())


def _classify_header(header_cells: list[str]) -> tuple[int, int, int]:
    """Return (col_idx, type_idx, desc_idx). -1 for any not present."""
    col_idx = type_idx = desc_idx = -1
    for i, c in enumerate(header_cells):
        norm = _strip_md(c).lower().strip()
        if col_idx < 0 and norm in COLUMN_HEADER_TOKENS:
            col_idx = i
        elif type_idx < 0 and norm in TYPE_HEADER_TOKENS:
            type_idx = i
        elif desc_idx < 0 and norm in DESC_HEADER_TOKENS:
            desc_idx = i
    return col_idx, type_idx, desc_idx


def scope_to_elements_section(text: str) -> str:
    m = ELEMENTS_HEADER_RE.search(text)
    if not m:
        return ""
    body = text[m.end():]
    nxt = NEXT_SECTION_RE.search(body)
    if nxt:
        return body[: nxt.start()]
    return body


def _iter_markdown_tables(scoped: str):
    """Yield (header_cells, [data_cells_lists]) for each markdown table in scoped text."""
    lines = scoped.splitlines()
    i = 0
    while i < len(lines):
        cells = _row_cells(lines[i])
        if cells and i + 1 < len(lines):
            sep_cells = _row_cells(lines[i + 1])
            if sep_cells and _is_separator_row(sep_cells) and len(sep_cells) == len(cells):
                header = cells
                data: list[list[str]] = []
                j = i + 2
                while j < len(lines):
                    r = _row_cells(lines[j])
                    if not r:
                        break
                    data.append(r)
                    j += 1
                yield header, data
                i = j
                continue
        i += 1


def parse_columns_robust(text: str) -> list[tuple[str, str]]:
    """Header-aware Elements-table parser.

    Strategy:
      1. Scope to the §N. Elements / §N. Table Elements section.
      2. For each markdown table in that section:
           * Classify header cells: which is "Column" / "Type" / "Description".
           * Need at minimum a column-cell and either a type-cell OR a desc-cell.
           * For each data row, extract by position; require the type cell (if
             present in header) to actually look like a SQL type — this gates
             out tables masquerading as Elements.
      3. Deduplicate by column name (case-sensitive first occurrence wins).
    """
    scoped = scope_to_elements_section(text)
    if not scoped:
        return []

    out: list[tuple[str, str]] = []
    seen: set[str] = set()

    for header, data_rows in _iter_markdown_tables(scoped):
        col_idx, type_idx, desc_idx = _classify_header(header)
        if col_idx < 0 or desc_idx < 0:
            continue
        for cells in data_rows:
            if len(cells) <= max(col_idx, desc_idx):
                continue
            col_raw = cells[col_idx]
            if not _is_identifier(col_raw):
                continue
            col_name = _strip_md(col_raw)
            if col_name.startswith("[") and col_name.endswith("]"):
                col_name = col_name[1:-1].strip()
            if type_idx >= 0:
                if len(cells) <= type_idx:
                    continue
                if not _is_type(cells[type_idx]):
                    continue
            desc = _strip_md(cells[desc_idx]).strip()
            if not desc or desc in {"-", "—", "n/a", "N/A"}:
                continue
            if col_name in seen:
                continue
            seen.add(col_name)
            out.append((col_name, desc))
    return out


# ----------------------------- blurb extraction -----------------------------

def extract_blurb(text: str, max_len: int = 900) -> str:
    """First paragraph after H1 — prefer the `>` blockquote (canonical
    'one-liner' summary in the Tier-1 wikis), else fall back to the first
    prose lines before §2.  The H1 title itself is dropped because the UC
    table identifier already carries that context."""
    lines = text.splitlines()
    h1_seen = False
    saw_section_1 = False
    blockquote: list[str] = []
    section_1_prose: list[str] = []
    in_section_1 = False
    for ln in lines:
        s = ln.strip()
        if not h1_seen:
            if ln.startswith("# ") and not ln.startswith("## "):
                h1_seen = True
            continue
        # H1 already seen — capture blockquote until §1 starts
        if not in_section_1 and not saw_section_1:
            if re.match(r"^##\s+1\.", ln):
                in_section_1 = True
                saw_section_1 = True
                continue
            if s.startswith(">"):
                blockquote.append(s.lstrip("> ").strip())
                continue
            if ln.startswith("## "):
                # Another H2 before §1 — stop collecting blockquote
                in_section_1 = False
                saw_section_1 = True
        if in_section_1:
            if ln.startswith("## "):
                in_section_1 = False
                break
            if not s or s.startswith("---") or s.startswith("|"):
                continue
            if s.startswith(">") or s.startswith("<"):
                continue
            if s.startswith("### "):
                continue
            # Strip leading bold prefix like "**What it is**:" and keep the
            # following clause on the same line.
            m = re.match(r"^\*\*([^*]+)\*\*\s*[:\-]\s*(.*)$", s)
            if m:
                clause = m.group(2).strip()
                if clause:
                    section_1_prose.append(clause)
                continue
            if s.startswith("**") and s.endswith("**"):
                continue  # standalone bold heading like "**Resolution Categories**"
            section_1_prose.append(s)
    if blockquote:
        blurb = " ".join(blockquote)
    else:
        blurb = " ".join(section_1_prose[:8])
    blurb = re.sub(r"\s+", " ", blurb).strip()
    if not blurb:
        return ""
    if len(blurb) <= max_len:
        return blurb
    cut = blurb[:max_len]
    # Prefer a sentence boundary within the last 120 chars.
    last_dot = max(cut.rfind(". "), cut.rfind("! "), cut.rfind("? "))
    if last_dot >= max_len - 120:
        return cut[: last_dot + 1]
    last_space = cut.rfind(" ")
    if last_space >= max_len - 40:
        return cut[:last_space].rstrip(",;:") + "..."
    return cut.rstrip() + "..."


# ----------------------------- UC schema lookup -----------------------------

def fetch_uc_schema(uc_targets: list[str]) -> dict[str, dict]:
    """For each target return:
        {full_uc_target: {
            "columns": [...UC-cased col names in ordinal_position order],
            "is_view": bool,
        }}
    """
    if not uc_targets:
        return {}
    from databricks import sql
    host = os.environ.get(
        "DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net"
    )
    http_path = os.environ.get(
        "DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308"
    )
    token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
    print(f"Fetching UC schema for {len(uc_targets)} targets...", flush=True)
    if token:
        conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
    else:
        conn = sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")
    cur = conn.cursor()

    by_schema: dict[tuple[str, str], set[str]] = defaultdict(set)
    parsed: dict[str, tuple[str, str, str]] = {}
    for t in uc_targets:
        parts = t.split(".")
        if len(parts) != 3:
            continue
        cat, sch, tbl = parts
        by_schema[(cat.lower(), sch.lower())].add(tbl.lower())
        parsed[t] = (cat, sch, tbl)

    cols_by_lower: dict[tuple[str, str, str], list[str]] = {}
    type_by_lower: dict[tuple[str, str, str], str] = {}
    for (cat, sch), tbls in by_schema.items():
        in_clause = ", ".join(f"'{t}'" for t in sorted(tbls))
        cur.execute(
            f"SELECT lower(table_name), column_name "
            f"FROM {cat}.information_schema.columns "
            f"WHERE table_schema = '{sch}' AND lower(table_name) IN ({in_clause}) "
            f"ORDER BY ordinal_position"
        )
        for tbl_l, col in cur.fetchall():
            cols_by_lower.setdefault((cat, sch, tbl_l), []).append(col)
        cur.execute(
            f"SELECT lower(table_name), table_type "
            f"FROM {cat}.information_schema.tables "
            f"WHERE table_schema = '{sch}' AND lower(table_name) IN ({in_clause})"
        )
        for tbl_l, ttype in cur.fetchall():
            type_by_lower[(cat, sch, tbl_l)] = (ttype or "").upper()

    out: dict[str, dict] = {}
    for t, (cat, sch, tbl) in parsed.items():
        key = (cat.lower(), sch.lower(), tbl.lower())
        out[t] = {
            "columns": cols_by_lower.get(key, []),
            "is_view": "VIEW" in type_by_lower.get(key, ""),
        }
    cur.close()
    conn.close()
    return out


# Back-compat wrapper for older callers that only need column lists.
def fetch_uc_columns(uc_targets: list[str]) -> dict[str, list[str]]:
    return {k: v["columns"] for k, v in fetch_uc_schema(uc_targets).items()}


# ----------------------------- scaffold writer -----------------------------

def sql_quote_comment(text: str, max_len: int = 1024) -> str:
    t = sanitize_uc_sql_comment_text(text)
    # Databricks SQL treats `\` as an escape char inside single-quoted strings
    # by default. Escape backslashes BEFORE doubling single quotes so a literal
    # `\'` in the source can't accidentally close the string.
    t = t.replace("\\", "\\\\").replace("'", "''")
    if len(t) > max_len:
        t = t[: max_len - 3] + "..."
    return t


def quote_col_for_sql(col: str) -> str:
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", col):
        return col
    return f"`{col}`"


def build_alter_text(*, uc_target: str, source_wiki_rel: str,
                     blurb: str, paired_cols: list[tuple[str, str]],
                     is_view: bool = False, cols_only: bool = False) -> str:
    gen = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    obj_kind = "VIEW" if is_view else "TABLE"
    lines = [
        "-- =============================================================================",
        f"-- Databricks ALTER Script: {uc_target}  ({obj_kind})",
        f"-- Generated: {gen} | scaffold_alter_for_uc_targets.py",
        f"-- Source wiki: {source_wiki_rel}",
        "-- Target: Unity Catalog comments (1024 char limit per comment)",
        "-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql",
        "-- =============================================================================",
        "",
    ]
    if blurb and not cols_only:
        esc = sql_quote_comment(blurb)
        lines += [
            "-- ---- Table/View Comment ----",
            f"ALTER {obj_kind} {uc_target} SET TBLPROPERTIES (",
            f"    'comment' = '{esc}'",
            ");",
            "",
        ]
    elif cols_only:
        lines += [
            "-- ---- Table comment intentionally not emitted (--cols-only) ----",
            "",
        ]
    if paired_cols:
        lines += ["-- ---- Column Comments ----"]
        for col, desc in paired_cols:
            assert_comment_safe(col, desc, context=f"{uc_target}.{col}")
            esc_d = sql_quote_comment(desc)
            qcol = quote_col_for_sql(col)
            if is_view:
                # ANSI COMMENT ON COLUMN works on views without recreating them.
                lines.append(f"COMMENT ON COLUMN {uc_target}.{qcol} IS '{esc_d}';")
            else:
                lines.append(f"ALTER TABLE {uc_target} ALTER COLUMN {qcol} COMMENT '{esc_d}';")
        lines.append("")
        lines += [
            "-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.",
            "-- Blanket-tagging every column 'pii=none' would risk silently misclassifying",
            "-- PII-masked columns. Run the dedicated PII classifier afterwards.",
            "",
        ]
    return "\n".join(lines)


# ----------------------------- main -----------------------------

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets", required=True,
                    help="Path to a JSON file: [{wiki_md, uc_target, ...}, ...]")
    ap.add_argument("--dry-run", action="store_true",
                    help="Print summary but do not write .alter.sql files")
    ap.add_argument("--skip-uc-lookup", action="store_true",
                    help="Skip UC schema fetch (use wiki cols as-is)")
    ap.add_argument("--cols-only", action="store_true",
                    help="Skip the SET TBLPROPERTIES table-comment block; only emit "
                         "column comments. Use for ONLY_TABLE_COMMENT backfill where "
                         "UC already has a (possibly hand-written) table comment.")
    ap.add_argument("--summary-out",
                    default="tools/lakebridge/bare_43_scaffold_summary.json",
                    help="Path to write the per-target summary JSON.")
    args = ap.parse_args()

    targets = json.loads(Path(args.targets).read_text(encoding="utf-8"))
    print(f"Loaded {len(targets)} targets  (cols_only={args.cols_only})")

    uc_full_targets = [t["uc_target"] for t in targets if t.get("uc_target")]
    uc_schema: dict[str, dict] = {}
    if not args.skip_uc_lookup:
        uc_schema = fetch_uc_schema(uc_full_targets)

    summary: list[dict] = []
    written = 0
    skipped = 0
    errored = 0

    for t in targets:
        md_rel = t["wiki_md"]
        uc = t["uc_target"]
        md_path = REPO / md_rel
        if not md_path.is_file():
            print(f"NO WIKI: {md_rel}")
            errored += 1
            continue
        text = md_path.read_text(encoding="utf-8")
        wiki_cols = parse_columns_robust(text)
        blurb = extract_blurb(text)

        uc_info = uc_schema.get(uc, {"columns": [], "is_view": False})
        uc_col_list = uc_info["columns"]
        is_view = uc_info["is_view"]
        uc_lower_to_real = {c.lower(): c for c in uc_col_list}
        paired: list[tuple[str, str]] = []
        wiki_missing: list[str] = []
        for cname, desc in wiki_cols:
            real = uc_lower_to_real.get(cname.lower())
            if real:
                paired.append((real, desc))
            else:
                wiki_missing.append(cname)
        uc_uncovered = [c for c in uc_col_list if c.lower() not in {wc[0].lower() for wc in wiki_cols}]

        try:
            body = build_alter_text(
                uc_target=uc,
                source_wiki_rel=md_rel,
                blurb=blurb,
                paired_cols=paired,
                is_view=is_view,
                cols_only=args.cols_only,
            )
        except BadCommentError as e:
            print(f"DRIFT GUARD blocked {md_rel}: {e}")
            errored += 1
            continue

        problems = validate_alter_sql(body, source=md_rel)
        if problems:
            print(f"VALIDATOR refused {md_rel}: {problems[:2]}")
            errored += 1
            continue

        if not paired and (args.cols_only or not blurb):
            print(f"SKIP empty (no cols matched{' / cols_only' if args.cols_only else ', no blurb'}): {md_rel}")
            skipped += 1
            summary.append({"wiki": md_rel, "uc": uc, "paired": 0, "uc_cols": len(uc_col_list),
                            "wiki_cols_parsed": len(wiki_cols),
                            "wiki_unmatched": wiki_missing, "uc_uncovered": uc_uncovered,
                            "blurb_len": len(blurb), "is_view": is_view})
            continue

        alter_path = md_path.with_name(md_path.stem + ".alter.sql")
        if args.dry_run:
            kind = "VIEW" if is_view else "TABLE"
            print(f"[dry-run] would write {alter_path.relative_to(REPO).as_posix()} "
                  f"({kind} {len(paired)}/{len(uc_col_list)} cols, blurb {len(blurb)} chars)")
        else:
            alter_path.write_text(body, encoding="utf-8")
            kind = "VIEW" if is_view else "TABLE"
            print(f"WROTE {alter_path.relative_to(REPO).as_posix()} "
                  f"({kind} {len(paired)}/{len(uc_col_list)} cols, blurb {len(blurb)} chars)")
            written += 1
        summary.append({"wiki": md_rel, "uc": uc, "paired": len(paired),
                        "uc_cols": len(uc_col_list), "wiki_cols_parsed": len(wiki_cols),
                        "wiki_unmatched": wiki_missing, "uc_uncovered": uc_uncovered,
                        "blurb_len": len(blurb), "is_view": is_view,
                        "alter_path": str(alter_path.relative_to(REPO)).replace("\\", "/")})

    print()
    print("=" * 78)
    print(f"Scaffold done: {written} written, {skipped} skipped (empty), {errored} errored")
    print()
    # Per-row table for inspection
    print(f"{'paired/uc':<12} {'wiki_cols':<10} blurb  uc_target")
    for s in sorted(summary, key=lambda x: -x["paired"]):
        cov = f"{s['paired']}/{s['uc_cols']}"
        print(f"  {cov:<10} {s['wiki_cols_parsed']:>4}      {s['blurb_len']:>4}   {s['uc']}")
        if s["wiki_unmatched"]:
            print(f"      wiki cols not in UC: {s['wiki_unmatched'][:6]}{'...' if len(s['wiki_unmatched'])>6 else ''}")
        if s["uc_uncovered"]:
            print(f"      UC cols missing from wiki: {s['uc_uncovered'][:6]}{'...' if len(s['uc_uncovered'])>6 else ''}")

    out_path = REPO / args.summary_out
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print()
    print(f"Summary JSON: {out_path.relative_to(REPO).as_posix()}")


if __name__ == "__main__":
    main()
