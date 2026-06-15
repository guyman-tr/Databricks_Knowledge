"""Post-deploy verification: query information_schema for comment coverage on
all four AppsFlyer objects + spot-check the table comments."""
from __future__ import annotations
import os
from databricks import sql

OBJECTS = [
    ("main", "de_output", "de_output_appsflyer_silver_reports", "TABLE"),
    ("main", "bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_appflyer_reports", "TABLE"),
    ("main", "bi_db", "bronze_marketperformance_tracking_customer", "TABLE"),
    ("main", "bridgeclaw_permitted_data", "appflyer_reports", "VIEW"),
]

host = os.environ.get("DATABRICKS_SERVER_HOSTNAME", "adb-5142916747090026.6.azuredatabricks.net")
http_path = os.environ.get("DATABRICKS_HTTP_PATH", "/sql/1.0/warehouses/208214768b0e0308")
token = (os.environ.get("DATABRICKS_TOKEN") or "").strip()
if token:
    conn = sql.connect(server_hostname=host, http_path=http_path, access_token=token)
else:
    conn = sql.connect(server_hostname=host, http_path=http_path, auth_type="databricks-oauth")

cur = conn.cursor()
print(f"{'OBJECT':<70} {'TOTAL':>6} {'WITH_COMMENT':>13} {'COVERAGE':>9}")
print("-" * 100)

grand = []
for cat, sch, tbl, kind in OBJECTS:
    cur.execute(f"""
        SELECT COUNT(*) AS total,
               COUNT(comment) AS with_comment,
               ROUND(100.0 * COUNT(comment) / COUNT(*), 1) AS pct
        FROM {cat}.information_schema.columns
        WHERE table_catalog = '{cat}'
          AND table_schema = '{sch}'
          AND table_name = '{tbl}'
    """)
    total, withc, pct = cur.fetchone()
    fqn = f"{cat}.{sch}.{tbl}"
    print(f"{fqn:<70} {total:>6} {withc:>13} {pct:>8.1f}%")
    grand.append((fqn, total, withc, pct))

print("\n=== TABLE / VIEW COMMENTS ===\n")
for cat, sch, tbl, kind in OBJECTS:
    cur.execute(f"""
        SELECT comment FROM {cat}.information_schema.tables
        WHERE table_catalog = '{cat}'
          AND table_schema = '{sch}'
          AND table_name = '{tbl}'
    """)
    row = cur.fetchone()
    cmt = (row[0] or "")[:160] if row else "(NOT FOUND)"
    print(f"{cat}.{sch}.{tbl}:")
    print(f"  {cmt}")
    print()

cur.close(); conn.close()

print("=" * 100)
all_full = all(t == w for _, t, w, _ in grand)
print(f"All four objects fully covered: {all_full}")
