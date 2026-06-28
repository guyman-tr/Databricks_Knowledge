#!/usr/bin/env python3
"""Incident memory bank helpers for migration_autoloop."""
from __future__ import annotations

import csv
from pathlib import Path
from typing import Any

MEMORY_FIELDS = [
    "event_ts",
    "run_id",
    "pipeline_name",
    "status",
    "issue_key",
    "error_excerpt",
    "root_cause",
    "recommended_fix",
    "retry_count",
    "qa_compared_count",
    "qa_mismatch_count",
    "qa_error_count",
    "evidence_path",
]


def _normalize_excerpt(text: str, max_len: int = 500) -> str:
    clean = " ".join((text or "").strip().split())
    return clean[:max_len]


def classify_issue(error_text: str) -> tuple[str, str, str]:
    text = (error_text or "").lower()

    if "local_variable_in_temp_object_definition" in text:
        return (
            "dbsql.local_var_in_temp_object",
            "Databricks SQL scripting variable used inside temp object definition.",
            "Inline the expression, switch to session vars correctly, or avoid temp views in procedures.",
        )
    if "call_in_execute_immediate" in text:
        return (
            "dbsql.call_in_execute_immediate",
            "Nested CALL executed inside EXECUTE IMMEDIATE is disallowed.",
            "Call procedures directly; do not wrap CALL in EXECUTE IMMEDIATE.",
        )
    if "unresolved_routine" in text and "lastrowcount" in text:
        return (
            "transpile.missing_helper_lastrowcount",
            "Transpiled SQL still references SQL Server helper routine dbo.LastRowCount.",
            "Remove helper logging calls or replace with Databricks-native logging.",
        )
    if "incompatible_column_type" in text:
        return (
            "schema.union_column_type_mismatch",
            "UNION inputs have mismatched column types between staging tables.",
            "Align source column types before UNION (e.g., cast/rebuild table schema).",
        )
    if "table_or_view_not_found" in text:
        return (
            "object.missing_table_or_view",
            "Expected source object missing under canonical name.",
            "Create compatibility view/alias or update SQL to actual object name.",
        )
    if "unable to fetch sql file from path" in text:
        return (
            "orchestration.workspace_file_unavailable",
            "Databricks SQL task path points to missing or wrong object type.",
            "Re-import as WORKSPACE FILE and validate path exists before job run.",
        )
    if "qa_parity_no_rows" in text:
        return (
            "qa.no_rows_compared",
            "No QA rows were produced for mapped tables.",
            "Validate table mapping and ensure comparison job populated gold_phase_comparison.",
        )
    if "parity_fail date=" in text:
        return (
            "qa.parity_gate_failed",
            "Databricks parity gate failed on target date counts/sums.",
            "Validate target-date baseline snapshot, then rerun helper SP chain and parity gate.",
        )
    if "qa_mismatch=" in text or "qa_error=" in text:
        return (
            "qa.parity_failed",
            "QA parity comparison found mismatches or errors.",
            "Inspect latest comparison rows and fix transformation or snapshot timing issues.",
        )
    if "deploy_hook_failed" in text:
        return (
            "hook.deploy_failed",
            "Deploy/transpile hook command failed.",
            "Inspect deploy hook stderr and stabilize deploy script inputs.",
        )
    if "run_hook_failed" in text:
        return (
            "hook.run_failed",
            "Run hook command failed.",
            "Inspect run hook stderr and validate job/task prerequisites.",
        )
    return (
        "unknown.unclassified",
        "Issue signature not yet classified.",
        "Review evidence JSON and add a classifier entry for this signature.",
    )


def append_memory_event(
    memory_bank_csv: Path,
    *,
    event_ts: str,
    run_id: str,
    pipeline_name: str,
    status: str,
    raw_error_text: str,
    retry_count: int,
    qa_compared_count: int,
    qa_mismatch_count: int,
    qa_error_count: int,
    evidence_path: str,
) -> None:
    issue_key, root_cause, recommended_fix = classify_issue(raw_error_text)
    row: dict[str, Any] = {
        "event_ts": event_ts,
        "run_id": run_id,
        "pipeline_name": pipeline_name,
        "status": status,
        "issue_key": issue_key,
        "error_excerpt": _normalize_excerpt(raw_error_text),
        "root_cause": root_cause,
        "recommended_fix": recommended_fix,
        "retry_count": retry_count,
        "qa_compared_count": qa_compared_count,
        "qa_mismatch_count": qa_mismatch_count,
        "qa_error_count": qa_error_count,
        "evidence_path": evidence_path,
    }

    memory_bank_csv.parent.mkdir(parents=True, exist_ok=True)
    write_header = not memory_bank_csv.exists()
    with memory_bank_csv.open("a", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=MEMORY_FIELDS)
        if write_header:
            writer.writeheader()
        writer.writerow(row)

