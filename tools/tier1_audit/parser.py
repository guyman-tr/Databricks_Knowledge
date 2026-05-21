"""parser.py — extract column rows and Tier-N tags from synapse/DWH wiki .md files.

The DWH wiki §4 Elements table is the focus. A canonical row looks like:

    | 47 | Credit | money | YES | Customer credit balance (...). (Tier 1 -- V_Liabilities via Fact_SnapshotEquity) |

OLTP / source wikis use a wider schema with an extra Confidence column:

    | 15 | Credit | money | NO | - | VERIFIED | Customer's total credit balance ... |

This module exposes one public function — `parse_wiki_columns(path)` — that
returns a list of `ColumnRow` dataclasses where every row has at minimum a
`column_name` and a `description`. The `tier_tag` field is populated only when
a `(Tier N -- X)` (or `— ` / `- ` / `–`) suffix is present at the end of the
description.

Design notes:
  * We do not require the header to match an exact spelling. We just locate
    a markdown table that has 5+ pipe-delimited columns and a header row
    where one column matches /column|element|field|name/i and another
    matches /description|notes/i.
  * Multi-line descriptions are not supported (none observed in this repo).
  * We strip the tier suffix off of `description` so the LLM judge sees the
    raw description text only.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

# ----- Tier-tag regex --------------------------------------------------------
#
# Real-world variants seen across the repo:
#   (Tier 1 - Customer.CustomerStatic)
#   (Tier 1 -- Customer.CustomerStatic)
#   (Tier 1 — Customer.CustomerStatic)        # em-dash
#   (Tier 1 – Customer.CustomerStatic)        # en-dash
#   (Tier 2 — SP_Fact_SnapshotEquity)
#   (Tier N — null-with-provenance)           # UC pipeline emits "Tier N"
#   (Tier U — unclassified)
#
# Group 1 = tier label  (1, 2, 3, 4, 5, U, N)
# Group 2 = source text (free-form, terminated by the closing paren)
TIER_TAG_RE = re.compile(
    r"\(\s*Tier\s+([0-9NUu])\s*(?:[-–—]|--)\s*([^()]+?)\s*\)",
    re.IGNORECASE,
)

# Match the LAST tier-tag on a line (descriptions sometimes carry two,
# e.g. UC view inherits "(Tier 1 -- X) (Tier 1 — inherited from Y)").
# Capture all then take the last.
TIER_TAG_ALL_RE = TIER_TAG_RE

HEADER_NAME_RE = re.compile(r"^\s*(column|element|field|name)\s*$", re.IGNORECASE)
HEADER_DESC_RE = re.compile(r"^\s*(description|notes|business meaning|definition)\s*$",
                            re.IGNORECASE)
HEADER_TYPE_RE = re.compile(r"^\s*(type|datatype|data\s*type)\s*$", re.IGNORECASE)
HEADER_NULL_RE = re.compile(r"^\s*(null(?:able)?)\s*$", re.IGNORECASE)
HEADER_CONF_RE = re.compile(r"^\s*(confidence|tier|provenance)\s*$", re.IGNORECASE)
HEADER_INDEX_RE = re.compile(r"^\s*(#|num|number|ord|ordinal)\s*$", re.IGNORECASE)


@dataclass(frozen=True)
class TierTag:
    tier: str            # "1", "2", "3", "4", "5", "N", "U"
    source_text: str     # the free-form X inside the parens

    @property
    def is_tier1(self) -> bool:
        return self.tier == "1"


@dataclass
class ColumnRow:
    wiki_path: Path
    table_no: int            # 1-based index of which markdown table this came from
    line_no: int             # 1-based source line number
    column_index: str | None = None  # value of the # column if present
    column_name: str = ""
    column_type: str | None = None
    nullable: str | None = None
    confidence: str | None = None    # only present on OLTP wikis
    description: str = ""             # tier-tag stripped
    raw_description: str = ""         # original, untouched
    tier_tags: list[TierTag] = field(default_factory=list)

    @property
    def primary_tier_tag(self) -> TierTag | None:
        """Last (i.e. outermost) tier tag — the claim being audited."""
        return self.tier_tags[-1] if self.tier_tags else None


def _split_row(line: str) -> list[str] | None:
    """Split a markdown table row into trimmed cells, or None if not a row."""
    s = line.rstrip("\n")
    if not s.lstrip().startswith("|"):
        return None
    # remove leading/trailing pipe, then split
    inner = s.strip()
    if inner.endswith("|"):
        inner = inner[:-1]
    if inner.startswith("|"):
        inner = inner[1:]
    cells = [c.strip() for c in inner.split("|")]
    return cells


def _is_separator_row(cells: list[str]) -> bool:
    """A markdown header separator row (---|---|---)."""
    if not cells:
        return False
    return all(re.fullmatch(r":?-{3,}:?", c.strip()) for c in cells if c.strip())


def _identify_columns(headers: list[str]) -> dict[str, int] | None:
    """Map our role names (index/name/type/null/confidence/description) to
    column positions. Returns None if we can't find both name and description
    columns."""
    roles: dict[str, int] = {}
    for i, h in enumerate(headers):
        if HEADER_INDEX_RE.match(h) and "index" not in roles:
            roles["index"] = i
        elif HEADER_NAME_RE.match(h) and "name" not in roles:
            roles["name"] = i
        elif HEADER_TYPE_RE.match(h) and "type" not in roles:
            roles["type"] = i
        elif HEADER_NULL_RE.match(h) and "null" not in roles:
            roles["null"] = i
        elif HEADER_CONF_RE.match(h) and "confidence" not in roles:
            roles["confidence"] = i
        elif HEADER_DESC_RE.match(h) and "description" not in roles:
            roles["description"] = i
    if "name" not in roles or "description" not in roles:
        return None
    return roles


def _extract_tags(text: str) -> list[TierTag]:
    return [TierTag(tier=m.group(1).upper(), source_text=m.group(2).strip())
            for m in TIER_TAG_ALL_RE.finditer(text)]


def _strip_tags(text: str) -> str:
    """Remove all trailing tier tags from the description and return the lead
    sentence(s) only."""
    return TIER_TAG_ALL_RE.sub("", text).rstrip(" .;,").strip()


def parse_wiki_columns(path: Path) -> list[ColumnRow]:
    """Walk a markdown wiki file, locate every column-table row, and return
    `ColumnRow` records. Tables that don't have both name and description
    columns are silently skipped."""
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    return _state_machine_parse(path, lines)


def _state_machine_parse(path: Path, lines: list[str]) -> list[ColumnRow]:
    """Cleaner re-pass that handles the header/separator/body sequence."""
    rows: list[ColumnRow] = []
    state = "scan"  # scan -> saw_header -> in_body -> scan
    headers: list[str] = []
    header_line_no = 0
    roles: dict[str, int] | None = None
    table_no = 0
    for idx, line in enumerate(lines, start=1):
        cells = _split_row(line)
        if state == "scan":
            if cells is None:
                continue
            if _is_separator_row(cells):
                continue
            headers = cells
            header_line_no = idx
            state = "saw_header"
        elif state == "saw_header":
            if cells is None:
                state = "scan"
                continue
            if _is_separator_row(cells):
                roles = _identify_columns(headers)
                if roles is None:
                    state = "scan"
                    continue
                table_no += 1
                state = "in_body"
            else:
                # two header-like rows in a row — restart with the newer one
                headers = cells
                header_line_no = idx
        elif state == "in_body":
            if cells is None:
                state = "scan"
                roles = None
                continue
            if roles is None or len(cells) <= roles.get("name", 0) or \
               len(cells) <= roles.get("description", 0):
                continue
            name = cells[roles["name"]].strip()
            raw_desc = cells[roles["description"]].strip()
            if not name or name.startswith(":-") or set(name) <= {"-"}:
                continue
            # Skip rows whose name is itself just punctuation (some wikis
            # have a "continuation" pattern).
            if not re.search(r"[A-Za-z0-9_]", name):
                continue
            tags = _extract_tags(raw_desc)
            rows.append(
                ColumnRow(
                    wiki_path=path,
                    table_no=table_no,
                    line_no=idx,
                    column_index=cells[roles["index"]].strip() if "index" in roles and len(cells) > roles["index"] else None,
                    column_name=name,
                    column_type=cells[roles["type"]].strip() if "type" in roles and len(cells) > roles["type"] else None,
                    nullable=cells[roles["null"]].strip() if "null" in roles and len(cells) > roles["null"] else None,
                    confidence=cells[roles["confidence"]].strip() if "confidence" in roles and len(cells) > roles["confidence"] else None,
                    description=_strip_tags(raw_desc),
                    raw_description=raw_desc,
                    tier_tags=tags,
                )
            )
    return rows


def find_tier1_claims(path: Path) -> list[ColumnRow]:
    """Return only rows whose outermost tier tag is Tier 1."""
    return [r for r in parse_wiki_columns(path)
            if r.primary_tier_tag and r.primary_tier_tag.is_tier1]


def iter_columns_with_any_tier(rows: Iterable[ColumnRow], tier: str) -> Iterable[ColumnRow]:
    """Helper: rows where ANY tier tag matches the given tier (e.g. '2')."""
    tier = tier.upper()
    for r in rows:
        for t in r.tier_tags:
            if t.tier == tier:
                yield r
                break
