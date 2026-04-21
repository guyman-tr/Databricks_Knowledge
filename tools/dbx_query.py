#!/usr/bin/env python3
"""
Run SQL on Databricks using the SAME auth stack as the Cursor MCP server:
  WorkspaceClient(profile from env) + Statement Execution API + ~/.databrickscfg

Use this when MCP is red, returns "tool not found", or async results never poll back.

Usage:
  python tools/dbx_query.py "SELECT 1"
  python tools/dbx_query.py --file query.sql
  set DATABRICKS_MCP_PROFILE=guyman
  python tools/dbx_query.py "SELECT COUNT(*) FROM main.etoro_kpi_prep_stg.v_ddr_mimo_tradingplatform WHERE DateID = 20250101"

Prereq:
  pip install databricks-sdk

Re-auth (no PAT required — same as MCP):
  databricks auth login --host https://<workspace-host> --profile <name>
"""
from __future__ import annotations

import argparse
import os
import re
import sys
import time

try:
    from databricks.sdk import WorkspaceClient
    from databricks.sdk.service.sql import StatementState
except ImportError:
    print("Install: pip install databricks-sdk", file=sys.stderr)
    sys.exit(1)


def warehouse_id_from_env() -> str:
    path = os.environ.get("DATABRICKS_HTTP_PATH", "")
    m = re.search(r"/warehouses/([a-f0-9]+)", path, re.I)
    if m:
        return m.group(1)
    wid = (os.environ.get("DATABRICKS_WAREHOUSE_ID") or "").strip()
    if wid:
        return wid
    return "208214768b0e0308"


def profile_from_env() -> str:
    return (
        (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
        or (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
        or "DEFAULT"
    )


def rows_from_statement_response(response) -> tuple[list[str], list[list]]:
    if response.result is None or response.manifest is None:
        return [], []
    cols = [c.name for c in response.manifest.schema.columns]
    data = response.result.data_array or []
    return cols, data


def wait_for_statement(w: WorkspaceClient, statement_id: str, deadline: float) -> object:
    """Poll until terminal state or deadline."""
    while time.time() < deadline:
        st = w.statement_execution.get_statement(statement_id)
        state = st.status.state
        if state in (
            StatementState.SUCCEEDED,
            StatementState.FAILED,
            StatementState.CANCELED,
            StatementState.CLOSED,
        ):
            return st
        time.sleep(2.0)
    raise TimeoutError(f"Statement {statement_id} did not finish before timeout.")


def run_sql(
    w: WorkspaceClient,
    warehouse_id: str,
    sql_text: str,
    wait_timeout: str,
    poll_deadline_sec: float,
) -> tuple[list[str], list[list]]:
    resp = w.statement_execution.execute_statement(
        warehouse_id=warehouse_id,
        statement=sql_text,
        wait_timeout=wait_timeout,
    )
    sid = resp.statement_id
    state = resp.status.state

    if state in (StatementState.PENDING, StatementState.RUNNING):
        resp = wait_for_statement(w, sid, time.time() + poll_deadline_sec)
        state = resp.status.state

    if state == StatementState.SUCCEEDED:
        return rows_from_statement_response(resp)

    if state == StatementState.FAILED:
        err = resp.status.error
        msg = err.message if err else "unknown"
        raise RuntimeError(f"SQL FAILED: {msg}")

    raise RuntimeError(f"Unexpected statement state: {state}")


def print_table(cols: list[str], rows: list[list], max_rows: int) -> None:
    if not cols:
        print("(no columns returned)")
        return
    trunc = rows[:max_rows]
    # simple fixed: tab-separated header + rows
    print("\t".join(cols))
    for r in trunc:
        print("\t".join("" if v is None else str(v) for v in r))
    if len(rows) > max_rows:
        print(f"... ({len(rows) - max_rows} more rows not shown)", file=sys.stderr)


def main() -> None:
    ap = argparse.ArgumentParser(description="Databricks SQL via SDK (same auth as MCP)")
    ap.add_argument("sql", nargs="?", help="SQL string")
    ap.add_argument("--file", "-f", help="Read SQL from file")
    ap.add_argument(
        "--profile",
        "-p",
        default=None,
        help="Config profile (~/.databrickscfg). Default: DATABRICKS_MCP_PROFILE or guyman",
    )
    ap.add_argument(
        "--warehouse-id",
        "-w",
        default=None,
        help="SQL warehouse ID. Default: from DATABRICKS_HTTP_PATH or built-in",
    )
    ap.add_argument(
        "--wait",
        default="50s",
        help="Initial wait_timeout for execute_statement (default 50s, API max)",
    )
    ap.add_argument(
        "--poll-sec",
        type=float,
        default=600.0,
        help="Extra polling budget if still RUNNING after initial wait (default 600)",
    )
    ap.add_argument("--max-rows", type=int, default=500, help="Max rows to print")
    args = ap.parse_args()

    if args.file:
        sql_text = open(args.file, encoding="utf-8").read()
    elif args.sql:
        sql_text = args.sql
    else:
        ap.print_help()
        sys.exit(2)

    profile = args.profile or profile_from_env()
    warehouse_id = args.warehouse_id or warehouse_id_from_env()

    print(f"Profile: {profile}  Warehouse: {warehouse_id}", file=sys.stderr)

    w = WorkspaceClient(profile=profile)

    cols, rows = run_sql(
        w,
        warehouse_id,
        sql_text.strip(),
        wait_timeout=args.wait,
        poll_deadline_sec=args.poll_sec,
    )
    print_table(cols, rows, args.max_rows)
    print(f"{len(rows)} row(s)", file=sys.stderr)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
