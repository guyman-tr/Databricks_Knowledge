import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
src = ROOT / "audits" / "_convergence_gap" / "proposed_converged.csv"
rows = list(csv.DictReader(src.open(encoding="utf-8")))
print(f"{'len':>4}  {'uc_fqn (tail)':40s}  column                    rules")
print("-" * 110)
for r in rows:
    tail = r["uc_fqn"].split(".")[-1]
    print(f"{len(r['converged']):4d}  {tail:40s}  {r['column']:24s}  {r['rules_fired']}")
over = [r for r in rows if len(r['converged']) > 500]
print(f"\nOver-500: {len(over)} / {len(rows)}")
for r in over:
    print(f"  {r['uc_fqn']}.{r['column']} = {len(r['converged'])} chars")
