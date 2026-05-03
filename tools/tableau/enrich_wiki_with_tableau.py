"""Enrich an existing DWH wiki file with Tableau usage signal.

Touches only:
  Section 1 (Business Meaning)  -> appends a fenced summary block
  Section 4 (Elements)          -> appends a fenced "Tableau Usage Notes" subsection

Both blocks are wrapped in HTML-comment fences so re-runs replace prior
insertions cleanly and `--remove` restores the file byte-for-byte (modulo
the matched columns map).

Usage
-----
    python tools/tableau/enrich_wiki_with_tableau.py \
        --wiki knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_MIMO_AllPlatforms.md \
        [--tableau knowledge/tableau/sql_dp_prod_we__BI_DB_dbo/BI_DB_DDR_Fact_MIMO_AllPlatforms.md] \
        [--dry-run | --apply | --remove] \
        [--out-diff <path>]

Flags
-----
    --wiki        One wiki path, comma-separated paths, or a glob pattern.
    --tableau     Optional explicit Tableau extract path. If omitted, auto-resolve
                  by table name -> knowledge/tableau/*/<TableName>.md.
    --dry-run     (default) Write preview to <wiki>.tableau-enriched.md and print diff.
    --apply       Rewrite the wiki in place.
    --remove      Strip both fenced blocks (and the auto-added subsection heading).
    --out-diff    Write the diff to a file as well as printing to stdout.

Safety
------
The wiki's Element table rows (Section 4) are NOT modified. The (Tier N - source)
suffix rule, column-count assertions, and parity validators all keep passing
because we only ADD a new sub-section. Section 8 is untouched. No rule files
or validators are modified.
"""
from __future__ import annotations

import argparse
import difflib
import glob
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
KNOWLEDGE_TABLEAU = REPO_ROOT / "knowledge" / "tableau"

TABLE_BLOCK_OPEN = "<!-- TABLEAU-ENRICHMENT-TABLE v1 -->"
TABLE_BLOCK_CLOSE = "<!-- /TABLEAU-ENRICHMENT-TABLE -->"
COLS_BLOCK_OPEN = "<!-- TABLEAU-ENRICHMENT-COLS v1 -->"
COLS_BLOCK_CLOSE = "<!-- /TABLEAU-ENRICHMENT-COLS -->"
COLS_SUBHEADING = "### Tableau Usage Notes"

# Columns whose name is a common SQL keyword -> require a qualified match
# (alias.column) to count as a real usage and avoid noise like AS DATE.
SQL_KEYWORD_COLUMNS = {
    "Date", "Time", "Datetime", "Type", "Name", "Value", "Currency",
    "Description", "Status", "Year", "Month", "Day", "Number", "Order",
    "Group", "User", "Source", "Target", "Action", "Level", "Index",
    "Range", "Count", "Sum", "Min", "Max", "Avg",
}

# Maximum workbook names to list per column row before truncating with (+N more)
MAX_WORKBOOKS_PER_ROW = 5


# ---------------------------------------------------------------------------
# Wiki parsing
# ---------------------------------------------------------------------------
@dataclass
class WikiSection:
    name: str           # e.g. "Business Meaning"
    number: int         # e.g. 1
    header_idx: int     # index of "## 1. Business Meaning" line
    body_start: int     # first line after the header
    end_idx: int        # index of the trailing "---" line (the section's closer)


@dataclass
class WikiDoc:
    path: Path
    raw_text: str
    line_ending: str
    lines: List[str]              # text split, without trailing newline
    sections: Dict[int, WikiSection]
    columns: List[str]            # canonical column names from Section 4 Elements table
    object_name: str              # parsed from the H1 header

    @classmethod
    def load(cls, path: Path) -> "WikiDoc":
        raw = path.read_bytes()
        # Detect line ending from first occurrence
        if b"\r\n" in raw:
            line_ending = "\r\n"
        else:
            line_ending = "\n"
        text = raw.decode("utf-8")
        normalized = text.replace("\r\n", "\n")
        lines = normalized.split("\n")
        # Strip trailing empty element if file ends with newline
        # (preserve roundtripping by remembering)
        sections = _parse_sections(lines)
        columns = _parse_element_columns(lines, sections.get(4))
        obj_name = _parse_object_name(lines)
        return cls(
            path=path,
            raw_text=text,
            line_ending=line_ending,
            lines=lines,
            sections=sections,
            columns=columns,
            object_name=obj_name,
        )

    def join_lines(self) -> str:
        return self.line_ending.join(self.lines)


