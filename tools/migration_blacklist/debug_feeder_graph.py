"""Debug why feeder graph has 0 hits."""

from __future__ import annotations

import csv
from pathlib import Path

REPO_ROOT  = Path(__file__).resolve().parents[2]
A3_CSV     = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a3_2026-05-31.csv"
FINAL_CSV  = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_FINAL_2026-05-31.csv"
WBS_CSV    = REPO_ROOT / "knowledge" / "tableau" / "_index" / "workbooks.csv"
DEPS_CSV   = REPO_ROOT / "audits" / "blacklist" / "_b_work" / "sp_dependencies.csv"


def main() -> int:
    blacklisted = set()
    with FINAL_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            blacklisted.add((row["ProcedureName"], row["TableName"]))

    surviving = []
    with A3_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if (row["ProcedureName"], row["TableName"]) in blacklisted:
                continue
            if (row.get("decision") or "").strip().lower() == "blacklist":
                continue
            surviving.append(row)

    wb_tables = set()
    with WBS_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            t = (row.get("table") or "").strip()
            if t:
                wb_tables.add(t)

    print(f"surviving: {len(surviving)}")
    print(f"workbooks.csv distinct tables: {len(wb_tables)}")

    # live_output_bare
    live_output_bare = set()
    for s in surviving:
        bare = s["TableName"].split(".", 1)[-1].strip("[]") if "." in s["TableName"] else s["TableName"]
        if bare in wb_tables:
            live_output_bare.add(bare)
    print(f"live_output_bare: {len(live_output_bare)}")
    print(f"  sample: {list(live_output_bare)[:5]}")

    # live_producing_procs
    live_producing_procs = set()
    for s in surviving:
        bare = s["TableName"].split(".", 1)[-1].strip("[]") if "." in s["TableName"] else s["TableName"]
        if bare in live_output_bare:
            proc_full = s["ProcedureName"]
            if "." in proc_full:
                sch, name = proc_full.split(".", 1)
            else:
                sch, name = "dbo", proc_full
            live_producing_procs.add((sch.strip("[]"), name.strip("[]")))
    print(f"live_producing_procs: {len(live_producing_procs)}")
    print(f"  sample: {list(live_producing_procs)[:5]}")

    # deps procs
    dep_procs = set()
    dep_rows_with_match = 0
    feeder_targets = set()
    with DEPS_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            key = (row["referencing_schema"], row["referencing_proc"])
            dep_procs.add(key)
            if key in live_producing_procs:
                dep_rows_with_match += 1
                referenced = (row.get("referenced_object") or "").strip().strip("[]")
                if referenced:
                    feeder_targets.add(referenced)
    print(f"deps distinct procs: {len(dep_procs)}")
    print(f"  sample: {list(dep_procs)[:5]}")
    print(f"intersection live_producing_procs ∩ deps: {len(live_producing_procs & dep_procs)}")
    print(f"  sample: {list(live_producing_procs & dep_procs)[:5]}")
    print(f"dep rows where ref proc is live_producing: {dep_rows_with_match}")
    print(f"feeder_targets: {len(feeder_targets)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
