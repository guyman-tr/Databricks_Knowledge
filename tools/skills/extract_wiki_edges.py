"""
Mine join/relationship/lineage edges from existing wiki markdown.

Walks knowledge/synapse/Wiki/**/*.md, parses §3.3 Common JOINs, §5.1 Production
Sources, §6.1 References To, §6.2 Referenced By; emits a single edge CSV.

Usage:
    python tools/skills/extract_wiki_edges.py
Output:
    knowledge/skills/_edges_wiki.csv
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[2]
WIKI_ROOT = ROOT / "knowledge" / "synapse" / "Wiki"
OUT = ROOT / "knowledge" / "skills" / "_edges_wiki.csv"

SECTION_PATTERNS = {
    "common_joins": re.compile(r"^#{2,4}\s*3\.3\s+Common\s+JOINs\b", re.IGNORECASE | re.MULTILINE),
    "production_sources": re.compile(r"^#{2,4}\s*5\.1\s+Production\s+Sources\b", re.IGNORECASE | re.MULTILINE),
    "references_to": re.compile(r"^#{2,4}\s*6\.1\s+References\s+To\b", re.IGNORECASE | re.MULTILINE),
    "referenced_by": re.compile(r"^#{2,4}\s*6\.2\s+Referenced\s+By\b", re.IGNORECASE | re.MULTILINE),
}

# Stop sections (we read the table that follows the heading until the next heading
# or a blank-line cluster that doesn't belong to a markdown table)
NEXT_HEADING = re.compile(r"^#{1,4}\s", re.MULTILINE)


def find_section_text(content: str, start_match: re.Match) -> str:
    start = start_match.end()
    next_heading = NEXT_HEADING.search(content, start)
    end = next_heading.start() if next_heading else len(content)
    return content[start:end]


def parse_md_table(text: str) -> list[dict]:
    """Parse the first markdown table found in text. Returns list of row dicts."""
    lines = text.splitlines()
    table_lines = []
    in_table = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("|") and stripped.endswith("|"):
            table_lines.append(stripped)
            in_table = True
        elif in_table and not stripped:
            break  # end of table
        elif in_table:
            break
    if len(table_lines) < 2:
        return []
    headers = [h.strip() for h in table_lines[0].strip("|").split("|")]
    # second line is the divider (---)
    rows = []
    for line in table_lines[2:]:
        cells = [c.strip() for c in line.strip("|").split("|")]
        if len(cells) != len(headers):
            continue
        rows.append(dict(zip(headers, cells)))
    return rows


# Heuristic to extract a table-name token from a free-form cell.
# Captures things like:
#   DWH_dbo.Dim_Customer
#   `BI_DB_dbo.BI_DB_CIDFirstDates`
#   [DWH_dbo].[Dim_Position]
#   Trade.PositionTbl  (production)
#   etoro_kpi_prep.v_xxx
TABLE_TOKEN = re.compile(
    r"(?:\[?([A-Za-z_][A-Za-z0-9_]+)\]?\.)?\[?([A-Za-z_][A-Za-z0-9_]+)\]?",
)


def normalize_object_ref(raw: str) -> str | None:
    """Try to extract a 'schema.object' from a free-form wiki cell."""
    if not raw:
        return None
    s = raw.strip().strip("`").strip("[]")
    s = s.split("(")[0].strip()  # strip "(production)" hints
    s = s.split("—")[0].strip()
    s = s.split("--")[0].strip()
    s = s.split(",")[0].strip()
    # split on whitespace - we only want the first token
    parts = s.split()
    if not parts:
        return None
    head = parts[0].strip("`").strip("[]")
    # strip trailing punctuation
    head = head.rstrip(":,;.")
    if "." in head:
        seg = [p.strip("`[]") for p in head.split(".")]
        seg = [p for p in seg if p]
        if len(seg) >= 2:
            return f"{seg[-2]}.{seg[-1]}"
    # bare name with no schema - useful in some contexts
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]+$", head):
        return head
    return None


def object_from_filename(path: Path) -> str:
    """Filename Foo.md is assumed to encode a Schema.Object header. Use H1 as truth."""
    return path.stem


def extract_h1(content: str) -> str | None:
    m = re.search(r"^#\s+(.+)\s*$", content, re.MULTILINE)
    if m:
        head = m.group(1).strip()
        head = head.rstrip("#").strip()
        # strip any trailing parens
        head = head.split("(")[0].strip()
        return head
    return None


def emit_edges(wiki_path: Path) -> Iterable[dict]:
    content = wiki_path.read_text(encoding="utf-8", errors="replace")
    h1 = extract_h1(content)
    self_obj = normalize_object_ref(h1) if h1 else None
    if not self_obj:
        self_obj = object_from_filename(wiki_path)

    schema_dir = wiki_path.parent.parent.name  # e.g. DWH_dbo
    obj_kind_dir = wiki_path.parent.name  # Tables / Views / Functions

    # 3.3 Common JOINs
    m = SECTION_PATTERNS["common_joins"].search(content)
    if m:
        sec = find_section_text(content, m)
        rows = parse_md_table(sec)
        for r in rows:
            join_to = r.get("Join To") or r.get("To") or r.get("Object") or ""
            cond = r.get("Join Condition") or r.get("Condition") or ""
            purpose = r.get("Purpose") or ""
            target = normalize_object_ref(join_to)
            if target and self_obj and target != self_obj:
                yield {
                    "left": self_obj,
                    "right": target,
                    "edge_kind": "common_join",
                    "join_keys": cond,
                    "purpose": purpose,
                    "source_wiki": wiki_path.relative_to(ROOT).as_posix(),
                    "schema_dir": schema_dir,
                }

    # 5.1 Production Sources (column-level lineage)
    m = SECTION_PATTERNS["production_sources"].search(content)
    if m:
        sec = find_section_text(content, m)
        rows = parse_md_table(sec)
        for r in rows:
            prod = r.get("Production Source") or r.get("Source") or ""
            col = r.get("Synapse Column") or r.get("Column") or ""
            src_col = r.get("Source Column") or ""
            transform = r.get("Transform") or ""
            # production source field can be "Trade.PositionTbl" or
            # "Fact_Deposit_State / Fact_Cashout_State" - split on / and ,
            parts = re.split(r"\s*/\s*|\s*,\s*", prod)
            for p in parts:
                target = normalize_object_ref(p)
                if target and self_obj and target != self_obj:
                    yield {
                        "left": self_obj,
                        "right": target,
                        "edge_kind": "lineage",
                        "join_keys": f"{col} <- {src_col}",
                        "purpose": transform[:80],
                        "source_wiki": wiki_path.relative_to(ROOT).as_posix(),
                        "schema_dir": schema_dir,
                    }

    # 6.1 References To
    m = SECTION_PATTERNS["references_to"].search(content)
    if m:
        sec = find_section_text(content, m)
        rows = parse_md_table(sec)
        for r in rows:
            related = r.get("Related Object") or r.get("Object") or ""
            element = r.get("Element") or r.get("Column") or ""
            desc = r.get("Description") or ""
            target = normalize_object_ref(related)
            if target and self_obj and target != self_obj:
                yield {
                    "left": self_obj,
                    "right": target,
                    "edge_kind": "references_to",
                    "join_keys": element,
                    "purpose": desc[:80],
                    "source_wiki": wiki_path.relative_to(ROOT).as_posix(),
                    "schema_dir": schema_dir,
                }

    # 6.2 Referenced By
    m = SECTION_PATTERNS["referenced_by"].search(content)
    if m:
        sec = find_section_text(content, m)
        rows = parse_md_table(sec)
        for r in rows:
            src_obj = r.get("Source Object") or r.get("Object") or ""
            src_el = r.get("Source Element") or r.get("Element") or ""
            desc = r.get("Description") or ""
            origin = normalize_object_ref(src_obj)
            if origin and self_obj and origin != self_obj:
                yield {
                    "left": origin,
                    "right": self_obj,
                    "edge_kind": "referenced_by",
                    "join_keys": src_el,
                    "purpose": desc[:80],
                    "source_wiki": wiki_path.relative_to(ROOT).as_posix(),
                    "schema_dir": schema_dir,
                }


def main() -> int:
    files = []
    for p in WIKI_ROOT.rglob("*.md"):
        name = p.name
        if name.startswith("_"):
            continue
        if ".review-needed" in name or ".lineage" in name:
            continue
        # skip top-level non-content files
        if p.parent.name not in {"Tables", "Views", "Functions", "External Tables", "Wiki"}:
            continue
        files.append(p)

    print(f"Scanning {len(files)} wiki files...", flush=True)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    edges = []
    for i, p in enumerate(files):
        if i % 200 == 0 and i:
            print(f"  ... {i}/{len(files)}", flush=True)
        try:
            for e in emit_edges(p):
                edges.append(e)
        except Exception as exc:
            print(f"  WARN: {p.name}: {exc}", flush=True)

    print(f"Total edges: {len(edges)}", flush=True)

    fields = ["left", "right", "edge_kind", "join_keys", "purpose", "source_wiki", "schema_dir"]
    with OUT.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for e in edges:
            w.writerow(e)
    print(f"Wrote {OUT.relative_to(ROOT)}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
