"""Verify the 49 LOW_COL_COVERAGE targets after the cols-only backfill."""
import csv
import json
import os
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
targets = json.loads((REPO / "tools/lakebridge/low_coverage_targets.json").read_text(encoding="utf-8"))

from databricks import sql
host = os.environ.get("DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net")
http_path = os.environ.get("DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308")
token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
conn = sql.connect(server_hostname=host, http_path=http_path,
                   access_token=token) if token else \
       sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")
cur = conn.cursor()

by_schema = defaultdict(list)
prior: dict[str, int] = {}
prior_total: dict[str, int] = {}
for t in targets:
    parts = t["uc_target"].split(".")
    if len(parts) == 3:
        by_schema[(parts[0], parts[1])].append(parts[2].lower())
        prior[t["uc_target"]] = t.get("uc_commented_cols", 0)
        prior_total[t["uc_target"]] = t.get("uc_total_cols", 0)

print(f"Verifying {len(targets)} UC targets...\n")
print(f"{'UC target':<88} {'before':>7} {'after':>7} {'delta':>7}  status")
print("-" * 130)

rows: list[dict] = []
for (cat, sch), tbls in by_schema.items():
    in_clause = ", ".join(f"'{t}'" for t in sorted(tbls))
    cur.execute(
        f"SELECT lower(table_name), COUNT(*) AS total, "
        f"  SUM(CASE WHEN comment IS NOT NULL AND comment <> '' THEN 1 ELSE 0 END) AS commented "
        f"FROM {cat}.information_schema.columns "
        f"WHERE table_schema = '{sch}' AND lower(table_name) IN ({in_clause}) "
        f"GROUP BY lower(table_name)"
    )
    ccov = {r[0]: (int(r[1]), int(r[2])) for r in cur.fetchall()}
    for t in sorted(tbls):
        full = f"{cat}.{sch}.{t}"
        total, commented = ccov.get(t, (0, 0))
        was = prior.get(full, 0)
        if total == 0:
            status = "NO TABLE"
        elif commented == total:
            status = "FULL"
        elif commented > was:
            status = f"+{commented - was}"
        else:
            status = "unchanged"
        print(f"{full:<88} {was:>7} {commented:>7} {commented - was:>7}  {status}  ({commented}/{total})")
        rows.append({"uc_target": full, "before": was, "after": commented,
                     "delta": commented - was, "total": total, "status": status})

cur.close()
conn.close()

total_before = sum(r["before"] for r in rows)
total_after = sum(r["after"] for r in rows)
total_cols = sum(r["total"] for r in rows)
print(f"\nAggregate: before={total_before}  after={total_after}  delta=+{total_after - total_before}  "
      f"of {total_cols} total cols  ({100*total_after/max(1,total_cols):.1f}% covered)")
full = sum(1 for r in rows if r["status"] == "FULL")
print(f"FULL: {full}/{len(rows)}")

out = REPO / "tools/lakebridge/low_coverage_verify_report.csv"
with out.open("w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["uc_target", "before", "after", "delta", "total", "status"])
    w.writeheader()
    w.writerows(rows)
print(f"Report: {out.relative_to(REPO).as_posix()}")