def _parse_object_name(lines: List[str]) -> str:
    for line in lines[:5]:
        m = re.match(r"^#\s+(.+?)\s*$", line)
        if m:
            full = m.group(1).strip()
            # strip optional schema prefix: "BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms"
            return full.split(".")[-1]
    return ""


def _parse_sections(lines: List[str]) -> Dict[int, WikiSection]:
    """Identify ## N. <Name> headers and the trailing --- separator that closes each."""
    headers: List[Tuple[int, int, str]] = []  # (line_idx, section_num, name)
    pat = re.compile(r"^##\s+(\d+)\.\s+(.+?)\s*$")
    for i, line in enumerate(lines):
        m = pat.match(line)
        if m:
            headers.append((i, int(m.group(1)), m.group(2)))

    out: Dict[int, WikiSection] = {}
    for idx, (header_idx, num, name) in enumerate(headers):
        body_start = header_idx + 1
        # End is the next "---" line BEFORE the next section header (or EOF).
        next_header_idx = headers[idx + 1][0] if idx + 1 < len(headers) else len(lines)
        end_idx = -1
        # Walk backwards from next_header_idx to find the last --- line
        # immediately before it (skipping blank lines).
        for j in range(next_header_idx - 1, header_idx, -1):
            stripped = lines[j].strip()
            if stripped == "---":
                end_idx = j
                break
            if stripped:  # non-blank, non-separator content
                break
        if end_idx == -1:
            end_idx = next_header_idx  # fallback: insert just before next header
        out[num] = WikiSection(name=name, number=num, header_idx=header_idx,
                               body_start=body_start, end_idx=end_idx)
    return out


def _parse_element_columns(lines: List[str], section: Optional[WikiSection]) -> List[str]:
    """From Section 4 Elements table, return the column names (col 2 of each data row)."""
    if section is None:
        return []
    columns: List[str] = []
    in_table = False
    seen_header = False
    for i in range(section.body_start, section.end_idx):
        line = lines[i]
        # Match the Elements table header
        if not seen_header and re.match(r"^\|\s*#\s*\|\s*Element\s*\|", line):
            seen_header = True
            in_table = True
            continue
        if in_table:
            # Skip the separator row
            if re.match(r"^\|[\s:|-]+\|\s*$", line):
                continue
            # Stop at first non-table line
            if not line.startswith("|"):
                break
            # Parse data row -> split on "|", take cell index 2 (Element name)
            # Cells: [empty, "1", "DateID", "int", "YES", "Date key ...", empty]
            cells = [c.strip() for c in line.split("|")]
            if len(cells) >= 4:
                # Strip optional backticks from the column name cell
                col = cells[2].strip("`").strip()
                if col:
                    columns.append(col)
    return columns


# ---------------------------------------------------------------------------
# Tableau extract parsing
# ---------------------------------------------------------------------------
@dataclass
class CustomSqlQuery:
    name: str
    body: str


@dataclass
class CalcField:
    name: str
    formula: str
    workbook: str
    datasource: str


@dataclass
class WorkbookRow:
    name: str
    project: str
    owner: str


@dataclass
class TableauExtract:
    path: Path
    custom_sql: List[CustomSqlQuery] = field(default_factory=list)
    calc_fields: List[CalcField] = field(default_factory=list)
    workbooks: List[WorkbookRow] = field(default_factory=list)

    @classmethod
    def load(cls, path: Path) -> "TableauExtract":
        text = path.read_text(encoding="utf-8")
        lines = text.replace("\r\n", "\n").split("\n")
        ex = cls(path=path)
        _parse_tableau_sections(ex, lines)
        return ex


