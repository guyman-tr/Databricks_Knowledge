"""
audit_main_mirror_gaps.py

For every table that a transpiled SP writes to in
`dwh_daily_process.migration_tables.<X>`, check whether a "twin mirror"
exists somewhere under `main.<any_schema>.*`. The naming conventions we
recognize:

    main.<schema>.gold_sql_dp_prod_we_dwh_dbo_<lower_x>
    main.<schema>.gold_sql_dp_prod_we_dwh_dbo_<lower_x>_masked
    main.<schema>.bronze_<sourcedb>_<sub>_<lower_x>          (any bronze)
    main.<schema>.gold_inc_test_dwh_dbo_<lower_x>            (legacy test)
    main.<schema>.<lower_x>                                  (bare name match)

When **none** match, the table is reported as missing -- DE needs to add it
to the generic replication pipeline so the production SP can find it after
cutover.

Output:
  tools/lakebridge/audit/MAIN_MIRROR_GAPS.md   (human-readable)
  tools/lakebridge/audit/main_mirror_gaps.csv  (full data)
"""

from __future__ import annotations

import csv
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).parent
AUDIT_DIR = ROOT / "audit"
AUDIT_DIR.mkdir(exist_ok=True)
AUDIT_CSV = AUDIT_DIR / "migration_tables_audit.csv"
GAPS_CSV = AUDIT_DIR / "main_mirror_gaps.csv"
GAPS_MD = AUDIT_DIR / "MAIN_MIRROR_GAPS.md"


def fetch_token(profile: str) -> str:
    res = subprocess.run(
        ["databricks", "auth", "token", "--profile", profile, "-o", "json"],
        capture_output=True, text=True, check=True, shell=True,
    )
    return json.loads(res.stdout)["access_token"]


def load_sp_outputs() -> dict[str, list[str]]:
    """Return {table_name: [sp1, sp2, ...]} for every output table our audit
    saw at least one SP write to."""
    out: dict[str, list[str]] = {}
    with AUDIT_CSV.open(encoding="utf-8") as fh:
        r = csv.DictReader(fh)
        for row in r:
            if row["in_lake"] != "Y":
                continue
            if int(row["sp_count"]) == 0:
                continue
            sps = [s for s in row["written_by_sps"].split(";") if s]
            out[row["table_name"]] = sps
    return out


def classify_table(name: str) -> str:
    n = name.lower()
    if n.startswith("ext_"):
        return "Ext_ staging (internal)"
    if n.startswith("dim_"):
        return "Dim_*"
    if n.startswith("fact_"):
        return "Fact_*"
    if n.startswith("v_") or n.startswith("vw_"):
        return "View"
    if n.startswith("util_") or n.startswith("val_"):
        return "Validation / util"
    if n.startswith("temp_"):
        return "Temp"
    return "Other"


