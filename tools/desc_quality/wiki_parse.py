"""
Wiki table parser for §4 Output Columns / Elements tables.

Each Synapse-mirror wiki has a markdown table that lists output columns. The
table header varies across the corpus:

    | # | Column | Source | Transformation | Tier |             (V_Liabilities, Functions)
    | # | Column | Type | Source | Description |               (V_Fact_SnapshotEquity_*)
    | # | Column | Type | Nullable | Description |             (many Tables)
    | # | Column | Type | Nullable | Source | Description |    (v_Dim_Mirror, Vw_STS_...)
    | # | Column | Source | Transform | Tier |                 (BI_DB_Finance_Audit_*)
    | # | Column | Type | Tier | Description |                 (BI_DB_ASIC_*)
    | # | Column | Type | Description |                        (Dim_Customer nested)

The "semantic-carrying" cell is whichever of {Transformation, Transform,
Description} appears in the header (first hit wins, in that order — when both
are present, "Transformation" carries the math, "Description" carries prose).

Returns parsed rows with these fields:
    idx, column, type, nullable, source, semantic_cell, semantic_header, tier, raw_row_text
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


SEMANTIC_HEADERS_PRIORITY = ("Transformation", "Transform", "Description")
SOURCE_HEADERS = ("Source",)
# Header cell values that name the column-of-columns. We accept either; some
# wikis use `Element` instead of `Column` (e.g. Dim_DocumentStatus).
COLUMN_HEADER_CELLS = ("Column", "Element")
HEADING_RE = re.compile(r"^##\s+4\.\s+(.+?)\s*$", re.MULTILINE)
SECTION_3_HEADING_RE = re.compile(r"^##\s+3\.\s+(.+?)\s*$", re.MULTILINE)
# §3 headings we will mine for upstream object lists. The canonical title is
# "Source Objects" (BI_DB function wikis, V_Liabilities etc.). Some Tables-style
# wikis don't have this section; we don't synthesize one.
SECTION_3_ALLOWED = {"Source Objects", "Sources"}
# Headings we DO want to grade. Skip Live Data Verification / Known Issues / etc.
SECTION_4_ALLOWED = {
    "Output Columns",
    "Elements",
    "Data Elements",
    "Columns",
    "Schema",
}


@dataclass
class ParsedRow:
    idx: str
    column: str
    type: str
    nullable: str
    source: str
    semantic_cell: str
    semantic_header: str
    tier: str
    raw_row_text: str


@dataclass
class ParsedTable:
    wiki_path: Path
    section_4_title: str
    headers: list[str]
    rows: list[ParsedRow]
    has_source_column: bool
    semantic_header_used: str | None
    # When section 4 is not a column table (e.g. Live Data Verification), rows is empty
    # and skipped_reason is set.
    skipped_reason: str | None = None


def _find_section_4(text: str) -> tuple[str | None, int | None]:
    """Return (section_title, start_offset_after_heading) or (None, None) if no ## 4. heading."""
    m = HEADING_RE.search(text)
    if not m:
        return None, None
    return m.group(1).strip(), m.end()


def _find_section_3(text: str) -> tuple[str | None, int | None]:
    m = SECTION_3_HEADING_RE.search(text)
    if not m:
        return None, None
    return m.group(1).strip(), m.end()


def parse_section_3_source_objects(wiki_path: Path) -> list[str]:
    """Extract bare object names listed in `## 3. Source Objects` (or `Sources`).

    Returns [] if §3 is absent, is not a recognized heading, or has no
    `| Object | …` table.
    """
    text = wiki_path.read_text(encoding="utf-8", errors="replace")
    title, after = _find_section_3(text)
    if not title or after is None:
        return []
    if title not in SECTION_3_ALLOWED:
        return []
    body = _slice_until_next_section(text, after)
    lines = body.splitlines()
    # Find a table whose header has a cell named exactly `Object`.
    header_idx = None
    for i, ln in enumerate(lines):
        stripped = ln.strip()
        if not stripped.startswith("|") or "---" in stripped:
            continue
        cells = _split_table_row(ln)
        if "Object" in cells:
            nxt = lines[i + 1].strip() if i + 1 < len(lines) else ""
            if nxt.startswith("|") and "---" in nxt:
                header_idx = i
                break
    if header_idx is None:
        return []
    headers = _split_table_row(lines[header_idx])
    obj_col = headers.index("Object")
    out: list[str] = []
    for ln in lines[header_idx + 2 :]:
        stripped = ln.strip()
        if not stripped.startswith("|"):
            break
        if "---" in stripped:
            break
        parts = _split_table_row(ln)
        if obj_col >= len(parts):
            continue
        name = parts[obj_col].strip().strip("`").strip("[").strip("]")
        if name:
            out.append(name)
    return out


def _slice_until_next_section(text: str, start: int) -> str:
    """Return text from `start` until the next `## ` heading (any level-2)."""
    next_h = re.search(r"^##\s+", text[start:], re.MULTILINE)
    if not next_h:
        return text[start:]
    return text[start : start + next_h.start()]


