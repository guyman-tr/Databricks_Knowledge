"""Diff old (Phase D) vs new (Phase E) proposed_fixes."""
import csv
from pathlib import Path

OLD = Path("audits/_desc_quality_rewrite_corpus/proposed_fixes.csv")
NEW = Path("audits/_desc_quality_rewrite_corpus3/proposed_fixes.csv")

old = list(csv.DictReader(open(OLD, encoding="utf-8")))
new = list(csv.DictReader(open(NEW, encoding="utf-8")))
print(f"OLD  {OLD} : {len(old)} rows")
print(f"NEW  {NEW} : {len(new)} rows")
print()

def key(r):
    return (r["wiki_path"], r["column"])

old_idx = {key(r): r for r in old}
new_idx = {key(r): r for r in new}

only_new = sorted(set(new_idx) - set(old_idx))
only_old = sorted(set(old_idx) - set(new_idx))
print(f"Rows added in NEW: {len(only_new)}")
print(f"Rows dropped from OLD: {len(only_old)}")
print()
print("Function_PnL_Single_Day rows in NEW report:")
for r in new:
    if "Function_PnL_Single_Day" in r["wiki_path"]:
        proposed = r.get("proposed_transformation") or r.get("new_cell") or ""
        print(f"  {r['column']:25s} -> {proposed[:120]}")
print()
print("Sample of newly-added rows (Phase E reclaims):")
shown = 0
for k in only_new:
    r = new_idx[k]
    proposed = r.get("proposed_transformation") or r.get("new_cell") or ""
    wiki = k[0].split("/")[-1]
    print(f"  {wiki:55s} {k[1]:25s} -> {proposed[:90]}")
    shown += 1
    if shown >= 15:
        break