def _parse_tableau_sections(ex: TableauExtract, lines: List[str]) -> None:
    """Walk the Tableau-extract markdown line-by-line."""
    section: Optional[str] = None  # "csql" | "wb" | "calc" | None
    csql_name: Optional[str] = None
    csql_body_lines: List[str] = []
    in_csql_code = False
    cf_workbook = ""
    cf_datasource = ""
    cf_field_name: Optional[str] = None
    cf_formula_lines: List[str] = []
    in_cf_code = False
    in_workbook_table = False
    workbook_table_seen_header = False

    def flush_csql():
        nonlocal csql_name, csql_body_lines
        if csql_name is not None:
            body = "\n".join(csql_body_lines).strip()
            if body:
                ex.custom_sql.append(CustomSqlQuery(name=csql_name, body=body))
        csql_name = None
        csql_body_lines = []

    def flush_cf():
        nonlocal cf_field_name, cf_formula_lines
        if cf_field_name is not None and cf_formula_lines:
            formula = "\n".join(cf_formula_lines).rstrip()
            ex.calc_fields.append(CalcField(
                name=cf_field_name, formula=formula,
                workbook=cf_workbook, datasource=cf_datasource,
            ))
        cf_field_name = None
        cf_formula_lines = []

    for line in lines:
        # Top-level section markers
        if line.startswith("## "):
            # Flush any open per-item state
            if section == "csql":
                flush_csql()
            if section == "calc":
                flush_cf()
            in_csql_code = False
            in_cf_code = False
            in_workbook_table = False
            workbook_table_seen_header = False
            heading = line[3:].strip()
            if heading.startswith("Custom SQL queries"):
                section = "csql"
            elif heading.startswith("Downstream workbooks"):
                section = "wb"
            elif heading.startswith("Downstream calculated fields"):
                section = "calc"
            else:
                section = None
            continue

        if section == "csql":
            # Each query begins with "### N. <name>"
            m = re.match(r"^###\s+\d+\.\s+(.+?)\s*$", line)
            if m and not in_csql_code:
                flush_csql()
                csql_name = m.group(1).strip()
                continue
            if line.strip().startswith("```sql") and csql_name is not None:
                in_csql_code = True
                continue
            if line.strip() == "```" and in_csql_code:
                in_csql_code = False
                continue
            if in_csql_code:
                csql_body_lines.append(line)
            continue

        if section == "wb":
            if not in_workbook_table and re.match(r"^\|\s*#\s*\|\s*Workbook\s*\|", line):
                in_workbook_table = True
                workbook_table_seen_header = True
                continue
            if in_workbook_table:
                if re.match(r"^\|[\s:|-]+\|\s*$", line):
                    continue
                if not line.startswith("|"):
                    in_workbook_table = False
                    continue
                cells = [c.strip() for c in line.split("|")]
                # | "" | # | Workbook | Project | Owner | Last updated | Tableau id | "" |
                if len(cells) >= 6:
                    ex.workbooks.append(WorkbookRow(
                        name=cells[2], project=cells[3], owner=cells[4],
                    ))
            continue

        if section == "calc":
            m_wb = re.match(r"^###\s+Workbook:\s*(.+?)\s*$", line)
            if m_wb:
                flush_cf()
                cf_workbook = m_wb.group(1).strip()
                cf_datasource = ""
                in_cf_code = False
                continue
            m_ds = re.match(r"^####\s+Datasource:\s*(.+?)\s*$", line)
            if m_ds:
                flush_cf()
                cf_datasource = m_ds.group(1).strip()
                in_cf_code = False
                continue
            # Field name -> "- **Field Name**"
            m_field = re.match(r"^-\s+\*\*(.+?)\*\*\s*$", line)
            if m_field and not in_cf_code:
                flush_cf()
                cf_field_name = m_field.group(1).strip()
                continue
            # Formula opening fence: "  ```"
            if cf_field_name is not None:
                stripped = line.strip()
                if stripped == "```" and not in_cf_code:
                    in_cf_code = True
                    continue
                if stripped == "```" and in_cf_code:
                    in_cf_code = False
                    flush_cf()
                    continue
                if in_cf_code:
                    # Strip the leading 2-space indentation that was added during write
                    if line.startswith("  "):
                        cf_formula_lines.append(line[2:])
                    else:
                        cf_formula_lines.append(line)
            continue

    # End-of-file flushes
    if section == "csql":
        flush_csql()
    if section == "calc":
        flush_cf()


