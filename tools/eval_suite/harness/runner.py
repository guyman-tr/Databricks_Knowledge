"""Glue between cases, SUTs, and scoring.

Single-case path:
    case  -> sut.ask(question, case) -> score_numeric(case, response.numeric_answer)
                                     -> CaseResult

Batch helper (`run_cases`) just iterates and aggregates. The harness is fully
synchronous in v1 — async / parallel calls can be added later if SUT latency
warrants it.

Drift-vs-skill verdict
----------------------
If a baseline SUT (typically `DirectSQLSUT`) is provided to `run_cases`, every
SUT failure gets a `drift_verdict`:

  PASS                — case passed, no investigation needed
  SKILL_GAP           — SUT failed, but baseline (direct_sql) passed at the
                        SAME pinned value -> the canonical SQL still produces
                        the right answer. The SUT (Genie Code / custom MCP)
                        constructed a wrong query or interpreted the question
                        wrongly. Investigate the SUT / skill corpus.
  DATA_DRIFT          — SUT failed, AND baseline also drifted in the same
                        direction by a similar amount -> the underlying UC
                        data has changed (backfill / late-arriving rows). The
                        pinned value is now stale and should be re-pinned. NOT
                        a skill issue.
  BASELINE_BROKEN     — Both SUT and baseline failed but in different
                        directions or by very different magnitudes -> something
                        weirder is happening; manual triage required.
  N/A                 — baseline not run (drift comparison disabled, or SUT == baseline)
"""
from __future__ import annotations

import datetime as dt
import json
import socket
import time
from dataclasses import asdict, dataclass

from .schema import CaseV1
from .scorer import Score, score_numeric
from .suts.base import SUT, SUTResponse


def _extract_trace_fields(response: SUTResponse) -> dict:
    """Project SUTResponse.raw['trace'] (if present) into CaseResult kwargs.

    Returns a dict suitable for ** unpack into CaseResult(...). For SUTs that
    don't emit a trace (mock, direct_sql, databricks_mcp), returns {} and the
    CaseResult fields stay at their dataclass defaults (None).
    """
    raw = response.raw or {}
    trace = raw.get("trace")
    if not isinstance(trace, dict):
        return {}

    sql_execs = trace.get("sql_execs") or []
    return {
        "trace_skills_loaded": json.dumps(trace.get("skills_loaded") or []),
        "trace_sql_executed_count": len(sql_execs),
        "trace_sql_succeeded_count": sum(1 for x in sql_execs if x.get("succeeded")),
        "trace_tool_call_count": trace.get("tool_call_count"),
        "trace_tool_call_by_kind": json.dumps(trace.get("tool_call_by_kind") or {}),
        "trace_mcp_tool_call_by_name": json.dumps(trace.get("mcp_tool_call_by_name") or {}),
        "trace_input_tokens": trace.get("input_tokens"),
        "trace_output_tokens": trace.get("output_tokens"),
        "trace_cache_read_tokens": trace.get("cache_read_tokens"),
        "trace_cache_write_tokens": trace.get("cache_write_tokens"),
        # Truncate the thinking excerpt for CSV friendliness (already truncated in SUT, belt-and-braces)
        "trace_thinking_excerpt": (trace.get("thinking_excerpt") or "")[:1500] or None,
        "trace_session_id": trace.get("session_id"),
        "trace_model": trace.get("model"),
    }


# Treat baseline as "agreeing with SUT direction" if the relative difference
# between the two failures is <= this fraction of the SUT's diff.
_DRIFT_AGREE_TOL_FRACTION = 0.25


@dataclass
class CaseResult:
    """One row of telemetry — one (case, sut, run) triple."""
    run_id: str
    run_started_at: str          # ISO-8601 UTC
    host: str
    case_id: str
    case_status: str
    sut_name: str
    asof: str
    natural_language_question: str
    expected_value: float
    observed_value: float | None
    diff_abs: float | None
    diff_pct: float | None
    tolerance_pct: float
    passed: bool
    reason: str
    sql_used: str | None
    sut_text_answer: str | None
    sut_error: str | None
    elapsed_ms: int
    tags: list[str]
    # Drift-vs-skill differentiator (filled in only when a baseline SUT runs)
    baseline_sut_name: str | None = None
    baseline_value: float | None = None
    baseline_diff_pct: float | None = None
    baseline_passed: bool | None = None
    drift_verdict: str = "N/A"
    # LLM-judge secondary scoring (filled by scorer.judge_textual when enabled)
    judge_score: float | None = None
    judge_label: str | None = None
    judge_rationale: str | None = None
    judge_model: str | None = None
    # Trace-derived telemetry (filled when SUT.raw["trace"] is available — e.g. cursor_agent)
    trace_skills_loaded: str | None = None        # JSON list of {method, slug}
    trace_sql_executed_count: int | None = None
    trace_sql_succeeded_count: int | None = None
    trace_tool_call_count: int | None = None
    trace_tool_call_by_kind: str | None = None    # JSON dict
    trace_mcp_tool_call_by_name: str | None = None  # JSON dict
    trace_input_tokens: int | None = None
    trace_output_tokens: int | None = None
    trace_cache_read_tokens: int | None = None
    trace_cache_write_tokens: int | None = None
    trace_thinking_excerpt: str | None = None
    trace_session_id: str | None = None
    trace_model: str | None = None

    def to_dict(self) -> dict:
        return asdict(self)


