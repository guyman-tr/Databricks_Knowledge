"""Direct-SQL SUT: executes the case's `uc_equivalent.sql` and returns the
scalar result.

Purpose: pipeline / data-freshness control group.
- Mock SUT proves the harness loop works.
- Direct-SQL SUT proves the UC data pipeline still produces the pinned answer
  today. If a case passes here today but failed yesterday, the upstream UC
  pipeline drifted (ETL freshness or backfill rewrote history) — that is a
  data signal, NOT a skill-coverage signal.

Auth: uses `databricks-sdk` WorkspaceClient. In Cursor, this picks up
`~/.databrickscfg`. Inside a Databricks notebook, it picks up the runtime
identity automatically. Same code path either way.
"""
from __future__ import annotations

import os
import re
import time

from ..schema import CaseV1
from .base import SUT, SUTResponse


class DirectSQLSUT(SUT):
    name = "direct_sql"

    def __init__(
        self,
        *,
        warehouse_id: str | None = None,
        profile: str | None = None,
        spark_session=None,
    ):
        """Construct.

        Args:
            warehouse_id: SQL warehouse to use when running outside a notebook.
                If None, falls back to `DATABRICKS_HTTP_PATH` -> `DATABRICKS_WAREHOUSE_ID`
                -> the team-default `208214768b0e0308`.
            profile: `~/.databrickscfg` profile when not in a notebook. Defaults
                to `DATABRICKS_CONFIG_PROFILE` env or `DEFAULT`.
            spark_session: If provided, use spark.sql() instead of the SDK.
                The notebook will pass `spark` here; the CLI leaves it None.
        """
        self.spark = spark_session
        if self.spark is None:
            self.warehouse_id = warehouse_id or self._resolve_warehouse_id()
            self.profile = profile or self._resolve_profile()
            self._client = None  # lazy

    @staticmethod
    def _resolve_warehouse_id() -> str:
        path = os.environ.get("DATABRICKS_HTTP_PATH", "")
        m = re.search(r"/warehouses/([a-f0-9]+)", path, re.I)
        if m:
            return m.group(1)
        wid = (os.environ.get("DATABRICKS_WAREHOUSE_ID") or "").strip()
        return wid or "208214768b0e0308"

    @staticmethod
    def _resolve_profile() -> str:
        return (
            (os.environ.get("DATABRICKS_MCP_PROFILE") or "").strip()
            or (os.environ.get("DATABRICKS_CONFIG_PROFILE") or "").strip()
            or "DEFAULT"
        )

    def _get_sdk_client(self):
        if self._client is None:
            from databricks.sdk import WorkspaceClient
            self._client = WorkspaceClient(profile=self.profile)
        return self._client

    def _run_sql_via_sdk(self, sql: str) -> tuple[list[str], list[list]]:
        from databricks.sdk.service.sql import StatementState
        w = self._get_sdk_client()
        resp = w.statement_execution.execute_statement(
            warehouse_id=self.warehouse_id,
            statement=sql,
            wait_timeout="50s",
        )
        sid = resp.statement_id
        state = resp.status.state
        if state in (StatementState.PENDING, StatementState.RUNNING):
            deadline = time.time() + 600.0
            while time.time() < deadline:
                resp = w.statement_execution.get_statement(sid)
                state = resp.status.state
                if state in (
                    StatementState.SUCCEEDED, StatementState.FAILED,
                    StatementState.CANCELED, StatementState.CLOSED,
                ):
                    break
                time.sleep(2.0)
        if state != StatementState.SUCCEEDED:
            err = (resp.status.error.message if resp.status.error else "unknown")
            raise RuntimeError(f"SQL FAILED ({state}): {err}")
        if resp.result is None or resp.manifest is None:
            return [], []
        cols = [c.name for c in resp.manifest.schema.columns]
        return cols, (resp.result.data_array or [])

    def _run_sql(self, sql: str) -> tuple[list[str], list[list]]:
        if self.spark is not None:
            df = self.spark.sql(sql)
            cols = df.columns
            data = [list(r) for r in df.collect()]
            return cols, data
        return self._run_sql_via_sdk(sql)

    def ask(self, question: str, case: CaseV1) -> SUTResponse:
        t0 = time.time()
        sql = case.uc_equivalent.sql
        try:
            cols, rows = self._run_sql(sql)
            if not rows:
                return SUTResponse(
                    numeric_answer=None,
                    text_answer="(no rows returned)",
                    sql_used=sql,
                    raw={"backend": "direct_sql", "cols": cols, "rows": rows},
                    error="no rows",
                    elapsed_ms=int((time.time() - t0) * 1000),
                )
            v = rows[0][0]
            v_f = float(v) if v is not None else None
            return SUTResponse(
                numeric_answer=v_f,
                text_answer=f"The query returned {v_f:,.4f}." if v_f is not None else "(NULL)",
                sql_used=sql,
                raw={"backend": "direct_sql", "cols": cols, "rows": rows},
                elapsed_ms=int((time.time() - t0) * 1000),
            )
        except Exception as e:
            return SUTResponse(
                numeric_answer=None,
                text_answer=None,
                sql_used=sql,
                raw={"backend": "direct_sql"},
                error=str(e),
                elapsed_ms=int((time.time() - t0) * 1000),
            )
