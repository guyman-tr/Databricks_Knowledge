"""Show V_Liabilities summary from the latest rewrite report."""
import csv
rows = list(csv.DictReader(open("audits/_desc_quality_rewrite_corpus3/report.csv", encoding="utf-8")))
v = [r for r in rows if r["wiki_path"].endswith("V_Liabilities.md")]
n_found = sum(1 for r in v if r["status"] == "FOUND")
n_exh = sum(1 for r in v if r["status"] == "EXHAUSTED")
print(f"V_Liabilities: {len(v)} trivial rows, {n_found} FOUND, {n_exh} EXHAUSTED")
print()
print("Exhausted rows in V_Liabilities:")
for r in v:
    if r["status"] == "EXHAUSTED":
        print(f"  {r['column']:30s} src={r['source']!r:55s} reason={r['exhausted_reason']}")
print()
print("Sample of FOUND in V_Liabilities (first 10):")
shown = 0
for r in v:
    if r["status"] == "FOUND":
        print(f"  {r['column']:30s} via {r['terminal_object']:35s}")
        print(f"    -> {r['new_cell'][:110]}")
        shown += 1
        if shown >= 10:
            break