def _classify_drift(
    sut_score: Score,
    baseline_score: Score | None,
    sut_response: SUTResponse | None = None,
) -> str:
    """Decide drift_verdict given SUT and (optional) baseline scores.

    MCP-enforcement verdicts (cursor_agent SUT only) take precedence over
    pass/fail: a run that bypassed the MCP is invalid regardless of whether
    the number happened to match the baseline.
    """
    # MCP-enforcement verdicts (precedence over numeric scoring)
    if sut_response is not None:
        raw = sut_response.raw or {}
        if raw.get("mcp_bypass_violations"):
            return "MCP_BYPASS_VIOLATION"
        # `mcp_engaged` is False AND there were tool calls -> agent answered
        # via memorised text or another non-SQL path. Flagged as NOT_ENGAGED
        # only if the SUT had MCP enforcement on (i.e. raw includes the key).
        if "mcp_engaged" in raw and not raw["mcp_engaged"]:
            trace = raw.get("trace") or {}
            if (trace.get("tool_call_count") or 0) > 0:
                return "MCP_NOT_ENGAGED"

    if sut_score.passed:
        return "PASS"
    if baseline_score is None:
        return "N/A"
    if baseline_score.passed:
        # SUT failed but the canonical SQL is fine -> skill gap.
        return "SKILL_GAP"
    # Both failed. Did they fail in agreement?
    if sut_score.diff_pct is None or baseline_score.diff_pct is None:
        return "BASELINE_BROKEN"
    # Same sign and within agreement tolerance?
    same_sign = (sut_score.diff_pct >= 0) == (baseline_score.diff_pct >= 0)
    if not same_sign:
        return "BASELINE_BROKEN"
    denom = max(abs(sut_score.diff_pct), 1e-9)
    rel_gap = abs(sut_score.diff_pct - baseline_score.diff_pct) / denom
    if rel_gap <= _DRIFT_AGREE_TOL_FRACTION:
        return "DATA_DRIFT"
    return "BASELINE_BROKEN"


def run_case(
    case: CaseV1,
    sut: SUT,
    *,
    run_id: str,
    run_started_at: str,
    baseline_sut: SUT | None = None,
) -> CaseResult:
    t0 = time.time()
    response: SUTResponse = sut.ask(case.natural_language_question, case)
    score: Score = score_numeric(case, response.numeric_answer)

    baseline_score: Score | None = None
    baseline_value: float | None = None
    baseline_passed: bool | None = None
    baseline_diff_pct: float | None = None
    baseline_name: str | None = None

    # Don't run the baseline against itself (useless and slow).
    if baseline_sut is not None and baseline_sut.name != sut.name:
        b_resp = baseline_sut.ask(case.natural_language_question, case)
        baseline_score = score_numeric(case, b_resp.numeric_answer)
        baseline_value = baseline_score.observed
        baseline_passed = baseline_score.passed
        baseline_diff_pct = baseline_score.diff_pct
        baseline_name = baseline_sut.name

    drift_verdict = _classify_drift(score, baseline_score, sut_response=response)

    return CaseResult(
        run_id=run_id,
        run_started_at=run_started_at,
        host=socket.gethostname(),
        case_id=case.case_id,
        case_status=case.status,
        sut_name=sut.name,
        asof=case.asof,
        natural_language_question=case.natural_language_question,
        expected_value=score.expected,
        observed_value=score.observed,
        diff_abs=score.diff_abs,
        diff_pct=score.diff_pct,
        tolerance_pct=score.tolerance_pct,
        passed=score.passed,
        reason=score.reason,
        sql_used=response.sql_used,
        sut_text_answer=response.text_answer,
        sut_error=response.error,
        elapsed_ms=response.elapsed_ms or int((time.time() - t0) * 1000),
        tags=case.tags,
        baseline_sut_name=baseline_name,
        baseline_value=baseline_value,
        baseline_diff_pct=baseline_diff_pct,
        baseline_passed=baseline_passed,
        drift_verdict=drift_verdict,
        **_extract_trace_fields(response),
    )


