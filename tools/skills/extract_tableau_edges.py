"""
Extract co-occurrence edges from Tableau custom SQL queries.

For each custom SQL query, parse all FROM/JOIN clauses to find which tables
are used together; emit edges between them.

Output: knowledge/skills/_edges_tableau.csv
"""
from __future__ import annotations

import csv
import re
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INDEX_CSV = ROOT / "knowledge" / "tableau" / "_index" / "custom_sql.csv"
TABLE_DIR = ROOT / "knowledge" / "tableau"
OUT = ROOT / "knowledge" / "skills" / "_edges_tableau.csv"


TABLE_REF = re.compile(
    r"\b(?:FROM|JOIN)\s+"
    r"(?!\(|LATERAL\b|UNNEST\b)"
    r"(\[?[A-Za-z_][\w]*\]?(?:\s*\.\s*\[?[A-Za-z_][\w]*\]?){0,2})",
    re.IGNORECASE,
)


def normalize(raw: str) -> str | None:
    parts = [p.strip().strip("[]").strip("`") for p in raw.split(".") if p.strip()]
    if not parts:
        return None
    if len(parts) == 1:
        return parts[0]
    return f"{parts[-2]}.{parts[-1]}"


def parse_refs(sql: str) -> set[str]:
    sql = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)
    sql = re.sub(r"--[^\n]*", " ", sql)
    refs = set()
    for m in TABLE_REF.finditer(sql):
        ref = normalize(m.group(1))
        if ref and "." in ref:  # require a schema
            refs.add(ref)
    return refs


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    edges = []

    # Pull SQL bodies out of the per-table tableau md files
    md_files = list(TABLE_DIR.rglob("*.md"))
    seen_query_ids = set()
    print(f"Scanning {len(md_files)} tableau markdown files", flush=True)
    for p in md_files:
        text = p.read_text(encoding="utf-8", errors="replace")
        # find each ```sql ... ``` block
        for m in re.finditer(r"```sql\s*\n(.*?)```", text, re.DOTALL):
            sql = m.group(1)
            # query id may appear on a preceding line; we don't strictly need it
            refs = parse_refs(sql)
            if len(refs) < 2:
                continue
            for a, b in combinations(sorted(refs), 2):
                edges.append({
                    "left": a,
                    "right": b,
                    "edge_kind": "tableau_co_occurrence",
                    "join_keys": "",
                    "purpose": p.stem[:80],
                    "source": p.relative_to(ROOT).as_posix(),
                })

    print(f"Total tableau edges: {len(edges)}", flush=True)
    fields = ["left", "right", "edge_kind", "join_keys", "purpose", "source"]
    with OUT.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for e in edges:
            w.writerow(e)
    print(f"Wrote {OUT.relative_to(ROOT)}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
