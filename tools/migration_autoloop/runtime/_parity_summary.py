"""
Show what's in migration_parallel after the run:
- row counts per table
- gold row counts for D-1 (etr_ymd = yesterday)
- parity delta
"""
import sys, os, json
sys.path.insert(0, r"c:\Users\guyman\Documents\github\Databricks_Knowledge")
from tools.migration_autoloop.db import make_workspace_client, execute_sql
from tools.migration_autoloop.orchestration_targets import RING_TARGETS
from datetime import date, timedelta

w = make_workspace_client()
wid = "6f72189f967b42a9"
TARGET_DATE = date.today() - timedelta(days=1)
print(f"Target date (D-1): {TARGET_DATE}\n")

rows = []
for ring, targets in RING_TARGETS.items():
    for t in targets:
        par_fqn = f"dwh_daily_process.migration_parallel.{t.parallel_table_name}"
        gold_fqn = t.gold_table

        # parallel count
        try:
            _, rows_r = execute_sql(w, sql_text=f"SELECT COUNT(*) AS n FROM {par_fqn}", warehouse_id=wid)
            par_cnt = int(rows_r[0][0]) if rows_r else 0
        except Exception as e:
            par_cnt = f"ERR: {str(e)[:60]}"

        # gold count (D-1 partition or full)
        if t.has_etr_ymd:
            gold_sql = f"SELECT COUNT(*) AS n FROM {gold_fqn} WHERE etr_ymd = '{TARGET_DATE}'"
        else:
            gold_sql = f"SELECT COUNT(*) AS n FROM {gold_fqn}"

        try:
            _, rows_r = execute_sql(w, sql_text=gold_sql, warehouse_id=wid)
            gold_cnt = int(rows_r[0][0]) if rows_r else 0
        except Exception as e:
            gold_cnt = f"ERR: {str(e)[:60]}"

        skip = "skip" if t.skip_compare else ""
        rows.append((f"ring{ring}", t.parallel_table_name, par_cnt, gold_cnt, skip))

print(f"{'Ring':<8} {'Table':<45} {'Par rows':>12} {'Gold rows':>12} {'Note'}")
print("-" * 90)
for ring, name, par, gold, note in rows:
    match = ""
    if isinstance(par, int) and isinstance(gold, int) and not note:
        match = "MATCH" if par == gold else f"DIFF {par-gold:+,}"
    print(f"{ring:<8} {name:<45} {str(par):>12} {str(gold):>12}  {note or match}")
