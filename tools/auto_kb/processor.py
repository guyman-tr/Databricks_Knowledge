"""Per-item processor: dry-run simulation or live Cursor SDK execution."""
from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.auto_kb.models import ItemOutcome, RunContext, WorkItem

# Map the agent's RESULT_JSON status vocabulary onto the auto_kb lifecycle.
_AGENT_STATUS_MAP = {
    "done": "done",
    "pushed": "done",
    "skipped": "skipped",
    "skipped_overlap": "skipped",
    "error": "error",
}


@dataclass
class ActionSpec:
    """Defines how one app turns a WorkItem into an action.

    build_prompt: produces the Cursor agent prompt (live mode).
    simulate:     produces a deterministic dry-run outcome (no external calls).
    """

    name: str
    build_prompt: Callable[[WorkItem, RunContext], str]
    simulate: Callable[[WorkItem], ItemOutcome]


@dataclass
class GateDecision:
    status: str  # approve | reject | review
    score: int
    notes: str


def _model_for(role: str) -> str | None:
    if not role:
        return os.environ.get("CURSOR_AGENT_MODEL")
    return os.environ.get(f"CURSOR_AGENT_MODEL_{role.upper()}") or os.environ.get(
        "CURSOR_AGENT_MODEL"
    )


def _heuristic_gate(item: WorkItem, min_score: int) -> GateDecision:
    text = f"{item.title} {item.source_ref} {item.kind}".lower()
    score = 70
    reasons: list[str] = []

    hard_trivial_tokens = ("tmp", "temp", "test", "sandbox", "adhoc", "backup", "sample", "demo")
    if any(tok in text for tok in hard_trivial_tokens):
        score -= 45
        reasons.append("contains temporary/testing marker")

    ephemeral_tokens = ("csv", "excel", "xlsx", "export", "tag", "list")
    if any(tok in text for tok in ephemeral_tokens):
        score -= 20
        reasons.append("looks like export/tag/list artifact")

    has_date_signal = bool(
        re.search(r"(?:19|20)\d{2}", text)
        or re.search(r"\b(?:jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\b", text)
        or re.search(r"(?:jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)[_-]?\d{1,4}", text)
        or re.search(r"\bq[1-4]\b", text)
        or re.search(r"\b(?:20)?\d{2}[_-]?(?:0[1-9]|1[0-2])\b", text)
    )
    if has_date_signal:
        score -= 20
        reasons.append("has date/version stamp (potentially temporary)")

    n_cols = int(item.payload.get("n_columns") or 0)
    if n_cols and n_cols <= 3:
        score -= 10
        reasons.append("very small object footprint")

    if item.kind.startswith("confluence_") and item.payload.get("tracked_skill"):
        score += 15
        reasons.append("tracked skill-backing page")

    if item.kind.startswith("genie_") and int(item.payload.get("score") or 0) >= 40:
        score += 10
        reasons.append("high curation genie space")

    score = max(0, min(score, 100))
    if score < min_score:
        return GateDecision("reject", score, "; ".join(reasons) or "below durability threshold")
    if score < min_score + 10:
        return GateDecision("review", score, "; ".join(reasons) or "borderline durability")
    return GateDecision("approve", score, "; ".join(reasons) or "durability signal passed")


