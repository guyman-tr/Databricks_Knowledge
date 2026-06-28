"""Shared dataclasses for the auto_kb framework."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


# Generic item lifecycle status (distinct from the skills-only vocabulary).
VALID_STATUS = {"new", "processing", "done", "skipped", "error"}


@dataclass
class WorkItem:
    """One detected delta to process."""

    id: str
    kind: str  # e.g. "genie_new", "genie_changed", "uc_new_object", ...
    title: str
    payload: dict[str, Any] = field(default_factory=dict)
    source_ref: str = ""  # space_id / FQN / file path / page id


@dataclass
class ItemOutcome:
    item_id: str
    status: str  # one of VALID_STATUS
    ok: bool
    artifact_ref: str | None = None  # wiki path, skill id, evidence path
    pr_url: str | None = None
    notes: str = ""


@dataclass
class RunContext:
    app: str
    workspace_cwd: Path
    dry_run: bool = True
    staging: bool = False  # live ingest/update without production push
    no_notify: bool = False
    no_runlog: bool = False
    stop_on_error: bool = False
    notify_channels: tuple[str, ...] = ("teams",)
    model_role: str = ""  # forwarded to CURSOR_AGENT_MODEL_<ROLE> resolution
    adversarial_enabled: bool = True
    adversarial_min_score: int = 60
