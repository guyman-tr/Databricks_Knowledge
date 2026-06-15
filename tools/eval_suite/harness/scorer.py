"""Scoring for one (case, sut_response) pair.

V1 is intentionally minimal: a numeric tolerance gate. The case YAML's
`scoring.numeric_tolerance_pct` is the per-case knob; harness-level overrides
can be passed to `score_numeric` directly.

Important semantics:
- Score is computed against `case.uc_equivalent.value` (the UC ground truth),
  NOT against `case.ground_truth.value` (the Synapse pin). The Synapse pin is
  a parity/sanity reference; the UC value is the source of truth at runtime.
  This is consistent with the user's directive: 'once obtained a truth, we
  dont care about synapse anymore. once established, the equivalent dbx
  query is the EVAL.'
- A null SUT answer is always a fail (cannot match anything within tolerance).
- We use relative tolerance (pct) by default; if the expected value is exactly
  zero, we fall back to absolute tolerance of 1.0 (anything less is a pass).
"""
from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from typing import TYPE_CHECKING

from .schema import CaseV1

if TYPE_CHECKING:
    from .runner import CaseResult


@dataclass
class Score:
    passed: bool
    expected: float
    observed: float | None
    diff_abs: float | None
    diff_pct: float | None
    tolerance_pct: float
    reason: str


def score_numeric(
    case: CaseV1,
    observed: float | None,
    *,
    tolerance_pct_override: float | None = None,
    expected_override: float | None = None,
) -> Score:
    """Score the SUT's `observed` against ground truth.

    By default the ground truth is the YAML-pinned `case.uc_equivalent.value`.
    Pass `expected_override` to score against a live-from-UC value instead
    (the rebaseline-on-each-run mode); the YAML pin is still useful for
    regression detection but the live value is the per-run truth.
    """
    expected = expected_override if expected_override is not None else case.uc_equivalent.value
    tol = (
        tolerance_pct_override
        if tolerance_pct_override is not None
        else case.scoring.numeric_tolerance_pct
    )

    if observed is None:
        return Score(
            passed=False, expected=expected, observed=None,
            diff_abs=None, diff_pct=None, tolerance_pct=tol,
            reason="SUT returned no numeric answer",
        )

    diff_abs = observed - expected
    if expected == 0:
        # Avoid div-by-zero; treat anything within +/-1.0 as a pass.
        passed = abs(diff_abs) <= 1.0
        reason = (
            f"expected=0; observed={observed:,.4f}; "
            f"|diff|={abs(diff_abs):,.4f} {'<=' if passed else '>'} 1.0 (absolute fallback)"
        )
        return Score(
            passed=passed, expected=expected, observed=observed,
            diff_abs=diff_abs, diff_pct=None, tolerance_pct=tol,
            reason=reason,
        )

    diff_pct = (diff_abs / expected) * 100.0
    passed = abs(diff_pct) <= tol
    reason = (
        f"expected={expected:,.4f}; observed={observed:,.4f}; "
        f"diff={diff_pct:+.4f}% {'<=' if passed else '>'} tol={tol}%"
    )
    return Score(
        passed=passed, expected=expected, observed=observed,
        diff_abs=diff_abs, diff_pct=diff_pct, tolerance_pct=tol,
        reason=reason,
    )


# ---------------------------------------------------------------------------
# LLM-judge secondary scorer
# ---------------------------------------------------------------------------
#
# Why a judge ON TOP of numeric scoring?
#   Numeric scoring needs the SUT to have produced a clean number. A real SUT
#   (Genie Code, custom MCP) replies with prose: "Yesterday's revenue was about
#   $4.2M, driven mostly by overnight fees ($1.7M)." A free-text answer might
#   contain the right number but our numeric extractor missed it, OR the free
#   text might be qualitatively wrong even when a number happens to land in
#   tolerance. The judge gives us a SECOND, qualitative signal.
#
#   We deliberately do NOT use the judge to override the numeric verdict. The
#   primary verdict stays numeric (deterministic, replayable). The judge is a
#   secondary annotation that lives alongside it in telemetry.
#
# Skip-when-unset
#   If ANTHROPIC_API_KEY is not in env, judge_textual_inplace is a no-op. This
#   keeps the harness usable in environments without LLM access (CI sandbox,
#   restricted Databricks workspaces, offline laptops).

_JUDGE_MODEL_DEFAULT = os.environ.get("EVAL_JUDGE_MODEL", "claude-sonnet-4-5")

