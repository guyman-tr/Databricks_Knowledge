"""Fill in missing freshness rows by running per-table MAX(UpdateDate) queries.

Reads:
  - audits/blacklist/_keep_universe_2026-05-31.csv          (570 unique targets)
  - audits/blacklist/_a3_work/freshness_results.csv         (already-probed)

For every (TableSchema, BareTable) in keep_universe.BI_DB_dbo /
keep_universe.Dealing_dbo that is NOT yet in freshness_results, runs
    SELECT MAX([UpdateDate]) FROM [<schema>].[<table>]
and appends a row. Tables that fail (no column / table missing) get an
empty max_update so the aggregator marks them A3_NO_DATA.

Run after run_freshness_probes.py.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

sys.stdout.reconfigure(line_buffering=True)

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

import synapse_connect as sc  # noqa: E402
from synapse_connect import run_query  # noqa: E402

sc.SERVER   = "prod-synapse-dataplatform-we.sql.azuresynapse.net"
sc.DATABASE = "sql_dp_prod_we"

KEEP_CSV  = REPO_ROOT / "audits" / "blacklist" / "_keep_universe_2026-05-31.csv"
FRESH_CSV = REPO_ROOT / "audits" / "blacklist" / "_a3_work" / "freshness_results.csv"


def main() -> int:
    have: set[tuple[str, str]] = set()
    if FRESH_CSV.exists():
        with FRESH_CSV.open("r", encoding="utf-8-sig") as f:
            for row in csv.DictReader(f):
                have.add((row["schema"], row["table_name"]))
    print(f"[fill] already have {len(have)} freshness rows", flush=True)

    targets: list[tuple[str, str]] = []
    seen: set[tuple[str, str]] = set()
    with KEEP_CSV.open("r", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            schema = row["TableSchema"].strip()
            table  = row["BareTable"].strip()
            if schema not in {"BI_DB_dbo", "Dealing_dbo", "Dealing_staging"}:
                continue
            key = (schema, table)
            if key in seen:
                continue
            seen.add(key)
            if key not in have:
                targets.append(key)

    print(f"[fill] {len(targets)} tables need a single-table probe", flush=True)
    if not targets:
        return 0

    print("[fill] connecting to PROD synapse ...", flush=True)
    conn = sc.connect()
    print("[fill] connected", flush=True)

    appended = 0
    no_col   = 0
    no_table = 0
    other    = 0
    new_rows: list[tuple[str, str, str]] = []

    for i, (schema, table) in enumerate(targets, 1):
        sql = (
            "SELECT '" + schema + "' AS schema_name, "
            "'" + table.replace("'", "''") + "' AS table_name, "
            "CONVERT(varchar(20), MAX([UpdateDate]), 120) AS max_update "
            "FROM [" + schema + "].[" + table + "]"
        )
        try:
            cols, rows = run_query(conn, sql)
            mx = ""
            if rows:
                mx = rows[0][2] if rows[0][2] is not None else ""
            new_rows.append((schema, table, mx))
            appended += 1
            print(f"[fill] [{i:3d}/{len(targets)}] OK  {schema}.{table} -> {mx or '(empty)'}", flush=True)
        except Exception as e:
            msg = str(e).splitlines()[0][:200]
            if "Invalid column name" in msg:
                no_col += 1
            elif "Invalid object name" in msg:
                no_table += 1
            else:
                other += 1
            new_rows.append((schema, table, ""))
            print(f"[fill] [{i:3d}/{len(targets)}] FAIL {schema}.{table} -> {msg[:120]}", flush=True)

    # Append to freshness_results.csv (preserve existing order, just append).
    with FRESH_CSV.open("a", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        for r in new_rows:
            w.writerow(r)

    print("", flush=True)
    print(f"[fill] appended {len(new_rows)} rows ({appended} OK, "
          f"{no_col} no UpdateDate col, {no_table} table missing, {other} other)",
          flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