def main() -> None:
    sp_outputs = load_sp_outputs()
    print(f"Loaded {len(sp_outputs)} SP-written tables from audit CSV")

    token = fetch_token("name-of-profile")
    from databricks import sql as dbsql
    conn = dbsql.connect(
        server_hostname="adb-5142916747090026.6.azuredatabricks.net",
        http_path="/sql/1.0/warehouses/208214768b0e0308",
        access_token=token,
    )
    cur = conn.cursor()

    print("Loading all table/view names under main.* ...")
    cur.execute(
        "SELECT lower(table_schema) AS sch, lower(table_name) AS name, table_type "
        "FROM system.information_schema.tables WHERE table_catalog='main'"
    )
    all_main: list[tuple[str, str, str]] = cur.fetchall()
    cur.close()
    conn.close()
    print(f"  {len(all_main)} objects found across {len(set(r[0] for r in all_main))} schemas in main.*")

    # Build an index keyed by lowercased name, value = list of (schema, name, type)
    by_name: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    for sch, name, ttype in all_main:
        by_name[name].append((sch, name, ttype))
    # Also build a substring index: for each main object, the part after the
    # last `_dwh_dbo_` (if present) is the "logical" table name.
    by_logical: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    logical_pat = re.compile(r"_dwh_dbo_(.*?)(?:_masked)?$")
    bronze_pat = re.compile(r"^bronze_[a-z0-9_]+?_([a-z0-9_]+)$")
    for sch, name, ttype in all_main:
        m1 = logical_pat.search(name)
        if m1:
            by_logical[m1.group(1)].append((sch, name, ttype))
        m2 = bronze_pat.search(name)
        if m2:
            by_logical[m2.group(1)].append((sch, name, ttype))
        # Bare name match
        by_logical[name].append((sch, name, ttype))

    # ---- Match each SP output to candidate twins -------------------------
    rows: list[dict] = []
    for tbl, sps in sorted(sp_outputs.items()):
        n = tbl.lower()
        twins: list[tuple[str, str, str]] = []
        # Direct candidates: any name in main.* whose logical name matches.
        twins.extend(by_logical.get(n, []))
        # Dedup
        twins = sorted(set(twins))
        rows.append({
            "table_name": tbl,
            "category": classify_table(tbl),
            "sp_count": len(sps),
            "sps": ", ".join(sps[:3]) + (f" +{len(sps)-3}" if len(sps) > 3 else ""),
            "twin_count": len(twins),
            "twin_names": "; ".join(f"main.{s}.{nm}" for s, nm, _t in twins[:3])
                          + (f" +{len(twins)-3}" if len(twins) > 3 else ""),
            "has_twin": "Y" if twins else "N",
        })

    # ---- Write CSV -------------------------------------------------------
    with GAPS_CSV.open("w", encoding="utf-8", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    print(f"CSV written: {GAPS_CSV}")

    # ---- Group missing by category --------------------------------------
    missing = [r for r in rows if r["has_twin"] == "N"]
    has = [r for r in rows if r["has_twin"] == "Y"]
    print(f"With twin in main.*: {len(has)}")
    print(f"WITHOUT twin (DE needs to add): {len(missing)}")

    # ---- Write MD report ------------------------------------------------
    with GAPS_MD.open("w", encoding="utf-8") as fh:
        fh.write("# `main.<schema>` mirror-gap audit\n\n")
        fh.write(f"For every of the {len(sp_outputs)} tables in ")
        fh.write("`dwh_daily_process.migration_tables` that an SP writes to, ")
        fh.write("we searched `main.<any_schema>.*` for a twin mirror using these ")
        fh.write("naming conventions:\n\n")
        fh.write("- `gold_sql_dp_prod_we_dwh_dbo_<table>` (with or without `_masked` suffix)\n")
        fh.write("- `bronze_<sourcedb>_<schema>_<table>`\n")
        fh.write("- bare `<table>`\n\n")
        fh.write(f"## Result\n\n")
        fh.write(f"- **Has twin** in `main.*`: **{len(has)}**\n")
        fh.write(f"- **NO twin in `main.*`**: **{len(missing)}** _but only the ")
        fh.write("non-Ext_ ones are real gaps DE must fix; Ext_ tables are ")
        fh.write("internal staging built by `*_DL_To_Synapse` SPs and don't need a ")
        fh.write("main.* mirror._\n\n")

        by_cat: dict[str, list[dict]] = defaultdict(list)
        for r in missing:
            by_cat[r["category"]].append(r)

        # Real DE-action gaps: everything that's NOT Ext_ staging.
        real_gap_cats = ["Dim_*", "Fact_*", "Validation / util", "Other", "View", "Temp"]
        real_gaps: list[dict] = []
        for c in real_gap_cats:
            real_gaps.extend(by_cat.get(c, []))
        real_gaps.sort(key=lambda x: (x["category"], x["table_name"]))

        fh.write(f"---\n\n## Part 1 — Real gaps (DE must add): {len(real_gaps)}\n\n")
        fh.write("These tables are consumer-facing outputs (Dim_, Fact_, util/val, ")
        fh.write("logging, process-status) that have no `main.*` mirror. When ")
        fh.write("Databricks SPs become the production writer, downstream consumers ")
        fh.write("(reports, dashboards, other SPs that read from `main.*`) will ")
        fh.write("fail unless these are added to the generic replication pipeline.\n\n")

        for c in real_gap_cats:
            items = sorted(by_cat.get(c, []), key=lambda x: x["table_name"])
            if not items:
                continue
            fh.write(f"### {c} ({len(items)})\n\n")
            fh.write("| # | table | # SPs | sample SPs |\n|---:|---|---:|---|\n")
            for i, r in enumerate(items, 1):
                fh.write(f"| {i} | `{r['table_name']}` | {r['sp_count']} | {r['sps']} |\n")
            fh.write("\n")

        # Copy-paste list for the DE ticket.
        fh.write("\n#### Copy-paste list for DE ticket\n\n")
        fh.write("```\n")
        for r in real_gaps:
            fh.write(f"DWH_dbo.{r['table_name']}\n")
        fh.write("```\n\n")

        # Part 2: Ext_ informational
        fh.write(f"---\n\n## Part 2 — Ext_* internal staging ({len(by_cat.get('Ext_ staging (internal)', []))})\n\n")
        fh.write("Listed for completeness only. These are NOT a DE ask — they are ")
        fh.write("populated by `*_DL_To_Synapse` migration SPs from sources in ")
        fh.write("`daily_snapshot` views and consumed only by other migration SPs ")
        fh.write("inside `migration_tables`. No `main.*` mirror is required.\n\n")
        ext_items = sorted(by_cat.get("Ext_ staging (internal)", []), key=lambda x: x["table_name"])
        fh.write("<details><summary>Expand to see the 114 Ext_* tables</summary>\n\n")
        fh.write("| # | table | # SPs |\n|---:|---|---:|\n")
        for i, r in enumerate(ext_items, 1):
            fh.write(f"| {i} | `{r['table_name']}` | {r['sp_count']} |\n")
        fh.write("\n</details>\n\n")

        fh.write(f"---\n\n## Has twin (KEEP — already mirrored) — {len(has)} tables\n\n")
        fh.write("_See `main_mirror_gaps.csv` for the full table→twin mapping._\n")

    print(f"Report written: {GAPS_MD}")


if __name__ == "__main__":
    main()
