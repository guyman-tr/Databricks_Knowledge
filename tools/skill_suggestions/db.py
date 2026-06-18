"""Databricks SQL helpers for skill suggestion queue tools."""
from __future__ import annotations

import os
import re
import time
from typing import Any

from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState


DEFAULT_WAREHOUSE_ID = "208214768b0e0308"


def profile_from_env() -> str:
    return (
        (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
        or (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
        or "DEFAULT"
    )


def warehouse_id_from_env() -> str:
    path = os.environ.get("DATABRICKS_HTTP_PATH", "")
    m = re.search(r"/warehouses/([a-f0-9]+)", path, re.I)
    if m:
        return m.group(1)
    wid = (os.environ.get("DATABRICKS_WAREHOUSE_ID") or "").strip()
    return wid or DEFAULT_WAREHOUSE_ID


def make_workspace_client(profile: str | None = None) -> WorkspaceClient:
    return WorkspaceClient(profile=profile or profile_from_env())


def execute_sql(
    w: WorkspaceClient,
    *,
    sql_text: str,
    warehouse_id: str | None = None,
    wait_timeout: str = "50s",
    poll_deadline_sec: float = 600.0,
) -> tuple[list[str], list[list[Any]]]:
    wid = warehouse_id or warehouse_id_from_env()
    resp = w.statement_execution.execute_statement(
        warehouse_id=wid,
        statement=sql_text,
        wait_timeout=wait_timeout,
    )

    state = resp.status.state
    sid = resp.statement_id
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

    if state != StatementState.SUCCEEDED:
        err = getattr(resp.status, "error", None)
        msg = err.message if err else f"state={state}"
        raise RuntimeError(f"Databricks SQL failed: {msg}")

    if not resp.manifest or not resp.result:
        return [], []

    cols = [c.name for c in resp.manifest.schema.columns]
    rows = resp.result.data_array or []
    return cols, rows