# ---------------------------------------------------------------------------
# Column matching
# ---------------------------------------------------------------------------
_STRING_LITERAL_RE = re.compile(r"'(?:[^'\\]|\\.|'')*'", re.DOTALL)


def _strip_sql_strings(sql: str) -> str:
    return _STRING_LITERAL_RE.sub("''", sql)


@dataclass
class ColumnUsage:
    column: str
    sql_count: int = 0
    calc_count: int = 0
    workbooks: List[str] = field(default_factory=list)

    @property
    def total(self) -> int:
        return self.sql_count + self.calc_count


def compute_column_usage(
    columns: List[str],
    extract: TableauExtract,
) -> List[ColumnUsage]:
    """For each wiki column, count occurrences in custom SQL + calc field formulas."""
    # Pre-strip strings from SQL bodies once
    stripped_csql = [(q.body, _strip_sql_strings(q.body)) for q in extract.custom_sql]

    usage: Dict[str, ColumnUsage] = {c: ColumnUsage(column=c) for c in columns}

    # workbook lookup: each calc field already carries its workbook;
    # custom SQL queries are not directly tied to a single workbook in our extract,
    # but they're typically used by the same downstream workbooks listed in
    # extract.workbooks - we attribute SQL hits to "(custom SQL)" pseudo-source.

    for col in columns:
        u = usage[col]
        # Pick regex based on whether col is a SQL keyword
        if col in SQL_KEYWORD_COLUMNS:
            # require qualifier: alias.col
            sql_pat = re.compile(r"\b\w+\." + re.escape(col) + r"\b")
        else:
            sql_pat = re.compile(r"\b" + re.escape(col) + r"\b")
        bracket_pat = re.compile(r"\[" + re.escape(col) + r"\]")

        for _orig, stripped in stripped_csql:
            hits = sql_pat.findall(stripped)
            u.sql_count += len(hits)

        for cf in extract.calc_fields:
            n = len(bracket_pat.findall(cf.formula))
            if n:
                u.calc_count += n
                if cf.workbook and cf.workbook not in u.workbooks:
                    u.workbooks.append(cf.workbook)

    return [u for u in usage.values()]


# ---------------------------------------------------------------------------
# Block builders
# ---------------------------------------------------------------------------
def build_table_block(extract: TableauExtract) -> List[str]:
    """Section 1 fenced summary block."""
    n_wb = len(extract.workbooks)
    projects = sorted({w.project for w in extract.workbooks if w.project})
    owners = sorted({w.owner for w in extract.workbooks if w.owner})
    n_csql = len(extract.custom_sql)
    n_cf = len(extract.calc_fields)

    # Top consumers by calc-field count
    cf_per_wb: Dict[str, int] = {}
    for cf in extract.calc_fields:
        cf_per_wb[cf.workbook] = cf_per_wb.get(cf.workbook, 0) + 1
    top_wbs = [name for name, _ in sorted(cf_per_wb.items(), key=lambda x: -x[1])[:3] if name]
    if not top_wbs and extract.workbooks:
        top_wbs = [w.name for w in extract.workbooks[:3]]

    rel_path = extract.path.relative_to(REPO_ROOT).as_posix()

    summary_parts = [
        f"{n_wb} workbook{'s' if n_wb != 1 else ''}"
        + (f" across {len(projects)} project{'s' if len(projects) != 1 else ''}" if projects else "")
        + (f" ({len(owners)} owner{'s' if len(owners) != 1 else ''})" if owners else ""),
        f"{n_csql} custom SQL quer{'ies' if n_csql != 1 else 'y'}",
        f"{n_cf} calculated field{'s' if n_cf != 1 else ''}",
    ]
    summary = ", ".join(summary_parts)

    block: List[str] = []
    block.append(TABLE_BLOCK_OPEN)
    block.append(f"> **Downstream Tableau usage**: {summary}.")
    if top_wbs:
        formatted = ", ".join(f"*{w}*" for w in top_wbs)
        block.append(f"> Top consumers: {formatted}.")
    block.append(f"> Full extract: `{rel_path}`.")
    block.append("> _(auto-generated by `tools/tableau/enrich_wiki_with_tableau.py`; safe to delete -- regenerable)_")
    block.append(TABLE_BLOCK_CLOSE)
    return block


