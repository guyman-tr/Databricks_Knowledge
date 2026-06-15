import re
from pathlib import Path
files = [
    "knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Customer_Daily_Status.alter.sql",
    "knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_AUM.alter.sql",
    "knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoneyClientBalance.alter.sql",
    "knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_ContactType.alter.sql",
    "knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_CommoditiesIntraHour_Clients.alter.sql",
    "knowledge/synapse/Wiki/Dealing_dbo/Tables/Dealing_Islamic_Daily_Administrative_Fee.alter.sql",
    "knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoney_Panel_Retention_Monthly.alter.sql",
    "knowledge/synapse/Wiki/eMoney_dbo/Views/v_eMoney_Card_Instance_Summary.alter.sql",
]
for fp in files:
    p = Path(fp)
    if not p.exists():
        print(f"NOT FOUND {fp}")
        continue
    t = p.read_text(encoding="utf-8")
    m = re.search(r"SET\s+TBLPROPERTIES\s*\(\s*'comment'\s*=\s*'((?:[^']|'')*)'", t, re.IGNORECASE)
    if m:
        c = m.group(1)
        print(f"{p.name}: alter tbl comment len={len(c)}, first 100 chars: {c[:100]!r}")
    else:
        print(f"{p.name}: NO TBLPROPERTIES comment line in alter")
