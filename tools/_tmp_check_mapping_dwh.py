"""Verify _generic_pipeline_mapping.json has rows for all 5 DWH schemas."""
import json
from collections import Counter
from pathlib import Path

m = json.loads(
    Path("knowledge/synapse/Wiki/_generic_pipeline_mapping.json").read_text(
        encoding="utf-8"
    )
)["mappings"]

print(f"Total rows: {len(m)}")
print()

# Look for sql_dp_prod_we entries (the DWH server)
sdpw = [r for r in m if r.get("database_name") == "sql_dp_prod_we"]
print(f"database='sql_dp_prod_we' rows: {len(sdpw)}")
print()

print("Schema breakdown for sql_dp_prod_we:")
schemas = Counter(r.get("schema_name", "") for r in sdpw)
for s, n in schemas.most_common():
    print(f"  {s:25s}  {n}")

print()
print("Sample uc_table values:")
for s in ["BI_DB_dbo", "Dealing_dbo", "DWH_dbo", "eMoney_dbo", "EXW_Wallet"]:
    rows = [r for r in sdpw if r.get("schema_name") == s]
    print(f"  {s} ({len(rows)} rows)")
    for r in rows[:2]:
        print(f"    {r['schema_name']}.{r['table_name']:50s} -> {r['uc_table']}")
