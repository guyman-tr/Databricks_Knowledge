"""Telemetry sink — writes CaseResult rows to either a local CSV (Cursor /
local dev) or a UC Delta table (notebook).

Design: one schema, two implementations. The runner doesn't care which sink
is in use, and the schema we write here is the same schema we'll persist to
`main.bi_eval.eval_runs` in production.

CSV path is the default in Cursor; pass `target='delta'` from a notebook.
"""
from __future__ import annotations

import csv
import json
import os
from dataclasses import asdict
from typing import Any

from .runner import CaseResult


# The columns are pinned here so CSV and Delta agree. Bumping the schema
# is a deliberate decision (add a `schema_version` column if/when needed).
_COLUMNS = [
    "run_id",
    "run_started_at",
    "host",
    "case_id",
    "case_status",
    "sut_name",
    "asof",
    "natural_language_question",
    "expected_value",
    "observed_value",
    "diff_abs",
    "diff_pct",
    "tolerance_pct",
    "passed",
    "reason",
    "sql_used",
    "sut_text_answer",
    "sut_error",
    "elapsed_ms",
    "tags",                # JSON-encoded list[str] in CSV; ARRAY<STRING> in Delta
    "baseline_sut_name",
    "baseline_value",
    "baseline_diff_pct",
    "baseline_passed",
    "drift_verdict",       # PASS | SKILL_GAP | DATA_DRIFT | BASELINE_BROKEN | N/A
    "judge_score",         # 0.0..1.0; NULL if no judge ran
    "judge_label",         # 'correct' | 'partial' | 'incorrect' | 'unparseable' | NULL
    "judge_rationale",     # short text from the judge model
    "judge_model",         # e.g. 'claude-sonnet-4'
    # Trace-derived telemetry (cursor_agent stream-json). NULL for SUTs without traces.
    "trace_skills_loaded",          # JSON list[{method, slug}]
    "trace_sql_executed_count",     # total SQL execs the agent attempted
    "trace_sql_succeeded_count",    # of those, how many succeeded
    "trace_tool_call_count",
    "trace_tool_call_by_kind",      # JSON {readToolCall: N, shellToolCall: M, mcpToolCall: K, ...}
    "trace_mcp_tool_call_by_name",  # JSON {databricks_sql_execute_*: N, skills_get_skill: M, ...}
    "trace_input_tokens",
    "trace_output_tokens",
    "trace_cache_read_tokens",
    "trace_cache_write_tokens",
    "trace_thinking_excerpt",       # tail of the model's thinking trace (last ~1500 chars)
    "trace_session_id",
    "trace_model",
]


def _row_for_csv(r: CaseResult) -> dict[str, Any]:
    d = asdict(r)
    d["tags"] = json.dumps(d.get("tags") or [])
    return {k: d.get(k) for k in _COLUMNS}


def write_telemetry_csv(results: list[CaseResult], out_path: str) -> str:
    os.makedirs(os.path.dirname(os.path.abspath(out_path)), exist_ok=True)
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=_COLUMNS)
        writer.writeheader()
        for r in results:
            writer.writerow(_row_for_csv(r))
    return out_path


def write_telemetry_delta(
    results: list[CaseResult],
    table_name: str,
    *,
    spark_session,
    mode: str = "append",
) -> str:
    """Append CaseResult rows to a UC Delta table.

    `spark_session` is required and must be the notebook's `spark`. We don't
    create one here because Cursor doesn't have spark; this function is
    intentionally a no-op outside a notebook (caller must guard).
    """
    if spark_session is None:
        raise RuntimeError("write_telemetry_delta requires an active spark session")
    rows = [asdict(r) for r in results]
    df = spark_session.createDataFrame(rows)
    df.write.format("delta").mode(mode).saveAsTable(table_name)
    return table_name


def write_telemetry(
    results: list[CaseResult],
    *,
    target: str = "csv",
    out_path: str | None = None,
    table_name: str | None = None,
    spark_session=None,
    mode: str = "append",
) -> str:
    """Single entry point used by both the CLI and notebook.

    target='csv':   writes to `out_path` (required).
    target='delta': appends to `table_name` (required; spark_session required).
    """
    if target == "csv":
        if not out_path:
            raise ValueError("out_path is required for target='csv'")
        return write_telemetry_csv(results, out_path)
    if target == "delta":
        if not table_name:
            raise ValueError("table_name is required for target='delta'")
        return write_telemetry_delta(
            results, table_name, spark_session=spark_session, mode=mode,
        )
    raise ValueError(f"unknown telemetry target: {target!r}")
