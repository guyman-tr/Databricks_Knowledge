"""Print custom SQL body + a per-tile field summary for the LIVE-QUERY workbook."""
import json
import os, sys

WB = "knowledge/tableau/_workbooks/DDR_s/eToro_s_Daily_Data_Report_New_DDR_2025_-_LIVE_QUERY.tiles.json"

d = json.load(open(WB, encoding="utf-8"))

print("=" * 78)
print(f"Custom SQL bodies ({len(d.get('custom_sql', []))})")
print("=" * 78)
for c in d.get("custom_sql", []):
    print(f"--- {c.get('name')} (datasource={c.get('datasource_name')}) ---")
    body = c.get("query") or ""
    print(body[:2000])
    print()

# Per-tile field summary for our 14 candidate tiles
TILE_NAMES = [
    "Revenue: Commission & Other Fees",
    "Revenue: Rollover Fees Breakdown",
    "Revenue: Admin Fees Breakdown",
    "Revenue: Spot Adjustment Fees Breakdown",
    "Revenue: Marketing Region Chart",
    "MIMO: Trading Platform's Deposits & Withdraws",
    "MIMO: Global Deposits & Withdraws",
    "MIMO: External Deposits to TP",
    "MIMO: Internal Deposits to TP",
    "MIMO: Cashout & Redeem Users Count",
    "AUM & PnL: PnL KPIs",
    "AUM & PnL: Yesterday's KPIs 1",
    "AUM & PnL: PnL Chart",
    "Yesterday's: Financial KPIs",
]

print()
print("=" * 78)
print("Per-tile field summary")
print("=" * 78)
sheets_by_name = {s["name"]: s for s in d["sheets"]}
for name in TILE_NAMES:
    s = sheets_by_name.get(name)
    if not s:
        print(f"\n??? sheet not found: {name}")
        continue
    print(f"\n--- {name} ---")
    print(f"  datasources: {s['datasource_names']}")
    fis = s.get("field_instances", [])
    # Group fields: ColumnField (data columns), CalculatedField (formulas), SetField (filter sets), ParameterField (params)
    cols = [f for f in fis if f.get("kind") == "ColumnField"]
    calcs = [f for f in fis if f.get("kind") == "CalculatedField"]
    sets_ = [f for f in fis if f.get("kind") == "SetField"]
    params = [f for f in fis if f.get("kind") == "ParameterField"]
    bins = [f for f in fis if f.get("kind") == "BinField"]
    others = [f for f in fis if f.get("kind") not in ("ColumnField", "CalculatedField", "SetField", "ParameterField", "BinField")]
    print(f"  ColumnFields ({len(cols)}):")
    for f in cols:
        agg = f.get("aggregation") or "(none)"
        print(f"    - {f['name']}  agg={agg}")
    if calcs:
        print(f"  CalculatedFields ({len(calcs)}):")
        for f in calcs:
            formula = (f.get("formula") or "").replace("\r\n", " ").replace("\n", " ")
            print(f"    - {f['name']}: {formula[:140]}")
    if sets_:
        print(f"  SetFields ({len(sets_)}):")
        for f in sets_:
            print(f"    - {f['name']}")
    if params:
        print(f"  ParameterFields ({len(params)}):")
        for f in params:
            print(f"    - {f['name']}")
    if others:
        print(f"  Other ({len(others)}):")
        for f in others:
            print(f"    - {f['name']} kind={f.get('kind')}")
