"""List touched wikis split by whether apply_tvf_col_comments.py MAPPING covers them."""
from __future__ import annotations
import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

FILES = [
    "audits/_desc_quality_apply_v_liabilities/proposed_fixes.csv",
    "audits/_desc_quality_apply_revenue/proposed_fixes.csv",
    "audits/_desc_quality_apply_rest/proposed_fixes.csv",
]

wikis: dict[str, int] = {}
for f in FILES:
    p = ROOT / f
    for r in csv.DictReader(p.open(encoding="utf-8")):
        wikis[r["wiki_path"]] = wikis.get(r["wiki_path"], 0) + 1

mapping_src = (ROOT / "tools" / "apply_tvf_col_comments.py").read_text(encoding="utf-8")
mapped = set(re.findall(r'"(Function_\w+|V_\w+)"', mapping_src))
uc_for: dict[str, str] = {}
for m in re.finditer(r'"(Function_\w+|V_\w+)"\s*,\s*"(main\.[\w.]+)"', mapping_src):
    uc_for[m.group(1)] = m.group(2)

print(f"Total wikis touched: {len(wikis)}")
print(f"MAPPING entries: {len(mapped)}")
print("-" * 70)

mapped_list: list[tuple[str, int, str]] = []
unmapped_list: list[tuple[str, int]] = []
for wp, n in sorted(wikis.items()):
    stem = Path(wp).stem
    if stem in mapped:
        mapped_list.append((stem, n, uc_for.get(stem, "?")))
    else:
        unmapped_list.append((stem, n))

print(f"IN MAPPING (will deploy via apply_tvf_col_comments.py): {len(mapped_list)}")
for stem, n, uc in mapped_list:
    print(f"  {n:4d} rows  {stem:50s} -> {uc}")

print(f"\nNOT MAPPED (need a separate deploy path): {len(unmapped_list)}")
for stem, n in unmapped_list:
    print(f"  {n:4d} rows  {stem}")

print("-" * 70)
total_mapped_rows = sum(n for _, n, _ in mapped_list)
total_unmapped_rows = sum(n for _, n in unmapped_list)
print(f"Mapped rows:   {total_mapped_rows}")
print(f"Unmapped rows: {total_unmapped_rows}")
print(f"Grand total:   {total_mapped_rows + total_unmapped_rows}")
