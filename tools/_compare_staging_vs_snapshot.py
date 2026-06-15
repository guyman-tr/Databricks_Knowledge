#!/usr/bin/env python3
"""
Side-by-side audit of Synapse DWH_staging.* vs DBX dwh_daily_process.daily_snapshot.*
For each table pair: row count and freshness (MAX of best-guess update column).

Auth:
  Synapse: SQL auth from C:\\Users\\guyman\\.cursor\\synapse-credentials.env
  DBX:     Databricks SDK with DEFAULT profile (azure-cli backed, already cached)

Output: tools/_staging_vs_snapshot_diff.csv
"""
from __future__ import annotations

import csv
import os
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO))


# Load synapse SQL credentials FIRST so synapse_connect picks them up
def load_synapse_creds() -> None:
    env_file = Path(r"C:\Users\guyman\.cursor\synapse-credentials.env")
    if not env_file.exists():
        print(f"[warn] synapse credentials file not found: {env_file}", file=sys.stderr)
        return
    for line in env_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        k, v = k.strip(), v.strip()
        if k in ("SYNAPSE_SQL_USER", "SYNAPSE_SQL_PASS", "SYNAPSE_SQL_PASSWORD"):
            os.environ.setdefault(k, v)
    # synapse_connect expects SYNAPSE_SQL_PASSWORD
    if "SYNAPSE_SQL_PASSWORD" not in os.environ and "SYNAPSE_SQL_PASS" in os.environ:
        os.environ["SYNAPSE_SQL_PASSWORD"] = os.environ["SYNAPSE_SQL_PASS"]


load_synapse_creds()
os.environ["SYNAPSE_SERVER"] = "prod-synapse-dataplatform-we.sql.azuresynapse.net"
os.environ["SYNAPSE_DATABASE"] = "sql_dp_prod_we"

import synapse_connect  # noqa: E402

synapse_connect.QUERY_TIMEOUT = 1200

from databricks.sdk import WorkspaceClient  # noqa: E402
from databricks.sdk.service.sql import StatementState  # noqa: E402


WAREHOUSE_ID = os.environ.get("DATABRICKS_WAREHOUSE_ID", "208214768b0e0308")
DBX_PROFILE = os.environ.get("DATABRICKS_MCP_PROFILE", "DEFAULT")
SYN_SCHEMA = "DWH_staging"
DBX_SCHEMA = "dwh_daily_process.daily_snapshot"
OUT_CSV = REPO / "tools" / "_staging_vs_snapshot_diff.csv"


# Common update-column candidates, in priority order
UPDATE_COL_CANDIDATES = [
    "UpdateDate",
    "Updated",
    "LastUpdateDate",
    "ModifiedDate",
    "ModifiedAt",
    "CreatedAt",
    "Created",
    "BatchTimestamp",
    "ValidFrom",
    "DateAdded",
    "Occurred",
    "Ocurred",
    "ProcessDate",
    "TxStatusModificationTime",
]


def dbx_run(w: WorkspaceClient, sql: str, wait="50s", poll=600) -> tuple[list[str], list[list]]:
    resp = w.statement_execution.execute_statement(
        warehouse_id=WAREHOUSE_ID, statement=sql, wait_timeout=wait
    )
    sid = resp.statement_id
    state = resp.status.state
    deadline = time.time() + poll
    while state in (StatementState.PENDING, StatementState.RUNNING) and time.time() < deadline:
        time.sleep(2.0)
        resp = w.statement_execution.get_statement(sid)
        state = resp.status.state
    if state != StatementState.SUCCEEDED:
        err = resp.status.error
        raise RuntimeError(f"DBX SQL failed: {state} {err.message if err else ''}")
    if resp.result is None or resp.manifest is None:
        return [], []
    cols = [c.name for c in resp.manifest.schema.columns]
    rows = resp.result.data_array or []
    return cols, rows


def get_table_lists(w: WorkspaceClient, syn_conn):
    print("[info] listing DBX daily_snapshot tables...", file=sys.stderr)
    _, dbx_rows = dbx_run(
        w,
        f"SELECT table_name FROM dwh_daily_process.information_schema.tables "
        f"WHERE table_schema='daily_snapshot' AND table_type IN ('MANAGED','EXTERNAL') ORDER BY table_name",
    )
    dbx_tables = [r[0] for r in dbx_rows]

    print("[info] listing Synapse DWH_staging tables...", file=sys.stderr)
    _, syn_rows = synapse_connect.run_query(
        syn_conn,
        "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES "
        f"WHERE TABLE_SCHEMA='{SYN_SCHEMA}' AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME",
    )
    syn_tables = [r[0] for r in syn_rows]
    return dbx_tables, syn_tables


def syn_columns(syn_conn, table: str) -> set[str]:
    _, rows = synapse_connect.run_query(
        syn_conn,
        "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS "
        f"WHERE TABLE_SCHEMA='{SYN_SCHEMA}' AND TABLE_NAME='{table}'",
    )
    return {r[0] for r in rows}


def dbx_columns(w: WorkspaceClient, table: str) -> set[str]:
    _, rows = dbx_run(
        w,
        "SELECT column_name FROM dwh_daily_process.information_schema.columns "
        f"WHERE table_schema='daily_snapshot' AND table_name='{table}'",
    )
    return {r[0].lower() for r in rows}


