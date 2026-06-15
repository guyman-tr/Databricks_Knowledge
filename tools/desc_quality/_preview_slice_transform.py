"""Preview the slice-category surgical transform end-to-end."""
import os, sys
sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parents[1]))
from sweep_creditbureau_to_client_balance import (
    transform_slice, transform_legacy_prev,
    open_connection, fetch_comment,
)

print("Connecting...")
conn = open_connection()
cur = conn.cursor()

cases = [
    ("bi_db", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status",
     "IsCreditReportValidCB_ThisMonth", "slice"),
    ("general", "gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg",
     "IsCreditReportValidCBPrev", "legacy"),
]

for schema, table, col, cat in cases:
    cur.execute(
        f"SELECT comment FROM system.information_schema.columns "
        f"WHERE table_catalog='main' AND table_schema='{schema}' "
        f"AND table_name='{table}' AND column_name='{col}'"
    )
    row = cur.fetchone()
    before = row[0] if row else ""
    after = transform_slice(before) if cat == "slice" else transform_legacy_prev(before)
    print("=" * 110)
    print(f"{schema}.{table}.{col}  ({cat})")
    print(f"\n  BEFORE ({len(before)} chars):\n  {before}")
    print(f"\n  AFTER  ({len(after)} chars):\n  {after}")
    print()

cur.close()
conn.close()