def _adversarial_gate(item: WorkItem, ctx: RunContext, heuristic: GateDecision) -> GateDecision:
    # Lazy import so dry-run never requires cursor_sdk.
    from tools.skill_suggestions.agent_runner import run_cursor_agent_prompt

    prompt = (
        "You are an adversarial durability judge for automated knowledge ingestion.\n"
        "Goal: block trivial/ephemeral/noisy findings from becoming skills.\n\n"
        "Evaluate this candidate and decide if it is durable enough for long-term skill memory.\n"
        f"- app: {ctx.app}\n"
        f"- item_id: {item.id}\n"
        f"- kind: {item.kind}\n"
        f"- title: {item.title}\n"
        f"- source_ref: {item.source_ref}\n"
        f"- payload: {item.payload}\n"
        f"- heuristic_status: {heuristic.status}\n"
        f"- heuristic_score: {heuristic.score}\n"
        f"- heuristic_notes: {heuristic.notes}\n\n"
        "Reject when likely temporary (dated/export/test artifacts), shallow, "
        "or not reusable beyond a one-off context.\n"
        "Approve only for durable domain concepts with reusable analytical value.\n\n"
        "Return exactly one line:\n"
        'RESULT_JSON:{"status":"approve|reject|review","notes":"short reason"}\n'
    )
    result = run_cursor_agent_prompt(
        prompt=prompt,
        workspace_cwd=ctx.workspace_cwd,
        model_id=_model_for("adversarial"),
    )
    status = (result.final_status or "").strip().lower()
    if status not in {"approve", "reject", "review"}:
        return GateDecision(
            status="review",
            score=heuristic.score,
            notes=f"adversarial parser fallback: {result.notes}",
        )
    return GateDecision(status=status, score=heuristic.score, notes=result.notes)


def process_item(item: WorkItem, spec: ActionSpec, ctx: RunContext) -> ItemOutcome:
    if ctx.dry_run:
        heuristic = _heuristic_gate(item, ctx.adversarial_min_score)
        if heuristic.status == "reject":
            return ItemOutcome(
                item_id=item.id,
                status="skipped",
                ok=True,
                artifact_ref=None,
                pr_url=None,
                notes=f"dry-run adversarial-heuristic reject (score={heuristic.score}): {heuristic.notes}",
            )
        out = spec.simulate(item)
        out.notes = f"{out.notes} | dry-run gate={heuristic.status} score={heuristic.score} ({heuristic.notes})"
        return out

    heuristic = _heuristic_gate(item, ctx.adversarial_min_score)
    if heuristic.status == "reject":
        return ItemOutcome(
            item_id=item.id,
            status="skipped",
            ok=True,
            artifact_ref=None,
            pr_url=None,
            notes=f"adversarial-heuristic reject (score={heuristic.score}): {heuristic.notes}",
        )

    gate = heuristic
    if ctx.adversarial_enabled:
        try:
            gate = _adversarial_gate(item, ctx, heuristic)
        except Exception as exc:  # noqa: BLE001
            gate = GateDecision(
                status=heuristic.status,
                score=heuristic.score,
                notes=f"adversarial unavailable; fallback heuristic: {exc}",
            )

    if gate.status != "approve":
        return ItemOutcome(
            item_id=item.id,
            status="skipped",
            ok=True,
            artifact_ref=None,
            pr_url=None,
            notes=f"adversarial gate {gate.status} (score={gate.score}): {gate.notes}",
        )

    # Staging safety: UC processing currently times out in Cursor SDK live calls.
    # Keep pipeline moving with deterministic staged outcomes once gate approved.
    if ctx.staging and spec.name == "uc_object":
        out = spec.simulate(item)
        out.notes = f"staging deterministic UC processing: {out.notes} | gate=approve score={gate.score} ({gate.notes})"
        return out

    # Lazy import so dry-run never requires cursor_sdk.
    from tools.skill_suggestions.agent_runner import run_cursor_agent_prompt

    prompt = spec.build_prompt(item, ctx)
    result = run_cursor_agent_prompt(
        prompt=prompt,
        workspace_cwd=ctx.workspace_cwd,
        model_id=_model_for(ctx.model_role),
    )
    status = _AGENT_STATUS_MAP.get(result.final_status, "error")
    return ItemOutcome(
        item_id=item.id,
        status=status,
        ok=status in {"done", "skipped"},
        artifact_ref=None,
        pr_url=result.pr_url,
        notes=f"{result.notes} | gate=approve score={gate.score} ({gate.notes})",
    )
