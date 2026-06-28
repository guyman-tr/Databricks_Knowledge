"""Generic diff -> process -> log -> notify loop.

Mirrors tools/skill_suggestions/run_once.main but app-agnostic: the detector
already produced WorkItems; this engine processes each, records a run-log row,
notifies, aggregates a summary, and (on a fully successful, non-dry run)
advances the state snapshot baseline via an optional commit callback.
"""
from __future__ import annotations

import datetime as _dt
import json
import sys
import uuid
from pathlib import Path
from typing import Callable

if __package__ in {None, ""}:
    sys.path.append(str(Path(__file__).resolve().parents[2]))

from tools.auto_kb import notify, runlog
from tools.auto_kb.models import ItemOutcome, RunContext, WorkItem
from tools.auto_kb.processor import ActionSpec, process_item


def run_cycle(
    *,
    items: list[WorkItem],
    spec: ActionSpec,
    ctx: RunContext,
    commit_snapshot: Callable[[], None] | None = None,
) -> dict:
    run_id = f"{ctx.app}-{_dt.datetime.now(_dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ')}-{uuid.uuid4().hex[:8]}"
    print(f"[{ctx.app}] run_id={run_id} items={len(items)} dry_run={ctx.dry_run}")

    failures = 0
    processed = 0
    results: list[dict] = []

    for item in items:
        try:
            outcome = process_item(item, spec, ctx)
        except Exception as exc:  # noqa: BLE001
            outcome = ItemOutcome(
                item_id=item.id, status="error", ok=False, notes=f"exception: {exc}"
            )

        try:
            runlog.record_outcome(
                app=ctx.app,
                run_id=run_id,
                item=item,
                outcome=outcome,
                dry_run=ctx.dry_run,
                skip=ctx.no_runlog,
            )
        except Exception as exc:  # noqa: BLE001
            print(f"[warn] run-log write failed for {item.id}: {exc}", file=sys.stderr)

        notify.send(
            subject=f"auto_kb/{ctx.app}: {outcome.status} ({item.id})",
            body=(
                f"app={ctx.app}\nrun_id={run_id}\nitem={item.id}\nkind={item.kind}\n"
                f"title={item.title}\nstatus={outcome.status}\n"
                f"artifact={outcome.artifact_ref}\npr_url={outcome.pr_url}\nnotes={outcome.notes}"
            ),
            status="ok" if outcome.ok else "fail",
            channels=ctx.notify_channels,
            dry_run=ctx.dry_run,
            skip=ctx.no_notify,
        )

        processed += 1
        if not outcome.ok:
            failures += 1
        results.append(
            {
                "id": item.id,
                "kind": item.kind,
                "status": outcome.status,
                "ok": outcome.ok,
                "artifact_ref": outcome.artifact_ref,
                "pr_url": outcome.pr_url,
                "notes": outcome.notes,
            }
        )
        if failures and ctx.stop_on_error:
            break

    # Advance baseline only when everything we attempted succeeded and this is a
    # real run. Dry runs never mutate the snapshot.
    committed = False
    if commit_snapshot is not None and not ctx.dry_run and failures == 0:
        commit_snapshot()
        committed = True

    summary = {
        "app": ctx.app,
        "run_id": run_id,
        "total": len(items),
        "processed": processed,
        "failures": failures,
        "dry_run": ctx.dry_run,
        "snapshot_committed": committed,
        "results": results,
    }
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    return summary
