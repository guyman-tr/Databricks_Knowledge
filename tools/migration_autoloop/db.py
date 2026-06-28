"""Databricks SQL helpers for migration autoloop."""
from __future__ import annotations

import configparser
import os
import re
import time
from typing import Any

from databricks.sdk import WorkspaceClient
from databricks.sdk.service.sql import StatementState

DEFAULT_WAREHOUSE_ID = "208214768b0e0308"


def profile_from_env() -> str:
    explicit_mcp = (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
    explicit_cfg = (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
    if explicit_mcp:
        return explicit_mcp
    # Honour explicit env var before any hard-coded preference.
    if explicit_cfg and explicit_cfg not in ("name-of-profile", ""):
        return explicit_cfg

    cfg = os.path.join(os.path.expanduser("~"), ".databrickscfg")
    parser = configparser.ConfigParser()
    if os.path.exists(cfg):
        parser.read(cfg, encoding="utf-8")
        if "guyman" in parser.sections():
            return "guyman"
        if "DEFAULT" in parser.sections():
            return "DEFAULT"
    return "DEFAULT"


def warehouse_id_from_env() -> str:
    path = os.environ.get("DATABRICKS_HTTP_PATH", "")
    match = re.search(r"/warehouses/([a-f0-9]+)", path, re.I)
    if match:
        return match.group(1)
    wid = (os.environ.get("DATABRICKS_WAREHOUSE_ID") or "").strip()
    return wid or DEFAULT_WAREHOUSE_ID


def make_workspace_client(profile: str | None = None) -> WorkspaceClient:
    if profile is None:
        cfg_path = os.path.join(os.path.expanduser("~"), ".databrickscfg")
        if os.path.exists(cfg_path):
            # Local dev: use profile from env / config file
            profile = profile_from_env()
        else:
            # Databricks cluster: no config file — let SDK auto-detect from env vars
            # (DATABRICKS_HOST + DATABRICKS_TOKEN are set by the cluster runtime)
            profile = None
    return WorkspaceClient(profile=profile)


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
        message = err.message if err else f"state={state}"
        raise RuntimeError(f"Databricks SQL failed: {message}")

    if not resp.manifest or not resp.result:
        return [], []
    cols = [c.name for c in resp.manifest.schema.columns]
    rows = resp.result.data_array or []
    return cols, rows