def build_cols_block(usages: List[ColumnUsage]) -> List[str]:
    matched = [u for u in usages if u.total > 0]
    matched.sort(key=lambda u: (-u.total, u.column.lower()))

    block: List[str] = []
    block.append(COLS_SUBHEADING)
    block.append("")
    block.append(COLS_BLOCK_OPEN)
    block.append("Auto-generated map of wiki columns to downstream Tableau usage.")
    block.append("Counts come from regex matches against custom SQL bodies and")
    block.append("calculated-field formulas in the corresponding Tableau extract.")
    block.append("")
    if not matched:
        block.append("_No wiki columns matched any custom SQL or calc-field formula. The")
        block.append("table may be referenced indirectly via published datasources or via")
        block.append("aliased columns that we cannot match by name alone._")
    else:
        block.append("| Column | Custom SQL refs | Calc field refs | Workbooks (calc fields) |")
        block.append("|---|---:|---:|---|")
        for u in matched:
            wbs = u.workbooks
            shown = wbs[:MAX_WORKBOOKS_PER_ROW]
            if len(wbs) > MAX_WORKBOOKS_PER_ROW:
                shown_str = ", ".join(shown) + f" (+{len(wbs) - MAX_WORKBOOKS_PER_ROW} more)"
            else:
                shown_str = ", ".join(shown) if shown else "_(custom SQL only)_"
            block.append(
                f"| `{u.column}` | {u.sql_count} | {u.calc_count} | {shown_str} |"
            )
        block.append("")
        block.append("_Columns from Section 4 not appearing here had no detected matches in")
        block.append("custom SQL or calc-field formulas (may still be referenced indirectly)._")
    block.append(COLS_BLOCK_CLOSE)
    return block


# ---------------------------------------------------------------------------
# Wiki mutation
# ---------------------------------------------------------------------------
def _strip_block(lines: List[str], open_marker: str, close_marker: str,
                 also_strip_subheading: Optional[str] = None) -> List[str]:
    """Remove the fenced block (and optional preceding subheading + blank line)."""
    out = list(lines)
    open_idx = next((i for i, l in enumerate(out) if l.strip() == open_marker), -1)
    if open_idx == -1:
        return out
    close_idx = next(
        (j for j in range(open_idx + 1, len(out)) if out[j].strip() == close_marker), -1
    )
    if close_idx == -1:
        return out

    start = open_idx
    end = close_idx
    # Eat a single trailing blank line after close
    if end + 1 < len(out) and out[end + 1].strip() == "":
        end += 1
    # Eat a single leading blank line before open
    if start - 1 >= 0 and out[start - 1].strip() == "":
        start -= 1

    # Optionally also strip the subheading + its trailing blank line that we added
    if also_strip_subheading is not None:
        # The subheading should immediately precede the (blank line +) open marker
        sh_idx = -1
        for j in range(start - 1, max(start - 4, -1), -1):
            if out[j].strip() == also_strip_subheading.strip():
                sh_idx = j
                break
        if sh_idx >= 0:
            # Eat blank line(s) between subheading and start
            new_start = sh_idx
            # Eat a single leading blank line before subheading
            if new_start - 1 >= 0 and out[new_start - 1].strip() == "":
                new_start -= 1
            start = new_start

    return out[:start] + out[end + 1:]


