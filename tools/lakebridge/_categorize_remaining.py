"""Categorize the residual 74 SP failures by business priority.

Priority buckets:
  CRITICAL    : Dim_/Fact_ SPs that write to one of the 40 main.* mirror-gap
                tables (i.e. the SPs the user really needs working).
  BUSINESS    : Other Dim_/Fact_ SPs and their _DL_To_Synapse loaders.
  BACKUP      : SP names containing _bkp_, _20240507, _OLD_VER, _Eyal, JUNK_, etc.
  TEST        : SP_Test_*, SP_Check_*
  INFRA       : CopyInto*, DropTable, Truncate*, AddPartitions*, KillTableau*,
                AlterWorkLoadGroup, CreateParquet*, ProcessStatusLog, Log_*,
                Remove_CI_*, DBA_*, Columnstore*
"""
import csv
import re
from collections import defaultdict
from pathlib import Path

# Known critical Fact/Dim outputs (from the prior main mirror gap audit).
CRITICAL_OUTPUTS = {
    "dim_instrument_correlation_groupsinstruments",
    "dim_instrument_correlation_half_records",
    "dim_instrument_snapshot",
    "dim_position_switch_single",
    "dim_positionhedgeserverchangelog_snapshot",
    "fact_cashout_rollback",
    "fact_cashout_state",
    "fact_customeraction_switch",
    "fact_customerunrealized_pnl_userapi",
    "fact_deposit_fees",
    "fact_deposit_state",
    "fact_position_futures_snapshot",
    "fact_reverse_deposits",
    "fact_settlement_prices",
    "fact_snapshotcustomer",
    "fact_snapshotequity",
    "fact_withdraw_fees",
    "dim_getspreadedpricecandle60minsplitted",
    "dim_getspreadedpriceusdconversionrate",
}


def bucket(name: str) -> str:
    low = name.lower()
    base = re.sub(r"\.sql$", "", name).lower()
    base = re.sub(r"^dwh_dbo\.|^bi_db_dbo\.", "", base)

    if re.search(r"_bkp_|_20240507|_old_ver|_eyal|_backup_|junk_", low):
        return "BACKUP"
    if base.startswith("sp_test_") or base.startswith("sp_check_"):
        return "TEST"
    infra_prefixes = (
        "copyinto", "droptable", "dropstaging", "truncate", "addpartitions",
        "checkifpartition", "killtableau", "alterworkload", "createparquet",
        "processstatuslog", "sp_log_", "remove_ci_", "dba_",
        "dwh_columnstore", "sp_dwh_status", "sp_populatedimdate",
        "sp_alterworkload", "waitforseconds",
    )
    for p in infra_prefixes:
        if base.startswith(p) or p in base:
            return "INFRA"
    # Try to extract the Fact_/Dim_ output table the SP writes to.
    for tag in CRITICAL_OUTPUTS:
        if tag.lower() in base:
            return "CRITICAL"
    if "fact_" in base or "dim_" in base or "dl_to_synapse" in base:
        return "BUSINESS"
    return "OTHER"


rows = [
    r for r in csv.DictReader(
        open("bulk_fix_deploy_report.csv", encoding="utf-8")
    )
    if r["status"] == "error"
]

groups: dict[str, list[dict]] = defaultdict(list)
for r in rows:
    name = Path(r["rel"]).name
    err = (r["error"] or "")
    m = re.search(r"near '([^']*)'", err)
    near = m.group(1) if m else "?"
    groups[bucket(name)].append({"name": name, "near": near})

order = ["CRITICAL", "BUSINESS", "BACKUP", "TEST", "INFRA", "OTHER"]
print(f"Total residual failures: {len(rows)}")
print()
for c in order:
    items = groups.get(c, [])
    if not items:
        continue
    print(f"=== {c} ({len(items)}) ===")
    for it in sorted(items, key=lambda x: x["name"]):
        print(f"  {it['name']:65s} near {it['near']!r}")
    print()
