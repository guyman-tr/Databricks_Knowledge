import csv
rows = list(csv.DictReader(open("tools/lakebridge/wiki_vs_uc_coverage.csv", encoding="utf-8")))
print(f"Total rows: {len(rows)}\n")
for bucket in ("MISSING_IN_UC", "NO_COMMENTS_AT_ALL", "ONLY_TABLE_COMMENT", "LOW_COL_COVERAGE", "NO_TABLE_COMMENT"):
    sel = [r for r in rows if r["bucket"] == bucket]
    if not sel:
        continue
    print("=" * 100)
    print(f"{bucket} ({len(sel)} rows)")
    print("=" * 100)
    for r in sorted(sel, key=lambda x: (x["schema_folder"], x["object_name"])):
        pct = r["uc_col_coverage_pct"]
        cov = f"{r['uc_commented_cols']}/{r['uc_total_cols']} ({pct} pct)"
        alter = r["wiki_alter_exists"]
        tbl_c = r["uc_table_comment_set"]
        print(f"  {r['schema_folder']:<14} {r['object_name']:<55} alter={alter:<3} cov={cov:<16} tbl_comment={tbl_c:<3} -> {r['uc_table']}")
    print()