def _insert_block(lines: List[str], section: WikiSection, block_lines: List[str]) -> List[str]:
    """Insert block_lines just before the section's closing --- separator."""
    out = list(lines)
    insert_at = section.end_idx
    # Walk back over a single trailing blank line so we insert AFTER content
    # and BEFORE that blank+separator pair.
    while insert_at - 1 > section.body_start and out[insert_at - 1].strip() == "":
        insert_at -= 1
    # Now insert: blank line, block lines, blank line
    payload = [""] + block_lines + [""]
    out[insert_at:insert_at] = payload
    return out


def remove_blocks(doc: WikiDoc) -> str:
    new_lines = doc.lines
    new_lines = _strip_block(new_lines, TABLE_BLOCK_OPEN, TABLE_BLOCK_CLOSE)
    new_lines = _strip_block(
        new_lines, COLS_BLOCK_OPEN, COLS_BLOCK_CLOSE,
        also_strip_subheading=COLS_SUBHEADING,
    )
    # Rebuild section index? Not needed for output — just join
    return doc.line_ending.join(new_lines)


def apply_blocks(doc: WikiDoc, extract: TableauExtract) -> str:
    # Always start from a "removed" baseline so re-runs replace cleanly
    baseline_text = remove_blocks(doc)
    baseline_lines = baseline_text.split(doc.line_ending)
    # Re-parse sections from the baseline because indices shifted
    sections = _parse_sections(baseline_lines)

    table_block = build_table_block(extract)
    cols_block = build_cols_block(compute_column_usage(doc.columns, extract))

    new_lines = baseline_lines
    # Insert in REVERSE order (later section first) so earlier indices stay valid.
    if 4 in sections:
        new_lines = _insert_block(new_lines, sections[4], cols_block)
    # Re-parse for accurate Section 1 end_idx
    sections = _parse_sections(new_lines)
    if 1 in sections:
        new_lines = _insert_block(new_lines, sections[1], table_block)

    return doc.line_ending.join(new_lines)


# ---------------------------------------------------------------------------
# Path resolution + diff helpers
# ---------------------------------------------------------------------------
def auto_resolve_tableau(wiki: WikiDoc) -> Optional[Path]:
    if not wiki.object_name:
        return None
    matches = sorted(KNOWLEDGE_TABLEAU.glob(f"*/{wiki.object_name}.md"))
    return matches[0] if matches else None


def expand_wiki_arg(value: str) -> List[Path]:
    out: List[Path] = []
    for token in value.split(","):
        token = token.strip()
        if not token:
            continue
        if any(ch in token for ch in "*?["):
            for hit in glob.glob(token, recursive=True):
                p = Path(hit).resolve()
                if p.is_file() and p not in out:
                    out.append(p)
        else:
            p = Path(token)
            if not p.is_absolute():
                p = (REPO_ROOT / p).resolve()
            else:
                p = p.resolve()
            if p.is_file() and p not in out:
                out.append(p)
    return out


