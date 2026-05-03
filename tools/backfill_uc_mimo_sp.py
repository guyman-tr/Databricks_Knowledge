#!/usr/bin/env python3
"""
Backfill main.de_output.de_output_ddr_fact_mimo_allplatforms by re-calling the
incremental SP for every DateID in [START, END] inclusive.

Usage:
  python tools/backfill_uc_mimo_sp.py 20260324 20260502
"""
from __future__ import annotations

import os
import sys
import time
from datetime import date, timedelta

from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState

PROFILE = (
    os.environ.get("DATABRICKS_MCP_PROFILE")
    or os.environ.get("DATABRICKS_CONFIG_PROFILE")
    or "guyman"
)
WAREHOUSE = "208214768b0e0308"
TARGET = "main.de_output.de_output_ddr_fact_mimo_allplatforms"
SP = "main.de_output.sp_ddr_fact_mimo_allplatforms"


def parse_dateid(s: str) -> date:
    return date(int(s[:4]), int(s[4:6]), int(s[6:8]))


def daterange(start: date, end: date):
    d = start
    while d <= end:
        yield d
        d += timedelta(days=1)


def run_one(w: WorkspaceClient, dateid: str, attempt: int = 1) -> tuple[str, float]:
    sql = (
        f"CALL {SP}(target_table => '{TARGET}', p_date => '{dateid}')"
    )
    t0 = time.time()
    resp = w.statement_execution.execute_statement(
        warehouse_id=WAREHOUSE, statement=sql, wait_timeout="50s"
    )
    sid = resp.statement_id
    deadline = time.time() + 600
    while resp.status.state in (StatementState.PENDING, StatementState.RUNNING):
        if time.time() > deadline:
            raise TimeoutError(f"{dateid} did not finish in 10 min")
        time.sleep(2)
        resp = w.statement_execution.get_statement(sid)
    elapsed = time.time() - t0
    if resp.status.state == StatementState.SUCCEEDED:
        return "OK", elapsed
    err = resp.status.error.message if resp.status.error else str(resp.status.state)
    if attempt < 3 and ("DELTA_METADATA_CHANGED" in err or "ConcurrentAppend" in err):
        time.sleep(5)
        return run_one(w, dateid, attempt + 1)
    return f"FAIL: {err[:200]}", elapsed


def main():
    if len(sys.argv) != 3:
        print("Usage: python tools/backfill_uc_mimo_sp.py YYYYMMDD YYYYMMDD", file=sys.stderr)
        sys.exit(2)
    start = parse_dateid(sys.argv[1])
    end = parse_dateid(sys.argv[2])
    days = list(daterange(start, end))
    print(f"[backfill] profile={PROFILE} warehouse={WAREHOUSE}", file=sys.stderr, flush=True)
    print(f"[backfill] {len(days)} dates from {sys.argv[1]} to {sys.argv[2]}", file=sys.stderr, flush=True)

    w = WorkspaceClient(profile=PROFILE)
    ok = fail = 0
    t_total = time.time()
    for i, d in enumerate(days, 1):
        did = d.strftime("%Y%m%d")
        status, elapsed = run_one(w, did)
        if status == "OK":
            ok += 1
        else:
            fail += 1
        print(f"[{i:>3}/{len(days)}] {did}  {elapsed:5.1f}s  {status}", flush=True)
    dur = time.time() - t_total
    print(f"\n[done] ok={ok} fail={fail} total={dur:.1f}s", flush=True)


if __name__ == "__main__":
    sys.stdout.reconfigure(line_buffering=True)
    main()
