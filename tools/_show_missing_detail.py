import json
from pathlib import Path
m = json.loads(Path("knowledge/synapse/Wiki/_generic_pipeline_mapping.json").read_text(encoding="utf-8"))["mappings"]
by_key = {}
for x in m:
    by_key.setdefault((x.get("schema_name", ""), x.get("table_name", "")), []).append(x)

names = [
    ("BI_DB_dbo", "BI_DB_BO_Generated_Compensations"),
    ("BI_DB_dbo", "BI_DB_ICF_Report"),
    ("BI_DB_dbo", "BI_DB_RiskAlertManagementTool"),
    ("DWH_dbo", "Dim_Instrument_Snapshot"),
    ("DWH_dbo", "V_Fact_CustomerAction_for_generic"),
    ("DWH_dbo", "V_Fact_SnapshotEquity"),
    ("Dealing_dbo", "Dealing_Staking_Summary_US"),
    ("eMoney_dbo", "eMoney_Customer_Risk_Assessment"),
    ("eMoney_dbo", "eMoney_Customer_Risk_Assessment_History"),
]
for k in names:
    rows = by_key.get(k, [])
    print(f"\n{k[0]}.{k[1]}: {len(rows)} mapping row(s)")
    for r in rows:
        uc = r.get("uc_table", "")
        db = r.get("database_name", "")
        cs = r.get("copy_strategy", "")
        src = r.get("source_type", "")
        print(f"  db={db:<25} uc={uc:<70} copy={cs} src={src}")
