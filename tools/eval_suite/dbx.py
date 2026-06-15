"""Shared Databricks SQL helper for eval_suite.

Mirrors `tools/dbx_query.py` so we use the SAME auth path as the Cursor MCP
(WorkspaceClient + Statement Execution API + ~/.databrickscfg). Avoids
opening a second connection model (and another auth popup).
"""
from __future__ import annotations

import os
import re
import time
from dataclasses import dataclass

try:
    from databricks.sdk import WorkspaceClient
    from databricks.sdk.service.sql import StatementState
except ImportError as e:  # pragma: no cover
    raise SystemExit("ERROR: pip install databricks-sdk") from e


DEFAULT_WAREHOUSE_ID = "208214768b0e0308"


@dataclass
class QueryResult:
    columns: list[str]
    rows: list[list]


def warehouse_id_from_env() -> str:
    path = os.environ.get("DATABRICKS_HTTP_PATH", "")
    m = re.search(r"/warehouses/([a-f0-9]+)", path, re.I)
    if m:
        return m.group(1)
    wid = (os.environ.get("DATABRICKS_WAREHOUSE_ID") or "").strip()
    return wid or DEFAULT_WAREHOUSE_ID


def profile_from_env() -> str:
    return (
        (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
        or (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
        or "DEFAULT"
    )


def make_client(profile: str | None = None) -> WorkspaceClient:
    return WorkspaceClient(profile=profile or profile_from_env())


def run_sql(
    w: WorkspaceClient,
    sql_text: str,
    *,
    warehouse_id: str | None = None,
    wait_timeout: str = "50s",
    poll_deadline_sec: float = 600.0,
) -> QueryResult:
    wid = warehouse_id or warehouse_id_from_env()
    resp = w.statement_execution.execute_statement(
        warehouse_id=wid,
        statement=sql_text,
        wait_timeout=wait_timeout,
    )
    sid = resp.statement_id
    state = resp.status.state
    if state in (StatementState.PENDING, StatementState.RUNNING):
        deadline = time.time() + poll_deadline_sec
        while time.time() < deadline:
            resp = w.statement_execution.get_statement(sid)
            state = resp.status.state
            if state in (
                StatementState.SUCCEEDED,
                StatementState.FAILED,
                StatementState.CANCELED,
                StatementState.CLOSED,
            ):
                break
            time.sleep(2.0)
        else:
            raise TimeoutError(f"statement {sid} did not finish in {poll_deadline_sec}s")
    if state == StatementState.SUCCEEDED:
        if resp.result is None or resp.manifest is None:
            return QueryResult([], [])
        cols = [c.name for c in resp.manifest.schema.columns]
        data = resp.result.data_array or []
        return QueryResult(cols, data)
    if state == StatementState.FAILED:
        err = resp.status.error
        msg = err.message if err else "unknown"
        raise RuntimeError(f"SQL FAILED: {msg}")
    raise RuntimeError(f"unexpected state: {state}")
