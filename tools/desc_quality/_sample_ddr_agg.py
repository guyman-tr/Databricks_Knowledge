"""Sample one DDR_Aggregation wiki to see what its rows look like."""
from __future__ import annotations
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from tools.desc_quality.wiki_parse import parse_wiki  # noqa: E402

p = ROOT / "knowledge/synapse/Wiki/BI_DB_dbo/Functions/Function_DDR_Aggregation_ThisMonth.md"
tbl = parse_wiki(p)
print(f"Wiki: {p.name}")
print(f"Total rows: {len(tbl.rows)}")
print(f"semantic_header_used: {tbl.semantic_header_used}")
print()
print("First 20 rows:")
for r in tbl.rows[:20]:
    cell = r.semantic_cell[:90]
    print(f"  {r.column:30s} -> {cell!r}")
print()
lens: Counter[str] = Counter()
for r in tbl.rows:
    L = len(r.semantic_cell)
    if L < 20:
        lens["<20"] += 1
    elif L < 40:
        lens["20-39"] += 1
    elif L < 80:
        lens["40-79"] += 1
    elif L < 200:
        lens["80-199"] += 1
    else:
        lens["200+"] += 1
print("=== Length distribution of semantic cells ===")
for k, v in lens.most_common():
    print(f"  {k:8s}: {v}")
