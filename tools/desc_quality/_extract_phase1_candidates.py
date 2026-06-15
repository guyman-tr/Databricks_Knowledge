"""Extract the high-confidence Phase-1 candidates: every EMPTY UC column where
the wiki has a §4 row authored for THIS exact table. These are direct matches
(not sibling-fallback) so they're the right first batch to deploy.

Outputs:
  audits/_weakness_inventory/phase1_auto_deploy_wiki.csv
  audits/_weakness_inventory/phase1_summary.txt
"""
import csv
import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INV = ROOT / "audits" / "_weakness_inventory" / "inventory_master.csv"
OUT = ROOT / "audits" / "_weakness_inventory" / "phase1_auto_deploy_wiki.csv"
SUMMARY = ROOT / "audits" / "_weakness_inventory" / "phase1_summary.txt"


def main():
    rows = []
    with INV.open(encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            if r["bucket"] == "EMPTY_HAS_WIKI" and r["action"] == "auto_deploy_wiki":
                rows.append(r)

    rows.sort(key=lambda r: (r["schema"], r["table"], int(r["ordinal"])))

    fields = [
        "schema", "table", "column", "ordinal",
        "wiki_path", "wiki_len", "wiki_rich", "proposed_comment",
    ]
    with OUT.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader()
        for r in rows:
            w.writerow({
                "schema": r["schema"],
                "table": r["table"],
                "column": r["column"],
                "ordinal": r["ordinal"],
                "wiki_path": r["wiki_path"],
                "wiki_len": r["wiki_len"],
                "wiki_rich": r["wiki_rich"],
                "proposed_comment": r["wiki_cell"],
            })

    by_schema = defaultdict(int)
    by_table = defaultdict(int)
    for r in rows:
        by_schema[r["schema"]] += 1
        by_table[f"{r['schema']}.{r['table']}"] += 1

    lines = []
    lines.append(f"Phase-1 candidates: {len(rows)} rows (auto_deploy_wiki only)")
    lines.append("")
    lines.append("By schema:")
    for sch, n in sorted(by_schema.items(), key=lambda kv: -kv[1]):
        lines.append(f"  {sch:<22} {n:>4}")
    lines.append("")
    lines.append("Top 15 tables by row count:")
    for t, n in sorted(by_table.items(), key=lambda kv: -kv[1])[:15]:
        lines.append(f"  {n:>4}  {t}")
    SUMMARY.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("\n".join(lines))
    print()
    print(f"CSV: {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