def _split_table_row(line: str) -> list[str]:
    parts = line.strip().split("|")
    # Strip the leading and trailing empties from the pipe split.
    if parts and parts[0].strip() == "":
        parts = parts[1:]
    if parts and parts[-1].strip() == "":
        parts = parts[:-1]
    return [p.strip() for p in parts]


def _find_all_table_headers(lines: list[str]) -> list[int]:
    """Return indices (into `lines`) of every markdown table header in this slice.

    A line counts as a header when:
      - it starts with `|`, is NOT a separator (`---`),
      - has at least one cell equal to `Column` or `Element`,
      - is followed by a separator row.
    """
    out: list[int] = []
    for i, ln in enumerate(lines):
        stripped = ln.strip()
        if not stripped.startswith("|") or "---" in stripped:
            continue
        cells = _split_table_row(ln)
        if any(c in COLUMN_HEADER_CELLS for c in cells):
            nxt = lines[i + 1].strip() if i + 1 < len(lines) else ""
            if nxt.startswith("|") and "---" in nxt:
                out.append(i)
    return out


def _parse_one_subtable(
    lines: list[str], header_idx: int
) -> tuple[list[str], str | None, list[ParsedRow]]:
    """Parse a single sub-table starting at `header_idx`.

    Returns (headers, semantic_header_used_or_None, rows). If the table has no
    semantic-carrying header, returns ([], None, []) — caller decides.
    """
    headers = _split_table_row(lines[header_idx])
    semantic_header = next((h for h in SEMANTIC_HEADERS_PRIORITY if h in headers), None)
    if semantic_header is None:
        return headers, None, []

    col_idx = {h: i for i, h in enumerate(headers)}
    col_name_header = next((h for h in COLUMN_HEADER_CELLS if h in col_idx), None)
    rows: list[ParsedRow] = []
    for ln in lines[header_idx + 2 :]:
        stripped = ln.strip()
        if not stripped.startswith("|"):
            break
        if "---" in stripped:
            break  # next sub-table starts; the caller will see the new header next iteration
        parts = _split_table_row(ln)
        if len(parts) != len(headers):
            break

        def cell(name: str) -> str:
            i = col_idx.get(name)
            if i is None or i >= len(parts):
                return ""
            return parts[i]

        rows.append(
            ParsedRow(
                idx=cell("#"),
                column=cell(col_name_header) if col_name_header else "",
                type=cell("Type"),
                nullable=cell("Nullable"),
                source=cell("Source"),
                semantic_cell=cell(semantic_header),
                semantic_header=semantic_header,
                tier=cell("Tier"),
                raw_row_text=ln.rstrip(),
            )
        )
    return headers, semantic_header, rows


def parse_wiki(wiki_path: Path) -> ParsedTable:
    text = wiki_path.read_text(encoding="utf-8", errors="replace")
    title, after_heading = _find_section_4(text)
    if not title or after_heading is None:
        return ParsedTable(
            wiki_path=wiki_path,
            section_4_title="",
            headers=[],
            rows=[],
            has_source_column=False,
            semantic_header_used=None,
            skipped_reason="no_section_4",
        )
    if title not in SECTION_4_ALLOWED:
        return ParsedTable(
            wiki_path=wiki_path,
            section_4_title=title,
            headers=[],
            rows=[],
            has_source_column=False,
            semantic_header_used=None,
            skipped_reason=f"section_4_not_a_column_table:{title}",
        )

    body = _slice_until_next_section(text, after_heading)
    lines = body.splitlines()
    header_indices = _find_all_table_headers(lines)
    if not header_indices:
        return ParsedTable(
            wiki_path=wiki_path,
            section_4_title=title,
            headers=[],
            rows=[],
            has_source_column=False,
            semantic_header_used=None,
            skipped_reason="no_column_table",
        )

    primary_headers: list[str] = []
    primary_semantic: str | None = None
    has_source_column = False
    all_rows: list[ParsedRow] = []
    seen_columns: set[str] = set()
    for hi in header_indices:
        headers, semantic_header, rows = _parse_one_subtable(lines, hi)
        if not primary_headers:
            primary_headers = headers
        if primary_semantic is None and semantic_header is not None:
            primary_semantic = semantic_header
        if "Source" in headers:
            has_source_column = True
        # Deduplicate by column name (case-insensitive). First sub-table wins
        # when the same column appears twice — defensive; rare in practice.
        for r in rows:
            key = r.column.lower()
            if key in seen_columns:
                continue
            seen_columns.add(key)
            all_rows.append(r)

    if primary_semantic is None:
        return ParsedTable(
            wiki_path=wiki_path,
            section_4_title=title,
            headers=primary_headers,
            rows=[],
            has_source_column=has_source_column,
            semantic_header_used=None,
            skipped_reason="no_semantic_header",
        )

    return ParsedTable(
        wiki_path=wiki_path,
        section_4_title=title,
        headers=primary_headers,
        rows=all_rows,
        has_source_column=has_source_column,
        semantic_header_used=primary_semantic,
    )