_JUDGE_PROMPT = """You are grading a data analyst's answer for FACTUAL CORRECTNESS.

You will be shown:
  - The natural-language question.
  - The pinned ground-truth value (a single scalar; this is the correct answer).
  - The system's full answer text.

Decide whether the system's answer is CORRECT, PARTIAL, INCORRECT, or
UNPARSEABLE relative to the pinned value.

Definitions:
  CORRECT      = the answer states the right scalar (within ~0.5%) AND any
                 narrative around it is consistent with that scalar.
  PARTIAL      = the right ballpark scalar appears, but the narrative is
                 misleading, hedges incorrectly, or attributes the value to
                 the wrong driver.
  INCORRECT    = the answer states a different scalar, or asserts a different
                 conclusion, OR refuses / says it cannot answer.
  UNPARSEABLE  = no scalar value is extractable from the answer.

Be strict. Do not give credit for vague answers. Use only the evidence shown.

Respond with a single JSON object on one line, no markdown, no preamble:
{{"label": "<one of CORRECT|PARTIAL|INCORRECT|UNPARSEABLE>", "score": <0.0 to 1.0>, "rationale": "<<= 30 words>"}}
"""


def _build_judge_user_msg(question: str, pinned_value: float, sut_answer: str | None, sut_error: str | None) -> str:
    if not sut_answer and sut_error:
        sut_answer = f"[SUT ERRORED] {sut_error}"
    if not sut_answer:
        sut_answer = "[SUT returned empty answer]"
    return (
        f"Question: {question}\n\n"
        f"Pinned correct answer: {pinned_value:,.4f}\n\n"
        f"System's answer:\n---\n{sut_answer}\n---"
    )


def _parse_judge_json(raw: str) -> dict:
    """Best-effort JSON parse from model output. Falls back to UNPARSEABLE."""
    raw = raw.strip()
    # Strip ```json fences if model added them despite instructions.
    raw = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw, flags=re.MULTILINE).strip()
    try:
        d = json.loads(raw)
    except json.JSONDecodeError:
        # Try to extract the first {...} blob.
        m = re.search(r"\{.*\}", raw, flags=re.DOTALL)
        if not m:
            return {"label": "UNPARSEABLE", "score": 0.0, "rationale": f"could not parse: {raw[:80]}"}
        try:
            d = json.loads(m.group(0))
        except json.JSONDecodeError:
            return {"label": "UNPARSEABLE", "score": 0.0, "rationale": f"could not parse: {raw[:80]}"}
    return d


def judge_textual_inplace(
    results: list["CaseResult"],
    case_by_id: dict[str, CaseV1],
    *,
    model: str | None = None,
) -> None:
    """Mutate each CaseResult in-place with judge_score / judge_label / judge_rationale.

    Skips silently if ANTHROPIC_API_KEY is not set, or if the anthropic SDK is
    not installed. Per-result errors do NOT abort the whole batch.
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("  (judge: ANTHROPIC_API_KEY not set; skipping)")
        return
    try:
        import anthropic  # type: ignore[import-not-found]
    except ImportError:
        print("  (judge: `pip install anthropic` to enable; skipping)")
        return

    client = anthropic.Anthropic(api_key=api_key)
    use_model = model or _JUDGE_MODEL_DEFAULT

    label_to_score = {"CORRECT": 1.0, "PARTIAL": 0.5, "INCORRECT": 0.0, "UNPARSEABLE": 0.0}

    for r in results:
        case = case_by_id.get(r.case_id)
        if case is None:
            continue
        user_msg = _build_judge_user_msg(
            r.natural_language_question,
            case.uc_equivalent.value,
            r.sut_text_answer,
            r.sut_error,
        )
        try:
            resp = client.messages.create(
                model=use_model,
                max_tokens=200,
                system=_JUDGE_PROMPT,
                messages=[{"role": "user", "content": user_msg}],
            )
            raw = "".join(
                block.text for block in resp.content if getattr(block, "type", None) == "text"
            )
            parsed = _parse_judge_json(raw)
            label = str(parsed.get("label", "UNPARSEABLE")).upper()
            label = label if label in label_to_score else "UNPARSEABLE"
            try:
                score_val = float(parsed.get("score", label_to_score[label]))
            except (TypeError, ValueError):
                score_val = label_to_score[label]
            r.judge_score = max(0.0, min(1.0, score_val))
            r.judge_label = label.lower()
            r.judge_rationale = str(parsed.get("rationale", ""))[:500]
            r.judge_model = use_model
        except Exception as e:
            r.judge_score = None
            r.judge_label = None
            r.judge_rationale = f"[judge error] {e!s}"[:500]
            r.judge_model = use_model
