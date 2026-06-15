"""Check whether any tables flagged B_NO_TABLEAU_CONSUMER in Phase B are
actually referenced by a Published Datasource."""

from __future__ import annotations

import csv
from pathlib import Path

REPO_ROOT  = Path(__file__).resolve().parents[2]
B_CSV      = REPO_ROOT / "audits" / "blacklist" / "migration_blacklist_phase_b_2026-05-31.csv"
PDS_CSV    = REPO_ROOT / "knowledge" / "tableau" / "_index" / "published_datasources.csv"


def main() -> int:
    pds_tables: dict[str, list[tuple[str, str]]] = {}
    with PDS_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            bare = (row.get("upstream_table_bare") or "").strip()
            if not bare:
                continue
            pds_tables.setdefault(bare, []).append(
                (row["pds_name"], row["downstream_workbook_count"])
            )
    print(f"unique tables referenced by ≥1 PDS: {len(pds_tables)}")
    print("Tables with PDS references:")
    for bare in sorted(pds_tables):
        refs = pds_tables[bare]
        wbs = sum(int(c) for _, c in refs if c.isdigit())
        print(f"  {bare:60s} pds_count={len(refs)}  total_downstream_wbs={wbs}")

    no_consumer_in_b: list[dict] = []
    with B_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            if row["verdict"] == "B_NO_TABLEAU_CONSUMER":
                no_consumer_in_b.append(row)
    print(f"\nB_NO_TABLEAU_CONSUMER count: {len(no_consumer_in_b)}")

    overlap: list[dict] = []
    for r in no_consumer_in_b:
        bare = r["TableName"].split(".", 1)[-1].strip("[]") if "." in r["TableName"] else r["TableName"]
        if bare in pds_tables:
            overlap.append({**r, "_pds_refs": pds_tables[bare]})

    print(f"\nFalse-positive count (PDS references a B_NO_TABLEAU_CONSUMER table): {len(overlap)}")
    for r in overlap:
        bare = r["TableName"].split(".", 1)[-1].strip("[]")
        wbs_total = sum(int(c) for _, c in r["_pds_refs"] if c.isdigit())
        print(f"  {r['TableName']}")
        for pds_name, wb_count in r["_pds_refs"]:
            print(f"      via PDS '{pds_name}'  (downstream_workbooks={wb_count})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
