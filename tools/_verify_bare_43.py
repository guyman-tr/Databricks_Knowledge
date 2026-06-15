"""Verify all 42 bare-43 UC targets now have:
  * Non-empty table comment
  * Column comments covering most/all columns

Reads original targets file (not the post-Duration overwritten summary).
"""
import csv
import json
import os
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
targets = json.loads((REPO / "tools/lakebridge/bare_43_targets.json").read_text(encoding="utf-8"))

from databricks import sql
host = os.environ.get("DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net")
http_path = os.environ.get("DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308")
token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
if token:
    conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
else:
    conn = sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")
cur = conn.cursor()

# Per-schema query: table comments + column comment coverage
by_schema = defaultdict(list)
for t in targets:
    parts = t["uc_target"].split(".")
    if len(parts) == 3:
        by_schema[(parts[0], parts[1])].append(parts[2].lower())

print(f"Verifying {len(targets)} UC targets...\n")
print(f"{'UC target':<70} {'tcom':>5}  {'cols':>10}  status")
print("-" * 100)

rows: list[dict] = []
for (cat, sch), tbls in by_schema.items():
    in_clause = ", ".join(f"'{t}'" for t in sorted(tbls))
    # table comments
    cur.execute(
        f"SELECT table_name, comment FROM {cat}.information_schema.tables "
        f"WHERE table_schema = '{sch}' AND lower(table_name) IN ({in_clause})"
    )
    tcom = {r[0].lower(): (r[1] or "") for r in cur.fetchall()}
    # column comments
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
        tc = tcom.get(t, "")
        total, commented = ccov.get(t, (0, 0))
        ok_tc = bool(tc.strip())
        if total == 0:
            status = "NO TABLE in UC"
        elif not ok_tc and commented == 0:
            status = "STILL BARE"
        elif ok_tc and commented == total:
            status = "FULLY COMMENTED"
        elif ok_tc and commented > 0:
            status = f"PARTIAL ({commented}/{total} cols)"
        elif ok_tc:
            status = "TABLE-ONLY"
        else:
            status = f"COLS-ONLY ({commented}/{total})"
        print(f"{full:<70} {'Y' if ok_tc else 'n':>5}  {commented:>3}/{total:<3}    {status}")
        rows.append({"uc_target": full, "table_comment_set": ok_tc,
                     "cols_total": total, "cols_commented": commented,
                     "status": status, "table_comment_len": len(tc)})

cur.close()
conn.close()

# Summary
buckets = defaultdict(int)
for r in rows:
    buckets[r["status"].split(" ")[0]] += 1
print("\nSummary:")
for k, v in sorted(buckets.items(), key=lambda x: -x[1]):
    print(f"  {k:<20} {v}")

out = REPO / "tools/lakebridge/bare_43_verify_report.csv"
with out.open("w", encoding="utf-8", newline="") as f:
    w = csv.DictWriter(f, fieldnames=["uc_target", "table_comment_set",
                                      "cols_total", "cols_commented", "status",
                                      "table_comment_len"])
    w.writeheader()
    w.writerows(rows)
print(f"\nReport: {out.relative_to(REPO).as_posix()}")
