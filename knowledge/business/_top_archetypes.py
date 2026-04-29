"""Print top high-priority SPs per archetype for the doc."""
import csv
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).parent
rows = list(csv.DictReader((ROOT / "subaccount-option1-triage.csv").open(encoding="utf-8")))

by_arch = defaultdict(list)
for r in rows:
    by_arch[r["archetype"]].append(r)

for a in "ABCDEFX":
    arr = by_arch.get(a, [])
    arr.sort(key=lambda r: -int(r["priority"]) if r["priority"].lstrip("-").isdigit() else 0)
    print(f"\n=== Archetype {a} === total={len(arr)} ===")
    seen = 0
    for r in arr:
        try:
            pri = int(r["priority"])
        except ValueError:
            continue
        if pri < 20: continue
        seen += 1
        if seen > 10: break
        keys = r["dest_customer_keys"][:40]
        money = r["dest_money_cols"][:50]
        flags = r["dest_pop_flag_cols"][:40]
        cnt = r["dest_count_cols"][:30]
        txn = r["dest_txn_cols"][:30]
        print(f"  pri={pri:>3} {r['schema']}.{r['object_name']}")
        print(f"            keys=[{keys}] money=[{money}]")
        print(f"            flags=[{flags}] count=[{cnt}] txn=[{txn}]")
