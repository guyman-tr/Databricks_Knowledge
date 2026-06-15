"""Spot-check the DDR tile JSON for the user."""
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
P = REPO / "knowledge/tableau/_workbooks/DDR_s/eToro_s_Daily_Data_Report_DDR.tiles.json"
d = json.loads(P.read_text(encoding="utf-8"))

print("=" * 70)
print(f"WORKBOOK: {d['name']}  (luid {d['luid']})")
print(f"  {len(d['dashboards'])} dashboards, {len(d['sheets'])} sheets, "
      f"{len(d['custom_sql'])} custom-SQL, {len(d['embedded_datasources'])} datasources")

print("\n=== DASHBOARDS ===")
for ds in d["dashboards"]:
    print(f"  {ds['name']:55s} -> {len(ds['sheet_ids'])} sheets")
    for sn in ds["sheet_names"][:3]:
        print(f"      - {sn}")

print("\n=== CUSTOM SQL HEADS ===")
for c in d["custom_sql"]:
    sql = c["sql"] or ""
    head = "\n".join(sql.splitlines()[:8])
    print(f"\n--- {c['name']!r} (id={c['id'][:12]}, {len(sql)} chars, "
          f"unsupported={c['is_unsupported']}, db={c['database_name']!r}) ---")
    print(head)
    if len(sql.splitlines()) > 8:
        print(f"... [{len(sql.splitlines())-8} more lines]")

# Drill into one Revenue dashboard sheet
print("\n\n=== ONE REVENUE SHEET ===")
target = None
for s in d["sheets"]:
    if "Revenue:" in s["name"] and "Yesterday" in (",".join(s["contained_in_dashboards"])):
        target = s
        break
if not target:
    for s in d["sheets"]:
        if "Revenue:" in s["name"]:
            target = s; break
if target:
    print(f"sheet name: {target['name']!r}")
    print(f"in dashboards: {target['contained_in_dashboards']}")
    print(f"datasources : {target['datasource_names']}")
    print(f"field_instances: {len(target['field_instances'])}, "
          f"worksheet_fields: {len(target['worksheet_fields'])}")
    print("\n  -- field_instances --")
    for f in target["field_instances"]:
        agg = f["aggregation"] or ""
        formula = (f["formula"] or "").replace("\n", " ")[:70]
        ucs = [(c["name"], c["table_full_name"]) for c in f["upstream_columns"]][:2]
        rf = f["remote_field"]
        rfi = f"  remote=({rf['kind']},{rf['name']},{rf['aggregation']})" if rf else ""
        print(f"    [{f['kind']}] {f['name']!r:35s} agg={agg!r}{rfi}")
        if formula:
            print(f"        formula: {formula}")
        if ucs:
            print(f"        upstream cols: {ucs}")

# Pull two more from the Money Movement / PnL set for the 10-15 starter list
print("\n\n=== CANDIDATE TILES FOR REVENUE / MIMO / PNL DASHBOARDS ===")
seen = {}
for s in d["sheets"]:
    for dn in s["contained_in_dashboards"]:
        if dn in seen:
            continue
        if any(k in dn.lower() for k in ("revenue", "money movement", "pnl", "p&l", "trades")):
            seen[dn] = True
for dn in seen:
    print(f"\nDashboard: {dn}")
    for s in d["sheets"]:
        if dn in s["contained_in_dashboards"]:
            measures = [f["name"] for f in s["field_instances"]
                        if f["aggregation"] in ("Sum", "Count", "Avg", "Min", "Max", "CountD")
                        or (f["kind"] == "CalculatedField" and (f["formula"] or "").strip().lower().startswith("sum"))]
            print(f"  - {s['name']!r:55s} measures={measures[:5]}")
