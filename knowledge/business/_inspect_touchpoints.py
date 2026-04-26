"""Inspect top hits from subaccount-option1-touchpoints.csv to sanity-check the scanner."""
from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)

CSV_PATH = Path(__file__).parent / "subaccount-option1-touchpoints.csv"


def show(rows: list[dict], limit: int = 999) -> None:
    for i, r in enumerate(rows[:limit]):
        print(f"  [{i+1:>3}] {r['schema']}.{r['object_name']} ({r['object_type']})  prio={r['priority']}  proc={r['process_name']}", flush=True)
        print(f"        reasons: {r['reasons']}", flush=True)
        sample = json.loads(r["samples_json"]) if r.get("samples_json") else {}
        for key in ("VAL.IsValidCustomer", "VAL.IsCreditReportValid", "USR.FTD", "USR.Registration", "USR.Funded", "USR.COUNT_DISTINCT_CID", "USR.GROUP_BY_CID"):
            if key in sample:
                first = sample[key][0] if sample[key] else ""
                print(f"        {key}: {first}", flush=True)
        print(flush=True)


def main() -> int:
    rows = list(csv.DictReader(CSV_PATH.open(encoding="utf-8")))

    print("\n=== TIER A priority 99 (FinanceReportSPS) ===\n", flush=True)
    show([r for r in rows if r["tier"] == "A" and r["priority"] == "99"])

    print("\n=== TIER A priority 90 ===\n", flush=True)
    show([r for r in rows if r["tier"] == "A" and r["priority"] == "90"])

    print("\n=== TIER A priority 20 (top 15) ===\n", flush=True)
    show([r for r in rows if r["tier"] == "A" and r["priority"] == "20"], limit=15)

    print("\n=== TIER A priority 0 — TOP 15 by hit count ===\n", flush=True)
    a_zero = [r for r in rows if r["tier"] == "A" and r["priority"] == "0"]
    a_zero.sort(key=lambda r: -(int(r.get("VAL.IsValidCustomer", 0)) + int(r.get("USR.COUNT_DISTINCT_CID", 0)) + int(r.get("USR.FTD", 0))))
    show(a_zero, limit=15)

    print("\n=== TIER A unscheduled — TOP 15 (these are likely views/functions/legacy) ===\n", flush=True)
    show([r for r in rows if r["tier"] == "A" and r["priority"] == "-1"], limit=15)

    print("\n=== TIER B priority 99 ===\n", flush=True)
    show([r for r in rows if r["tier"] == "B" and r["priority"] == "99"])

    return 0


if __name__ == "__main__":
    sys.exit(main())