def pick_update_col(cols_lower: set[str]) -> str | None:
    for cand in UPDATE_COL_CANDIDATES:
        if cand.lower() in cols_lower:
            return cand
    return None


def syn_metrics(syn_conn, table: str, update_col: str | None):
    sql = f"SELECT COUNT_BIG(*) AS row_cnt"
    if update_col:
        sql += f", CAST(MAX([{update_col}]) AS VARCHAR(40)) AS max_update"
    else:
        sql += ", CAST(NULL AS VARCHAR(40)) AS max_update"
    sql += f" FROM {SYN_SCHEMA}.[{table}]"
    try:
        _, rows = synapse_connect.run_query(syn_conn, sql)
        if rows:
            return int(rows[0][0]), rows[0][1]
    except Exception as e:  # noqa: BLE001
        return None, f"ERR:{e.__class__.__name__}"
    return None, None


def dbx_metrics(w: WorkspaceClient, table_lower: str, update_col: str | None):
    parts = [f"COUNT(*) AS row_cnt"]
    if update_col:
        parts.append(f"CAST(MAX(`{update_col}`) AS STRING) AS max_update")
    else:
        parts.append("CAST(NULL AS STRING) AS max_update")
    sql = f"SELECT {', '.join(parts)} FROM {DBX_SCHEMA}.`{table_lower}`"
    try:
        _, rows = dbx_run(w, sql)
        if rows:
            return int(rows[0][0]), rows[0][1]
    except Exception as e:  # noqa: BLE001
        return None, f"ERR:{e.__class__.__name__}"
    return None, None


def main():
    w = WorkspaceClient(profile=DBX_PROFILE)
    syn_conn = synapse_connect.connect()

    dbx_tables, syn_tables = get_table_lists(w, syn_conn)
    print(f"[info] dbx={len(dbx_tables)} syn={len(syn_tables)}", file=sys.stderr)

    dbx_lower_to_original = {t.lower(): t for t in dbx_tables}
    syn_lower_to_original = {t.lower(): t for t in syn_tables}
    all_keys = sorted(set(dbx_lower_to_original) | set(syn_lower_to_original))

    results = []
    for i, key in enumerate(all_keys, 1):
        syn_name = syn_lower_to_original.get(key)
        dbx_name = dbx_lower_to_original.get(key)
        print(f"[{i:3d}/{len(all_keys)}] {key}", file=sys.stderr)

        syn_cnt = syn_max = dbx_cnt = dbx_max = None
        update_col = None

        if syn_name:
            cols = syn_columns(syn_conn, syn_name)
            update_col = pick_update_col({c.lower() for c in cols})
            syn_cnt, syn_max = syn_metrics(syn_conn, syn_name, update_col)
        if dbx_name:
            if update_col is None:
                cols = dbx_columns(w, dbx_name)
                update_col = pick_update_col(cols)
            dbx_cnt, dbx_max = dbx_metrics(w, dbx_name, update_col)

        delta = None
        ratio = None
        if syn_cnt is not None and dbx_cnt is not None:
            delta = dbx_cnt - syn_cnt
            if syn_cnt:
                ratio = dbx_cnt / syn_cnt
        verdict = "MATCH"
        if syn_cnt is None and dbx_cnt is None:
            verdict = "BOTH_NULL"
        elif syn_cnt is None:
            verdict = "SYN_ONLY_MISSING"
        elif dbx_cnt is None:
            verdict = "DBX_ONLY_MISSING"
        elif syn_cnt == dbx_cnt:
            verdict = "MATCH"
        elif ratio is not None and 0.99 <= ratio <= 1.01:
            verdict = "NEAR_MATCH"
        elif ratio is not None and ratio < 0.5:
            verdict = "DBX_SHORT"
        elif ratio is not None and ratio > 2:
            verdict = "DBX_OVER"
        else:
            verdict = "DRIFT"

        results.append(
            {
                "key": key,
                "syn_name": syn_name or "",
                "dbx_name": dbx_name or "",
                "syn_rows": syn_cnt if syn_cnt is not None else "",
                "dbx_rows": dbx_cnt if dbx_cnt is not None else "",
                "delta": delta if delta is not None else "",
                "ratio": f"{ratio:.4f}" if ratio is not None else "",
                "update_col": update_col or "",
                "syn_max_update": syn_max or "",
                "dbx_max_update": dbx_max or "",
                "verdict": verdict,
            }
        )

    OUT_CSV.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=list(results[0].keys()))
        writer.writeheader()
        writer.writerows(results)
    print(f"[done] wrote {OUT_CSV}", file=sys.stderr)

    # Print quick summary to stdout
    by_verdict: dict[str, int] = {}
    for r in results:
        by_verdict[r["verdict"]] = by_verdict.get(r["verdict"], 0) + 1
    print("\n=== summary ===")
    for v, n in sorted(by_verdict.items(), key=lambda x: -x[1]):
        print(f"  {v:20s} {n:4d}")

    print("\n=== non-match details ===")
    for r in results:
        if r["verdict"] not in ("MATCH", "NEAR_MATCH", "BOTH_NULL"):
            print(
                f"  {r['verdict']:18s} {r['key']:60s} "
                f"syn={r['syn_rows']:>12} dbx={r['dbx_rows']:>12} "
                f"d={r['delta']:>12} r={r['ratio']:>6} "
                f"syn_max={r['syn_max_update']} dbx_max={r['dbx_max_update']}"
            )


if __name__ == "__main__":
    main()
