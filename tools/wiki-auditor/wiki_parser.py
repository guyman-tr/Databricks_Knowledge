"""Wiki parsing helpers for the post-run auditor.

Parses three artifacts:
1. Wiki .md element table (downstream wikis under knowledge/synapse/Wiki/{schema}/Tables/)
2. .lineage.md companion file (column-level upstream mapping)
3. Inline (Tier X -- src.col) suffix in element row descriptions (fallback)

The auditor never modifies these files; this module is read-only.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional


# --- Tier suffix parsing -----------------------------------------------------

# Tier values seen: 1, 2, 2b, 3, 3b, 4, 5. Dash variants: -, --, em-dash, en-dash.
# Match the START of a tier marker; the closing ')' is found by balanced-paren walk
# in `parse_tier_suffix` so nested groups like
#   (Tier 4 — Confluence, Conversion fee Revenue Calculation (PIP in USD))
# parse correctly.
_TIER_OPEN_RE = re.compile(
    r"\(Tier\s+(?P<tier>\d+[a-z]?)\s*[\-\u2013\u2014]+\s*",
    re.IGNORECASE,
)
# Confluence is a special Tier 4 sub-type.
_CONFLUENCE_HINT_RE = re.compile(r"confluence", re.IGNORECASE)
# Source-table.column pattern inside the tier suffix, e.g. "Fact_*_State.PIPsInUSD".
_TABLE_COL_RE = re.compile(r"\b([A-Za-z][A-Za-z0-9_*]*)\.([A-Za-z_][A-Za-z0-9_]*)\b")
# Confluence URL pattern.
_CONFLUENCE_URL_RE = re.compile(r"https?://[^\s)\]]*atlassian\.net[^\s)\]]*", re.IGNORECASE)


@dataclass
class TierInfo:
    raw: str  # e.g. "Tier 2 -- SP_DepositWithdrawFee, Fact_*_State.PIPsInUSD"
    tier: str  # "1", "2", "2b", "3", "3b", "4", "5"
    is_confluence: bool  # True iff "Confluence" appears in source label
    source_label: str  # everything after the dash, e.g. "SP_X" or "Confluence, page name"


def parse_tier_suffix(description: str) -> Optional[TierInfo]:
    """Pull the (Tier ...) suffix out of an element-row description.

    Returns None if no recognisable tier marker is present.
    Strategy:
      1. Find the LAST `(Tier N ...` opening (handles mid-description tier markers
         and ignores any nested `(Tier ...)` that don't end at description end).
      2. From that position, walk paren depth to find the matching closing `)`.
      3. Source label = text between the dash and that closing `)`.
    """
    desc = description.rstrip()
    starts = [m for m in _TIER_OPEN_RE.finditer(desc)]
    if not starts:
        return None
    # Prefer a tier suffix whose matched closing ')' is at end-of-string. If
    # multiple candidates qualify, take the last one. Otherwise fall back to
    # the last opening anywhere.
    best_open = starts[-1]
    best_end = -1
    for m in reversed(starts):
        end = _find_balanced_close(desc, m.start())
        if end == -1:
            continue
        # Prefer a suffix that is at end-of-string after stripping right whitespace.
        if end == len(desc):
            best_open = m
            best_end = end
            break
        if best_end == -1:
            best_open = m
            best_end = end
    if best_end == -1:
        # No balanced close found for any opening. Bail.
        return None
    open_pos = best_open.start()
    tier = best_open.group("tier")
    # Source label = text between the dash-region (already consumed by the regex)
    # and the closing ')'. The opening regex consumed up to the trailing `\s*`,
    # so source starts at best_open.end().
    source = desc[best_open.end() : best_end - 1].strip()
    raw = desc[open_pos + 1 : best_end - 1]
    return TierInfo(
        raw=raw,
        tier=tier,
        is_confluence=bool(_CONFLUENCE_HINT_RE.search(source)),
        source_label=source,
    )


def _find_balanced_close(text: str, open_paren_pos: int) -> int:
    """Given the index of an opening '(' in `text`, return the index *after*
    its matching ')'. Returns -1 if unbalanced.
    """
    if open_paren_pos >= len(text) or text[open_paren_pos] != "(":
        return -1
    depth = 0
    for i in range(open_paren_pos, len(text)):
        ch = text[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i + 1
    return -1


def description_without_tier_suffix(description: str) -> str:
    """Return the description text with the trailing (Tier ...) suffix stripped.

    If the tier suffix is mid-description (rare) we leave it in place; only an
    end-of-string suffix is stripped, since that's the canonical form generated
    by the doc pipeline.
    """
    desc = description.rstrip()
    starts = [m for m in _TIER_OPEN_RE.finditer(desc)]
    if not starts:
        return desc
    # Walk in reverse: find the latest tier opening whose balanced close lands
    # at end-of-string. Strip from the opening paren onwards.
    for m in reversed(starts):
        end = _find_balanced_close(desc, m.start())
        if end == len(desc):
            return desc[: m.start()].rstrip(" .;")
    return desc


def extract_table_column_hints(source_label: str) -> list[tuple[str, str]]:
    """Pull (table, column) pairs out of a tier-suffix source label.

    Example input: "SP_DepositWithdrawFee, Fact_*_State.PIPsInUSD"
    Output:        [("Fact_*_State", "PIPsInUSD")]
    """
    return [(m.group(1), m.group(2)) for m in _TABLE_COL_RE.finditer(source_label)]


# --- Element table parsing ---------------------------------------------------

# The doc pipeline emits three element-table schemas:
#
# Variant A (golden):     | # | Column | Type | Nullable | Description |
# Variant B (with cols):  | Column | Type | Description | Tier | Source |
# Variant C (compact):    | Column | Type | Description |
#                         (tier embedded inline in description as "(Tier X -- ...)")
#
# Some wikis (e.g. wide CID panels) have several Variant B/C tables grouped under
# `### 3A`, `### 3B` ... headings. The parser walks the whole file and merges
# rows from every recognised table.
_ELEMENT_HEADER_A_RE = re.compile(
    r"^\s*\|\s*#\s*\|\s*(Column|Element)\s*\|\s*Type\s*\|",
    re.IGNORECASE,
)
_ELEMENT_HEADER_B_RE = re.compile(
    r"^\s*\|\s*Column\s*\|\s*Type\s*\|\s*Description\s*\|\s*Tier\s*\|\s*Source\s*\|\s*$",
    re.IGNORECASE,
)
_ELEMENT_HEADER_C_RE = re.compile(
    r"^\s*\|\s*Column\s*\|\s*Type\s*\|\s*Description\s*\|\s*$",
    re.IGNORECASE,
)
_ELEMENT_DIVIDER_RE = re.compile(r"^\s*\|[\s\-:|]+\|\s*$")
_INLINE_TIER_RE = re.compile(r"^\s*T?(\d+)([a-z])?(?:\s*[-\u2013\u2014]\s*(.+))?$", re.IGNORECASE)


@dataclass
class ElementRow:
    index: int  # ordinal "#" column (1-based)
    name: str
    dtype: str
    nullable: str  # "YES"/"NO" usually
    description: str
    line_no: int  # 1-based line in the source file (for patch targeting)
    tier: Optional[TierInfo] = None


def parse_element_table(wiki_text: str) -> list[ElementRow]:
    """Extract rows from every recognised element table in a wiki .md file.

    Supports both schemas (variant A and variant B). Variant B tables can
    appear multiple times in a single wiki (sectioned 3A/3B/3C...); rows are
    accumulated across all of them.
    """
    lines = wiki_text.splitlines()
    rows: list[ElementRow] = []
    state = "scan"  # "scan" | "in_a" | "in_b" | "in_c"
    header_seen = False
    synthetic_ord = 0  # used for variant B/C since they have no ordinal column

    for idx, raw_line in enumerate(lines, start=1):
        if state == "scan":
            if _ELEMENT_HEADER_A_RE.match(raw_line):
                state = "in_a"
                header_seen = False
                continue
            if _ELEMENT_HEADER_B_RE.match(raw_line):
                state = "in_b"
                header_seen = False
                continue
            if _ELEMENT_HEADER_C_RE.match(raw_line):
                state = "in_c"
                header_seen = False
                continue
            continue
        if not header_seen:
            if _ELEMENT_DIVIDER_RE.match(raw_line):
                header_seen = True
            continue
        line = raw_line.rstrip()
        if not line.startswith("|") or line.strip() == "|":
            # Table ended -- resume scanning for the next one.
            state = "scan"
            header_seen = False
            continue
        cells = _split_md_row(line)
        if state == "in_a":
            if len(cells) < 5:
                state = "scan"
                continue
            try:
                ord_n = int(cells[0])
            except ValueError:
                continue
            name = cells[1].strip("`* ")
            dtype = cells[2].strip()
            nullable = cells[3].strip()
            description = cells[4].strip()
            tier = parse_tier_suffix(description)
            rows.append(
                ElementRow(
                    index=ord_n,
                    name=name,
                    dtype=dtype,
                    nullable=nullable,
                    description=description,
                    line_no=idx,
                    tier=tier,
                )
            )
        elif state == "in_b":
            if len(cells) < 4:
                state = "scan"
                continue
            name = cells[0].strip("`* ")
            dtype = cells[1].strip()
            description_body = cells[2].strip()
            tier_cell = cells[3].strip() if len(cells) > 3 else ""
            source_cell = cells[4].strip() if len(cells) > 4 else ""
            synthetic_ord += 1
            tier = parse_tier_suffix(description_body)
            if tier is None and tier_cell:
                tier = _tier_from_cells(tier_cell, source_cell)
            # Reconstruct a "full" description that downstream rules can read,
            # appending a synthesised tier suffix so MECH_ONLY etc. behave
            # consistently across both schemas.
            description = description_body
            if tier and "(Tier" not in description:
                description = f"{description} ({tier.raw})"
            rows.append(
                ElementRow(
                    index=synthetic_ord,
                    name=name,
                    dtype=dtype,
                    nullable="",
                    description=description,
                    line_no=idx,
                    tier=tier,
                )
            )
        elif state == "in_c":
            if len(cells) < 3:
                state = "scan"
                continue
            name = cells[0].strip("`* ")
            dtype = cells[1].strip()
            description = cells[2].strip()
            synthetic_ord += 1
            tier = parse_tier_suffix(description)
            rows.append(
                ElementRow(
                    index=synthetic_ord,
                    name=name,
                    dtype=dtype,
                    nullable="",
                    description=description,
                    line_no=idx,
                    tier=tier,
                )
            )
    return rows


def _tier_from_cells(tier_cell: str, source_cell: str) -> Optional[TierInfo]:
    """Build a TierInfo from the variant-B 'Tier' and 'Source' columns.

    Tier cell formats observed: `T1`, `T2`, `T4-Confluence`, `1`, `2`,
    `Tier 2`, `T4 — Confluence`. Confluence detection is on the union
    of tier_cell + source_cell so URLs in source still get caught.
    """
    raw = tier_cell.strip()
    m = _INLINE_TIER_RE.match(raw)
    if not m:
        return None
    tier_num = m.group(1)
    sub = m.group(2) or ""
    inline_label = m.group(3) or ""
    label_text = " ".join(p for p in [inline_label, source_cell] if p).strip()
    is_confluence = bool(_CONFLUENCE_HINT_RE.search(label_text)) or bool(
        _CONFLUENCE_HINT_RE.search(raw)
    )
    raw_combined = f"Tier {tier_num}{sub} - {label_text}" if label_text else f"Tier {tier_num}{sub}"
    return TierInfo(
        raw=raw_combined,
        tier=f"{tier_num}{sub}".lower(),
        is_confluence=is_confluence,
        source_label=label_text,
    )


def _split_md_row(line: str) -> list[str]:
    """Split a markdown table row into trimmed cells."""
    parts = line.split("|")
    if parts and parts[0] == "":
        parts = parts[1:]
    if parts and parts[-1] == "":
        parts = parts[:-1]
    return [p.strip() for p in parts]


# --- Confluence detection on a wiki ------------------------------------------


def wiki_has_confluence_links(wiki_text: str) -> bool:
    """Heuristic: True if the wiki cites at least one Atlassian/Confluence URL."""
    return bool(_CONFLUENCE_URL_RE.search(wiki_text))


# --- Lineage file parsing ----------------------------------------------------

_LINEAGE_HEADER_RE = re.compile(
    r"^\s*\|\s*DWH\s+Column\s*\|\s*Source\s+Table\s*\|\s*Source\s+Column\s*\|",
    re.IGNORECASE,
)
# Source-table values that mean "no real upstream wiki to look up".
_LINEAGE_SYNTHETIC_SOURCES = {
    "multi-source",
    "sp parameter",
    "sp",
    "computed",
    "etl-computed",
    "constant",
    "literal",
    "n/a",
    "-",
    "",
}


@dataclass
class LineageRow:
    dwh_column: str
    source_table: str  # may be "Multi-source" etc.
    source_column: str  # may be "Computed", "@param", or "alias.col"
    transform: str
    notes: str
    is_synthetic: bool  # True when source_table is non-resolvable

    @property
    def resolved_source_column(self) -> Optional[str]:
        """Strip alias prefix from source_column. Returns None if synthetic."""
        if self.is_synthetic:
            return None
        col = self.source_column.strip()
        if not col or col.startswith("@") or col.lower() in {"computed", "passthrough"}:
            return None
        # Take the first token if multiple aliases listed (e.g. "cb.CID / i.CID")
        first = col.split("/")[0].strip()
        if "." in first:
            first = first.split(".")[-1]
        # Strip backticks / asterisks.
        first = first.strip("`* ")
        if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", first):
            return None
        return first


def parse_lineage_file(text: str) -> list[LineageRow]:
    """Parse the column-lineage table from a .lineage.md file."""
    lines = text.splitlines()
    rows: list[LineageRow] = []
    in_table = False
    header_seen = False
    for raw_line in lines:
        if not in_table:
            if _LINEAGE_HEADER_RE.match(raw_line):
                in_table = True
                header_seen = False
            continue
        if not header_seen:
            if _ELEMENT_DIVIDER_RE.match(raw_line):
                header_seen = True
            continue
        if not raw_line.lstrip().startswith("|"):
            break
        cells = _split_md_row(raw_line)
        if len(cells) < 4:
            break
        col, src_tbl, src_col, transform = cells[:4]
        notes = cells[4] if len(cells) >= 5 else ""
        is_synthetic = src_tbl.strip().lower() in _LINEAGE_SYNTHETIC_SOURCES
        rows.append(
            LineageRow(
                dwh_column=col.strip("`* "),
                source_table=src_tbl.strip(),
                source_column=src_col.strip(),
                transform=transform.strip(),
                notes=notes.strip(),
                is_synthetic=is_synthetic,
            )
        )
    return rows


# --- Upstream wiki resolution -------------------------------------------------


@dataclass
class UpstreamPointer:
    """A resolved upstream lookup target derived from lineage or tier suffix."""

    table: str  # e.g. "Fact_Deposit_State" (wildcards already expanded by caller)
    column: str  # downstream column maps to this upstream column
    schema_hint: Optional[str] = None  # if known, e.g. "DWH_dbo"
    via: str = "lineage"  # "lineage" | "tier_suffix"


def upstream_pointers_for_object(
    wiki_path: Path,
    elements: list[ElementRow],
    lineage_rows: Optional[list[LineageRow]],
) -> dict[str, list[UpstreamPointer]]:
    """For every element row, return any upstream (table, column) pointers.

    Priority:
      1. lineage_rows (structured)
      2. tier-suffix table.column hints (fallback)

    Returns a dict keyed by downstream column name. Each value is a list
    because some columns can have multiple sources (multi-source rows).
    """
    by_col: dict[str, list[UpstreamPointer]] = {}

    # Stage 1: lineage.md
    if lineage_rows:
        for lr in lineage_rows:
            if lr.is_synthetic:
                continue
            up_col = lr.resolved_source_column
            if not up_col:
                continue
            tbl = _normalize_lineage_table(lr.source_table)
            if not tbl:
                continue
            schema, table = _split_schema_table(tbl)
            by_col.setdefault(lr.dwh_column, []).append(
                UpstreamPointer(
                    table=table,
                    column=up_col,
                    schema_hint=schema,
                    via="lineage",
                )
            )

    # Stage 2: tier-suffix fallback (only if lineage didn't already provide a pointer)
    for el in elements:
        if el.name in by_col:
            continue
        if not el.tier:
            continue
        # Skip Tier 4-Confluence and Tier 5 — those aren't structural upstreams.
        if el.tier.is_confluence or el.tier.tier == "5":
            continue
        for tbl, col in extract_table_column_hints(el.tier.source_label):
            schema, table = _split_schema_table(tbl)
            by_col.setdefault(el.name, []).append(
                UpstreamPointer(
                    table=table,
                    column=col,
                    schema_hint=schema,
                    via="tier_suffix",
                )
            )
    return by_col


def _normalize_lineage_table(text: str) -> Optional[str]:
    """Trim a lineage 'Source Table' cell to a clean schema.table identifier."""
    cleaned = text.strip().strip("`* ")
    if not cleaned:
        return None
    # Sometimes the cell carries trailing parens/notes; cut at first whitespace
    # that follows the identifier characters.
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*|[A-Za-z_][A-Za-z0-9_*]*)", cleaned)
    if not m:
        return None
    return m.group(1)


def _split_schema_table(qualified: str) -> tuple[Optional[str], str]:
    """Split a 'Schema.Table' or bare 'Table' into (schema, table)."""
    if "." in qualified:
        schema, table = qualified.split(".", 1)
        return schema.strip(), table.strip()
    return None, qualified.strip()


def expand_wildcard_table(table: str, wiki_root: Path, schema_hint: Optional[str] = None) -> list[Path]:
    """Resolve a possibly-wildcard table name to concrete wiki .md paths.

    Supports a single '*' wildcard (e.g. 'Fact_*_State'). schema_hint, if given,
    restricts the search to that schema folder; otherwise searches all schemas.
    """
    schemas = [schema_hint] if schema_hint else _list_schema_folders(wiki_root)
    matches: list[Path] = []
    if "*" not in table:
        for schema in schemas:
            for sub in ("Tables", "Views"):
                p = wiki_root / schema / sub / f"{table}.md"
                if p.exists():
                    matches.append(p)
        return matches
    pattern_re = re.compile(
        "^" + re.escape(table).replace(r"\*", ".*") + r"\.md$",
        re.IGNORECASE,
    )
    for schema in schemas:
        for sub in ("Tables", "Views"):
            folder = wiki_root / schema / sub
            if not folder.is_dir():
                continue
            for f in folder.iterdir():
                if pattern_re.match(f.name):
                    matches.append(f)
    return matches


def _list_schema_folders(wiki_root: Path) -> list[str]:
    if not wiki_root.is_dir():
        return []
    return [p.name for p in wiki_root.iterdir() if p.is_dir()]
