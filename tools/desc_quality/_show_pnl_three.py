"""Show the new descriptions for the 3 PnL_Single_Day columns the user asked about."""
import csv
rows = list(csv.DictReader(open("audits/_desc_quality_rewrite_corpus7/proposed_fixes.csv", encoding="utf-8")))
targets = {"ClosedOnDate", "IsCopyFund", "IsMarginTrade"}
for r in rows:
    if "Function_PnL_Single_Day" in r["wiki_path"] and r["column"] in targets:
        print(r["column"])
        print(f"  reason: {r['reason']}")
        print(f"  new:    {r['new_description']}")
        print()