def run_cases(
    cases: list[CaseV1],
    sut: SUT,
    *,
    run_id: str | None = None,
    progress: bool = True,
    baseline_sut: SUT | None = None,
    rebaseline: bool = False,
) -> list[CaseResult]:
    """Run every case once against the same SUT. Synchronous.

    If `baseline_sut` is provided (typically a `DirectSQLSUT`):
      - rebaseline=False (default): baseline is a tie-breaker — only runs on
        SUT failure, used to decide SKILL_GAP vs DATA_DRIFT vs BASELINE_BROKEN
        relative to the YAML pin.
      - rebaseline=True: baseline runs FIRST on every case; its live UC value
        replaces the YAML pin as the ground truth for that run. Use this when
        you want the SUT scored against TODAY's UC data, not against a stale
        pin. The YAML pin still appears in telemetry as a regression breadcrumb.
    """
    if run_id is None:
        run_id = f"run-{dt.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}"
    started = dt.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

    can_rebaseline = (
        rebaseline
        and baseline_sut is not None
        and baseline_sut.name != sut.name
    )

    results: list[CaseResult] = []
    for i, case in enumerate(cases, 1):
        if progress:
            print(f"  [{i:02d}/{len(cases):02d}] {case.case_id} ...", end="", flush=True)

        b_resp_value: float | None = None
        b_text: str | None = None
        if can_rebaseline:
            # Run baseline FIRST so we have a live UC value to score against.
            b_first = baseline_sut.ask(case.natural_language_question, case)
            b_resp_value = b_first.numeric_answer
            b_text = b_first.text_answer

        t0 = time.time()
        response: SUTResponse = sut.ask(case.natural_language_question, case)

        # Score the SUT against the live baseline value if rebaseline mode,
        # otherwise against the YAML pin.
        if can_rebaseline and b_resp_value is not None:
            score: Score = score_numeric(case, response.numeric_answer, expected_override=b_resp_value)
        else:
            score: Score = score_numeric(case, response.numeric_answer)

        b_score: Score | None = None
        b_name: str | None = None
        b_value: float | None = None
        b_passed: bool | None = None
        b_diff_pct: float | None = None

        if can_rebaseline:
            # We already have b_resp_value; compute baseline's score against the YAML pin
            # so we can still classify drift (live UC value vs the historical pin).
            b_score = score_numeric(case, b_resp_value)
            b_name = baseline_sut.name
            b_value = b_resp_value
            b_passed = b_score.passed
            b_diff_pct = b_score.diff_pct
        elif (
            baseline_sut is not None
            and baseline_sut.name != sut.name
            and not score.passed
        ):
            # Tie-breaker mode: only run baseline if SUT failed.
            b_resp = baseline_sut.ask(case.natural_language_question, case)
            b_score = score_numeric(case, b_resp.numeric_answer)
            b_name = baseline_sut.name
            b_value = b_score.observed
            b_passed = b_score.passed
            b_diff_pct = b_score.diff_pct

        drift_verdict = _classify_drift(score, b_score, sut_response=response)

        r = CaseResult(
            run_id=run_id,
            run_started_at=started,
            host=socket.gethostname(),
            case_id=case.case_id,
            case_status=case.status,
            sut_name=sut.name,
            asof=case.asof,
            natural_language_question=case.natural_language_question,
            expected_value=score.expected,
            observed_value=score.observed,
            diff_abs=score.diff_abs,
            diff_pct=score.diff_pct,
            tolerance_pct=score.tolerance_pct,
            passed=score.passed,
            reason=score.reason,
            sql_used=response.sql_used,
            sut_text_answer=response.text_answer,
            sut_error=response.error,
            elapsed_ms=response.elapsed_ms or int((time.time() - t0) * 1000),
            tags=case.tags,
            baseline_sut_name=b_name,
            baseline_value=b_value,
            baseline_diff_pct=b_diff_pct,
            baseline_passed=b_passed,
            drift_verdict=drift_verdict,
            **_extract_trace_fields(response),
        )
        results.append(r)
        if progress:
            verdict = "PASS" if r.passed else "FAIL"
            extras = []
            if r.diff_pct is not None:
                extras.append(f"{r.diff_pct:+.4f}%")
            if r.sut_error:
                extras.append(f"err={r.sut_error[:50]}")
            if r.drift_verdict not in ("PASS", "N/A"):
                extras.append(r.drift_verdict)
            extra = "  (" + ", ".join(extras) + ")" if extras else ""
            print(f"  {verdict}{extra}")
    return results
