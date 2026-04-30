"""Shared parser for Tier 1 / Synapse wiki markdown files.

Both Tier 1 ProdSchemas wikis and Synapse DWH wikis follow the same
'## 4. Elements' table schema:

    | # | Element | Type | Nullable | Default | Confidence | Description |

This module provides a single parse_wiki(path) -> dict that extracts the
table description and column metadata used by the bronze ALTER generator
and (later) downstream propagation tooling.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional


# ---- Markdown helpers -------------------------------------------------------

_BOLD = re.compile(r"\*\*(.+?)\*\*")
_ITAL = re.compile(r"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)")
_CODE = re.compile(r"`([^`]+)`")
_LINK = re.compile(r"\[([^\]]+)\]\([^)]+\)")
_WS = re.compile(r"\s+")


def clean_md(text: str) -> str:
    """Strip markdown formatting, collapse whitespace."""
    if text is None:
        return ""
    text = _LINK.sub(r"\1", text)
    text = _BOLD.sub(r"\1", text)
    text = _ITAL.sub(r"\1", text)
    text = _CODE.sub(r"\1", text)
    return _WS.sub(" ", text).strip()


def split_pipe_row(line: str) -> list[str]:
    """Split a markdown table row into trimmed cell values (without the leading/trailing empty)."""
    parts = [p.strip() for p in line.split("|")]
    if parts and parts[0] == "":
        parts = parts[1:]
    if parts and parts[-1] == "":
        parts = parts[:-1]
    return parts


# ---- Section extraction -----------------------------------------------------

_SECTION = re.compile(r"^##\s+(\d+)\.\s+(.+?)\s*$", re.MULTILINE)


def find_section(content: str, header_num: int, header_name_hint: str | None = None) -> Optional[str]:
    """Return the body of '## {header_num}. ...' up to the next '## N.' header.

    If header_name_hint is provided, only matches headers whose name contains it.
    """
    matches = list(_SECTION.finditer(content))
    for i, m in enumerate(matches):
        try:
            num = int(m.group(1))
        except ValueError:
            continue
        if num != header_num:
            continue
        name = m.group(2).strip().lower()
        if header_name_hint and header_name_hint.lower() not in name:
            continue
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        return content[start:end]
    return None


def find_property_table(content: str) -> dict[str, str]:
    """Parse the leading | Property | Value | block right after the H1."""
    out: dict[str, str] = {}
    in_table = False
    for line in content.splitlines():
        s = line.strip()
        if s.startswith("| Property") or s.startswith("|Property"):
            in_table = True
            continue
        if in_table and s.startswith("|---"):
            continue
        if in_table:
            if not s.startswith("|"):
                if s == "" or s.startswith("---"):
                    continue
                break
            cells = split_pipe_row(s)
            if len(cells) >= 2:
                key = clean_md(cells[0]).rstrip(":")
                val = clean_md(cells[1])
                out[key] = val
    return out


# ---- Column / element parsing ----------------------------------------------

@dataclass
class Column:
    pos: int
    name: str
    type_: str
    nullable: str
    default: str
    confidence: str
    description: str

    def to_dict(self) -> dict:
        d = asdict(self)
        d["type"] = d.pop("type_")
        return d


def _header_index_map(header_cells: list[str]) -> dict[str, int]:
    """Map normalized header names to their column index."""
    out: dict[str, int] = {}
    for i, h in enumerate(header_cells):
        norm = clean_md(h).lower().strip()
        out[norm] = i
    return out


def parse_elements_table(section_body: str) -> list[Column]:
    """Parse the §4 Elements markdown table into Column rows.

    Supports both the Synapse 5-col layout (# | Element | Type | Nullable | Description)
    and the Tier 1 ProdSchemas 7-col layout
    (# | Element | Type | Nullable | Default | Confidence | Description).

    Column lookup is by header name, so any future column reshuffles still parse.
    """
    cols: list[Column] = []
    header_idx: dict[str, int] | None = None

    def col(cells: list[str], key: str, default: str = "") -> str:
        i = (header_idx or {}).get(key)
        if i is None or i >= len(cells):
            return default
        return clean_md(cells[i])

    for line in section_body.splitlines():
        s = line.strip()
        if not s.startswith("|"):
            continue
        cells = split_pipe_row(s)
        if not cells:
            continue
        joined = " ".join(clean_md(c).lower() for c in cells)
        if header_idx is None:
            if "element" in joined and ("type" in joined or "data type" in joined):
                header_idx = _header_index_map(cells)
            continue
        if all(set(c.strip()) <= set("-: ") for c in cells):
            continue
        first = cells[0].strip()
        try:
            pos = int(re.sub(r"[^\d]", "", first) or "0")
        except ValueError:
            pos = 0
        if pos == 0:
            continue
        cols.append(
            Column(
                pos=pos,
                name=col(cells, "element").strip("`") or col(cells, "name").strip("`"),
                type_=col(cells, "type") or col(cells, "data type"),
                nullable=col(cells, "nullable"),
                default=col(cells, "default", "-"),
                confidence=col(cells, "confidence", ""),
                description=col(cells, "description"),
            )
        )
    return cols


# ---- Top-level entry --------------------------------------------------------

@dataclass
class ParsedWiki:
    path: str
    object_name: str
    object_type: str
    schema: str
    table_name: str
    description: str
    columns: list[Column] = field(default_factory=list)
    tags: dict[str, str] = field(default_factory=dict)

    def to_dict(self) -> dict:
        return {
            "path": self.path,
            "object_name": self.object_name,
            "object_type": self.object_type,
            "schema": self.schema,
            "table_name": self.table_name,
            "description": self.description,
            "tags": self.tags,
            "columns": [c.to_dict() for c in self.columns],
        }


def parse_wiki(path: str | Path) -> Optional[ParsedWiki]:
    """Parse a wiki .md file. Returns None if the file lacks a §4 Elements table."""
    p = Path(path)
    if not p.is_file():
        return None
    content = p.read_text(encoding="utf-8", errors="replace")

    h1_match = re.search(r"^#\s+(.+?)\s*$", content, re.MULTILINE)
    if not h1_match:
        return None
    object_name = h1_match.group(1).strip()

    if "." in object_name:
        schema, table_name = object_name.split(".", 1)
    else:
        schema, table_name = "", object_name

    blockquote = re.search(r"^>\s+(.+?)$", content, re.MULTILINE)
    short_desc = clean_md(blockquote.group(1)) if blockquote else ""

    props = find_property_table(content)
    object_type = props.get("Object Type", "").strip() or "Table"

    elements_body = find_section(content, 4, "elements")
    if elements_body is None:
        elements_body = find_section(content, 4, "output columns")
    if elements_body is None:
        return None

    columns = parse_elements_table(elements_body)
    if not columns:
        return None

    description = short_desc
    if not description:
        bm = find_section(content, 1, "business meaning")
        if bm:
            for para in bm.strip().split("\n\n"):
                cleaned = clean_md(para)
                if cleaned:
                    description = cleaned
                    break

    tags = {k: v for k, v in props.items() if k and v}

    return ParsedWiki(
        path=str(p),
        object_name=object_name,
        object_type=object_type,
        schema=schema,
        table_name=table_name,
        description=description,
        columns=columns,
        tags=tags,
    )


# ---- CLI smoke test ---------------------------------------------------------

if __name__ == "__main__":
    import argparse
    import json

    ap = argparse.ArgumentParser(description="Smoke-test the wiki parser on one file.")
    ap.add_argument("path", help="Path to a wiki .md file")
    ap.add_argument("--full", action="store_true", help="Print all columns")
    args = ap.parse_args()

    parsed = parse_wiki(args.path)
    if parsed is None:
        print(f"PARSE FAILED or no Elements section: {args.path}")
        raise SystemExit(2)

    d = parsed.to_dict()
    if not args.full:
        d["columns"] = d["columns"][:5] + ([{"_more": len(parsed.columns) - 5}] if len(parsed.columns) > 5 else [])
    print(json.dumps(d, indent=2, ensure_ascii=False))
