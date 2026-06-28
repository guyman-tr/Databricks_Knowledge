"""Generic CLI runner shared by all four watcher apps.

A watcher module supplies a WatchSpec (fetch_current + per-item builders); this
runner does the uniform work: parse args, load the snapshot, fetch current
state, diff, build WorkItems for new/changed keys, run the cycle, optionally
write a manifest, and advance the snapshot baseline on a successful live run.
"""
from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.auto_kb import state
from tools.auto_kb.cycle import run_cycle
from tools.auto_kb.models import ItemOutcome, RunContext, WorkItem
from tools.auto_kb.processor import ActionSpec

KIND_NEW = "new"
KIND_CHANGED = "changed"


@dataclass
class WatchSpec:
    app: str  # runlog key: genie | uc_object | dbschema | confluence
    default_snapshot: str
    # fetch_current(current_override) -> {key: raw_record}
    fetch_current: Callable[[str | None], dict[str, Any]]
    # make_work_item(key, record, change_kind) -> WorkItem
    make_work_item: Callable[[str, Any, str], WorkItem]
    # build_prompt(item, ctx) -> str (live mode)
    build_prompt: Callable[[WorkItem, RunContext], str]
    # simulate(item) -> ItemOutcome (dry-run)
    simulate: Callable[[WorkItem], ItemOutcome]
    model_role: str = ""


def run_app(spec: WatchSpec, argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=f"auto_kb watcher: {spec.app}")
    ap.add_argument(
        "--current",
        default=None,
        help="Path to a JSON file with current state (bypasses live fetch). "
        "Used for fixtures/dry-run and for MCP-produced snapshots.",
    )
    ap.add_argument("--snapshot", default=spec.default_snapshot, help="Baseline snapshot path")
    ap.add_argument("--dry-run", action="store_true", help="Simulate processing; never mutate snapshot/DB/PRs")
    ap.add_argument(
        "--staging",
        action="store_true",
        help="Run live processing in staging mode (ingest/update evidence, but no /skills-push).",
    )
    ap.add_argument("--no-notify", action="store_true", help="Skip notifications")
    ap.add_argument("--no-runlog", action="store_true", help="Skip UC run-log writes")
    ap.add_argument("--stop-on-error", action="store_true", help="Stop after first failure")
    ap.add_argument(
        "--no-adversarial",
        action="store_true",
        help="Disable adversarial durability gate (not recommended for automation).",
    )
    ap.add_argument(
        "--adversarial-min-score",
        type=int,
        default=60,
        help="Heuristic durability floor (0-100) before ingest action is attempted.",
    )
    ap.add_argument("--workspace-cwd", default=".", help="Workspace root for live Cursor SDK execution")
    ap.add_argument("--limit", type=int, default=0, help="Process at most N items (0=all)")
    ap.add_argument("--manifest-out", default=None, help="Write the detected WorkItems to this JSON path")
    ap.add_argument("--detect-only", action="store_true", help="Detect + write manifest, do not process")
    args = ap.parse_args(argv)

    snap = state.load_snapshot(args.snapshot)
    prev_items = snap.get("items", {})

    current_records = spec.fetch_current(args.current)
    curr_items = state.build_items_map(current_records)
    diff = state.diff_hash_maps(prev_items, curr_items)

    print(
        f"[{spec.app}] diff: new={len(diff.new)} changed={len(diff.changed)} "
        f"removed={len(diff.removed)}"
    )
    if diff.removed:
        print(f"[{spec.app}] removed (logged, not processed): {diff.removed}")

    work: list[WorkItem] = []
    for key in diff.new:
        work.append(spec.make_work_item(key, curr_items[key]["meta"], KIND_NEW))
    for key in diff.changed:
        work.append(spec.make_work_item(key, curr_items[key]["meta"], KIND_CHANGED))

    if args.limit and len(work) > args.limit:
        work = work[: args.limit]

    if args.manifest_out:
        manifest = {
            "app": spec.app,
            "new": diff.new,
            "changed": diff.changed,
            "removed": diff.removed,
            "items": [
                {
                    "id": w.id,
                    "kind": w.kind,
                    "title": w.title,
                    "source_ref": w.source_ref,
                    "payload": w.payload,
                }
                for w in work
            ],
        }
        Path(args.manifest_out).parent.mkdir(parents=True, exist_ok=True)
        Path(args.manifest_out).write_text(
            json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        print(f"[{spec.app}] wrote manifest -> {args.manifest_out}")

    if args.detect_only:
        print(f"[{spec.app}] detect-only: {len(work)} item(s); skipping processing")
        return 0

    ctx = RunContext(
        app=spec.app,
        workspace_cwd=Path(args.workspace_cwd).resolve(),
        dry_run=args.dry_run,
        staging=args.staging,
        no_notify=args.no_notify,
        no_runlog=args.no_runlog,
        stop_on_error=args.stop_on_error,
        model_role=spec.model_role,
        adversarial_enabled=not args.no_adversarial,
        adversarial_min_score=max(0, min(int(args.adversarial_min_score), 100)),
    )
    action = ActionSpec(name=spec.app, build_prompt=spec.build_prompt, simulate=spec.simulate)

    def _commit() -> None:
        state.save_snapshot(args.snapshot, spec.app, curr_items)
        print(f"[{spec.app}] snapshot advanced -> {args.snapshot}")

    summary = run_cycle(items=work, spec=action, ctx=ctx, commit_snapshot=_commit)
    return 1 if summary["failures"] else 0
