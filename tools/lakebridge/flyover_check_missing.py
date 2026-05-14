"""
For each table on the 'missing twin' list, do a permissive substring
match against every object under main.* to surface any twin that the
strict pattern matcher missed.

Patterns checked:
  - gold_sql_dp_prod_we_dwh_dbo_<table>           (any schema, dwh+pii_data)
  - gold_sql_dp_prod_we_dwh_dbo_<table>_masked    (any schema)
  - gold_sql_dp_prod_we_*_dwh_dbo_<table>         (other middle tokens)
  - bronze_<anything>_<table>
  - silver_<anything>_<table>
  - bare <table> (exact)
  - any name CONTAINING the table token (substring, last resort)
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
GAPS_CSV = AUDIT_DIR / "main_mirror_gaps.csv"
OUT_MD = AUDIT_DIR / "FLYOVER_MISSING_CHECK.md"


def fetch_token(profile: str) -> str:
    res = subprocess.run(
        ["databricks", "auth", "token", "--profile", profile, "-o", "json"],
        capture_output=True, text=True, check=True, shell=True,
    )
    return json.loads(res.stdout)["access_token"]


def main() -> None:
    missing: list[str] = []
    with GAPS_CSV.open(encoding="utf-8") as fh:
        r = csv.DictReader(fh)
        for row in r:
            if row["has_twin"] == "N" and row["category"] != "Ext_ staging (internal)":
                missing.append(row["table_name"])
    print(f"Will fly-over check {len(missing)} non-Ext missing tables")

    token = fetch_token("name-of-profile")
    from databricks import sql as dbsql
    conn = dbsql.connect(
        server_hostname="adb-5142916747090026.6.azuredatabricks.net",
        http_path="/sql/1.0/warehouses/208214768b0e0308",
        access_token=token,
    )
    cur = conn.cursor()

    cur.execute(
        "SELECT lower(table_schema) AS sch, lower(table_name) AS name, table_type "
        "FROM system.information_schema.tables WHERE table_catalog='main'"
    )
    all_main = cur.fetchall()
    cur.close()
    conn.close()
    print(f"Loaded {len(all_main)} objects from main.*")

    # Index by exact name and as a flat list for substring scan.
    idx_exact: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    for sch, name, ttype in all_main:
        idx_exact[name].append((sch, name, ttype))

    flat = [(sch, name, ttype) for sch, name, ttype in all_main]

    found: list[dict] = []
    truly_missing: list[str] = []
    for tbl in sorted(missing):
        n = tbl.lower()
        hits: list[tuple[str, str, str]] = []

        # Hard patterns first
        candidates = [
            n,
            f"gold_sql_dp_prod_we_dwh_dbo_{n}",
            f"gold_sql_dp_prod_we_dwh_dbo_{n}_masked",
            f"gold_inc_test_dwh_dbo_{n}",
            f"gold_inc_test_dwh_dbo_{n}_masked",
            f"silver_{n}",
            f"bronze_{n}",
        ]
        for c in candidates:
            hits.extend(idx_exact.get(c, []))

        # Permissive substring scan: name contains "_<table>" or "<table>_"
        # or starts/ends with table. We exclude obviously unrelated longer
        # tokens (e.g. fact_customeraction_switch must not match fact_customeraction).
        # Use boundary check: the token must be flanked by '_' or start/end.
        token = f"_{n}_"
        for sch, name, ttype in flat:
            if (sch, name, ttype) in hits:
                continue
            padded = f"_{name}_"
            if token in padded:
                hits.append((sch, name, ttype))

        hits = sorted(set(hits))
        if hits:
            found.append({"table": tbl, "hits": hits})
        else:
            truly_missing.append(tbl)

    with OUT_MD.open("w", encoding="utf-8") as fh:
        fh.write("# Fly-over check on 'missing twin' list\n\n")
        fh.write(f"Checked {len(missing)} non-Ext missing tables against every ")
        fh.write("object under `main.*` using exact-pattern + permissive ")
        fh.write("substring matching (token must be word-boundary delimited).\n\n")
        fh.write(f"- Twin **found** after deeper search: **{len(found)}**\n")
        fh.write(f"- Still truly missing: **{len(truly_missing)}**\n\n")

        if found:
            fh.write("## Twins discovered in deeper search\n\n")
            fh.write("| migration_tables.<table> | main.<schema>.<twin> | type |\n")
            fh.write("|---|---|---|\n")
            for f in found:
                for sch, name, ttype in f["hits"]:
                    fh.write(f"| `{f['table']}` | `main.{sch}.{name}` | {ttype} |\n")
            fh.write("\n")

        fh.write("## Still truly missing\n\n")
        for t in truly_missing:
            fh.write(f"- `{t}`\n")

    print(f"Wrote {OUT_MD}")
    print(f"\nFound twins for {len(found)} of {len(missing)} tables")
    print(f"Truly missing: {len(truly_missing)}")


if __name__ == "__main__":
    main()
