"""Eval-suite runtime harness.

This package is intentionally portable: it has zero dependencies on Cursor,
on Synapse / pyodbc, or on any local-only file paths. Anything in here is
expected to work unchanged inside a Databricks notebook.

Authoring-time tooling lives in tools/eval_suite/loop_authoring/ and does
NOT belong here.

Public surface (what the notebook will import):
    from tools.eval_suite.harness import (
        load_cases,        # YAML -> [CaseV1]
        run_case,          # (CaseV1, SUT) -> CaseResult
        score_numeric,     # (expected, observed, tol_pct) -> Score
        write_telemetry,   # (rows, target='delta'|'csv') -> None
    )

The CLI entry point `tools/eval_suite/run_harness.py` is the Cursor-side
driver; the notebook will invoke the same functions directly.
"""
from .schema import CaseV1, Parity, ScoringConfig, GroundTruth, UcEquivalent
from .loader import load_cases
from .scorer import score_numeric, Score, judge_textual_inplace
from .runner import run_case, run_cases, CaseResult
from .telemetry import write_telemetry

__all__ = [
    "CaseV1",
    "Parity",
    "ScoringConfig",
    "GroundTruth",
    "UcEquivalent",
    "load_cases",
    "score_numeric",
    "Score",
    "judge_textual_inplace",
    "run_case",
    "run_cases",
    "CaseResult",
    "write_telemetry",
]