def make_diff(before: str, after: str, label: str) -> str:
    return "".join(
        difflib.unified_diff(
            before.splitlines(keepends=True),
            after.splitlines(keepends=True),
            fromfile=f"{label} (before)",
            tofile=f"{label} (after)",
            n=3,
        )
    )


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------
def process_one(
    wiki_path: Path,
    tableau_path_explicit: Optional[Path],
    mode: str,
    diff_chunks: List[str],
) -> Tuple[bool, str]:
    """Returns (ok, message)."""
    if not wiki_path.exists():
        return False, f"wiki not found: {wiki_path}"

    doc = WikiDoc.load(wiki_path)

    if mode == "remove":
        new_text = remove_blocks(doc)
        if new_text == doc.raw_text.replace("\r\n", "\n").replace("\n", doc.line_ending):
            return True, f"{wiki_path.name}: no fenced blocks present"
        diff_chunks.append(make_diff(doc.raw_text, new_text, str(wiki_path)))
        wiki_path.write_bytes(new_text.encode("utf-8"))
        return True, f"{wiki_path.name}: removed enrichment blocks"

    # apply / dry-run path -> need a tableau extract
    tableau_path = tableau_path_explicit or auto_resolve_tableau(doc)
    if tableau_path is None or not tableau_path.exists():
        return False, (
            f"{wiki_path.name}: no Tableau extract found "
            f"(looked for knowledge/tableau/*/{doc.object_name}.md). "
            "Pass --tableau explicitly or run extract_table_metadata.py first."
        )

    extract = TableauExtract.load(tableau_path)
    if 4 not in doc.sections:
        return False, f"{wiki_path.name}: cannot find Section 4 (Elements) - skipping"
    if 1 not in doc.sections:
        return False, f"{wiki_path.name}: cannot find Section 1 (Business Meaning) - skipping"

    new_text = apply_blocks(doc, extract)
    diff = make_diff(doc.raw_text, new_text, str(wiki_path))
    diff_chunks.append(diff)
    n_csql = len(extract.custom_sql)
    n_cf = len(extract.calc_fields)
    n_wb = len(extract.workbooks)
    n_match = sum(1 for u in compute_column_usage(doc.columns, extract) if u.total > 0)

    if mode == "apply":
        wiki_path.write_bytes(new_text.encode("utf-8"))
        return True, (
            f"{wiki_path.name}: applied "
            f"(workbooks={n_wb}, custom_sql={n_csql}, calc_fields={n_cf}, matched_columns={n_match})"
        )

    # dry-run
    preview_path = wiki_path.with_suffix(wiki_path.suffix + ".tableau-enriched.md")
    preview_path.write_bytes(new_text.encode("utf-8"))
    return True, (
        f"{wiki_path.name}: DRY-RUN preview at {preview_path.name} "
        f"(workbooks={n_wb}, custom_sql={n_csql}, calc_fields={n_cf}, matched_columns={n_match})"
    )


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    p.add_argument("--wiki", required=True, help="Wiki path(s) - comma-separated or glob")
    p.add_argument("--tableau", default="", help="Explicit Tableau extract path (optional)")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--dry-run", action="store_true", help="Default: write preview file + show diff")
    g.add_argument("--apply", action="store_true", help="Rewrite wiki in place")
    g.add_argument("--remove", action="store_true", help="Strip enrichment blocks from the wiki")
    p.add_argument("--out-diff", default="", help="Also write diff to this path")
    args = p.parse_args()

    if args.apply:
        mode = "apply"
    elif args.remove:
        mode = "remove"
    else:
        mode = "dry-run"

    wiki_paths = expand_wiki_arg(args.wiki)
    if not wiki_paths:
        print("No wiki paths matched.", file=sys.stderr)
        return 2

    tableau_explicit: Optional[Path] = None
    if args.tableau:
        tp = Path(args.tableau)
        if not tp.is_absolute():
            tp = (REPO_ROOT / tp).resolve()
        tableau_explicit = tp

    diff_chunks: List[str] = []
    ok_count = 0
    fail_count = 0
    for wp in wiki_paths:
        ok, msg = process_one(wp, tableau_explicit, mode, diff_chunks)
        prefix = "OK  " if ok else "ERR "
        print(f"{prefix}{msg}")
        if ok:
            ok_count += 1
        else:
            fail_count += 1

    combined_diff = "\n".join(c for c in diff_chunks if c)
    if combined_diff:
        print()
        print("--- DIFF ---")
        print(combined_diff)
    if args.out_diff and combined_diff:
        Path(args.out_diff).write_text(combined_diff, encoding="utf-8")
        print(f"Wrote diff to {args.out_diff}")

    print()
    print(f"Done. ok={ok_count} fail={fail_count} mode={mode}")
    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
