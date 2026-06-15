"""Count surviving output tables after A0+A3 blacklist, vs Tableau index coverage."""

from __future__ import annotations

import csv
from pathlib import Path

REPO_ROOT  = Path(__file__).resolve().parents[2]
A3_CSV     = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_a3_2026-05-31.csv"
FINAL_CSV  = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_FINAL_2026-05-31.csv"
TAB_INDEX  = REPO_ROOT / "knowledge" / "tableau" / "_index" / "workbooks.csv"


def main() -> int:
    blacklisted: set[tuple[str, str]] = set()
    with FINAL_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            blacklisted.add((row["ProcedureName"], row["TableName"]))

    surviving_tables: set[str] = set()
    surviving_pairs = 0
    with A3_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if (row["ProcedureName"], row["TableName"]) in blacklisted:
                continue
            if row["decision"].strip().lower() == "blacklist":
                continue
            surviving_pairs += 1
            surviving_tables.add(row["TableName"])

    print(f"surviving (proc, table) pairs:  {surviving_pairs}")
    print(f"unique surviving output tables: {len(surviving_tables)}")
    print()
    schemas: dict[str, int] = {}
    for t in surviving_tables:
        sch = t.split(".", 1)[0] if "." in t else "(none)"
        schemas[sch] = schemas.get(sch, 0) + 1
    for k, v in sorted(schemas.items(), key=lambda x: -x[1]):
        print(f"  {k:24s} {v:5d}")

    print()
    if TAB_INDEX.exists():
        already_probed: set[str] = set()
        with TAB_INDEX.open("r", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                already_probed.add(row["table"])
        print(f"tables already in knowledge/tableau/_index/workbooks.csv: {len(already_probed)}")
        bare_surviving = {t.split(".", 1)[1] if "." in t else t for t in surviving_tables}
        overlap = bare_surviving & already_probed
        print(f"overlap with surviving (by bare name):                    {len(overlap)}")
        print(f"surviving tables NOT yet probed in Tableau:               {len(bare_surviving) - len(overlap)}")
    else:
        print("(no existing tableau index)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
